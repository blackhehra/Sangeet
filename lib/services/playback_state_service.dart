import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';

/// Service to persist and restore playback state across app sessions
/// Saves the last played track so users can continue where they left off
class PlaybackStateService {
  static PlaybackStateService? _instance;
  static PlaybackStateService get instance => _instance ??= PlaybackStateService._();
  
  PlaybackStateService._();

  static const String _lastTrackKey = 'last_played_track';
  static const String _lastPositionKey = 'last_played_position';
  static const String _lastQueueKey = 'last_played_queue';
  static const String _lastQueueIndexKey = 'last_queue_index';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return; // Prevent double initialization
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('PlaybackStateService: Initialized');
  }

  /// Save the current playback state
  Future<void> savePlaybackState({
    required Track track,
    required Duration position,
    List<Track>? queue,
    int? queueIndex,
  }) async {
    if (_prefs == null) await init();
    
    try {
      // Save the current track
      final trackJson = jsonEncode(track.toJson());
      await _prefs?.setString(_lastTrackKey, trackJson);
      
      // Save the position in milliseconds
      await _prefs?.setInt(_lastPositionKey, position.inMilliseconds);
      
      // Save queue if provided (limit to 50 tracks to avoid storage issues)
      if (queue != null && queue.isNotEmpty) {
        final limitedQueue = queue.take(50).toList();
        final queueJson = jsonEncode(limitedQueue.map((t) => t.toJson()).toList());
        await _prefs?.setString(_lastQueueKey, queueJson);
        await _prefs?.setInt(_lastQueueIndexKey, queueIndex ?? 0);
      }
      
      print('PlaybackStateService: Saved state for "${track.title}" at ${position.inSeconds}s');
    } catch (e) {
      print('PlaybackStateService: Error saving state: $e');
    }
  }

  /// Get the last played track
  Track? getLastTrack() {
    try {
      final trackJson = _prefs?.getString(_lastTrackKey);
      if (trackJson == null) return null;
      
      final trackMap = jsonDecode(trackJson) as Map<String, dynamic>;
      return Track.fromJson(trackMap);
    } catch (e) {
      print('PlaybackStateService: Error loading last track: $e');
      return null;
    }
  }

  /// Get the last playback position
  Duration getLastPosition() {
    final positionMs = _prefs?.getInt(_lastPositionKey) ?? 0;
    return Duration(milliseconds: positionMs);
  }

  /// Get the last played queue
  List<Track>? getLastQueue() {
    try {
      final queueJson = _prefs?.getString(_lastQueueKey);
      if (queueJson == null) return null;
      
      final List<dynamic> queueList = jsonDecode(queueJson);
      return queueList
          .map((json) => Track.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('PlaybackStateService: Error loading queue: $e');
      return null;
    }
  }

  /// Get the last queue index
  int getLastQueueIndex() {
    return _prefs?.getInt(_lastQueueIndexKey) ?? 0;
  }

  /// Check if there's a saved playback state
  bool hasSavedState() {
    return _prefs?.getString(_lastTrackKey) != null;
  }

  /// Clear the saved playback state
  Future<void> clearState() async {
    await _prefs?.remove(_lastTrackKey);
    await _prefs?.remove(_lastPositionKey);
    await _prefs?.remove(_lastQueueKey);
    await _prefs?.remove(_lastQueueIndexKey);
    print('PlaybackStateService: Cleared saved state');
  }

  /// Get full saved state as a record
  ({Track? track, Duration position, List<Track>? queue, int queueIndex})? getSavedState() {
    final track = getLastTrack();
    if (track == null) return null;
    
    return (
      track: track,
      position: getLastPosition(),
      queue: getLastQueue(),
      queueIndex: getLastQueueIndex(),
    );
  }
}
