import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';

/// Music Recognition Service
/// Provides Shazam-like song identification functionality
/// Note: Full audio fingerprinting requires native implementation or external API
class MusicRecognitionService extends ChangeNotifier {
  static MusicRecognitionService? _instance;
  static MusicRecognitionService get instance => _instance ??= MusicRecognitionService._();
  
  MusicRecognitionService._();

  final YtMusicService _ytMusicService = YtMusicService();
  
  RecognitionState _state = RecognitionState.idle;
  String _statusMessage = 'Tap to identify music';
  Track? _recognizedTrack;
  double _confidence = 0.0;
  
  RecognitionState get state => _state;
  String get statusMessage => _statusMessage;
  Track? get recognizedTrack => _recognizedTrack;
  double get confidence => _confidence;

  /// Start listening for music
  /// In a real implementation, this would:
  /// 1. Record audio from microphone
  /// 2. Generate audio fingerprint
  /// 3. Send to recognition API (ACRCloud, Shazam API, etc.)
  Future<RecognitionResult> startRecognition() async {
    _state = RecognitionState.listening;
    _statusMessage = 'Listening...';
    _recognizedTrack = null;
    notifyListeners();

    try {
      // Simulate listening phase (3 seconds)
      await Future.delayed(const Duration(seconds: 3));
      
      _state = RecognitionState.processing;
      _statusMessage = 'Processing audio...';
      notifyListeners();
      
      // Simulate processing (2 seconds)
      await Future.delayed(const Duration(seconds: 2));
      
      // In real implementation, this would be the API response
      // For now, return a demo result or error
      _state = RecognitionState.idle;
      _statusMessage = 'Tap to identify music';
      notifyListeners();
      
      return RecognitionResult.notFound(
        'Music recognition requires microphone access.'
      );
    } catch (e) {
      _state = RecognitionState.error;
      _statusMessage = 'Recognition failed';
      notifyListeners();
      
      return RecognitionResult.error('Failed to recognize music: $e');
    }
  }

  /// Cancel ongoing recognition
  void cancelRecognition() {
    _state = RecognitionState.idle;
    _statusMessage = 'Tap to identify music';
    _recognizedTrack = null;
    notifyListeners();
  }

  /// Search for a song by lyrics (alternative to audio recognition)
  Future<List<Track>> searchByLyrics(String lyrics) async {
    if (lyrics.trim().isEmpty) return [];
    
    _state = RecognitionState.processing;
    _statusMessage = 'Searching by lyrics...';
    notifyListeners();

    try {
      await _ytMusicService.init();
      
      // Search with lyrics as query
      final results = await _ytMusicService.searchSongs(
        '"$lyrics" lyrics',
        limit: 10,
      );
      
      _state = RecognitionState.idle;
      _statusMessage = 'Tap to identify music';
      notifyListeners();
      
      return results;
    } catch (e) {
      _state = RecognitionState.error;
      _statusMessage = 'Search failed';
      notifyListeners();
      
      print('MusicRecognitionService: Lyrics search error: $e');
      return [];
    }
  }

  /// Humming/singing recognition (placeholder)
  /// Would require ML model for audio-to-melody matching
  Future<RecognitionResult> recognizeHumming() async {
    _state = RecognitionState.listening;
    _statusMessage = 'Hum or sing the melody...';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    
    _state = RecognitionState.idle;
    _statusMessage = 'Tap to identify music';
    notifyListeners();
    
    return RecognitionResult.notFound(
      'Hum to Search feature is coming soon!'
    );
  }

  /// Reset service state
  void reset() {
    _state = RecognitionState.idle;
    _statusMessage = 'Tap to identify music';
    _recognizedTrack = null;
    _confidence = 0.0;
    notifyListeners();
  }
}

enum RecognitionState {
  idle,
  listening,
  processing,
  found,
  notFound,
  error,
}

class RecognitionResult {
  final bool success;
  final Track? track;
  final double confidence;
  final String message;
  final RecognitionResultType type;

  const RecognitionResult._({
    required this.success,
    this.track,
    this.confidence = 0.0,
    required this.message,
    required this.type,
  });

  factory RecognitionResult.found(Track track, {double confidence = 0.9}) {
    return RecognitionResult._(
      success: true,
      track: track,
      confidence: confidence,
      message: 'Found: ${track.title} by ${track.artist}',
      type: RecognitionResultType.found,
    );
  }

  factory RecognitionResult.notFound(String message) {
    return RecognitionResult._(
      success: false,
      message: message,
      type: RecognitionResultType.notFound,
    );
  }

  factory RecognitionResult.error(String message) {
    return RecognitionResult._(
      success: false,
      message: message,
      type: RecognitionResultType.error,
    );
  }
}

enum RecognitionResultType {
  found,
  notFound,
  error,
}
