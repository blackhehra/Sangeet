import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lrc/lrc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/lyrics.dart';
import 'package:sangeet/models/track.dart';

/// Service for fetching synced lyrics from lrclib.net
/// Credits: lrclib.net and their contributors for the generous public API
class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  static const String _cachePrefix = 'lyrics_cache_';
  static const String _failedCachePrefix = 'lyrics_failed_';
  static const String _baseUrl = 'https://lrclib.net/api';
  static const int _maxRetries = 3;
  
  // Track retry attempts per song (in-memory for current session)
  final Map<String, int> _retryAttempts = {};

  /// Fetch lyrics for a track
  /// First checks cache, then fetches from API if not cached
  /// Limits retries to 3 attempts per song to avoid spamming failed requests
  Future<SubtitleSimple> getLyrics(Track track) async {
    // Try cache first
    final cached = await _getCachedLyrics(track.id);
    if (cached != null && cached.lyrics.isNotEmpty) {
      print('LyricsService: Returning cached lyrics for ${track.title}');
      return cached;
    }
    
    // Check if we've already failed too many times for this track
    final failedCount = await _getFailedAttempts(track.id);
    if (failedCount >= _maxRetries) {
      print('LyricsService: Max retries ($failedCount) reached for ${track.title}, skipping');
      return SubtitleSimple.empty(track.title);
    }
    
    // Check in-memory retry count for current session
    final sessionRetries = _retryAttempts[track.id] ?? 0;
    if (sessionRetries >= _maxRetries) {
      print('LyricsService: Session retry limit reached for ${track.title}');
      return SubtitleSimple.empty(track.title);
    }

    // Fetch from API
    try {
      final lyrics = await _fetchFromLrcLib(track);
      
      // Cache the result
      if (lyrics.lyrics.isNotEmpty) {
        await _cacheLyrics(track.id, lyrics);
        // Clear retry count on success
        _retryAttempts.remove(track.id);
        await _clearFailedAttempts(track.id);
      } else {
        // Track failed attempt
        await _incrementFailedAttempts(track.id);
      }
      
      return lyrics;
    } catch (e) {
      print('LyricsService: Error fetching lyrics: $e');
      // Track failed attempt
      _retryAttempts[track.id] = sessionRetries + 1;
      await _incrementFailedAttempts(track.id);
      return SubtitleSimple.empty(track.title);
    }
  }

  /// Fetch lyrics from lrclib.net API
  Future<SubtitleSimple> _fetchFromLrcLib(Track track) async {
    final uri = Uri.parse('$_baseUrl/get').replace(
      queryParameters: {
        'artist_name': track.artist,
        'track_name': track.title,
        if (track.album != null) 'album_name': track.album!,
        'duration': (track.duration.inSeconds).toString(),
      },
    );

    print('LyricsService: Fetching lyrics from $uri');

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'Sangeet Music App (https://github.com/user/sangeet)',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      print('LyricsService: API returned ${response.statusCode}');
      
      // Try search endpoint as fallback
      return _searchLyrics(track);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseLyricsResponse(json, track.title);
  }

  /// Search for lyrics using the search endpoint (fallback)
  Future<SubtitleSimple> _searchLyrics(Track track) async {
    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': '${track.artist} ${track.title}',
      },
    );

    print('LyricsService: Searching lyrics from $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Sangeet Music App (https://github.com/user/sangeet)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('LyricsService: Search API returned ${response.statusCode}');
        return SubtitleSimple.empty(track.title);
      }

      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) {
        print('LyricsService: No search results found');
        return SubtitleSimple.empty(track.title);
      }

      // Use the first result
      final json = results.first as Map<String, dynamic>;
      return _parseLyricsResponse(json, track.title);
    } catch (e) {
      print('LyricsService: Search error: $e');
      return SubtitleSimple.empty(track.title);
    }
  }

  /// Parse lyrics response from API
  SubtitleSimple _parseLyricsResponse(Map<String, dynamic> json, String trackName) {
    // Try synced lyrics first
    final syncedLyricsRaw = json['syncedLyrics'] as String?;
    if (syncedLyricsRaw != null && syncedLyricsRaw.isNotEmpty) {
      try {
        final lrc = Lrc.parse(syncedLyricsRaw);
        final lyrics = lrc.lyrics.map(LyricSlice.fromLrcLine).toList();
        
        if (lyrics.isNotEmpty) {
          print('LyricsService: Found ${lyrics.length} synced lyrics lines');
          return SubtitleSimple(
            name: trackName,
            lyrics: lyrics,
            rating: 100,
            provider: 'LRCLib',
          );
        }
      } catch (e) {
        print('LyricsService: Error parsing synced lyrics: $e');
      }
    }

    // Fall back to plain lyrics
    final plainLyrics = json['plainLyrics'] as String?;
    if (plainLyrics != null && plainLyrics.isNotEmpty) {
      final lyrics = plainLyrics
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => LyricSlice(text: line.trim(), time: Duration.zero))
          .toList();
      
      print('LyricsService: Found ${lyrics.length} plain lyrics lines');
      return SubtitleSimple(
        name: trackName,
        lyrics: lyrics,
        rating: 50,
        provider: 'LRCLib',
      );
    }

    print('LyricsService: No lyrics found in response');
    return SubtitleSimple.empty(trackName);
  }

  /// Get cached lyrics
  Future<SubtitleSimple?> _getCachedLyrics(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cachePrefix$trackId');
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return SubtitleSimple.fromJson(json);
      }
    } catch (e) {
      print('LyricsService: Error reading cache: $e');
    }
    return null;
  }

  /// Cache lyrics
  Future<void> _cacheLyrics(String trackId, SubtitleSimple lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$trackId', jsonEncode(lyrics.toJson()));
      print('LyricsService: Cached lyrics for $trackId');
    } catch (e) {
      print('LyricsService: Error caching lyrics: $e');
    }
  }

  /// Clear cached lyrics for a track
  Future<void> clearCache(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$trackId');
      await prefs.remove('$_failedCachePrefix$trackId');
      _retryAttempts.remove(trackId);
    } catch (e) {
      print('LyricsService: Error clearing cache: $e');
    }
  }
  
  /// Get failed attempt count for a track
  Future<int> _getFailedAttempts(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_failedCachePrefix$trackId') ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Increment failed attempt count for a track
  Future<void> _incrementFailedAttempts(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt('$_failedCachePrefix$trackId') ?? 0;
      await prefs.setInt('$_failedCachePrefix$trackId', current + 1);
    } catch (e) {
      print('LyricsService: Error tracking failed attempt: $e');
    }
  }
  
  /// Clear failed attempt count for a track
  Future<void> _clearFailedAttempts(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_failedCachePrefix$trackId');
    } catch (e) {
      // Ignore
    }
  }
}
