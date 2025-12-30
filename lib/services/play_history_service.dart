import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/play_event.dart';
import 'package:sangeet/models/track.dart';

/// Play history tracking service
/// Tracks play events and calculates song statistics for recommendations
class PlayHistoryService {
  static PlayHistoryService? _instance;
  static PlayHistoryService get instance => _instance ??= PlayHistoryService._();
  
  PlayHistoryService._();

  static const String _eventsKey = 'play_events';
  static const String _statsKey = 'song_stats';
  static const String _cachedQuickPicksKey = 'cached_quick_picks';
  static const String _likedSongsKey = 'liked_songs';
  static const int _maxEvents = 1000; // Keep last 1000 events

  SharedPreferences? _prefs;
  List<PlayEvent> _events = [];
  Map<String, SongStats> _stats = {};
  Map<String, Track> _likedSongs = {};

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadEvents();
    await _loadStats();
    await _loadLikedSongs();
    print('PlayHistoryService: Initialized with ${_events.length} events, ${_stats.length} song stats, ${_likedSongs.length} liked songs');
  }

  /// Record a play event - called when a song starts playing
  Future<void> recordPlayStart(Track track) async {
    final event = PlayEvent(
      id: '${track.id}_${DateTime.now().millisecondsSinceEpoch}',
      songId: track.id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      playTimeMs: 0,
    );
    
    _events.add(event);
    
    // Update or create song stats
    final existingStats = _stats[track.id];
    if (existingStats != null) {
      _stats[track.id] = existingStats.copyWith(
        playCount: existingStats.playCount + 1,
        lastPlayedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      _stats[track.id] = SongStats(
        songId: track.id,
        title: track.title,
        artist: track.artist,
        thumbnailUrl: track.thumbnailUrl,
        totalPlayTimeMs: 0,
        playCount: 1,
        lastPlayedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    
    await _saveEvents();
    await _saveStats();
    print('PlayHistoryService: Recorded play start for ${track.title}');
  }

  /// Update play time for the most recent event of a song
  Future<void> updatePlayTime(String songId, int playTimeMs) async {
    // Find the most recent event for this song
    for (int i = _events.length - 1; i >= 0; i--) {
      if (_events[i].songId == songId) {
        _events[i] = PlayEvent(
          id: _events[i].id,
          songId: _events[i].songId,
          timestamp: _events[i].timestamp,
          playTimeMs: playTimeMs,
        );
        break;
      }
    }
    
    // Update total play time in stats
    final existingStats = _stats[songId];
    if (existingStats != null) {
      _stats[songId] = existingStats.copyWith(
        totalPlayTimeMs: existingStats.totalPlayTimeMs + playTimeMs,
      );
    }
    
    await _saveEvents();
    await _saveStats();
  }

  /// Get trending songs - most played songs
  List<SongStats> getTrendingSongs({int limit = 10}) {
    final sortedStats = _stats.values.toList()
      ..sort((a, b) => b.totalPlayTimeMs.compareTo(a.totalPlayTimeMs));
    return sortedStats.take(limit).toList();
  }

  /// Get trending songs within a time period
  List<SongStats> getTrendingSongsInPeriod({
    required Duration period,
    int limit = 10,
  }) {
    final cutoff = DateTime.now().millisecondsSinceEpoch - period.inMilliseconds;
    
    // Calculate play time within the period
    final periodStats = <String, int>{};
    for (final event in _events) {
      if (event.timestamp >= cutoff) {
        periodStats[event.songId] = (periodStats[event.songId] ?? 0) + event.playTimeMs;
      }
    }
    
    // Sort by play time and get top songs
    final sortedEntries = periodStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((e) => _stats[e.key])
        .whereType<SongStats>()
        .toList();
  }

  /// Get most recently played song
  SongStats? getMostRecentSong() {
    if (_stats.isEmpty) return null;
    
    final sortedStats = _stats.values.toList()
      ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return sortedStats.first;
  }

  /// Get recent songs for variety in recommendations
  List<SongStats> getRecentSongs({int limit = 5}) {
    if (_stats.isEmpty) return [];
    
    final sortedStats = _stats.values.toList()
      ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return sortedStats.take(limit).toList();
  }

  /// Get play history - most recent events
  List<PlayEvent> getHistory({int limit = 100}) {
    final sorted = List<PlayEvent>.from(_events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get song stats by ID
  SongStats? getSongStats(String songId) => _stats[songId];

  /// Get all song stats
  List<SongStats> getAllStats() => _stats.values.toList();

  /// Clear all history
  Future<void> clearHistory() async {
    _events.clear();
    _stats.clear();
    await _saveEvents();
    await _saveStats();
    print('PlayHistoryService: History cleared');
  }

  /// Cache quick picks for faster loading
  Future<void> cacheQuickPicks(Map<String, dynamic> quickPicks) async {
    await _prefs?.setString(_cachedQuickPicksKey, jsonEncode(quickPicks));
  }

  /// Get cached quick picks
  Map<String, dynamic>? getCachedQuickPicks() {
    final cached = _prefs?.getString(_cachedQuickPicksKey);
    if (cached != null) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }
    return null;
  }

  // Private methods

  Future<void> _loadEvents() async {
    final eventsJson = _prefs?.getString(_eventsKey);
    if (eventsJson != null) {
      final List<dynamic> decoded = jsonDecode(eventsJson);
      _events = decoded
          .map((e) => PlayEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _loadStats() async {
    final statsJson = _prefs?.getString(_statsKey);
    if (statsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(statsJson);
      _stats = decoded.map((key, value) => 
          MapEntry(key, SongStats.fromJson(value as Map<String, dynamic>)));
    }
  }

  Future<void> _saveEvents() async {
    // Trim events if too many
    if (_events.length > _maxEvents) {
      _events = _events.sublist(_events.length - _maxEvents);
    }
    
    final eventsJson = jsonEncode(_events.map((e) => e.toJson()).toList());
    await _prefs?.setString(_eventsKey, eventsJson);
  }

  Future<void> _saveStats() async {
    final statsJson = jsonEncode(
      _stats.map((key, value) => MapEntry(key, value.toJson()))
    );
    await _prefs?.setString(_statsKey, statsJson);
  }

  Future<void> _loadLikedSongs() async {
    final likedJson = _prefs?.getString(_likedSongsKey);
    if (likedJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(likedJson);
      _likedSongs = decoded.map((key, value) => 
          MapEntry(key, Track.fromJson(value as Map<String, dynamic>)));
    }
  }

  Future<void> _saveLikedSongs() async {
    final likedJson = jsonEncode(
      _likedSongs.map((key, value) => MapEntry(key, value.toJson()))
    );
    await _prefs?.setString(_likedSongsKey, likedJson);
  }

  // Liked Songs Methods

  /// Check if a song is liked
  bool isLiked(String songId) => _likedSongs.containsKey(songId);

  /// Toggle like status for a song
  Future<bool> toggleLike(Track track) async {
    if (_likedSongs.containsKey(track.id)) {
      _likedSongs.remove(track.id);
      await _saveLikedSongs();
      print('PlayHistoryService: Unliked ${track.title}');
      return false;
    } else {
      _likedSongs[track.id] = track;
      await _saveLikedSongs();
      print('PlayHistoryService: Liked ${track.title}');
      return true;
    }
  }

  /// Like a song
  Future<void> likeSong(Track track) async {
    _likedSongs[track.id] = track;
    await _saveLikedSongs();
  }

  /// Unlike a song
  Future<void> unlikeSong(String songId) async {
    _likedSongs.remove(songId);
    await _saveLikedSongs();
  }

  /// Get all liked songs
  List<Track> getLikedSongs() => _likedSongs.values.toList();

  /// Get liked songs count
  int get likedSongsCount => _likedSongs.length;
}
