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
import 'package:sangeet/services/recently_played_service.dart';
import 'package:sangeet/services/user_taste_service.dart';

/// Check if running on desktop platform
bool get kIsDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Global navigator key for plugin webview navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Initialize all app services. Called by splash page after video finishes.
/// Returns a Future that completes when all critical services are ready.
Future<void> initializeAllServices() async {
  print('Services: Starting initialization...');
  
  // === PHASE 1: Critical services (needed for playback) ===
  try {
    await AudioPlayerService().initAudioHandler();
    print('AudioHandler: Initialized for lock screen controls');
  } catch (e) {
    print('AudioHandler: Init failed: $e');
  }
  
  // Stream cache + streaming server (needed for playback)
  try {
    await StreamingServer().initStreamCache();
    print('StreamingServer: Stream cache initialized');
  } catch (e) {
    print('StreamingServer: Stream cache init failed: $e');
  }
  
  try {
    await StreamingServer().start();
    print('StreamingServer: Pre-started');
  } catch (e) {
    print('StreamingServer: Pre-start failed: $e');
  }
  
  // Equalizer (affects audio output immediately)
  try {
    await EqualizerService.instance.init();
    print('EqualizerService: Initialized');
  } catch (e) {
    print('EqualizerService: Init failed: $e');
  }
  
  // Track matcher cache (for faster song matching on restart)
  TrackMatcherService().initCache().then((_) {
    print('TrackMatcherService: Cache initialized');
  }).catchError((e) {
    print('TrackMatcherService: Cache init failed: $e');
  });
  
  // Playback state + restore last track (shows in mini player)
  try {
    await PlaybackStateService.instance.init();
    print('PlaybackStateService: Initialized');
    final restored = await AudioPlayerService().restoreLastPlayedTrack();
    if (restored) {
      print('PlaybackStateService: Last played track restored');
    }
  } catch (e) {
    print('PlaybackStateService: Init failed: $e');
  }
  
  // Request notification permission for Android 13+
  try {
    final status = await Permission.notification.request();
    print('Notification permission: $status');
  } catch (e) {
    print('Notification permission request failed: $e');
  }
  
  // Initialize Spotify Plugin (needed for auth state check)
  try {
    await SpotifyPluginService.initialize(navigatorKey: rootNavigatorKey);
    print('SpotifyPlugin: Initialized successfully');
  } catch (e, stack) {
    print('SpotifyPlugin: Failed to initialize: $e');
    print(stack);
  }
  
  print('Services: Phase 1 complete');
  
  // === PHASE 2: Secondary services (fire-and-forget, don't block splash) ===
  UserTasteService.instance.init().then((_) {
    print('UserTasteService: Initialized');
  }).catchError((e) {
    print('UserTasteService: Init failed: $e');
  });
  
  YtMusicService().init().then((_) {
    print('YtMusicService: Pre-initialized');
  }).catchError((e) {
    print('YtMusicService: Pre-init failed: $e');
  });
  
  PlayHistoryService.instance.init().then((_) {
    print('PlayHistoryService: Initialized');
  }).catchError((e) {
    print('PlayHistoryService: Init failed: $e');
  });
  
  RecentlyPlayedService.instance.init().then((_) {
    print('RecentlyPlayedService: Initialized');
  }).catchError((e) {
    print('RecentlyPlayedService: Init failed: $e');
  });
  
  CustomPlaylistService.instance.init().then((_) {
    print('CustomPlaylistService: Initialized');
  }).catchError((e) {
    print('CustomPlaylistService: Init failed: $e');
  });
  
  DeepLinkHandlerService.instance.init(navigatorKey: rootNavigatorKey).then((_) {
    print('DeepLinkHandlerService: Initialized');
  }).catchError((e) {
    print('DeepLinkHandlerService: Init failed: $e');
  });
  
  // === PHASE 3: Non-critical services (fire-and-forget) ===
  BluetoothAudioService.instance.init().then((_) {
    print('BluetoothAudioService: Initialized');
  }).catchError((e) {
    print('BluetoothAudioService: Init failed: $e');
  });
  
  ListeningStatsService.instance.init().then((_) {
    print('ListeningStatsService: Initialized');
  }).catchError((e) {
    print('ListeningStatsService: Init failed: $e');
  });
  
  RecommendationService.instance.init().then((_) {
    print('RecommendationService: Initialized');
  }).catchError((e) {
    print('RecommendationService: Init failed: $e');
  });
  
  WrappedService.instance.init().then((_) {
    print('WrappedService: Initialized');
  }).catchError((e) {
    print('WrappedService: Init failed: $e');
  });
  
  print('Services: All initialization dispatched');
}

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
    
    // Initialize MediaKit (needed for splash video)
    MediaKit.ensureInitialized();
    
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
    
    // Launch app immediately - splash page handles service initialization
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

/// Custom HttpOverrides to bypass SSL certificate verification on desktop
/// This fixes CERTIFICATE_VERIFY_FAILED errors on Windows
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
