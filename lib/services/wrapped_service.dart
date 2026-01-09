import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/services/listening_stats_service.dart';
import 'package:sangeet/services/play_history_service.dart';

/// Wrapped Service
/// Generates year-end and monthly listening summaries like Spotify Wrapped
class WrappedService {
  static WrappedService? _instance;
  static WrappedService get instance => _instance ??= WrappedService._();
  
  WrappedService._();

  static const String _wrappedCacheKey = 'wrapped_data';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return; // Prevent double initialization
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('WrappedService: Initialized');
  }

  /// Generate wrapped data for a specific year
  Future<WrappedData> generateYearWrapped(int year) async {
    final statsService = ListeningStatsService.instance;
    final historyService = PlayHistoryService.instance;
    
    // Get all-time stats (in real implementation, filter by year)
    final topTracks = statsService.getTopTracksByPlayCount(limit: 10);
    final topArtists = statsService.getTopArtistsByPlayCount(limit: 10);
    final topGenres = statsService.getTopGenres(limit: 5);
    final totalTime = statsService.getTotalListeningTime();
    
    // Calculate monthly breakdown
    final monthlyMinutes = <int, int>{};
    final dailyStats = statsService.getDailyStatsForPastDays(365);
    
    for (final stat in dailyStats) {
      final date = _parseDate(stat.date);
      if (date != null && date.year == year) {
        monthlyMinutes[date.month] = 
            (monthlyMinutes[date.month] ?? 0) + (stat.totalPlayTimeMs ~/ 60000);
      }
    }
    
    // Find peak month
    int peakMonth = 1;
    int peakMinutes = 0;
    monthlyMinutes.forEach((month, minutes) {
      if (minutes > peakMinutes) {
        peakMonth = month;
        peakMinutes = minutes;
      }
    });
    
    // Calculate listening personality
    final personality = _calculateListeningPersonality(topGenres, topArtists);
    
    // Fun facts
    final funFacts = _generateFunFacts(
      totalMinutes: totalTime.inMinutes,
      topArtist: topArtists.isNotEmpty ? topArtists.first.artistName : null,
      topTrack: topTracks.isNotEmpty ? topTracks.first.title : null,
      trackCount: topTracks.length,
    );

    return WrappedData(
      year: year,
      totalMinutesListened: totalTime.inMinutes,
      totalTracksPlayed: dailyStats.fold(0, (sum, s) => sum + s.trackCount),
      topTracks: topTracks.map((t) => WrappedTrack(
        title: t.title,
        artist: t.artist,
        playCount: t.playCount,
        minutesListened: t.totalPlayTimeMs ~/ 60000,
        thumbnailUrl: t.thumbnailUrl,
      )).toList(),
      topArtists: topArtists.map((a) => WrappedArtist(
        name: a.artistName,
        playCount: a.playCount,
        minutesListened: a.totalPlayTimeMs ~/ 60000,
      )).toList(),
      topGenres: topGenres.map((g) => WrappedGenre(
        name: g.key,
        minutesListened: g.value ~/ 60000,
      )).toList(),
      monthlyMinutes: monthlyMinutes,
      peakMonth: peakMonth,
      peakMonthMinutes: peakMinutes,
      listeningPersonality: personality,
      funFacts: funFacts,
    );
  }

  /// Generate monthly summary
  Future<MonthlySummary> generateMonthlySummary(int year, int month) async {
    final statsService = ListeningStatsService.instance;
    
    final topTracks = statsService.getTopTracksByPlayCount(limit: 5);
    final topArtists = statsService.getTopArtistsByPlayCount(limit: 5);
    final monthTime = statsService.getListeningTimeForPeriod(StatsPeriod.month);
    final trackCount = statsService.getTrackCountForPeriod(StatsPeriod.month);
    
    // Get daily breakdown for the month
    final dailyStats = statsService.getDailyStatsForPastDays(30);
    final dailyMinutes = <int, int>{};
    
    for (final stat in dailyStats) {
      final date = _parseDate(stat.date);
      if (date != null) {
        dailyMinutes[date.day] = stat.totalPlayTimeMs ~/ 60000;
      }
    }
    
    // Find most active day
    int mostActiveDay = 1;
    int maxMinutes = 0;
    dailyMinutes.forEach((day, minutes) {
      if (minutes > maxMinutes) {
        mostActiveDay = day;
        maxMinutes = minutes;
      }
    });

    return MonthlySummary(
      year: year,
      month: month,
      totalMinutes: monthTime.inMinutes,
      totalTracks: trackCount,
      topTracks: topTracks.map((t) => WrappedTrack(
        title: t.title,
        artist: t.artist,
        playCount: t.playCount,
        minutesListened: t.totalPlayTimeMs ~/ 60000,
        thumbnailUrl: t.thumbnailUrl,
      )).toList(),
      topArtists: topArtists.map((a) => WrappedArtist(
        name: a.artistName,
        playCount: a.playCount,
        minutesListened: a.totalPlayTimeMs ~/ 60000,
      )).toList(),
      dailyMinutes: dailyMinutes,
      mostActiveDay: mostActiveDay,
      mostActiveDayMinutes: maxMinutes,
    );
  }

  /// Get listening streak info
  ListeningStreakInfo getStreakInfo() {
    final statsService = ListeningStatsService.instance;
    final streak = statsService.getListeningStreak();
    
    String message;
    String emoji;
    
    if (streak >= 30) {
      message = 'Incredible! A whole month of music!';
      emoji = '🔥';
    } else if (streak >= 14) {
      message = 'Two weeks strong! Keep it up!';
      emoji = '⚡';
    } else if (streak >= 7) {
      message = 'A week of great music!';
      emoji = '🎵';
    } else if (streak >= 3) {
      message = 'Nice streak going!';
      emoji = '🎶';
    } else if (streak >= 1) {
      message = 'Keep listening!';
      emoji = '🎧';
    } else {
      message = 'Start your streak today!';
      emoji = '▶️';
    }
    
    return ListeningStreakInfo(
      currentStreak: streak,
      message: message,
      emoji: emoji,
    );
  }

  String _calculateListeningPersonality(
    List<MapEntry<String, int>> topGenres,
    List<ArtistStats> topArtists,
  ) {
    if (topGenres.isEmpty) return 'Explorer';
    
    final topGenre = topGenres.first.key.toLowerCase();
    
    if (topGenre.contains('pop') || topGenre.contains('chart')) {
      return 'The Trendsetter';
    } else if (topGenre.contains('rock') || topGenre.contains('metal')) {
      return 'The Rocker';
    } else if (topGenre.contains('hip') || topGenre.contains('rap')) {
      return 'The Beat Master';
    } else if (topGenre.contains('electronic') || topGenre.contains('edm')) {
      return 'The Night Owl';
    } else if (topGenre.contains('classical') || topGenre.contains('jazz')) {
      return 'The Connoisseur';
    } else if (topGenre.contains('indie') || topGenre.contains('alternative')) {
      return 'The Indie Spirit';
    } else if (topGenre.contains('bollywood') || topGenre.contains('hindi')) {
      return 'The Desi Soul';
    } else if (topGenre.contains('lofi') || topGenre.contains('chill')) {
      return 'The Zen Master';
    } else {
      return 'The Explorer';
    }
  }

  List<String> _generateFunFacts({
    required int totalMinutes,
    String? topArtist,
    String? topTrack,
    required int trackCount,
  }) {
    final facts = <String>[];
    
    // Time comparisons
    final hours = totalMinutes ~/ 60;
    final days = hours ~/ 24;
    
    if (days > 0) {
      facts.add('You listened for $days days worth of music! 🎵');
    }
    
    if (hours > 100) {
      final movies = hours ~/ 2;
      facts.add('That\'s like watching $movies movies! 🎬');
    }
    
    if (totalMinutes > 1000) {
      final marathons = totalMinutes ~/ 240; // ~4 hours per marathon
      facts.add('You could have run $marathons marathons in that time! 🏃');
    }
    
    if (topArtist != null) {
      facts.add('$topArtist was basically your best friend this year! 🤝');
    }
    
    if (trackCount > 100) {
      facts.add('You discovered $trackCount different tracks! 🔍');
    }
    
    // Add some fun random facts
    facts.add('Music makes everything better! 💫');
    
    return facts.take(5).toList();
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }
}

class WrappedData {
  final int year;
  final int totalMinutesListened;
  final int totalTracksPlayed;
  final List<WrappedTrack> topTracks;
  final List<WrappedArtist> topArtists;
  final List<WrappedGenre> topGenres;
  final Map<int, int> monthlyMinutes;
  final int peakMonth;
  final int peakMonthMinutes;
  final String listeningPersonality;
  final List<String> funFacts;

  const WrappedData({
    required this.year,
    required this.totalMinutesListened,
    required this.totalTracksPlayed,
    required this.topTracks,
    required this.topArtists,
    required this.topGenres,
    required this.monthlyMinutes,
    required this.peakMonth,
    required this.peakMonthMinutes,
    required this.listeningPersonality,
    required this.funFacts,
  });

  int get totalHours => totalMinutesListened ~/ 60;
  
  String get peakMonthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[peakMonth];
  }
}

class WrappedTrack {
  final String title;
  final String artist;
  final int playCount;
  final int minutesListened;
  final String? thumbnailUrl;

  const WrappedTrack({
    required this.title,
    required this.artist,
    required this.playCount,
    required this.minutesListened,
    this.thumbnailUrl,
  });
}

class WrappedArtist {
  final String name;
  final int playCount;
  final int minutesListened;
  final String? thumbnailUrl;

  const WrappedArtist({
    required this.name,
    required this.playCount,
    required this.minutesListened,
    this.thumbnailUrl,
  });
}

class WrappedGenre {
  final String name;
  final int minutesListened;

  const WrappedGenre({
    required this.name,
    required this.minutesListened,
  });
}

class MonthlySummary {
  final int year;
  final int month;
  final int totalMinutes;
  final int totalTracks;
  final List<WrappedTrack> topTracks;
  final List<WrappedArtist> topArtists;
  final Map<int, int> dailyMinutes;
  final int mostActiveDay;
  final int mostActiveDayMinutes;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalMinutes,
    required this.totalTracks,
    required this.topTracks,
    required this.topArtists,
    required this.dailyMinutes,
    required this.mostActiveDay,
    required this.mostActiveDayMinutes,
  });

  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

class ListeningStreakInfo {
  final int currentStreak;
  final String message;
  final String emoji;

  const ListeningStreakInfo({
    required this.currentStreak,
    required this.message,
    required this.emoji,
  });
}
