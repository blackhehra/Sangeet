import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/models/lyrics.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/lyrics_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';

/// Provider for the lyrics service
final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsService();
});

/// Provider for fetching lyrics for a specific track
final trackLyricsProvider = FutureProvider.family<SubtitleSimple, Track>((ref, track) async {
  final service = ref.watch(lyricsServiceProvider);
  return service.getLyrics(track);
});

/// Provider for the current track's lyrics
final currentLyricsProvider = FutureProvider<SubtitleSimple?>((ref) async {
  final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
  if (currentTrack == null) return null;
  
  final service = ref.watch(lyricsServiceProvider);
  return service.getLyrics(currentTrack);
});

/// Provider for lyrics delay adjustment (in seconds)
final lyricsDelayProvider = StateProvider<int>((ref) => 0);

/// Provider that creates a map of seconds -> lyric text for efficient lookup
final lyricsMapProvider = FutureProvider<({bool isStatic, Map<int, String> lyricsMap})?>((ref) async {
  final lyrics = await ref.watch(currentLyricsProvider.future);
  if (lyrics == null || lyrics.lyrics.isEmpty) return null;
  
  // Check if lyrics are static (all have zero timestamp)
  final isStatic = lyrics.lyrics.every((l) => l.time == Duration.zero);
  
  // Create map of seconds -> text
  final Map<int, String> lyricsMap = {};
  for (final lyric in lyrics.lyrics) {
    lyricsMap[lyric.time.inSeconds] = lyric.text;
  }
  
  return (isStatic: isStatic, lyricsMap: lyricsMap);
});

/// Provider for the current active lyric index based on playback position
final activeLyricIndexProvider = Provider<int>((ref) {
  final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
  final delay = ref.watch(lyricsDelayProvider);
  final lyrics = ref.watch(currentLyricsProvider).valueOrNull;
  
  if (lyrics == null || lyrics.lyrics.isEmpty) return -1;
  
  final adjustedPosition = position + Duration(seconds: delay);
  
  // Find the current lyric index
  int activeIndex = -1;
  for (int i = 0; i < lyrics.lyrics.length; i++) {
    if (lyrics.lyrics[i].time <= adjustedPosition) {
      activeIndex = i;
    } else {
      break;
    }
  }
  
  return activeIndex;
});
