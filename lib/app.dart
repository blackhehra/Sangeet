import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/features/home/pages/home_page.dart';
import 'package:sangeet/features/search/pages/search_page.dart';
import 'package:sangeet/features/library/pages/library_page.dart';
import 'package:sangeet/features/player/widgets/mini_player.dart';
import 'package:sangeet/features/onboarding/pages/onboarding_page.dart';
import 'package:sangeet/features/desktop/pages/desktop_shell.dart';
import 'package:sangeet/features/splash/pages/splash_video_page.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/playback_state_service.dart';
import 'package:sangeet/services/streaming_server.dart';
import 'package:sangeet/main.dart' show rootNavigatorKey;
import 'package:iconsax/iconsax.dart';

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class SangeetApp extends ConsumerWidget {
  const SangeetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(userPreferencesServiceProvider);
    
    return MaterialApp(
      title: 'Sangeet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      navigatorKey: rootNavigatorKey, // Use global navigator key for plugin webview
      home: SplashVideoPage(
        videoAsset: 'assets/videos/splash.mp4',
        child: userPrefs.onboardingCompleted 
            ? (isDesktop ? const DesktopShell() : const MainShell())
            : const OnboardingPage(),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

// Global navigator keys for each tab
final homeNavigatorKey = GlobalKey<NavigatorState>();
final searchNavigatorKey = GlobalKey<NavigatorState>();
final libraryNavigatorKey = GlobalKey<NavigatorState>();

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save playback state when app goes to background or is paused
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _savePlaybackState();
    }
  }

  Future<void> _savePlaybackState() async {
    final audioService = AudioPlayerService();
    final track = audioService.currentTrack;
    if (track != null) {
      await PlaybackStateService.instance.savePlaybackState(
        track: track,
        position: audioService.position,
        queue: audioService.queue,
        queueIndex: audioService.currentIndex,
      );
      print('App: Saved playback state on background');
    }
    
    // Save stream URL cache for iOS (important for app restart)
    await StreamingServer().saveStreamCache();
  }

  // Handle back button press - pop within tab first, then switch tabs
  Future<bool> _onWillPop() async {
    final navigatorKey = _currentIndex == 0 
        ? homeNavigatorKey 
        : _currentIndex == 1 
            ? searchNavigatorKey 
            : libraryNavigatorKey;
    
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop();
      return false;
    }
    
    // If on home tab and can't pop, allow app to close
    if (_currentIndex == 0) {
      return true;
    }
    
    // Otherwise, go to home tab
    setState(() => _currentIndex = 0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            Navigator(
              key: homeNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            ),
            Navigator(
              key: searchNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const SearchPage(),
              ),
            ),
            Navigator(
              key: libraryNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const LibraryPage(),
              ),
            ),
          ],
        ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade800,
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                // If tapping the same tab, pop to root of that tab
                if (index == _currentIndex) {
                  final navigatorKey = index == 0 
                      ? homeNavigatorKey 
                      : index == 1 
                          ? searchNavigatorKey 
                          : libraryNavigatorKey;
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Iconsax.home),
                  selectedIcon: Icon(Iconsax.home_15),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.search_normal),
                  selectedIcon: Icon(Iconsax.search_normal_1),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Iconsax.music_library_2),
                  selectedIcon: Icon(Iconsax.music_library_25),
                  label: 'Library',
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
