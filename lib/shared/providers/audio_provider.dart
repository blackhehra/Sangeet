import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/settings_service.dart';

// Audio Player Service Provider
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  
  // Sync audio quality setting
  ref.listen<AppSettings>(settingsServiceProvider, (previous, next) {
    service.setAudioQuality(next.audioQuality);
  });
  
  // Set initial quality
  final settings = ref.read(settingsServiceProvider);
  service.setAudioQuality(settings.audioQuality);
  
  ref.onDispose(() => service.dispose());
  return service;
});

// Current Track Provider
final currentTrackProvider = StreamProvider<Track?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentTrackStream;
});

// Playing State Provider
final isPlayingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playingStream;
});

// Position Provider
final positionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.positionStream;
});

// Duration Provider
final durationProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.durationStream;
});

// Buffering Provider
final isBufferingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.bufferingStream;
});

// Queue Provider
final queueProvider = StreamProvider<List<Track>>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.queueStream;
});

// Shuffle State Provider
final isShuffledProvider = Provider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.isShuffled;
});

// Repeat Mode Provider
final repeatModeProvider = Provider<RepeatMode>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.repeatMode;
});

// Has Restored Track Provider - checks if there's a restored track ready to play
final hasRestoredTrackProvider = Provider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.hasRestoredTrack;
});
