import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:sangeet/app.dart';
import 'package:sangeet/services/spotify_plugin/spotify_plugin.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/streaming_server.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/services/equalizer_service.dart';
import 'package:sangeet/services/bluetooth_audio_service.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/custom_playlist_service.dart';
import 'package:sangeet/services/track_matcher_service.dart';
import 'package:sangeet/services/playback_state_service.dart';
import 'package:sangeet/services/sharing/deep_link_handler_service.dart';
import 'package:sangeet/services/recommendation_service.dart';
import 'package:sangeet/services/listening_stats_service.dart';
import 'package:sangeet/services/wrapped_service.dart';
import 'package:sangeet/services/album_color_service.dart';

/// Check if running on desktop platform
bool get kIsDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Global navigator key for plugin webview navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main(List<String> args) async {
  // Handle desktop webview window subprocess (required for desktop_webview_window)
  // This must be the first thing in main() for desktop platforms
  if (kIsDesktop && args.firstOrNull == 'multi_window') {
    runWebViewTitleBarWidget(args);
    return;
  }
  // Run app in a zone that filters out multicast DNS errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Fix SSL certificate verification issues on Windows
    // This allows self-signed or problematic certificates to work
    if (kIsDesktop) {
      HttpOverrides.global = _MyHttpOverrides();
    }
    
    // Initialize MediaKit
    MediaKit.ensureInitialized();
    
    // Initialize audio handler for lock screen media controls EARLY
    // This must happen before any audio playback
    try {
      await AudioPlayerService().initAudioHandler();
      print('AudioHandler: Initialized for lock screen controls');
    } catch (e) {
      print('AudioHandler: Init failed: $e');
    }
    
    // Initialize YTMusic service early (so home page loads faster)
    YtMusicService().init().then((_) {
      print('YtMusicService: Pre-initialized');
    }).catchError((e) {
      print('YtMusicService: Pre-init failed: $e');
    });
    
    // Start streaming server early
    StreamingServer().start().then((_) {
      print('StreamingServer: Pre-started');
    }).catchError((e) {
      print('StreamingServer: Pre-start failed: $e');
    });
    
    // Initialize play history service (for personalized recommendations)
    PlayHistoryService.instance.init().then((_) {
      print('PlayHistoryService: Initialized');
    }).catchError((e) {
      print('PlayHistoryService: Init failed: $e');
    });
    
    // Initialize custom playlist service
    CustomPlaylistService.instance.init().then((_) {
      print('CustomPlaylistService: Initialized');
    }).catchError((e) {
      print('CustomPlaylistService: Init failed: $e');
    });
    
    // Initialize equalizer service
    EqualizerService.instance.init().then((_) {
      print('EqualizerService: Initialized');
    }).catchError((e) {
      print('EqualizerService: Init failed: $e');
    });
    
    // Initialize Bluetooth audio service
    BluetoothAudioService.instance.init().then((_) {
      print('BluetoothAudioService: Initialized');
    }).catchError((e) {
      print('BluetoothAudioService: Init failed: $e');
    });
    
    // Initialize track matcher cache (for faster song matching on restart)
    TrackMatcherService().initCache().then((_) {
      print('TrackMatcherService: Cache initialized');
    }).catchError((e) {
      print('TrackMatcherService: Cache init failed: $e');
    });
    
    // Initialize stream URL cache (for instant playback of recently played songs)
    StreamingServer().initStreamCache().then((_) {
      print('StreamingServer: Stream cache initialized');
    }).catchError((e) {
      print('StreamingServer: Stream cache init failed: $e');
    });
    
    // Initialize playback state service and restore last played track
    PlaybackStateService.instance.init().then((_) async {
      print('PlaybackStateService: Initialized');
      // Restore last played track (shows in mini player)
      final restored = await AudioPlayerService().restoreLastPlayedTrack();
      if (restored) {
        print('PlaybackStateService: Last played track restored');
      }
    }).catchError((e) {
      print('PlaybackStateService: Init failed: $e');
    });
    
    // Initialize listening stats service (for analytics dashboard)
    ListeningStatsService.instance.init().then((_) {
      print('ListeningStatsService: Initialized');
    }).catchError((e) {
      print('ListeningStatsService: Init failed: $e');
    });
    
    // Initialize recommendation service (for daily mixes and personalization)
    RecommendationService.instance.init().then((_) {
      print('RecommendationService: Initialized');
    }).catchError((e) {
      print('RecommendationService: Init failed: $e');
    });
    
    // Initialize wrapped service (for year-end stats)
    WrappedService.instance.init().then((_) {
      print('WrappedService: Initialized');
    }).catchError((e) {
      print('WrappedService: Init failed: $e');
    });
    
    // Request notification permission for Android 13+
    try {
      final status = await Permission.notification.request();
      print('Notification permission: $status');
    } catch (e) {
      print('Notification permission request failed: $e');
    }
    
    // Initialize Deep Link Handler for sharing (lightweight, can run during splash)
    DeepLinkHandlerService.instance.init(navigatorKey: rootNavigatorKey).then((_) {
      print('DeepLinkHandlerService: Initialized');
    }).catchError((e) {
      print('DeepLinkHandlerService: Init failed: $e');
    });
    
    // NOTE: SpotifyPlugin initialization is deferred to after splash video
    // to prioritize video codec and reduce startup lag.
    // See initializeHeavyServices() which is called from SplashVideoPage.onComplete
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    runApp(
      const ProviderScope(
        child: SangeetApp(),
      ),
    );
  }, (error, stack) {
    final errorStr = error.toString();
    
    // Filter out multicast DNS socket errors from youtube_explode
    if (error is SocketException) {
      final msg = error.message;
      final addr = error.address?.address;
      if (msg.contains('Send failed') && addr == '0.0.0.0') {
        return; // Suppress multicast DNS errors
      }
    }
    
    // Filter out media_kit database errors (internal to the library)
    if (errorStr.contains('DatabaseException') || 
        errorStr.contains('no current transaction') ||
        errorStr.contains('database_closed')) {
      return; // Suppress media_kit internal database errors
    }
    
    // Filter out PathNotFoundException from media_kit
    if (errorStr.contains('PathNotFoundException') && 
        errorStr.contains('NativeReferenceHolder')) {
      return; // Suppress media_kit file errors
    }
    
    // Filter out FormatException for empty strings (often from parsing)
    if (error is FormatException && errorStr.contains('Invalid number')) {
      return; // Suppress number parsing errors
    }
    
    // Print other errors
    print('App Error: $error');
  });
}

/// Initialize heavy services after splash video completes
/// This defers CPU-intensive work (like Hetu bytecode compilation) to after
/// the video codec has finished, preventing video lag during splash
Future<void> initializeHeavyServices() async {
  // Initialize Spotify Plugin (heavy - loads Hetu bytecode)
  try {
    await SpotifyPluginService.initialize(navigatorKey: rootNavigatorKey);
    print('SpotifyPlugin: Initialized successfully');
  } catch (e, stack) {
    print('SpotifyPlugin: Failed to initialize: $e');
    print(stack);
  }
}

/// Custom HttpOverrides to bypass SSL certificate verification on desktop
/// This fixes CERTIFICATE_VERIFY_FAILED errors on Windows
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
