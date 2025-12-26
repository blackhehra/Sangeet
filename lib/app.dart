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
import 'package:sangeet/services/user_preferences_service.dart';
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
      home: userPrefs.onboardingCompleted 
          ? (isDesktop ? const DesktopShell() : const MainShell())
          : const OnboardingPage(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    LibraryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
                setState(() {
                  _currentIndex = index;
                });
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
    );
  }
}
