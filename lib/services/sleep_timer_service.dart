import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sangeet/services/audio_player_service.dart';

/// Sleep Timer Service
/// Automatically pauses playback after a set duration
class SleepTimerService extends ChangeNotifier {
  static final SleepTimerService _instance = SleepTimerService._internal();
  factory SleepTimerService() => _instance;
  SleepTimerService._internal();

  Timer? _timer;
  DateTime? _endTime;
  bool _endOfTrack = false;
  
  bool get isActive => _timer != null || _endOfTrack;
  DateTime? get endTime => _endTime;
  bool get isEndOfTrack => _endOfTrack;
  
  /// Get remaining time
  Duration get remainingTime {
    if (_endTime == null) return Duration.zero;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Set sleep timer for a specific duration
  void setTimer(Duration duration, AudioPlayerService audioService) {
    cancelTimer();
    
    _endTime = DateTime.now().add(duration);
    _endOfTrack = false;
    
    _timer = Timer(duration, () {
      _onTimerComplete(audioService);
    });
    
    print('SleepTimerService: Timer set for ${duration.inMinutes} minutes');
    notifyListeners();
  }

  /// Set timer to stop at end of current track
  void setEndOfTrack(AudioPlayerService audioService) {
    cancelTimer();
    
    _endOfTrack = true;
    _endTime = null;
    
    // Listen for track completion
    audioService.currentTrackStream.listen((track) {
      if (_endOfTrack && track == null) {
        _onTimerComplete(audioService);
      }
    });
    
    print('SleepTimerService: Timer set for end of track');
    notifyListeners();
  }

  /// Cancel the timer
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _endOfTrack = false;
    notifyListeners();
  }

  void _onTimerComplete(AudioPlayerService audioService) {
    print('SleepTimerService: Timer complete, pausing playback');
    audioService.pause();
    cancelTimer();
  }

  /// Extend timer by additional duration
  void extendTimer(Duration additionalTime, AudioPlayerService audioService) {
    if (_endTime != null) {
      final newEndTime = _endTime!.add(additionalTime);
      final newDuration = newEndTime.difference(DateTime.now());
      setTimer(newDuration, audioService);
    }
  }
}

/// Preset sleep timer durations
class SleepTimerPresets {
  static const Duration fifteenMinutes = Duration(minutes: 15);
  static const Duration thirtyMinutes = Duration(minutes: 30);
  static const Duration fortyFiveMinutes = Duration(minutes: 45);
  static const Duration oneHour = Duration(hours: 1);
  static const Duration twoHours = Duration(hours: 2);
  
  static const List<SleepTimerOption> options = [
    SleepTimerOption('15 minutes', fifteenMinutes),
    SleepTimerOption('30 minutes', thirtyMinutes),
    SleepTimerOption('45 minutes', fortyFiveMinutes),
    SleepTimerOption('1 hour', oneHour),
    SleepTimerOption('2 hours', twoHours),
  ];
}

class SleepTimerOption {
  final String label;
  final Duration duration;
  
  const SleepTimerOption(this.label, this.duration);
}
