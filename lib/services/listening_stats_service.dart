import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';

/// Listening statistics service
/// Tracks detailed listening analytics including play counts, listening time, and top content
class ListeningStatsService {
  static ListeningStatsService? _instance;
  static ListeningStatsService get instance => _instance ??= ListeningStatsService._();
  
  ListeningStatsService._();

  static const String _dailyStatsKey = 'daily_listening_stats';
  static const String _weeklyStatsKey = 'weekly_listening_stats';
  static const String _monthlyStatsKey = 'monthly_listening_stats';
  static const String _allTimeStatsKey = 'all_time_listening_stats';
  static const String _artistStatsKey = 'artist_listening_stats';
  static const String _genreStatsKey = 'genre_listening_stats';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  // Stats maps
  Map<String, TrackStats> _allTimeTrackStats = {};
  Map<String, ArtistStats> _artistStats = {};
  Map<String, int> _genreStats = {}; // genre -> total play time ms
  
  // Time-based stats
  Map<String, DailyStats> _dailyStats = {}; // date string -> stats
  
  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return; // Prevent double initialization
    _prefs = await SharedPreferences.getInstance();
    await _loadStats();
    _isInitialized = true;
    print('ListeningStatsService: Initialized');
  }

  /// Record a track play session
  Future<void> recordPlay({
    required Track track,
    required int playTimeMs,
    String? genre,
  }) async {
    final now = DateTime.now();
    final dateKey = _getDateKey(now);
    
    // Update track stats
    final existingTrackStats = _allTimeTrackStats[track.id];
    if (existingTrackStats != null) {
      _allTimeTrackStats[track.id] = existingTrackStats.copyWith(
        playCount: existingTrackStats.playCount + 1,
        totalPlayTimeMs: existingTrackStats.totalPlayTimeMs + playTimeMs,
        lastPlayedAt: now.millisecondsSinceEpoch,
      );
    } else {
      _allTimeTrackStats[track.id] = TrackStats(
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        thumbnailUrl: track.thumbnailUrl,
        playCount: 1,
        totalPlayTimeMs: playTimeMs,
        firstPlayedAt: now.millisecondsSinceEpoch,
        lastPlayedAt: now.millisecondsSinceEpoch,
      );
    }
    
    // Update artist stats
    final artistKey = track.artist.toLowerCase().trim();
    
    // Try to get artist thumbnail from the artists list first, fallback to track thumbnail
    String? artistThumbnail;
    if (track.artists != null && track.artists!.isNotEmpty) {
      // Find the primary artist (first one or one matching the track.artist name)
      final primaryArtist = track.artists!.firstWhere(
        (a) => a.name.toLowerCase() == artistKey,
        orElse: () => track.artists!.first,
      );
      artistThumbnail = primaryArtist.thumbnailUrl;
    }
    // Fallback to track thumbnail if no artist thumbnail available
    artistThumbnail ??= track.thumbnailUrl;
    
    final existingArtistStats = _artistStats[artistKey];
    if (existingArtistStats != null) {
      _artistStats[artistKey] = existingArtistStats.copyWith(
        playCount: existingArtistStats.playCount + 1,
        totalPlayTimeMs: existingArtistStats.totalPlayTimeMs + playTimeMs,
        lastPlayedAt: now.millisecondsSinceEpoch,
        // Always update thumbnail if we have a new one (to fix missing thumbnails)
        thumbnailUrl: artistThumbnail ?? existingArtistStats.thumbnailUrl,
      );
    } else {
      _artistStats[artistKey] = ArtistStats(
        artistName: track.artist,
        thumbnailUrl: artistThumbnail,
        playCount: 1,
        totalPlayTimeMs: playTimeMs,
        firstPlayedAt: now.millisecondsSinceEpoch,
        lastPlayedAt: now.millisecondsSinceEpoch,
      );
    }
    
    // Update genre stats if provided
    if (genre != null && genre.isNotEmpty) {
      _genreStats[genre] = (_genreStats[genre] ?? 0) + playTimeMs;
    }
    
    // Update daily stats
    final existingDailyStats = _dailyStats[dateKey];
    if (existingDailyStats != null) {
      _dailyStats[dateKey] = existingDailyStats.copyWith(
        totalPlayTimeMs: existingDailyStats.totalPlayTimeMs + playTimeMs,
        trackCount: existingDailyStats.trackCount + 1,
      );
    } else {
      _dailyStats[dateKey] = DailyStats(
        date: dateKey,
        totalPlayTimeMs: playTimeMs,
        trackCount: 1,
      );
    }
    
    await _saveStats();
  }

  /// Get top tracks by play count
  List<TrackStats> getTopTracksByPlayCount({int limit = 10}) {
    final sorted = _allTimeTrackStats.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted.take(limit).toList();
  }

  /// Get top tracks by listening time
  List<TrackStats> getTopTracksByListeningTime({int limit = 10}) {
    final sorted = _allTimeTrackStats.values.toList()
      ..sort((a, b) => b.totalPlayTimeMs.compareTo(a.totalPlayTimeMs));
    return sorted.take(limit).toList();
  }

  /// Get top artists by play count
  List<ArtistStats> getTopArtistsByPlayCount({int limit = 10}) {
    final sorted = _artistStats.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted.take(limit).toList();
  }

  /// Get top artists by listening time
  List<ArtistStats> getTopArtistsByListeningTime({int limit = 10}) {
    final sorted = _artistStats.values.toList()
      ..sort((a, b) => b.totalPlayTimeMs.compareTo(a.totalPlayTimeMs));
    return sorted.take(limit).toList();
  }

  /// Get top genres by listening time
  List<MapEntry<String, int>> getTopGenres({int limit = 10}) {
    final sorted = _genreStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Get total listening time (all time)
  Duration getTotalListeningTime() {
    int totalMs = 0;
    for (final stats in _allTimeTrackStats.values) {
      totalMs += stats.totalPlayTimeMs;
    }
    return Duration(milliseconds: totalMs);
  }

  /// Get listening time for a specific period
  Duration getListeningTimeForPeriod(StatsPeriod period) {
    final now = DateTime.now();
    int totalMs = 0;
    
    for (final entry in _dailyStats.entries) {
      final date = _parseDateKey(entry.key);
      if (date != null && _isInPeriod(date, now, period)) {
        totalMs += entry.value.totalPlayTimeMs;
      }
    }
    
    return Duration(milliseconds: totalMs);
  }

  /// Get track count for a specific period
  int getTrackCountForPeriod(StatsPeriod period) {
    final now = DateTime.now();
    int count = 0;
    
    for (final entry in _dailyStats.entries) {
      final date = _parseDateKey(entry.key);
      if (date != null && _isInPeriod(date, now, period)) {
        count += entry.value.trackCount;
      }
    }
    
    return count;
  }

  /// Get daily listening stats for the past N days
  List<DailyStats> getDailyStatsForPastDays(int days) {
    final now = DateTime.now();
    final List<DailyStats> result = [];
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      final stats = _dailyStats[dateKey];
      if (stats != null) {
        result.add(stats);
      } else {
        result.add(DailyStats(date: dateKey, totalPlayTimeMs: 0, trackCount: 0));
      }
    }
    
    return result.reversed.toList();
  }

  /// Get listening streak (consecutive days with listening activity)
  int getListeningStreak() {
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      if (_dailyStats.containsKey(dateKey)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    
    return streak;
  }

  /// Clear all stats
  Future<void> clearStats() async {
    _allTimeTrackStats.clear();
    _artistStats.clear();
    _genreStats.clear();
    _dailyStats.clear();
    await _saveStats();
  }

  // Private methods
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  DateTime? _parseDateKey(String key) {
    try {
      final parts = key.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }
  
  bool _isInPeriod(DateTime date, DateTime now, StatsPeriod period) {
    switch (period) {
      case StatsPeriod.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case StatsPeriod.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return date.isAfter(weekAgo) || date.isAtSameMomentAs(weekAgo);
      case StatsPeriod.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        return date.isAfter(monthAgo) || date.isAtSameMomentAs(monthAgo);
      case StatsPeriod.year:
        final yearAgo = now.subtract(const Duration(days: 365));
        return date.isAfter(yearAgo) || date.isAtSameMomentAs(yearAgo);
      case StatsPeriod.allTime:
        return true;
    }
  }

  Future<void> _loadStats() async {
    // Load track stats
    final trackStatsJson = _prefs?.getString(_allTimeStatsKey);
    if (trackStatsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(trackStatsJson);
      _allTimeTrackStats = decoded.map((key, value) => 
          MapEntry(key, TrackStats.fromJson(value as Map<String, dynamic>)));
    }
    
    // Load artist stats
    final artistStatsJson = _prefs?.getString(_artistStatsKey);
    if (artistStatsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(artistStatsJson);
      _artistStats = decoded.map((key, value) => 
          MapEntry(key, ArtistStats.fromJson(value as Map<String, dynamic>)));
    }
    
    // Load genre stats
    final genreStatsJson = _prefs?.getString(_genreStatsKey);
    if (genreStatsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(genreStatsJson);
      _genreStats = decoded.map((key, value) => MapEntry(key, value as int));
    }
    
    // Load daily stats
    final dailyStatsJson = _prefs?.getString(_dailyStatsKey);
    if (dailyStatsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(dailyStatsJson);
      _dailyStats = decoded.map((key, value) => 
          MapEntry(key, DailyStats.fromJson(value as Map<String, dynamic>)));
    }
  }

  Future<void> _saveStats() async {
    await _prefs?.setString(_allTimeStatsKey, jsonEncode(
      _allTimeTrackStats.map((key, value) => MapEntry(key, value.toJson()))
    ));
    
    await _prefs?.setString(_artistStatsKey, jsonEncode(
      _artistStats.map((key, value) => MapEntry(key, value.toJson()))
    ));
    
    await _prefs?.setString(_genreStatsKey, jsonEncode(_genreStats));
    
    await _prefs?.setString(_dailyStatsKey, jsonEncode(
      _dailyStats.map((key, value) => MapEntry(key, value.toJson()))
    ));
  }
}

enum StatsPeriod { today, week, month, year, allTime }

class TrackStats {
  final String trackId;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final int playCount;
  final int totalPlayTimeMs;
  final int firstPlayedAt;
  final int lastPlayedAt;

  const TrackStats({
    required this.trackId,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.playCount,
    required this.totalPlayTimeMs,
    required this.firstPlayedAt,
    required this.lastPlayedAt,
  });

  TrackStats copyWith({
    String? trackId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    int? playCount,
    int? totalPlayTimeMs,
    int? firstPlayedAt,
    int? lastPlayedAt,
  }) {
    return TrackStats(
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      playCount: playCount ?? this.playCount,
      totalPlayTimeMs: totalPlayTimeMs ?? this.totalPlayTimeMs,
      firstPlayedAt: firstPlayedAt ?? this.firstPlayedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'title': title,
    'artist': artist,
    'thumbnailUrl': thumbnailUrl,
    'playCount': playCount,
    'totalPlayTimeMs': totalPlayTimeMs,
    'firstPlayedAt': firstPlayedAt,
    'lastPlayedAt': lastPlayedAt,
  };

  factory TrackStats.fromJson(Map<String, dynamic> json) => TrackStats(
    trackId: json['trackId'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    playCount: json['playCount'] as int,
    totalPlayTimeMs: json['totalPlayTimeMs'] as int,
    firstPlayedAt: json['firstPlayedAt'] as int,
    lastPlayedAt: json['lastPlayedAt'] as int,
  );
}

class ArtistStats {
  final String artistName;
  final String? thumbnailUrl;
  final int playCount;
  final int totalPlayTimeMs;
  final int firstPlayedAt;
  final int lastPlayedAt;

  const ArtistStats({
    required this.artistName,
    this.thumbnailUrl,
    required this.playCount,
    required this.totalPlayTimeMs,
    required this.firstPlayedAt,
    required this.lastPlayedAt,
  });

  ArtistStats copyWith({
    String? artistName,
    String? thumbnailUrl,
    int? playCount,
    int? totalPlayTimeMs,
    int? firstPlayedAt,
    int? lastPlayedAt,
  }) {
    return ArtistStats(
      artistName: artistName ?? this.artistName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      playCount: playCount ?? this.playCount,
      totalPlayTimeMs: totalPlayTimeMs ?? this.totalPlayTimeMs,
      firstPlayedAt: firstPlayedAt ?? this.firstPlayedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'artistName': artistName,
    'thumbnailUrl': thumbnailUrl,
    'playCount': playCount,
    'totalPlayTimeMs': totalPlayTimeMs,
    'firstPlayedAt': firstPlayedAt,
    'lastPlayedAt': lastPlayedAt,
  };

  factory ArtistStats.fromJson(Map<String, dynamic> json) => ArtistStats(
    artistName: json['artistName'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    playCount: json['playCount'] as int,
    totalPlayTimeMs: json['totalPlayTimeMs'] as int,
    firstPlayedAt: json['firstPlayedAt'] as int,
    lastPlayedAt: json['lastPlayedAt'] as int,
  );
}

class DailyStats {
  final String date;
  final int totalPlayTimeMs;
  final int trackCount;

  const DailyStats({
    required this.date,
    required this.totalPlayTimeMs,
    required this.trackCount,
  });

  DailyStats copyWith({
    String? date,
    int? totalPlayTimeMs,
    int? trackCount,
  }) {
    return DailyStats(
      date: date ?? this.date,
      totalPlayTimeMs: totalPlayTimeMs ?? this.totalPlayTimeMs,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'totalPlayTimeMs': totalPlayTimeMs,
    'trackCount': trackCount,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    date: json['date'] as String,
    totalPlayTimeMs: json['totalPlayTimeMs'] as int,
    trackCount: json['trackCount'] as int,
  );
}
