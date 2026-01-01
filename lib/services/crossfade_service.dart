import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crossfade Service for smooth transitions between tracks
/// Handles crossfade duration settings and gapless playback
class CrossfadeService extends ChangeNotifier {
  static final CrossfadeService _instance = CrossfadeService._internal();
  factory CrossfadeService() => _instance;
  CrossfadeService._internal();

  static const String _crossfadeEnabledKey = 'crossfade_enabled';
  static const String _crossfadeDurationKey = 'crossfade_duration';
  static const String _gaplessEnabledKey = 'gapless_enabled';

  SharedPreferences? _prefs;
  
  bool _isEnabled = false;
  int _durationSeconds = 5; // Default 5 seconds
  bool _gaplessEnabled = true;
  
  bool get isEnabled => _isEnabled;
  int get durationSeconds => _durationSeconds;
  Duration get duration => Duration(seconds: _durationSeconds);
  bool get gaplessEnabled => _gaplessEnabled;

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isEnabled = _prefs?.getBool(_crossfadeEnabledKey) ?? false;
    _durationSeconds = _prefs?.getInt(_crossfadeDurationKey) ?? 5;
    _gaplessEnabled = _prefs?.getBool(_gaplessEnabledKey) ?? true;
    notifyListeners();
  }

  /// Enable/disable crossfade
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _prefs?.setBool(_crossfadeEnabledKey, enabled);
    notifyListeners();
  }

  /// Set crossfade duration in seconds
  Future<void> setDuration(int seconds) async {
    _durationSeconds = seconds.clamp(1, 12);
    await _prefs?.setInt(_crossfadeDurationKey, _durationSeconds);
    notifyListeners();
  }

  /// Enable/disable gapless playback
  Future<void> setGaplessEnabled(bool enabled) async {
    _gaplessEnabled = enabled;
    await _prefs?.setBool(_gaplessEnabledKey, enabled);
    notifyListeners();
  }

  /// Calculate the fade-out start position for current track
  /// Returns the position when fade-out should start
  Duration getFadeOutStartPosition(Duration trackDuration) {
    if (!_isEnabled) return trackDuration;
    return trackDuration - duration;
  }

  /// Calculate volume multiplier for fade-out
  /// Returns value between 0.0 and 1.0
  double getFadeOutVolume(Duration currentPosition, Duration trackDuration) {
    if (!_isEnabled) return 1.0;
    
    final fadeOutStart = getFadeOutStartPosition(trackDuration);
    if (currentPosition < fadeOutStart) return 1.0;
    
    final fadeProgress = (currentPosition - fadeOutStart).inMilliseconds / 
                         duration.inMilliseconds;
    return (1.0 - fadeProgress).clamp(0.0, 1.0);
  }

  /// Calculate volume multiplier for fade-in
  /// Returns value between 0.0 and 1.0
  double getFadeInVolume(Duration currentPosition) {
    if (!_isEnabled) return 1.0;
    
    if (currentPosition >= duration) return 1.0;
    
    final fadeProgress = currentPosition.inMilliseconds / duration.inMilliseconds;
    return fadeProgress.clamp(0.0, 1.0);
  }

  /// Check if we should start preparing next track
  bool shouldPrepareNextTrack(Duration currentPosition, Duration trackDuration) {
    if (!_isEnabled && !_gaplessEnabled) return false;
    
    // Start preparing when we're within crossfade duration + 2 seconds buffer
    final preparePosition = trackDuration - duration - const Duration(seconds: 2);
    return currentPosition >= preparePosition;
  }

  /// Available crossfade duration presets
  static const List<CrossfadePreset> presets = [
    CrossfadePreset(0, 'Off'),
    CrossfadePreset(3, '3 seconds'),
    CrossfadePreset(5, '5 seconds'),
    CrossfadePreset(8, '8 seconds'),
    CrossfadePreset(12, '12 seconds'),
  ];
}

class CrossfadePreset {
  final int seconds;
  final String label;
  
  const CrossfadePreset(this.seconds, this.label);
}
