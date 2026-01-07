import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/user_preferences_service.dart';

/// User Taste Service - Tracks and analyzes user listening preferences
/// to provide personalized recommendations while respecting selected language preferences.
/// 
/// Key principles:
/// 1. Selected language is PRIMARY - always prioritize user's chosen languages
/// 2. Discovered taste is SECONDARY - blend in based on actual listening behavior
/// 3. Ratio: ~80% selected language, ~20% discovered taste (adjustable)
class UserTasteService extends ChangeNotifier {
  static final UserTasteService _instance = UserTasteService._internal();
  factory UserTasteService() => _instance;
  UserTasteService._internal();

  static UserTasteService get instance => _instance;

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Taste profile data
  final Map<String, int> _artistPlayCounts = {};      // Artist -> play count
  final Map<String, int> _languagePlayCounts = {};    // Language -> play count
  final Map<String, int> _genrePlayCounts = {};       // Genre -> play count
  final Map<String, int> _searchedArtists = {};       // Searched artists -> count
  final Map<String, int> _searchedLanguages = {};     // Searched languages -> count
  final List<String> _recentArtists = [];             // Recently played artists
  final List<String> _recentGenres = [];              // Recently played genres
  
  // Spotify integration data
  Map<String, dynamic>? _spotifyTasteData;

  // Keys for persistence
  static const String _artistPlayCountsKey = 'taste_artist_play_counts';
  static const String _languagePlayCountsKey = 'taste_language_play_counts';
  static const String _genrePlayCountsKey = 'taste_genre_play_counts';
  static const String _searchedArtistsKey = 'taste_searched_artists';
  static const String _searchedLanguagesKey = 'taste_searched_languages';
  static const String _recentArtistsKey = 'taste_recent_artists';
  static const String _recentGenresKey = 'taste_recent_genres';
  static const String _spotifyTasteKey = 'taste_spotify_data';

  // Configuration
  static const double selectedLanguageWeight = 0.80;  // 80% from selected language
  static const double discoveredTasteWeight = 0.20;   // 20% from discovered taste
  static const int maxRecentItems = 50;
  static const int minPlaysForInfluence = 3;          // Minimum plays before influencing

  bool get isInitialized => _isInitialized;
  bool get hasSpotifyData => _spotifyTasteData != null;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadTasteData();
    _isInitialized = true;
    
    print('UserTasteService: Initialized with ${_artistPlayCounts.length} artists, '
        '${_languagePlayCounts.length} languages, ${_genrePlayCounts.length} genres');
  }

  Future<void> _loadTasteData() async {
    try {
      // Load artist play counts
      final artistJson = _prefs?.getString(_artistPlayCountsKey);
      if (artistJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(artistJson);
        _artistPlayCounts.clear();
        decoded.forEach((k, v) => _artistPlayCounts[k] = v as int);
      }

      // Load language play counts
      final langJson = _prefs?.getString(_languagePlayCountsKey);
      if (langJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(langJson);
        _languagePlayCounts.clear();
        decoded.forEach((k, v) => _languagePlayCounts[k] = v as int);
      }

      // Load genre play counts
      final genreJson = _prefs?.getString(_genrePlayCountsKey);
      if (genreJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(genreJson);
        _genrePlayCounts.clear();
        decoded.forEach((k, v) => _genrePlayCounts[k] = v as int);
      }

      // Load searched artists
      final searchedArtistsJson = _prefs?.getString(_searchedArtistsKey);
      if (searchedArtistsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(searchedArtistsJson);
        _searchedArtists.clear();
        decoded.forEach((k, v) => _searchedArtists[k] = v as int);
      }

      // Load searched languages
      final searchedLangJson = _prefs?.getString(_searchedLanguagesKey);
      if (searchedLangJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(searchedLangJson);
        _searchedLanguages.clear();
        decoded.forEach((k, v) => _searchedLanguages[k] = v as int);
      }

      // Load recent artists
      final recentArtistsList = _prefs?.getStringList(_recentArtistsKey);
      if (recentArtistsList != null) {
        _recentArtists.clear();
        _recentArtists.addAll(recentArtistsList);
      }

      // Load recent genres
      final recentGenresList = _prefs?.getStringList(_recentGenresKey);
      if (recentGenresList != null) {
        _recentGenres.clear();
        _recentGenres.addAll(recentGenresList);
      }

      // Load Spotify taste data
      final spotifyJson = _prefs?.getString(_spotifyTasteKey);
      if (spotifyJson != null) {
        _spotifyTasteData = jsonDecode(spotifyJson);
      }
    } catch (e) {
      print('UserTasteService: Error loading taste data: $e');
    }
  }

  Future<void> _saveTasteData() async {
    try {
      await _prefs?.setString(_artistPlayCountsKey, jsonEncode(_artistPlayCounts));
      await _prefs?.setString(_languagePlayCountsKey, jsonEncode(_languagePlayCounts));
      await _prefs?.setString(_genrePlayCountsKey, jsonEncode(_genrePlayCounts));
      await _prefs?.setString(_searchedArtistsKey, jsonEncode(_searchedArtists));
      await _prefs?.setString(_searchedLanguagesKey, jsonEncode(_searchedLanguages));
      await _prefs?.setStringList(_recentArtistsKey, _recentArtists);
      await _prefs?.setStringList(_recentGenresKey, _recentGenres);
    } catch (e) {
      print('UserTasteService: Error saving taste data: $e');
    }
  }

  // ============ TRACKING METHODS ============

  /// Record a track play - called when user plays a song
  Future<void> recordTrackPlay(Track track) async {
    if (!_isInitialized) await init();

    // Track artist
    final artist = track.artist.toLowerCase().trim();
    if (artist.isNotEmpty) {
      _artistPlayCounts[artist] = (_artistPlayCounts[artist] ?? 0) + 1;
      _addToRecent(_recentArtists, artist);
    }

    // Detect and track language
    final language = _detectLanguage(track);
    if (language != null) {
      _languagePlayCounts[language] = (_languagePlayCounts[language] ?? 0) + 1;
    }

    // Detect and track genre
    final genres = _detectGenres(track);
    for (final genre in genres) {
      _genrePlayCounts[genre] = (_genrePlayCounts[genre] ?? 0) + 1;
      _addToRecent(_recentGenres, genre);
    }

    await _saveTasteData();
    notifyListeners();
  }

  /// Record a search - called when user searches and clicks on a result
  Future<void> recordSearch(String query, {String? artistName, String? language}) async {
    if (!_isInitialized) await init();

    if (artistName != null && artistName.isNotEmpty) {
      final artist = artistName.toLowerCase().trim();
      _searchedArtists[artist] = (_searchedArtists[artist] ?? 0) + 1;
    }

    if (language != null && language.isNotEmpty) {
      _searchedLanguages[language.toLowerCase()] = 
          (_searchedLanguages[language.toLowerCase()] ?? 0) + 1;
    }

    // Try to detect language from query
    final detectedLang = _detectLanguageFromQuery(query);
    if (detectedLang != null) {
      _searchedLanguages[detectedLang] = (_searchedLanguages[detectedLang] ?? 0) + 1;
    }

    await _saveTasteData();
    notifyListeners();
  }

  /// Import Spotify taste data from raw map
  Future<void> importSpotifyTaste(Map<String, dynamic> spotifyData) async {
    if (!_isInitialized) await init();

    _spotifyTasteData = spotifyData;
    await _prefs?.setString(_spotifyTasteKey, jsonEncode(spotifyData));

    // Extract top artists from Spotify
    if (spotifyData['topArtists'] != null) {
      for (final artist in spotifyData['topArtists']) {
        final name = (artist['name'] as String?)?.toLowerCase();
        if (name != null) {
          // Give Spotify artists a boost
          _artistPlayCounts[name] = (_artistPlayCounts[name] ?? 0) + 5;
        }
      }
    }

    // Extract genres from Spotify
    if (spotifyData['topGenres'] != null) {
      for (final genre in spotifyData['topGenres']) {
        final name = (genre as String?)?.toLowerCase();
        if (name != null) {
          _genrePlayCounts[name] = (_genrePlayCounts[name] ?? 0) + 5;
        }
      }
    }

    await _saveTasteData();
    notifyListeners();
    print('UserTasteService: Imported Spotify taste data');
  }

  /// Sync taste data from Spotify plugin
  /// Call this after user logs in with Spotify
  Future<void> syncFromSpotifyPlugin() async {
    try {
      // Dynamic import to avoid circular dependency
      // The SpotifyPluginService should be initialized before calling this
      final spotifyPlugin = await _getSpotifyPlugin();
      if (spotifyPlugin == null) {
        print('UserTasteService: Spotify plugin not available');
        return;
      }

      print('UserTasteService: Syncing taste data from Spotify...');

      final topArtistsData = <Map<String, dynamic>>[];
      final topGenres = <String>[];

      // Get top artists from Spotify
      try {
        final topArtists = await spotifyPlugin.user.topArtists(limit: 20);
        for (final artist in topArtists.items) {
          topArtistsData.add({
            'name': artist.name,
            'id': artist.id,
          });
          
          // Add artist genres
          if (artist.genres != null) {
            topGenres.addAll(artist.genres!);
          }
        }
      } catch (e) {
        print('UserTasteService: Error fetching Spotify top artists: $e');
      }

      // Get followed artists as backup
      try {
        final followedArtists = await spotifyPlugin.user.savedArtists(limit: 20);
        for (final artist in followedArtists.items) {
          if (!topArtistsData.any((a) => a['id'] == artist.id)) {
            topArtistsData.add({
              'name': artist.name,
              'id': artist.id,
            });
            if (artist.genres != null) {
              topGenres.addAll(artist.genres!);
            }
          }
        }
      } catch (e) {
        print('UserTasteService: Error fetching Spotify followed artists: $e');
      }

      // Import the data
      await importSpotifyTaste({
        'topArtists': topArtistsData,
        'topGenres': topGenres.toSet().toList(), // Remove duplicates
        'syncedAt': DateTime.now().toIso8601String(),
      });

      print('UserTasteService: Synced ${topArtistsData.length} artists and ${topGenres.length} genres from Spotify');
    } catch (e) {
      print('UserTasteService: Error syncing from Spotify: $e');
    }
  }

  /// Set Spotify plugin reference (called from app initialization)
  static dynamic _spotifyPluginInstance;
  
  static void setSpotifyPlugin(dynamic plugin) {
    _spotifyPluginInstance = plugin;
  }

  /// Helper to get Spotify plugin instance
  Future<dynamic> _getSpotifyPlugin() async {
    return _spotifyPluginInstance;
  }

  // ============ RECOMMENDATION METHODS ============

  /// Get recommendation queries for home page
  /// Blends selected language (primary) with discovered taste (secondary)
  Future<List<String>> getRecommendationQueries({
    int totalQueries = 10,
    List<MusicLanguage>? selectedLanguages,
    List<String>? selectedArtists,
  }) async {
    if (!_isInitialized) await init();

    final queries = <String>[];
    
    // Calculate how many queries for each category
    final selectedLangCount = (totalQueries * selectedLanguageWeight).round();
    final discoveredCount = totalQueries - selectedLangCount;

    // 1. PRIMARY: Selected language queries
    if (selectedLanguages != null && selectedLanguages.isNotEmpty) {
      for (final lang in selectedLanguages) {
        queries.add('${lang.displayName} songs 2024');
        queries.add('${lang.displayName} hits');
        queries.add('new ${lang.displayName} music');
        
        // Add top artists from selected language
        for (final artist in lang.topArtists.take(2)) {
          queries.add('$artist songs');
        }
      }
    }

    // Add selected artists
    if (selectedArtists != null) {
      for (final artist in selectedArtists.take(3)) {
        queries.add('$artist latest songs');
        queries.add('$artist hits');
      }
    }

    // 2. SECONDARY: Discovered taste queries (from listening behavior)
    final discoveredQueries = _getDiscoveredTasteQueries(discoveredCount);
    queries.addAll(discoveredQueries);

    // 3. Add Spotify-influenced queries if available
    if (_spotifyTasteData != null) {
      final spotifyQueries = _getSpotifyInfluencedQueries(2);
      queries.addAll(spotifyQueries);
    }

    // Shuffle and limit
    queries.shuffle();
    return queries.take(totalQueries).toList();
  }

  /// Get discovered taste queries based on listening behavior
  List<String> _getDiscoveredTasteQueries(int count) {
    final queries = <String>[];

    // Get top discovered artists (not from selected language)
    final topArtists = getTopDiscoveredArtists(limit: 3);
    for (final artist in topArtists) {
      queries.add('$artist songs');
    }

    // Get top discovered genres
    final topGenres = getTopGenres(limit: 2);
    for (final genre in topGenres) {
      queries.add('$genre music');
      queries.add('$genre songs 2024');
    }

    // Get discovered languages (non-selected)
    final discoveredLangs = getDiscoveredLanguages(limit: 2);
    for (final lang in discoveredLangs) {
      queries.add('$lang songs');
    }

    return queries.take(count).toList();
  }

  /// Get Spotify-influenced queries
  List<String> _getSpotifyInfluencedQueries(int count) {
    final queries = <String>[];
    
    if (_spotifyTasteData == null) return queries;

    // Add queries based on Spotify top artists
    final topArtists = _spotifyTasteData!['topArtists'] as List?;
    if (topArtists != null) {
      for (final artist in topArtists.take(count)) {
        final name = artist['name'] as String?;
        if (name != null) {
          queries.add('$name songs');
        }
      }
    }

    return queries;
  }

  // ============ ANALYSIS METHODS ============

  /// Get top artists from discovered taste (excluding selected language artists)
  List<String> getTopDiscoveredArtists({int limit = 5}) {
    final sorted = _artistPlayCounts.entries
        .where((e) => e.value >= minPlaysForInfluence)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get top genres
  List<String> getTopGenres({int limit = 5}) {
    final sorted = _genrePlayCounts.entries
        .where((e) => e.value >= minPlaysForInfluence)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get discovered languages (languages user shows interest in via search/play)
  List<String> getDiscoveredLanguages({int limit = 3}) {
    // Combine play counts and search counts
    final combined = <String, int>{};
    
    _languagePlayCounts.forEach((k, v) {
      combined[k] = (combined[k] ?? 0) + v;
    });
    
    _searchedLanguages.forEach((k, v) {
      combined[k] = (combined[k] ?? 0) + (v * 2); // Weight searches higher
    });

    final sorted = combined.entries
        .where((e) => e.value >= minPlaysForInfluence)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get taste profile summary
  Map<String, dynamic> getTasteProfile() {
    return {
      'topArtists': getTopDiscoveredArtists(limit: 10),
      'topGenres': getTopGenres(limit: 10),
      'discoveredLanguages': getDiscoveredLanguages(limit: 5),
      'recentArtists': _recentArtists.take(10).toList(),
      'recentGenres': _recentGenres.take(10).toList(),
      'hasSpotifyData': hasSpotifyData,
      'totalArtistsTracked': _artistPlayCounts.length,
      'totalGenresTracked': _genrePlayCounts.length,
    };
  }

  /// Calculate taste influence score (0.0 to 1.0)
  /// Higher score = more discovered taste should influence recommendations
  double getTasteInfluenceScore() {
    final totalPlays = _artistPlayCounts.values.fold(0, (a, b) => a + b);
    final uniqueArtists = _artistPlayCounts.length;
    
    // More plays and variety = higher influence
    if (totalPlays < 10) return 0.0;
    if (totalPlays < 50) return 0.1;
    if (totalPlays < 100) return 0.15;
    return 0.2; // Max 20% influence
  }

  // ============ HELPER METHODS ============

  void _addToRecent(List<String> list, String item) {
    list.remove(item);
    list.insert(0, item);
    if (list.length > maxRecentItems) {
      list.removeRange(maxRecentItems, list.length);
    }
  }

  /// Detect language from track metadata
  String? _detectLanguage(Track track) {
    final title = track.title.toLowerCase();
    final artist = track.artist.toLowerCase();
    final combined = '$title $artist';

    // Hindi/Bollywood indicators
    if (_containsHindiIndicators(combined)) return 'hindi';
    
    // Punjabi indicators
    if (_containsPunjabiIndicators(combined)) return 'punjabi';
    
    // Tamil indicators
    if (_containsTamilIndicators(combined)) return 'tamil';
    
    // Telugu indicators
    if (_containsTeluguIndicators(combined)) return 'telugu';
    
    // Korean indicators
    if (_containsKoreanIndicators(combined)) return 'korean';
    
    // Spanish indicators
    if (_containsSpanishIndicators(combined)) return 'spanish';

    // Check for Devanagari script
    if (RegExp(r'[\u0900-\u097F]').hasMatch(combined)) return 'hindi';
    
    // Check for Gurmukhi script (Punjabi)
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(combined)) return 'punjabi';

    return null; // Unknown/English
  }

  bool _containsHindiIndicators(String text) {
    final indicators = [
      'bollywood', 'hindi', 'dil', 'pyaar', 'ishq', 'mohabbat',
      'arijit', 'shreya ghoshal', 'neha kakkar', 'jubin nautiyal',
      'atif aslam', 'armaan malik', 'darshan raval', 'sonu nigam'
    ];
    return indicators.any((i) => text.contains(i));
  }

  bool _containsPunjabiIndicators(String text) {
    final indicators = [
      'punjabi', 'bhangra', 'sidhu', 'moose wala', 'diljit', 'ap dhillon',
      'karan aujla', 'ammy virk', 'harrdy sandhu', 'shubh', 'parmish verma',
      'jassie gill', 'babbu maan', 'gurdas maan'
    ];
    return indicators.any((i) => text.contains(i));
  }

  bool _containsTamilIndicators(String text) {
    final indicators = [
      'tamil', 'anirudh', 'a.r. rahman', 'sid sriram', 'yuvan',
      'harris jayaraj', 'd. imman', 'santhosh narayanan'
    ];
    return indicators.any((i) => text.contains(i));
  }

  bool _containsTeluguIndicators(String text) {
    final indicators = [
      'telugu', 'thaman', 'devi sri prasad', 'dsp', 'mangli'
    ];
    return indicators.any((i) => text.contains(i));
  }

  bool _containsKoreanIndicators(String text) {
    final indicators = [
      'kpop', 'k-pop', 'bts', 'blackpink', 'twice', 'stray kids',
      'newjeans', 'aespa', 'ive', 'le sserafim', 'korean'
    ];
    return indicators.any((i) => text.contains(i));
  }

  bool _containsSpanishIndicators(String text) {
    final indicators = [
      'reggaeton', 'latin', 'bad bunny', 'j balvin', 'shakira',
      'daddy yankee', 'ozuna', 'maluma', 'karol g', 'spanish'
    ];
    return indicators.any((i) => text.contains(i));
  }

  /// Detect language from search query
  String? _detectLanguageFromQuery(String query) {
    final lower = query.toLowerCase();
    
    if (_containsHindiIndicators(lower)) return 'hindi';
    if (_containsPunjabiIndicators(lower)) return 'punjabi';
    if (_containsTamilIndicators(lower)) return 'tamil';
    if (_containsTeluguIndicators(lower)) return 'telugu';
    if (_containsKoreanIndicators(lower)) return 'korean';
    if (_containsSpanishIndicators(lower)) return 'spanish';
    
    return null;
  }

  /// Detect genres from track
  List<String> _detectGenres(Track track) {
    final title = track.title.toLowerCase();
    final genres = <String>[];

    final genreKeywords = {
      'romantic': ['romantic', 'love', 'pyaar', 'ishq', 'dil'],
      'sad': ['sad', 'broken', 'dard', 'tanha', 'alone'],
      'party': ['party', 'dance', 'club', 'dj'],
      'chill': ['chill', 'lofi', 'lo-fi', 'relax', 'calm'],
      'workout': ['workout', 'gym', 'motivation', 'energy'],
      'devotional': ['bhajan', 'aarti', 'mantra', 'devotional'],
      'sufi': ['sufi', 'qawwali'],
      'hip hop': ['hip hop', 'rap', 'trap'],
      'rock': ['rock', 'metal'],
      'pop': ['pop'],
      'edm': ['edm', 'electronic', 'house', 'techno'],
      'acoustic': ['acoustic', 'unplugged'],
      'indie': ['indie', 'alternative'],
    };

    for (final entry in genreKeywords.entries) {
      if (entry.value.any((keyword) => title.contains(keyword))) {
        genres.add(entry.key);
      }
    }

    return genres;
  }

  /// Clear all taste data
  Future<void> clearTasteData() async {
    _artistPlayCounts.clear();
    _languagePlayCounts.clear();
    _genrePlayCounts.clear();
    _searchedArtists.clear();
    _searchedLanguages.clear();
    _recentArtists.clear();
    _recentGenres.clear();
    _spotifyTasteData = null;

    await _prefs?.remove(_artistPlayCountsKey);
    await _prefs?.remove(_languagePlayCountsKey);
    await _prefs?.remove(_genrePlayCountsKey);
    await _prefs?.remove(_searchedArtistsKey);
    await _prefs?.remove(_searchedLanguagesKey);
    await _prefs?.remove(_recentArtistsKey);
    await _prefs?.remove(_recentGenresKey);
    await _prefs?.remove(_spotifyTasteKey);

    notifyListeners();
    print('UserTasteService: Cleared all taste data');
  }
}
