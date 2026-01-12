import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Music source options
enum MusicSource {
  youtube('YouTube', 'Uses youtube_explode_dart for audio streams'),
  ytMusic('YT Music', 'Uses YouTube Music API for better music search');

  final String label;
  final String description;

  const MusicSource(this.label, this.description);

  static MusicSource fromString(String value) {
    return MusicSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MusicSource.ytMusic,
    );
  }
}

/// Audio quality levels
enum AudioQuality {
  low(64000, 'Low', '64 kbps - Uses less data'),
  medium(128000, 'Medium', '128 kbps - Balanced'),
  high(192000, 'High', '192 kbps - Better quality'),
  ultra(320000, 'Ultra', '320 kbps - Best quality');

  final int bitrate;
  final String label;
  final String description;

  const AudioQuality(this.bitrate, this.label, this.description);

  static AudioQuality fromBitrate(int bitrate) {
    if (bitrate <= 64000) return AudioQuality.low;
    if (bitrate <= 128000) return AudioQuality.medium;
    if (bitrate <= 192000) return AudioQuality.high;
    return AudioQuality.ultra;
  }

  static AudioQuality fromString(String value) {
    return AudioQuality.values.firstWhere(
      (q) => q.name == value,
      orElse: () => AudioQuality.high,
    );
  }
}

/// App settings
class AppSettings {
  final AudioQuality audioQuality;
  final MusicSource musicSource;

  const AppSettings({
    this.audioQuality = AudioQuality.high,
    this.musicSource = MusicSource.ytMusic,
  });

  AppSettings copyWith({
    AudioQuality? audioQuality,
    MusicSource? musicSource,
  }) {
    return AppSettings(
      audioQuality: audioQuality ?? this.audioQuality,
      musicSource: musicSource ?? this.musicSource,
    );
  }
}

/// Settings service for managing app preferences
class SettingsService extends StateNotifier<AppSettings> {
  static const String _audioQualityKey = 'audio_quality';
  static const String _musicSourceKey = 'music_source';

  SettingsService() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qualityStr = prefs.getString(_audioQualityKey);
      final sourceStr = prefs.getString(_musicSourceKey);
      
      state = state.copyWith(
        audioQuality: qualityStr != null 
            ? AudioQuality.fromString(qualityStr) 
            : null,
        musicSource: sourceStr != null 
            ? MusicSource.fromString(sourceStr) 
            : null,
      );
      print('SettingsService: Loaded settings - quality: ${state.audioQuality.label}, source: ${state.musicSource.label}');
    } catch (e) {
      print('SettingsService: Failed to load settings: $e');
      // Keep default state on error
    }
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioQualityKey, quality.name);
    state = state.copyWith(audioQuality: quality);
    print('SettingsService: Set audio quality to: ${quality.label}');
  }

  Future<void> setMusicSource(MusicSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_musicSourceKey, source.name);
    state = state.copyWith(musicSource: source);
    print('SettingsService: Set music source to: ${source.label}');
  }

  AudioQuality get audioQuality => state.audioQuality;
  MusicSource get musicSource => state.musicSource;
}

/// Provider for settings service
final settingsServiceProvider = StateNotifierProvider<SettingsService, AppSettings>((ref) {
  return SettingsService();
});

/// Provider for just the audio quality
final audioQualityProvider = Provider<AudioQuality>((ref) {
  return ref.watch(settingsServiceProvider).audioQuality;
});

/// Provider for just the music source
final musicSourceProvider = Provider<MusicSource>((ref) {
  return ref.watch(settingsServiceProvider).musicSource;
});
