import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sangeet/services/audio_player_service.dart';

/// Keyboard Shortcuts Service for Desktop
/// Handles keyboard shortcuts for media controls
class KeyboardShortcutsService {
  static final KeyboardShortcutsService _instance = KeyboardShortcutsService._internal();
  factory KeyboardShortcutsService() => _instance;
  KeyboardShortcutsService._internal();

  AudioPlayerService? _audioService;
  
  /// Initialize with audio service
  void init(AudioPlayerService audioService) {
    _audioService = audioService;
  }

  /// Handle key event
  /// Returns true if the key was handled
  bool handleKeyEvent(KeyEvent event) {
    if (_audioService == null) return false;
    if (event is! KeyDownEvent) return false;
    
    final key = event.logicalKey;
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    
    // Space - Play/Pause
    if (key == LogicalKeyboardKey.space && !isCtrlPressed) {
      _audioService!.togglePlayPause();
      return true;
    }
    
    // Right Arrow - Seek forward 10 seconds
    if (key == LogicalKeyboardKey.arrowRight && !isCtrlPressed) {
      final newPosition = _audioService!.position + const Duration(seconds: 10);
      _audioService!.seek(newPosition);
      return true;
    }
    
    // Left Arrow - Seek backward 10 seconds
    if (key == LogicalKeyboardKey.arrowLeft && !isCtrlPressed) {
      final newPosition = _audioService!.position - const Duration(seconds: 10);
      _audioService!.seek(newPosition.isNegative ? Duration.zero : newPosition);
      return true;
    }
    
    // Ctrl + Right Arrow - Next track
    if (key == LogicalKeyboardKey.arrowRight && isCtrlPressed) {
      _audioService!.skipToNext();
      return true;
    }
    
    // Ctrl + Left Arrow - Previous track
    if (key == LogicalKeyboardKey.arrowLeft && isCtrlPressed) {
      _audioService!.skipToPrevious();
      return true;
    }
    
    // Up Arrow - Volume up
    if (key == LogicalKeyboardKey.arrowUp && !isCtrlPressed) {
      // Volume is 0-100 in media_kit
      final currentVolume = _audioService!.position.inMilliseconds > 0 ? 1.0 : 1.0; // Placeholder
      _audioService!.setVolume((currentVolume + 0.1).clamp(0.0, 1.0));
      return true;
    }
    
    // Down Arrow - Volume down
    if (key == LogicalKeyboardKey.arrowDown && !isCtrlPressed) {
      final currentVolume = 1.0; // Placeholder
      _audioService!.setVolume((currentVolume - 0.1).clamp(0.0, 1.0));
      return true;
    }
    
    // M - Mute/Unmute
    if (key == LogicalKeyboardKey.keyM && !isCtrlPressed) {
      // Toggle mute - would need to track mute state
      return true;
    }
    
    // S - Toggle shuffle
    if (key == LogicalKeyboardKey.keyS && !isCtrlPressed) {
      _audioService!.toggleShuffle();
      return true;
    }
    
    // R - Cycle repeat mode
    if (key == LogicalKeyboardKey.keyR && !isCtrlPressed) {
      _audioService!.cycleRepeatMode();
      return true;
    }
    
    // Media keys
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      _audioService!.togglePlayPause();
      return true;
    }
    
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      _audioService!.skipToNext();
      return true;
    }
    
    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      _audioService!.skipToPrevious();
      return true;
    }
    
    if (key == LogicalKeyboardKey.mediaStop) {
      _audioService!.stop();
      return true;
    }
    
    return false;
  }

  /// Get keyboard shortcuts map for display
  static Map<String, String> get shortcutsMap => {
    'Space': 'Play/Pause',
    '←': 'Seek backward 10s',
    '→': 'Seek forward 10s',
    'Ctrl + ←': 'Previous track',
    'Ctrl + →': 'Next track',
    '↑': 'Volume up',
    '↓': 'Volume down',
    'S': 'Toggle shuffle',
    'R': 'Cycle repeat mode',
    'M': 'Mute/Unmute',
  };
}

/// Widget that wraps the app to handle keyboard shortcuts
class KeyboardShortcutsWrapper extends StatelessWidget {
  final Widget child;
  final AudioPlayerService audioService;

  const KeyboardShortcutsWrapper({
    super.key,
    required this.child,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    final shortcutsService = KeyboardShortcutsService();
    shortcutsService.init(audioService);
    
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        shortcutsService.handleKeyEvent(event);
      },
      child: child,
    );
  }
}

/// Focus-aware keyboard shortcuts widget
class KeyboardShortcutsFocusWrapper extends StatefulWidget {
  final Widget child;
  final AudioPlayerService audioService;

  const KeyboardShortcutsFocusWrapper({
    super.key,
    required this.child,
    required this.audioService,
  });

  @override
  State<KeyboardShortcutsFocusWrapper> createState() => _KeyboardShortcutsFocusWrapperState();
}

class _KeyboardShortcutsFocusWrapperState extends State<KeyboardShortcutsFocusWrapper> {
  late FocusNode _focusNode;
  late KeyboardShortcutsService _shortcutsService;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _shortcutsService = KeyboardShortcutsService();
    _shortcutsService.init(widget.audioService);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (_shortcutsService.handleKeyEvent(event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
