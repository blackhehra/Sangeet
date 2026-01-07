import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/features/home/pages/home_page.dart';
import 'package:sangeet/features/search/pages/search_page.dart';
import 'package:sangeet/features/library/pages/library_page.dart';
import 'package:sangeet/features/player/widgets/enhanced_mini_player.dart';
import 'package:sangeet/features/player/pages/player_page.dart';
import 'package:sangeet/features/onboarding/pages/onboarding_page.dart';
import 'package:sangeet/features/desktop/pages/desktop_shell.dart';
import 'package:sangeet/features/splash/pages/splash_video_page.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/playback_state_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/player_dismiss_provider.dart';
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
        body: SafeArea(
          top: false, // Don't add padding at top (status bar handled by pages)
          bottom: true, // Add padding at bottom for system navigation buttons
          child: Stack(
            children: [
              // Main content - pages
              Positioned.fill(
                child: IndexedStack(
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
              ),
              // Player overlay (SlidingUpPanel) - rendered first (behind nav bar)
              const Positioned.fill(
                child: _PlayerOverlay(),
              ),
              // Nav bar at bottom - rendered last (IN FRONT of player overlay)
              // This ensures nav bar slides up in front of full player when dismissing
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SangeetNavigationBar(
                  currentIndex: _currentIndex,
                  onDestinationSelected: (index) {
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Player overlay using SlidingUpPanel (exactly like Spotube's PlayerOverlay)
/// Mini player as header, full player as panel content
class _PlayerOverlay extends ConsumerWidget {
  const _PlayerOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final panelController = ref.watch(playerPanelControllerProvider);
    final hidePlayer = ref.watch(hidePlayerProvider);
    
    final canShow = currentTrack.valueOrNull != null && !hidePlayer;
    final screenSize = MediaQuery.sizeOf(context);
    
    // Mini player height
    const miniPlayerHeight = 64.0;
    // Nav bar height when fully visible (reduced for tighter spacing)
    const navBarHeight = 72.0;
    
    return SlidingUpPanel(
      controller: panelController,
      maxHeight: screenSize.height,
      minHeight: canShow ? miniPlayerHeight + navBarHeight : 0,
      backdropEnabled: false,
      parallaxEnabled: true,
      renderPanelSheet: false,
      color: Colors.transparent,
      onPanelSlide: (position) {
        // Update navigation bar height based on panel position
        // position: 0.0 = collapsed, 1.0 = fully expanded
        final invertedPosition = 1 - position;
        ref.read(navigationBarHeightProvider.notifier).state = navBarHeight * invertedPosition;
      },
      // Header = mini player (only visible when collapsed)
      header: SizedBox(
        height: miniPlayerHeight + navBarHeight,
        width: screenSize.width,
        child: _CollapsedMiniPlayer(
          canShow: canShow,
          panelController: panelController,
        ),
      ),
      // Panel = full player (only visible when expanded, hidden when collapsed)
      panelBuilder: (scrollController) => _FullPlayerPanel(
        scrollController: scrollController,
        panelController: panelController,
      ),
    );
  }
}

/// Full player panel that only shows when panel is expanded
/// Hidden when collapsed to prevent showing behind mini player
class _FullPlayerPanel extends ConsumerWidget {
  final ScrollController scrollController;
  final PanelController panelController;
  
  const _FullPlayerPanel({
    required this.scrollController,
    required this.panelController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navBarHeight = ref.watch(navigationBarHeightProvider);
    
    // Only show full player when panel is not almost collapsed
    // When navBarHeight >= 68, panel is almost collapsed - hide full player
    final isCollapsed = navBarHeight >= 68;
    
    if (isCollapsed) {
      // Return transparent container when collapsed
      return const SizedBox.shrink();
    }
    
    return PlayerPage(
      scrollController: scrollController,
      panelController: panelController,
    );
  }
}

/// Mini player that only shows when panel is collapsed
/// Hides when panel is expanded (like Spotube's PlayerOverlayCollapsedSection)
class _CollapsedMiniPlayer extends ConsumerWidget {
  final bool canShow;
  final PanelController panelController;
  
  const _CollapsedMiniPlayer({
    required this.canShow,
    required this.panelController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navBarHeight = ref.watch(navigationBarHeightProvider);
    
    // Hide when keyboard is visible
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible) return const SizedBox.shrink();
    
    // Only show mini player when nav bar is at almost full height (panel almost collapsed)
    // This prevents mini player from appearing too early during dismissal
    final shouldShow = navBarHeight >= 68; // Wait until 95% collapsed before showing mini player
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 275),
      child: canShow && shouldShow
          ? Column(
              key: const ValueKey('mini-player-visible'),
              children: [
                const EnhancedMiniPlayer(),
                // IgnorePointer allows touches to pass through to nav bar below
                const IgnorePointer(
                  child: SizedBox(height: 72),
                ),
              ],
            )
          : const IgnorePointer(
              key: ValueKey('mini-player-hidden'),
              child: SizedBox(height: 64 + 72),
            ),
    );
  }
}

/// Animated navigation bar that shrinks as the player panel expands
/// Exactly like Spotube's SpotubeNavigationBar
class _SangeetNavigationBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _SangeetNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navBarHeight = ref.watch(navigationBarHeightProvider);
    
    // Hide when keyboard is visible
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible) return const SizedBox.shrink();
    
    // Fixed nav bar height for slide-down animation
    const fixedNavBarHeight = 72.0;
    
    // Calculate slide offset - when navBarHeight is 0 (fully expanded), slide down by full height
    // When navBarHeight is 72 (fully visible), no offset (at bottom)
    final slideOffset = fixedNavBarHeight - navBarHeight;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: 0,
      right: 0,
      bottom: -slideOffset, // Negative to slide down
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: fixedNavBarHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade800,
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, Iconsax.home, Iconsax.home_15, "Home", 0, currentIndex),
                  _buildNavItem(context, Iconsax.search_normal, Iconsax.search_normal_1, "Search", 1, currentIndex),
                  _buildNavItem(context, Iconsax.music_library_2, Iconsax.music_library_25, "Library", 2, currentIndex),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, IconData selectedIcon, String label, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory, // Remove splash effect
        hoverColor: Colors.transparent, // Remove hover effect
        focusColor: Colors.transparent, // Remove focus effect
        highlightColor: Colors.transparent, // Remove highlight effect
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..scale(isSelected ? 1.1 : 1.0),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? Colors.green : Theme.of(context).iconTheme.color,
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: isSelected ? Colors.green : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(top: isSelected ? 4 : 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: isSelected ? 2 : 0,
                  width: isSelected ? 20 : 0,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
