import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/youtube_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/user_taste_service.dart';
import 'package:sangeet/services/play_history_service.dart';

// Random seed that changes on each app launch/refresh for variety
final _randomSeed = Random();

/// Time-based rotation index — changes every 3 hours so the same session
/// feels fresh if the user comes back later in the day.
int _rotationIndex() => DateTime.now().hour ~/ 3;

/// Pick a random item from a list, biased by the current rotation window
/// so that different time slots tend to pick different items.
String _rotatedPick(List<String> items) {
  final idx = (_rotationIndex() + _randomSeed.nextInt(items.length)) % items.length;
  return items[idx];
}

// Query variations for different sections to get different results each time
final _trendingVariations = [
  'trending songs', 'viral songs', 'most popular songs', 'top charts',
  'hit songs right now', 'songs everyone is listening to', 'trending music',
  'popular songs this week', 'top songs today',
];

final _topHitsVariations = [
  'top hits', 'best songs', 'popular songs', 'hit songs', 'chart toppers',
  'most played', 'viral songs', 'trending hits', 'top tracks',
];

final _chillVariations = [
  'chill songs', 'relaxing music', 'calm songs', 'peaceful music',
  'lofi beats', 'soft music', 'ambient music', 'mellow songs',
];

final _newReleaseVariations = [
  'new songs', 'latest releases', 'new music', 'just released songs',
  'brand new songs', 'fresh music', 'newest tracks',
];

final _yearVariations = ['2025', '2024', 'latest', 'new'];

/// Deduplicate tracks by id, limit per artist, and shuffle
List<Track> _dedupeAndShuffle(List<Track> tracks, {int maxPerArtist = 3, int limit = 10}) {
  final seen = <String>{};
  final artistCount = <String, int>{};
  final result = <Track>[];
  for (final t in tracks) {
    if (seen.contains(t.id)) continue;
    final a = t.artist.toLowerCase();
    if ((artistCount[a] ?? 0) >= maxPerArtist) continue;
    seen.add(t.id);
    artistCount[a] = (artistCount[a] ?? 0) + 1;
    result.add(t);
  }
  result.shuffle(_randomSeed);
  return result.take(limit).toList();
}

/// Fetch from multiple queries in parallel and merge results for variety
Future<List<Track>> _multiQuerySearch(
  Ref ref,
  List<String> queries, {
  int perQuery = 8,
  int maxPerArtist = 2,
  int totalLimit = 10,
}) async {
  final futures = queries.map((q) => _searchWithSource(ref, q, limit: perQuery));
  final results = await Future.wait(futures);
  final all = results.expand((r) => r).toList();
  return _dedupeAndShuffle(all, maxPerArtist: maxPerArtist, limit: totalLimit);
}

/// Get a random artist from the user's selected artists list, rotated by time
String? _getRotatedArtist(List<PreferredArtist> artists, {int offset = 0}) {
  if (artists.isEmpty) return null;
  final idx = (_rotationIndex() + offset + _randomSeed.nextInt(artists.length)) % artists.length;
  return artists[idx].name;
}

/// Get a random top artist from a language, rotated by time
String _getRotatedLangArtist(MusicLanguage lang, {int offset = 0}) {
  if (lang.topArtists.isEmpty) return lang.displayName;
  final idx = (_rotationIndex() + offset + _randomSeed.nextInt(lang.topArtists.length)) % lang.topArtists.length;
  return lang.topArtists[idx];
}

// Music Service Provider
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService();
  ref.onDispose(() => service.dispose());
  return service;
});

// YTMusic Service Provider
final ytMusicServiceProvider = Provider<YtMusicService>((ref) {
  return YtMusicService();
});

/// Unified search function that uses the selected music source
Future<List<Track>> searchMusic(
  WidgetRef ref,
  String query, {
  int limit = 20,
}) async {
  final musicSource = ref.read(musicSourceProvider);
  
  if (musicSource == MusicSource.ytMusic) {
    final ytMusic = ref.read(ytMusicServiceProvider);
    return ytMusic.searchSongs(query, limit: limit);
  } else {
    final youtube = ref.read(youtubeServiceProvider);
    return youtube.searchMusic(query, limit: limit);
  }
}

/// Provider-based search that respects music source setting
Future<List<Track>> _searchWithSource(
  Ref ref,
  String query, {
  int limit = 20,
}) async {
  final musicSource = ref.watch(musicSourceProvider);
  
  if (musicSource == MusicSource.ytMusic) {
    final ytMusic = ref.watch(ytMusicServiceProvider);
    return ytMusic.searchSongs(query, limit: limit);
  } else {
    final youtube = ref.watch(youtubeServiceProvider);
    return youtube.searchMusic(query, limit: limit);
  }
}

// Search Results Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Track>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  return _searchWithSource(ref, query);
});

// Trending Music Provider - uses multiple rotating queries for variety
final trendingMusicProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final tasteService = UserTasteService.instance;
  
  final queries = <String>[];
  final variation = _rotatedPick(_trendingVariations);
  final year = _rotatedPick(_yearVariations);
  
  // Language-based trending (primary)
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    queries.add('${lang.displayName} $variation $year');
    // Add a rotated top artist from this language for variety
    final artist = _getRotatedLangArtist(lang);
    queries.add('$artist latest songs');
  }
  
  // Add a selected artist query if available
  final artistName = _getRotatedArtist(prefs.selectedArtists);
  if (artistName != null) {
    queries.add('$artistName trending');
  }
  
  // Add discovered taste artist if available
  final discovered = tasteService.getTopDiscoveredArtists(limit: 3);
  if (discovered.isNotEmpty) {
    final pick = discovered[_randomSeed.nextInt(discovered.length)];
    queries.add('$pick popular songs');
  }
  
  // Fallback
  if (queries.isEmpty) {
    queries.add('trending music $year');
    queries.add('$variation $year');
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 15);
});

// Home Page Data Providers - personalized based on preferences
final recentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final historyService = PlayHistoryService.instance;
  
  // Use actual listening history for seed queries
  final recentSongs = historyService.getRecentSongs(limit: 5);
  if (recentSongs.isNotEmpty) {
    final queries = <String>[];
    // Pick 2-3 random recent artists
    final artists = recentSongs.map((s) => s.artist).toSet().toList()..shuffle();
    for (final artist in artists.take(3)) {
      queries.add('$artist songs');
    }
    return _multiQuerySearch(ref, queries, totalLimit: 10);
  }
  
  // Fallback to selected artist
  final artistName = _getRotatedArtist(prefs.selectedArtists);
  if (artistName != null) {
    return _searchWithSource(ref, '$artistName songs', limit: 10);
  }
  
  return _searchWithSource(ref, 'popular songs 2024', limit: 10);
});

final newReleasesProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final variation = _rotatedPick(_newReleaseVariations);
  final year = _rotatedPick(_yearVariations);
  
  final queries = <String>[];
  
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    queries.add('${lang.displayName} $variation $year');
    // Add a rotated artist from this language
    final artist = _getRotatedLangArtist(lang, offset: 2);
    queries.add('$artist new song');
  }
  
  // Second language new releases too
  if (prefs.selectedLanguages.length > 1) {
    final lang2 = prefs.selectedLanguages[1];
    queries.add('${lang2.displayName} $variation $year');
  }
  
  if (queries.isEmpty) {
    queries.add('$variation $year');
    queries.add('new music releases $year');
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 10);
});

final topHitsProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final tasteService = UserTasteService.instance;
  
  final variation = _rotatedPick(_topHitsVariations);
  final year = _rotatedPick(_yearVariations);
  
  final queries = <String>[];
  
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    queries.add('${lang.displayName} $variation $year');
    // Rotate through top artists of this language
    final artist = _getRotatedLangArtist(lang, offset: 3);
    queries.add('$artist best songs');
  }
  
  // Blend in a discovered genre if available
  final topGenres = tasteService.getTopGenres(limit: 3);
  if (topGenres.isNotEmpty) {
    final genre = topGenres[_randomSeed.nextInt(topGenres.length)];
    queries.add('$genre $variation');
  }
  
  if (queries.isEmpty) {
    queries.add('$variation $year');
    queries.add('global top hits $year');
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 12);
});

final chillMusicProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  final variation = _rotatedPick(_chillVariations);
  
  final queries = <String>[];
  
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    queries.add('${lang.displayName} $variation');
    // Add an acoustic/unplugged variant of a selected artist
    final artistName = _getRotatedArtist(prefs.selectedArtists, offset: 1);
    if (artistName != null) {
      queries.add('$artistName acoustic unplugged');
    }
  }
  
  if (queries.isEmpty) {
    queries.add(variation);
    queries.add('chill vibes playlist');
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 10);
});

// Dynamic provider based on second language or Bollywood
final bollywoodHitsProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  final variation = _rotatedPick(_topHitsVariations);
  final year = _rotatedPick(_yearVariations);
  
  final queries = <String>[];
  
  if (prefs.selectedLanguages.length > 1) {
    final lang = prefs.selectedLanguages[1];
    queries.add('${lang.displayName} $variation $year');
    final artist = _getRotatedLangArtist(lang, offset: 1);
    queries.add('$artist songs');
  } else {
    queries.add('bollywood $variation $year');
    queries.add('bollywood romantic songs $year');
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 10);
});

final englishPopProvider = FutureProvider<List<Track>>((ref) async {
  final variation = _rotatedPick(_topHitsVariations);
  return _searchWithSource(ref, 'english pop $variation', limit: 10);
});

// Artist-based recommendations - blends selected artists with discovered taste
final forYouProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final tasteService = UserTasteService.instance;
  final historyService = PlayHistoryService.instance;
  
  final queries = <String>[];
  final queryVariants = ['best songs', 'top songs', 'hits', 'popular songs', 'latest songs'];
  final variant = _rotatedPick(queryVariants);
  
  // PRIMARY: Rotate through selected artists (not always the same 3)
  if (prefs.selectedArtists.isNotEmpty) {
    // Pick 2-3 artists with rotation so different sessions show different artists
    for (int offset = 0; offset < 3 && offset < prefs.selectedArtists.length; offset++) {
      final artist = _getRotatedArtist(prefs.selectedArtists, offset: offset);
      if (artist != null) queries.add('$artist $variant');
    }
  }
  
  // SECONDARY: Artists from listening history (not in selected list)
  final recentSongs = historyService.getRecentSongs(limit: 10);
  final selectedNames = prefs.selectedArtists.map((a) => a.name.toLowerCase()).toSet();
  final historyArtists = recentSongs
      .map((s) => s.artist)
      .where((a) => a.isNotEmpty && !selectedNames.contains(a.toLowerCase()))
      .toSet()
      .toList()..shuffle();
  for (final artist in historyArtists.take(2)) {
    queries.add('$artist songs');
  }
  
  // TERTIARY: Discovered taste artists
  final influenceScore = tasteService.getTasteInfluenceScore();
  if (influenceScore > 0) {
    final discovered = tasteService.getTopDiscoveredArtists(limit: 3);
    if (discovered.isNotEmpty) {
      final pick = discovered[_randomSeed.nextInt(discovered.length)];
      queries.add('$pick songs');
    }
  }
  
  // Fallback for first-time users: use language-based recommendations
  if (queries.isEmpty) {
    if (prefs.selectedLanguages.isNotEmpty) {
      final lang = prefs.selectedLanguages.first;
      queries.add('${lang.displayName} $variant');
      final artist = _getRotatedLangArtist(lang);
      queries.add('$artist songs');
    } else {
      queries.add('popular songs 2024');
    }
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 12);
});

// Second artist recommendations - includes discovered genres
final moreFromArtistsProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final tasteService = UserTasteService.instance;
  
  final queries = <String>[];
  
  // PRIMARY: Rotate through later selected artists (offset by 2 so it's different from forYou)
  if (prefs.selectedArtists.length > 2) {
    final artist = _getRotatedArtist(prefs.selectedArtists, offset: 4);
    if (artist != null) queries.add('$artist songs');
  }
  
  // SECONDARY: Discovered genres
  final topGenres = tasteService.getTopGenres(limit: 4);
  if (topGenres.isNotEmpty) {
    final genre = topGenres[(_rotationIndex() + 1) % topGenres.length];
    queries.add('$genre music ${_rotatedPick(_yearVariations)}');
    if (topGenres.length > 1) {
      final genre2 = topGenres[(_rotationIndex() + 2) % topGenres.length];
      queries.add('$genre2 songs');
    }
  }
  
  // Fallback
  if (queries.isEmpty) {
    if (prefs.selectedLanguages.isNotEmpty) {
      final lang = prefs.selectedLanguages.first;
      final artist = _getRotatedLangArtist(lang, offset: 5);
      queries.add('$artist songs');
      queries.add('${lang.displayName} indie music');
    } else {
      queries.add('indie music 2024');
    }
  }
  
  return _multiQuerySearch(ref, queries, totalLimit: 10);
});

// Discovered taste section - shows songs based on user's listening behavior
final discoveredForYouProvider = FutureProvider<List<Track>>((ref) async {
  final tasteService = UserTasteService.instance;
  
  final influenceScore = tasteService.getTasteInfluenceScore();
  if (influenceScore == 0) {
    // No taste data yet, return empty
    return [];
  }
  
  final queries = <String>[];
  
  // Get songs from discovered artists (rotated)
  final discoveredArtists = tasteService.getTopDiscoveredArtists(limit: 5);
  if (discoveredArtists.isNotEmpty) {
    // Pick 2 rotated artists instead of always the top ones
    for (int i = 0; i < 2 && i < discoveredArtists.length; i++) {
      final idx = (_rotationIndex() + i) % discoveredArtists.length;
      queries.add('${discoveredArtists[idx]} songs');
    }
  }
  
  // Get songs from discovered languages
  final discoveredLangs = tasteService.getDiscoveredLanguages(limit: 3);
  if (discoveredLangs.isNotEmpty) {
    final lang = discoveredLangs[_rotationIndex() % discoveredLangs.length];
    queries.add('$lang songs hits');
  }
  
  // Get songs from discovered genres (rotated)
  final topGenres = tasteService.getTopGenres(limit: 4);
  if (topGenres.isNotEmpty) {
    final genre = topGenres[(_rotationIndex() + 1) % topGenres.length];
    queries.add('$genre music');
  }
  
  if (queries.isEmpty) return [];
  
  return _multiQuerySearch(ref, queries, totalLimit: 10);
});
