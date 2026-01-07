import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

/// Provider to share the full player dismiss progress with other widgets
/// Progress is 0.0 when player is fully open, 1.0 when fully dismissed
final playerDismissProgressProvider = StateProvider<double>((ref) => 1.0);

/// Whether the full player is currently open
final isFullPlayerOpenProvider = StateProvider<bool>((ref) => false);

/// Panel controller for the sliding up panel
final playerPanelControllerProvider = StateProvider<PanelController>((ref) {
  return PanelController();
});

/// Navigation bar height - animated based on panel slide position
/// When panel is fully open (position=1.0), height = 0
/// When panel is collapsed (position=0.0), height = 72 (full height)
final navigationBarHeightProvider = StateProvider<double>((ref) => 72.0);

/// Whether to completely hide the player (both mini and full)
/// Used for pages like settings where player shouldn't be visible
final hidePlayerProvider = StateProvider<bool>((ref) => false);
