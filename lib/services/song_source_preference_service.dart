import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/services/settings_service.dart';

/// Service to manage per-song source preferences
/// Allows users to override the default music source for specific songs
class SongSourcePreferenceService {
  static final SongSourcePreferenceService _instance = SongSourcePreferenceService._internal();
  factory SongSourcePreferenceService() => _instance;
  SongSourcePreferenceService._internal();

  static const String _keyPrefix = 'song_source_';
  
  // In-memory cache for quick lookups
  final Map<String, MusicSource> _cache = {};
  bool _initialized = false;

  /// Initialize the service and load all preferences into cache
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    
    for (final key in keys) {
      final songId = key.substring(_keyPrefix.length);
      final sourceStr = prefs.getString(key);
      if (sourceStr != null) {
        _cache[songId] = MusicSource.fromString(sourceStr);
      }
    }
    
    _initialized = true;
    print('SongSourcePreferenceService: Loaded ${_cache.length} song preferences');
  }

  /// Get the preferred source for a song (null means use default)
  MusicSource? getPreferredSource(String songId) {
    return _cache[songId];
  }

  /// Set the preferred source for a song
  Future<void> setPreferredSource(String songId, MusicSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$songId', source.name);
    _cache[songId] = source;
    print('SongSourcePreferenceService: Set $songId to use ${source.label}');
  }

  /// Remove the preference for a song (use default)
  Future<void> removePreference(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$songId');
    _cache.remove(songId);
    print('SongSourcePreferenceService: Removed preference for $songId');
  }

  /// Check if a song has a custom preference
  bool hasPreference(String songId) {
    return _cache.containsKey(songId);
  }

  /// Get all songs with custom preferences
  Map<String, MusicSource> getAllPreferences() {
    return Map.unmodifiable(_cache);
  }

  /// Clear all preferences
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final songId in _cache.keys.toList()) {
      await prefs.remove('$_keyPrefix$songId');
    }
    _cache.clear();
    print('SongSourcePreferenceService: Cleared all preferences');
  }
}
