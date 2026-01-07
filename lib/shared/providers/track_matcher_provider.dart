import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/services/track_matcher_service.dart';
import 'package:sangeet/services/settings_service.dart';

/// Provider for TrackMatcherService that syncs with music source setting
final trackMatcherServiceProvider = Provider<TrackMatcherService>((ref) {
  final trackMatcher = TrackMatcherService();
  
  // Watch music source setting and update track matcher
  final musicSource = ref.watch(musicSourceProvider);
  trackMatcher.setMusicSource(musicSource);
  
  return trackMatcher;
});
