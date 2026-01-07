import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/youtube_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/user_taste_service.dart';

// Random seed that changes on each app launch/refresh for variety
final _randomSeed = Random();

// Query variations for different sections to get different results each time
final _topHitsVariations = [
  'top hits', 'best songs', 'popular songs', 'hit songs', 'chart toppers',
  'most played', 'viral songs', 'trending hits', 'top tracks',
];

final _chillVariations = [
  'chill songs', 'relaxing music', 'calm songs', 'peaceful music', 
  'lofi beats', 'soft music', 'ambient music', 'mellow songs',
];

final _yearVariations = ['2024', '2023', 'latest', 'new'];

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

// Trending Music Provider - based on user preferences
final trendingMusicProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  // If user has preferences, use them
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    return _searchWithSource(ref, '${lang.displayName} trending songs 2024', limit: 20);
  }
  
  return _searchWithSource(ref, 'trending music 2024', limit: 20);
});

// Home Page Data Providers - personalized based on preferences
final recentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  // Use first preferred artist if available
  if (prefs.selectedArtists.isNotEmpty) {
    final artist = prefs.selectedArtists.first;
    return _searchWithSource(ref, '${artist.name} songs', limit: 10);
  }
  
  return _searchWithSource(ref, 'popular songs 2024', limit: 10);
});

final newReleasesProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    return _searchWithSource(ref, 'new ${lang.displayName} songs 2024', limit: 10);
  }
  
  return _searchWithSource(ref, 'new music releases 2024', limit: 10);
});

final topHitsProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  // Use random variation for variety
  final variation = _topHitsVariations[_randomSeed.nextInt(_topHitsVariations.length)];
  final year = _yearVariations[_randomSeed.nextInt(_yearVariations.length)];
  
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    final results = await _searchWithSource(ref, '${lang.displayName} $variation $year', limit: 15);
    // Shuffle and take 10 for variety
    results.shuffle(_randomSeed);
    return results.take(10).toList();
  }
  
  final results = await _searchWithSource(ref, '$variation $year', limit: 15);
  results.shuffle(_randomSeed);
  return results.take(10).toList();
});

final chillMusicProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  // Use random variation for variety
  final variation = _chillVariations[_randomSeed.nextInt(_chillVariations.length)];
  
  if (prefs.selectedLanguages.isNotEmpty) {
    final lang = prefs.selectedLanguages.first;
    final results = await _searchWithSource(ref, '${lang.displayName} $variation', limit: 15);
    results.shuffle(_randomSeed);
    return results.take(10).toList();
  }
  
  final results = await _searchWithSource(ref, variation, limit: 15);
  results.shuffle(_randomSeed);
  return results.take(10).toList();
});

// Dynamic provider based on second language or Bollywood
final bollywoodHitsProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  
  final variation = _topHitsVariations[_randomSeed.nextInt(_topHitsVariations.length)];
  final year = _yearVariations[_randomSeed.nextInt(_yearVariations.length)];
  
  if (prefs.selectedLanguages.length > 1) {
    final lang = prefs.selectedLanguages[1];
    final results = await _searchWithSource(ref, '${lang.displayName} $variation $year', limit: 15);
    results.shuffle(_randomSeed);
    return results.take(10).toList();
  }
  
  final results = await _searchWithSource(ref, 'bollywood $variation $year', limit: 15);
  results.shuffle(_randomSeed);
  return results.take(10).toList();
});

final englishPopProvider = FutureProvider<List<Track>>((ref) async {
  return _searchWithSource(ref, 'english pop songs 2024', limit: 10);
});

// Artist-based recommendations - blends selected artists with discovered taste
final forYouProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final tasteService = UserTasteService.instance;
  await tasteService.init();
  
  final tracks = <Track>[];
  
  // PRIMARY: Selected artists (80%)
  if (prefs.selectedArtists.isNotEmpty) {
    for (int i = 0; i < prefs.selectedArtists.length && i < 3; i++) {
      final artist = prefs.selectedArtists[i];
      final artistTracks = await _searchWithSource(ref, '${artist.name} best songs', limit: 4);
      tracks.addAll(artistTracks);
    }
  }
  
  // SECONDARY: Discovered taste artists (20%)
  final influenceScore = tasteService.getTasteInfluenceScore();
  if (influenceScore > 0) {
    final discoveredArtists = tasteService.getTopDiscoveredArtists(limit: 2);
    for (final artist in discoveredArtists) {
      final artistTracks = await _searchWithSource(ref, '$artist songs', limit: 2);
      tracks.addAll(artistTracks);
    }
  }
  
  if (tracks.isEmpty) {
    return _searchWithSource(ref, 'popular songs 2024', limit: 10);
  }
  
  // Remove duplicates and shuffle
  final uniqueTracks = <String, Track>{};
  for (final track in tracks) {
    uniqueTracks[track.id] = track;
  }
  final result = uniqueTracks.values.toList()..shuffle();
  return result.take(10).toList();
});

// Second artist recommendations - includes discovered genres
final moreFromArtistsProvider = FutureProvider<List<Track>>((ref) async {
  final prefs = ref.watch(userPreferencesServiceProvider);
  final tasteService = UserTasteService.instance;
  await tasteService.init();
  
  final tracks = <Track>[];
  
  // PRIMARY: Third selected artist
  if (prefs.selectedArtists.length > 2) {
    final artist = prefs.selectedArtists[2];
    final artistTracks = await _searchWithSource(ref, '${artist.name} songs', limit: 8);
    tracks.addAll(artistTracks);
  }
  
  // SECONDARY: Discovered genres
  final topGenres = tasteService.getTopGenres(limit: 2);
  for (final genre in topGenres) {
    final genreTracks = await _searchWithSource(ref, '$genre music', limit: 2);
    tracks.addAll(genreTracks);
  }
  
  if (tracks.isEmpty) {
    return _searchWithSource(ref, 'indie music 2024', limit: 10);
  }
  
  // Remove duplicates and shuffle
  final uniqueTracks = <String, Track>{};
  for (final track in tracks) {
    uniqueTracks[track.id] = track;
  }
  final result = uniqueTracks.values.toList()..shuffle();
  return result.take(10).toList();
});

// Discovered taste section - shows songs based on user's listening behavior
final discoveredForYouProvider = FutureProvider<List<Track>>((ref) async {
  final tasteService = UserTasteService.instance;
  await tasteService.init();
  
  final influenceScore = tasteService.getTasteInfluenceScore();
  if (influenceScore == 0) {
    // No taste data yet, return empty
    return [];
  }
  
  final tracks = <Track>[];
  
  // Get songs from discovered artists
  final discoveredArtists = tasteService.getTopDiscoveredArtists(limit: 3);
  for (final artist in discoveredArtists) {
    final artistTracks = await _searchWithSource(ref, '$artist songs', limit: 3);
    tracks.addAll(artistTracks);
  }
  
  // Get songs from discovered languages
  final discoveredLangs = tasteService.getDiscoveredLanguages(limit: 2);
  for (final lang in discoveredLangs) {
    final langTracks = await _searchWithSource(ref, '$lang songs hits', limit: 2);
    tracks.addAll(langTracks);
  }
  
  // Get songs from discovered genres
  final topGenres = tasteService.getTopGenres(limit: 2);
  for (final genre in topGenres) {
    final genreTracks = await _searchWithSource(ref, '$genre music', limit: 2);
    tracks.addAll(genreTracks);
  }
  
  // Remove duplicates and shuffle
  final uniqueTracks = <String, Track>{};
  for (final track in tracks) {
    uniqueTracks[track.id] = track;
  }
  final result = uniqueTracks.values.toList()..shuffle();
  return result.take(10).toList();
});
