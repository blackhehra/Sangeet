import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/related_page.dart';
import 'package:sangeet/models/play_event.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/followed_artists_service.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/user_taste_service.dart';

/// Quick picks source for personalized recommendations
enum QuickPicksSource {
  trending,      // Based on most played songs
  lastInteraction, // Based on most recently played song
}

/// Quick picks state
class QuickPicksState {
  final SongStats? seedSong;
  final RelatedPage? relatedPage;
  final List<Track>? searchSongs; // Songs from search API (has duration)
  final bool isLoading;
  final String? error;

  const QuickPicksState({
    this.seedSong,
    this.relatedPage,
    this.searchSongs,
    this.isLoading = false,
    this.error,
  });

  QuickPicksState copyWith({
    SongStats? seedSong,
    RelatedPage? relatedPage,
    List<Track>? searchSongs,
    bool? isLoading,
    String? error,
  }) => QuickPicksState(
    seedSong: seedSong ?? this.seedSong,
    relatedPage: relatedPage ?? this.relatedPage,
    searchSongs: searchSongs ?? this.searchSongs,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Quick picks notifier for home screen recommendations
class QuickPicksNotifier extends StateNotifier<QuickPicksState> {
  final PlayHistoryService _historyService;
  final InnertubeService _innertubeService;
  final YtMusicService _ytMusicService = YtMusicService();
  final FollowedArtistsService _followedArtistsService = FollowedArtistsService.instance;
  QuickPicksSource _source = QuickPicksSource.trending;

  QuickPicksNotifier(this._historyService, this._innertubeService) 
      : super(const QuickPicksState());

  QuickPicksSource get source => _source;

  set source(QuickPicksSource value) {
    _source = value;
    refresh();
  }

  /// Load quick picks based on user's listening history
  Future<void> load() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get seed song based on source - with randomization for variety
      SongStats? seedSong;
      
      if (_source == QuickPicksSource.trending) {
        // Get from top trending songs with randomization for variety
        final trending = _historyService.getTrendingSongs(limit: 5);
        if (trending.isNotEmpty) {
          // Randomly pick from top 5 trending songs for variety
          trending.shuffle();
          seedSong = trending.first;
        }
      } else {
        // Get from recent songs with randomization
        final recentSongs = _historyService.getRecentSongs(limit: 5);
        if (recentSongs.isNotEmpty) {
          recentSongs.shuffle();
          seedSong = recentSongs.first;
        } else {
          seedSong = _historyService.getMostRecentSong();
        }
      }

      if (seedSong == null) {
        // No history yet - use user's selected language preferences for recommendations
        print('QuickPicks: No history, using language preferences');
        await _ytMusicService.init();
        
        final List<Track> searchSongs = await _fetchLanguageBasedSongs();
        
        // If no language preferences, fall back to popular songs
        if (searchSongs.isEmpty) {
          final fallbackSongs = await _ytMusicService.searchSongs('popular songs 2024', limit: 15);
          searchSongs.addAll(fallbackSongs);
        }
        
        final relatedPage = await _innertubeService.getRelatedPage('J7p4bzqLvCw');
        
        state = state.copyWith(
          relatedPage: relatedPage,
          searchSongs: searchSongs,
          isLoading: false,
        );
        return;
      }

      print('QuickPicks: Using seed song: ${seedSong.title} (${seedSong.songId})');

      // Always fetch fresh data for artists/albums - don't use cache
      // This ensures the "Similar Artists" section updates each time

      // Fetch related page from Innertube API (for artists, albums, playlists)
      final relatedPage = await _innertubeService.getRelatedPage(seedSong.songId);

      // IMPROVED ALGORITHM: Fetch diverse songs based on multiple factors
      // Goal: Show similar TYPE of music, not just same artist
      await _ytMusicService.init();
      final artistName = seedSong.artist ?? '';
      final songTitle = seedSong.title ?? '';
      
      // Get multiple seed songs for variety (use different recent songs)
      final recentSongs = _historyService.getRecentSongs(limit: 5);
      final trendingSongs = _historyService.getTrendingSongs(limit: 5);
      
      // Collect unique artists from history to EXCLUDE (avoid showing same artists)
      final excludeArtists = <String>{};
      for (final song in [...recentSongs, ...trendingSongs]) {
        if (song.artist != null && song.artist!.isNotEmpty) {
          excludeArtists.add(song.artist!.toLowerCase());
        }
      }
      
      final List<Track> searchSongs = [];
      
      // Strategy 1: Genre/mood based discovery (40% of recommendations)
      // Extract potential genre keywords from song title
      final genreKeywords = _extractGenreKeywords(songTitle);
      for (final genre in genreKeywords.take(2)) {
        final genreSongs = await _ytMusicService.searchSongs('$genre songs', limit: 4);
        searchSongs.addAll(genreSongs);
      }
      
      // Strategy 2: "Fans also like" style - similar artists (30%)
      if (artistName.isNotEmpty) {
        final similarArtistSongs = await _ytMusicService.searchSongs(
          'artists like $artistName music', limit: 5
        );
        searchSongs.addAll(similarArtistSongs);
      }
      
      // Strategy 3: Trending/popular in similar style (20%)
      final trendingQuery = genreKeywords.isNotEmpty 
          ? '${genreKeywords.first} trending songs'
          : 'trending music';
      final trendingSongsResult = await _ytMusicService.searchSongs(trendingQuery, limit: 4);
      searchSongs.addAll(trendingSongsResult);
      
      // Strategy 4: Discovery - random popular songs for variety (10%)
      final discoverySongs = await _ytMusicService.searchSongs('popular new songs', limit: 3);
      searchSongs.addAll(discoverySongs);
      
      // Remove duplicates and filter out songs from artists user already listens to heavily
      final uniqueSongs = <String, Track>{};
      final artistSongCount = <String, int>{}; // Limit songs per artist
      
      for (final song in searchSongs) {
        // Skip if it's the same song as seed
        if (song.id == seedSong.songId) continue;
        
        // Skip if same title and artist (likely same song)
        if (song.title.toLowerCase() == songTitle.toLowerCase() && 
            song.artist.toLowerCase() == artistName.toLowerCase()) continue;
        
        // Limit songs from same artist to max 2 (for variety)
        final songArtist = song.artist.toLowerCase();
        final currentCount = artistSongCount[songArtist] ?? 0;
        if (currentCount >= 2) continue;
        
        // Slightly deprioritize songs from artists user already plays a lot
        // (but don't completely exclude - they might still want some)
        if (excludeArtists.contains(songArtist) && currentCount >= 1) continue;
        
        uniqueSongs[song.id] = song;
        artistSongCount[songArtist] = currentCount + 1;
      }
      
      final dedupedSongs = uniqueSongs.values.toList();
      // Shuffle to mix different sources
      dedupedSongs.shuffle();

      // Fetch songs from followed artists and merge into quick picks (20-30%)
      final followedArtistSongs = await _fetchFollowedArtistSongs();
      final mergedSongs = _mergeWithFollowedArtistSongs(dedupedSongs, followedArtistSongs);

      state = state.copyWith(
        seedSong: seedSong,
        relatedPage: relatedPage,
        searchSongs: mergedSongs,
        isLoading: false,
      );

      // Cache the results
      if (relatedPage != null) {
        await _historyService.cacheQuickPicks(relatedPage.toJson());
      }
    } catch (e) {
      print('QuickPicks: Error loading: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Extract genre/mood keywords from song title for discovery
  List<String> _extractGenreKeywords(String songTitle) {
    final title = songTitle.toLowerCase();
    final keywords = <String>[];
    
    // Common genre/mood keywords to detect
    final genreMap = {
      // Hindi/Bollywood
      'romantic': ['romantic', 'love', 'pyaar', 'ishq', 'dil', 'heart'],
      'sad': ['sad', 'broken', 'dard', 'tanha', 'alone', 'cry'],
      'party': ['party', 'dance', 'club', 'dj', 'beat'],
      'devotional': ['bhajan', 'aarti', 'mantra', 'prayer', 'devotional'],
      'sufi': ['sufi', 'qawwali'],
      'ghazal': ['ghazal'],
      'punjabi': ['punjabi', 'bhangra'],
      
      // English/Western
      'pop': ['pop'],
      'rock': ['rock', 'metal'],
      'hip hop': ['hip hop', 'rap', 'trap'],
      'edm': ['edm', 'electronic', 'house', 'techno'],
      'r&b': ['r&b', 'rnb', 'soul'],
      'jazz': ['jazz'],
      'classical': ['classical', 'symphony', 'orchestra'],
      'acoustic': ['acoustic', 'unplugged'],
      'indie': ['indie', 'alternative'],
      'chill': ['chill', 'lofi', 'lo-fi', 'relax', 'calm'],
      'workout': ['workout', 'gym', 'motivation', 'energy'],
    };
    
    for (final entry in genreMap.entries) {
      for (final keyword in entry.value) {
        if (title.contains(keyword)) {
          keywords.add(entry.key);
          break;
        }
      }
    }
    
    // If no specific genre found, use general discovery queries
    if (keywords.isEmpty) {
      // Try to detect language/region from common patterns
      if (RegExp(r'[ा-ू]').hasMatch(songTitle)) {
        keywords.addAll(['hindi', 'bollywood']);
      } else {
        keywords.addAll(['trending', 'popular']);
      }
    }
    
    return keywords;
  }

  /// Merge followed artist songs into quick picks (20-30% of total)
  List<Track> _mergeWithFollowedArtistSongs(List<Track> baseSongs, List<Track> followedSongs) {
    if (followedSongs.isEmpty) return baseSongs;
    
    // Calculate how many followed artist songs to include (20-30% of total)
    final totalTarget = baseSongs.length + 3; // Add a few more songs
    final followedCount = (totalTarget * 0.25).round().clamp(1, followedSongs.length);
    final baseCount = totalTarget - followedCount;
    
    // Take songs from each list
    final selectedBase = baseSongs.take(baseCount).toList();
    final selectedFollowed = followedSongs.take(followedCount).toList();
    
    // Merge and shuffle to mix them naturally
    final merged = [...selectedBase, ...selectedFollowed];
    merged.shuffle();
    
    print('QuickPicks: Merged ${selectedBase.length} base + ${selectedFollowed.length} followed artist songs');
    return merged;
  }

  /// Fetch songs from followed artists (20-30% of recommendations)
  Future<List<Track>> _fetchFollowedArtistSongs() async {
    try {
      await _followedArtistsService.init();
      final artistNames = _followedArtistsService.getArtistsForRecommendations();
      
      if (artistNames.isEmpty) {
        print('QuickPicks: No followed artists for recommendations');
        return [];
      }
      
      print('QuickPicks: Fetching songs from ${artistNames.length} followed artists');
      
      final List<Track> allSongs = [];
      for (final artistName in artistNames) {
        try {
          final songs = await _ytMusicService.searchSongs('$artistName songs', limit: 5);
          allSongs.addAll(songs);
        } catch (e) {
          print('QuickPicks: Error fetching songs for $artistName: $e');
        }
      }
      
      // Shuffle to mix songs from different artists
      allSongs.shuffle();
      
      print('QuickPicks: Found ${allSongs.length} songs from followed artists');
      return allSongs;
    } catch (e) {
      print('QuickPicks: Error fetching followed artist songs: $e');
      return [];
    }
  }

  /// Fetch songs based on user's selected language preferences and discovered taste
  /// Prioritizes selected language (~80%) with small influence from discovered taste (~20%)
  Future<List<Track>> _fetchLanguageBasedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languagesJson = prefs.getStringList('selected_languages') ?? [];
      final artistsJson = prefs.getString('selected_artists');
      
      // Initialize taste service
      final tasteService = UserTasteService.instance;
      await tasteService.init();
      
      final List<Track> primarySongs = [];   // Selected language songs (80%)
      final List<Track> secondarySongs = []; // Discovered taste songs (20%)
      
      // ============ PRIMARY: Selected Language Songs (80%) ============
      
      // First priority: Songs from selected artists
      if (artistsJson != null && artistsJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(artistsJson);
          for (final artistData in decoded.take(5)) {
            final artistName = artistData['name'] as String?;
            if (artistName != null && artistName.isNotEmpty) {
              print('QuickPicks: Fetching songs for preferred artist: $artistName');
              final songs = await _ytMusicService.searchSongs('$artistName latest songs', limit: 4);
              primarySongs.addAll(songs);
            }
          }
        } catch (e) {
          print('QuickPicks: Error parsing selected artists: $e');
        }
      }
      
      // Second priority: Songs from selected languages
      for (final langCode in languagesJson.take(3)) {
        final language = MusicLanguage.values.firstWhere(
          (l) => l.code == langCode,
          orElse: () => MusicLanguage.hindi,
        );
        
        print('QuickPicks: Fetching songs for language: ${language.displayName}');
        
        // Search for popular songs in this language
        final langSongs = await _ytMusicService.searchSongs(
          '${language.displayName} songs 2024 hits', 
          limit: 6
        );
        primarySongs.addAll(langSongs);
        
        // Also get songs from top artists of this language
        for (final artist in language.topArtists.take(2)) {
          final artistSongs = await _ytMusicService.searchSongs('$artist songs', limit: 3);
          primarySongs.addAll(artistSongs);
        }
      }
      
      // ============ SECONDARY: Discovered Taste Songs (20%) ============
      
      // Get influence score - how much discovered taste should affect recommendations
      final influenceScore = tasteService.getTasteInfluenceScore();
      
      if (influenceScore > 0) {
        // Get top discovered artists (from listening behavior)
        final discoveredArtists = tasteService.getTopDiscoveredArtists(limit: 3);
        for (final artist in discoveredArtists) {
          print('QuickPicks: Adding discovered artist: $artist');
          final songs = await _ytMusicService.searchSongs('$artist songs', limit: 2);
          secondarySongs.addAll(songs);
        }
        
        // Get discovered languages (languages user shows interest in)
        final discoveredLangs = tasteService.getDiscoveredLanguages(limit: 2);
        for (final lang in discoveredLangs) {
          // Skip if already in selected languages
          if (!languagesJson.any((l) => l.toLowerCase() == lang.toLowerCase())) {
            print('QuickPicks: Adding discovered language: $lang');
            final songs = await _ytMusicService.searchSongs('$lang songs hits', limit: 2);
            secondarySongs.addAll(songs);
          }
        }
        
        // Get top genres
        final topGenres = tasteService.getTopGenres(limit: 2);
        for (final genre in topGenres) {
          print('QuickPicks: Adding discovered genre: $genre');
          final songs = await _ytMusicService.searchSongs('$genre music', limit: 2);
          secondarySongs.addAll(songs);
        }
      }
      
      // ============ BLEND RESULTS ============
      
      // Calculate how many songs from each category
      final totalTarget = 20;
      final primaryCount = (totalTarget * 0.80).round();
      final secondaryCount = totalTarget - primaryCount;
      
      // Remove duplicates from each list
      final uniquePrimary = <String, Track>{};
      for (final song in primarySongs) {
        uniquePrimary[song.id] = song;
      }
      
      final uniqueSecondary = <String, Track>{};
      for (final song in secondarySongs) {
        // Don't add if already in primary
        if (!uniquePrimary.containsKey(song.id)) {
          uniqueSecondary[song.id] = song;
        }
      }
      
      // Shuffle each list
      final primaryList = uniquePrimary.values.toList()..shuffle();
      final secondaryList = uniqueSecondary.values.toList()..shuffle();
      
      // Combine with proper ratio
      final result = <Track>[];
      result.addAll(primaryList.take(primaryCount));
      result.addAll(secondaryList.take(secondaryCount));
      result.shuffle(); // Final shuffle for natural mix
      
      print('QuickPicks: Found ${result.length} songs '
          '(${primaryList.length} primary, ${secondaryList.length} secondary)');
      return result.take(totalTarget).toList();
    } catch (e) {
      print('QuickPicks: Error fetching language-based songs: $e');
      return [];
    }
  }

  /// Refresh quick picks
  Future<void> refresh() async {
    state = const QuickPicksState();
    await load();
  }

  /// Load from cache if available
  Future<void> loadFromCache() async {
    final cached = _historyService.getCachedQuickPicks();
    if (cached != null) {
      try {
        final relatedPage = RelatedPage.fromJson(cached);
        state = state.copyWith(relatedPage: relatedPage);
      } catch (e) {
        print('QuickPicks: Failed to load from cache: $e');
      }
    }
  }
}

/// Provider for play history service
final playHistoryServiceProvider = Provider<PlayHistoryService>((ref) {
  return PlayHistoryService.instance;
});

/// Provider for quick picks
final quickPicksProvider = StateNotifierProvider<QuickPicksNotifier, QuickPicksState>((ref) {
  final historyService = ref.watch(playHistoryServiceProvider);
  final innertubeService = InnertubeService();
  return QuickPicksNotifier(historyService, innertubeService);
});

/// Provider for trending songs from user's history
final userTrendingSongsProvider = Provider<List<SongStats>>((ref) {
  final historyService = ref.watch(playHistoryServiceProvider);
  return historyService.getTrendingSongs(limit: 10);
});

/// Provider for play history
final playHistoryProvider = Provider<List<PlayEvent>>((ref) {
  final historyService = ref.watch(playHistoryServiceProvider);
  return historyService.getHistory(limit: 50);
});

/// Time period for filtering trending songs
enum TrendingPeriod {
  pastDay(Duration(days: 1), 'Past 24 hours'),
  pastWeek(Duration(days: 7), 'Past week'),
  pastMonth(Duration(days: 30), 'Past month'),
  pastYear(Duration(days: 365), 'Past year'),
  allTime(null, 'All time');

  final Duration? duration;
  final String displayName;
  const TrendingPeriod(this.duration, this.displayName);
}

/// Provider for trending songs with time period filter
final trendingSongsWithPeriodProvider = Provider.family<List<SongStats>, TrendingPeriod>((ref, period) {
  final historyService = ref.watch(playHistoryServiceProvider);
  
  if (period.duration == null) {
    return historyService.getTrendingSongs(limit: 50);
  }
  
  return historyService.getTrendingSongsInPeriod(
    period: period.duration!,
    limit: 50,
  );
});

/// Provider for local liked songs (from PlayHistoryService)
final localLikedSongsProvider = Provider<List<Track>>((ref) {
  final historyService = ref.watch(playHistoryServiceProvider);
  return historyService.getLikedSongs();
});

/// Notifier to refresh local liked songs
final localLikedSongsRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider for local liked songs that refreshes when notifier changes
final localLikedSongsStreamProvider = Provider<List<Track>>((ref) {
  // Watch the refresh trigger to rebuild when liked songs change
  ref.watch(localLikedSongsRefreshProvider);
  final historyService = ref.watch(playHistoryServiceProvider);
  return historyService.getLikedSongs();
});
