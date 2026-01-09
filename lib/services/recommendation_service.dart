import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/listening_stats_service.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/services/user_taste_service.dart';

/// Smart Recommendations Service
/// Provides ML-like recommendations based on listening history, time of day, and user preferences
class RecommendationService {
  static RecommendationService? _instance;
  static RecommendationService get instance => _instance ??= RecommendationService._();
  
  RecommendationService._();

  static const String _dailyMixCacheKey = 'daily_mix_cache';
  static const String _dailyMixDateKey = 'daily_mix_date';

  SharedPreferences? _prefs;
  final Random _random = Random();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return; // Prevent double initialization
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('RecommendationService: Initialized');
  }

  /// Get the current time-based mood
  DayMood getCurrentMood() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 9) {
      return DayMood.morning;
    } else if (hour >= 9 && hour < 12) {
      return DayMood.focus;
    } else if (hour >= 12 && hour < 14) {
      return DayMood.afternoon;
    } else if (hour >= 14 && hour < 17) {
      return DayMood.focus;
    } else if (hour >= 17 && hour < 20) {
      return DayMood.evening;
    } else if (hour >= 20 && hour < 23) {
      return DayMood.chill;
    } else {
      return DayMood.lateNight;
    }
  }

  /// Get search queries for daily mixes based on mood
  List<DailyMix> getDailyMixes() {
    return [
      DailyMix(
        id: 'morning_mix',
        name: 'Morning Mix',
        description: 'Start your day with uplifting tunes',
        mood: DayMood.morning,
        icon: '☀️',
        gradient: const [0xFFFF9A8B, 0xFFFF6A88],
        searchQueries: [
          'uplifting morning songs',
          'feel good music',
          'happy morning playlist',
          'positive vibes songs',
        ],
      ),
      DailyMix(
        id: 'focus_mix',
        name: 'Focus Mix',
        description: 'Concentrate with minimal distractions',
        mood: DayMood.focus,
        icon: '🎯',
        gradient: const [0xFF667EEA, 0xFF764BA2],
        searchQueries: [
          'focus music instrumental',
          'study music',
          'concentration music',
          'lo-fi beats',
        ],
      ),
      DailyMix(
        id: 'chill_mix',
        name: 'Chill Mix',
        description: 'Relax and unwind',
        mood: DayMood.chill,
        icon: '🌙',
        gradient: const [0xFF11998E, 0xFF38EF7D],
        searchQueries: [
          'chill vibes music',
          'relaxing songs',
          'calm music playlist',
          'ambient chill',
        ],
      ),
      DailyMix(
        id: 'workout_mix',
        name: 'Workout Mix',
        description: 'High energy for your exercise',
        mood: DayMood.workout,
        icon: '💪',
        gradient: const [0xFFFC466B, 0xFF3F5EFB],
        searchQueries: [
          'workout music',
          'gym motivation songs',
          'high energy workout',
          'running music',
        ],
      ),
      DailyMix(
        id: 'party_mix',
        name: 'Party Mix',
        description: 'Get the party started',
        mood: DayMood.party,
        icon: '🎉',
        gradient: const [0xFFF857A6, 0xFFFF5858],
        searchQueries: [
          'party songs 2024',
          'dance music hits',
          'club music',
          'party playlist',
        ],
      ),
      DailyMix(
        id: 'sleep_mix',
        name: 'Sleep Mix',
        description: 'Drift off peacefully',
        mood: DayMood.lateNight,
        icon: '😴',
        gradient: const [0xFF2C3E50, 0xFF4CA1AF],
        searchQueries: [
          'sleep music',
          'calming sleep sounds',
          'peaceful night music',
          'soft instrumental sleep',
        ],
      ),
    ];
  }

  /// Get personalized "For You" recommendations
  /// Combines listening history, taste profile, and time-based suggestions
  Future<List<String>> getForYouSearchQueries() async {
    final queries = <String>[];
    final tasteService = UserTasteService.instance;
    await tasteService.init();
    
    // Get top artists from listening history
    final topArtists = tasteService.getTopDiscoveredArtists(limit: 3);
    for (final artist in topArtists) {
      queries.add('$artist best songs');
      queries.add('$artist similar artists');
    }
    
    // Get top genres
    final topGenres = tasteService.getTopGenres(limit: 2);
    for (final genre in topGenres) {
      queries.add('$genre music 2024');
    }
    
    // Add time-based suggestions
    final mood = getCurrentMood();
    final moodQueries = _getMoodQueries(mood);
    queries.addAll(moodQueries.take(2));
    
    // Shuffle for variety
    queries.shuffle(_random);
    
    return queries.take(10).toList();
  }

  List<String> _getMoodQueries(DayMood mood) {
    switch (mood) {
      case DayMood.morning:
        return ['uplifting morning songs', 'feel good music', 'happy songs'];
      case DayMood.focus:
        return ['focus music', 'instrumental study', 'concentration playlist'];
      case DayMood.afternoon:
        return ['afternoon vibes', 'chill pop songs', 'easy listening'];
      case DayMood.evening:
        return ['evening relaxation', 'sunset music', 'mellow songs'];
      case DayMood.chill:
        return ['chill music', 'relaxing songs', 'calm vibes'];
      case DayMood.lateNight:
        return ['late night music', 'midnight songs', 'quiet night'];
      case DayMood.workout:
        return ['workout music', 'gym songs', 'high energy'];
      case DayMood.party:
        return ['party songs', 'dance hits', 'club music'];
    }
  }

  /// Calculate recommendation score for a track based on user's taste
  double calculateRecommendationScore(Track track) {
    double score = 0.5; // Base score
    
    final statsService = ListeningStatsService.instance;
    final historyService = PlayHistoryService.instance;
    
    // Check if artist is in top artists
    final topArtists = statsService.getTopArtistsByPlayCount(limit: 10);
    final artistMatch = topArtists.any(
      (a) => a.artistName.toLowerCase() == track.artist.toLowerCase()
    );
    if (artistMatch) {
      score += 0.3;
    }
    
    // Check if track was played before
    final songStats = historyService.getSongStats(track.id);
    if (songStats != null) {
      // Boost for familiar tracks, but not too much (we want discovery too)
      score += min(0.2, songStats.playCount * 0.05);
    }
    
    // Time-based boost
    final mood = getCurrentMood();
    if (_trackMatchesMood(track, mood)) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  bool _trackMatchesMood(Track track, DayMood mood) {
    final title = track.title.toLowerCase();
    final artist = track.artist.toLowerCase();
    
    switch (mood) {
      case DayMood.morning:
        return title.contains('morning') || title.contains('sunrise') || title.contains('happy');
      case DayMood.chill:
      case DayMood.lateNight:
        return title.contains('chill') || title.contains('relax') || title.contains('calm');
      case DayMood.workout:
        return title.contains('workout') || title.contains('energy') || title.contains('pump');
      case DayMood.party:
        return title.contains('party') || title.contains('dance') || title.contains('club');
      default:
        return false;
    }
  }

  /// Get listening patterns for insights
  ListeningPatterns getListeningPatterns() {
    final statsService = ListeningStatsService.instance;
    final dailyStats = statsService.getDailyStatsForPastDays(30);
    
    // Calculate peak listening hours
    final hourlyListening = <int, int>{};
    // This would need more detailed tracking, for now use daily stats
    
    // Calculate average daily listening
    int totalMs = 0;
    int activeDays = 0;
    for (final stat in dailyStats) {
      if (stat.totalPlayTimeMs > 0) {
        totalMs += stat.totalPlayTimeMs;
        activeDays++;
      }
    }
    
    final avgDailyMinutes = activeDays > 0 
        ? (totalMs / activeDays / 60000).round() 
        : 0;
    
    // Get most active day
    String mostActiveDay = 'N/A';
    int maxPlayTime = 0;
    for (final stat in dailyStats) {
      if (stat.totalPlayTimeMs > maxPlayTime) {
        maxPlayTime = stat.totalPlayTimeMs;
        mostActiveDay = stat.date;
      }
    }
    
    return ListeningPatterns(
      averageDailyMinutes: avgDailyMinutes,
      mostActiveDay: mostActiveDay,
      totalTracksPlayed: dailyStats.fold(0, (sum, s) => sum + s.trackCount),
      listeningStreak: statsService.getListeningStreak(),
    );
  }
}

enum DayMood {
  morning,
  focus,
  afternoon,
  evening,
  chill,
  lateNight,
  workout,
  party,
}

class DailyMix {
  final String id;
  final String name;
  final String description;
  final DayMood mood;
  final String icon;
  final List<int> gradient;
  final List<String> searchQueries;

  const DailyMix({
    required this.id,
    required this.name,
    required this.description,
    required this.mood,
    required this.icon,
    required this.gradient,
    required this.searchQueries,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'mood': mood.name,
    'icon': icon,
    'gradient': gradient,
    'searchQueries': searchQueries,
  };

  factory DailyMix.fromJson(Map<String, dynamic> json) => DailyMix(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    mood: DayMood.values.firstWhere((m) => m.name == json['mood']),
    icon: json['icon'] as String,
    gradient: (json['gradient'] as List).cast<int>(),
    searchQueries: (json['searchQueries'] as List).cast<String>(),
  );
}

class ListeningPatterns {
  final int averageDailyMinutes;
  final String mostActiveDay;
  final int totalTracksPlayed;
  final int listeningStreak;

  const ListeningPatterns({
    required this.averageDailyMinutes,
    required this.mostActiveDay,
    required this.totalTracksPlayed,
    required this.listeningStreak,
  });
}
