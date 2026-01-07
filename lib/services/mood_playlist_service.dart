import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';

/// Mood/Activity Playlist Service
/// Auto-generates playlists by mood (energetic, chill, focus) and time of day
class MoodPlaylistService {
  static final MoodPlaylistService _instance = MoodPlaylistService._internal();
  factory MoodPlaylistService() => _instance;
  MoodPlaylistService._internal();

  final YtMusicService _ytMusicService = YtMusicService();

  /// Get mood-based playlist
  Future<List<Track>> getMoodPlaylist(MoodType mood, {int limit = 20}) async {
    final searchQueries = _getMoodSearchQueries(mood);
    final List<Track> tracks = [];
    
    for (final query in searchQueries) {
      if (tracks.length >= limit) break;
      
      final results = await _ytMusicService.searchSongs(query, limit: 10);
      for (final track in results) {
        if (!tracks.any((t) => t.id == track.id)) {
          tracks.add(track);
          if (tracks.length >= limit) break;
        }
      }
    }
    
    // Shuffle for variety
    tracks.shuffle();
    return tracks.take(limit).toList();
  }

  /// Get time-based playlist suggestion
  Future<List<Track>> getTimeBasedPlaylist({int limit = 20}) async {
    final hour = DateTime.now().hour;
    final timeOfDay = _getTimeOfDay(hour);
    return getMoodPlaylist(timeOfDay, limit: limit);
  }

  /// Get activity-based playlist
  Future<List<Track>> getActivityPlaylist(ActivityType activity, {int limit = 20}) async {
    final searchQueries = _getActivitySearchQueries(activity);
    final List<Track> tracks = [];
    
    for (final query in searchQueries) {
      if (tracks.length >= limit) break;
      
      final results = await _ytMusicService.searchSongs(query, limit: 10);
      for (final track in results) {
        if (!tracks.any((t) => t.id == track.id)) {
          tracks.add(track);
          if (tracks.length >= limit) break;
        }
      }
    }
    
    tracks.shuffle();
    return tracks.take(limit).toList();
  }

  /// Get current time of day mood
  MoodType _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 9) {
      return MoodType.morning;
    } else if (hour >= 9 && hour < 12) {
      return MoodType.focus;
    } else if (hour >= 12 && hour < 17) {
      return MoodType.energetic;
    } else if (hour >= 17 && hour < 21) {
      return MoodType.chill;
    } else {
      return MoodType.sleep;
    }
  }

  /// Get search queries for mood
  List<String> _getMoodSearchQueries(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return [
          'upbeat pop songs',
          'energetic workout music',
          'high energy dance hits',
          'pump up songs',
        ];
      case MoodType.chill:
        return [
          'chill vibes music',
          'relaxing lofi beats',
          'chill acoustic songs',
          'mellow indie music',
        ];
      case MoodType.focus:
        return [
          'focus music instrumental',
          'study music concentration',
          'deep focus ambient',
          'productivity music',
        ];
      case MoodType.happy:
        return [
          'happy feel good songs',
          'uplifting music playlist',
          'positive vibes songs',
          'cheerful pop music',
        ];
      case MoodType.sad:
        return [
          'sad emotional songs',
          'melancholic music',
          'heartbreak songs',
          'emotional ballads',
        ];
      case MoodType.romantic:
        return [
          'romantic love songs',
          'romantic dinner music',
          'love ballads',
          'romantic acoustic',
        ];
      case MoodType.morning:
        return [
          'morning coffee music',
          'wake up playlist',
          'morning motivation songs',
          'peaceful morning music',
        ];
      case MoodType.sleep:
        return [
          'sleep music relaxing',
          'calming sleep sounds',
          'peaceful sleep music',
          'ambient sleep',
        ];
      case MoodType.party:
        return [
          'party hits playlist',
          'dance party music',
          'club bangers',
          'party anthems',
        ];
    }
  }

  /// Get search queries for activity
  List<String> _getActivitySearchQueries(ActivityType activity) {
    switch (activity) {
      case ActivityType.workout:
        return [
          'workout motivation music',
          'gym playlist',
          'running music high bpm',
          'fitness motivation songs',
        ];
      case ActivityType.study:
        return [
          'study music playlist',
          'concentration music',
          'study lofi beats',
          'focus music for studying',
        ];
      case ActivityType.work:
        return [
          'work from home music',
          'office background music',
          'productivity playlist',
          'work focus music',
        ];
      case ActivityType.cooking:
        return [
          'cooking music playlist',
          'kitchen vibes music',
          'dinner party music',
          'jazz cooking music',
        ];
      case ActivityType.driving:
        return [
          'driving music playlist',
          'road trip songs',
          'car music hits',
          'highway driving music',
        ];
      case ActivityType.meditation:
        return [
          'meditation music',
          'mindfulness music',
          'zen meditation sounds',
          'peaceful meditation',
        ];
      case ActivityType.yoga:
        return [
          'yoga music playlist',
          'yoga flow music',
          'relaxing yoga sounds',
          'yoga meditation music',
        ];
      case ActivityType.gaming:
        return [
          'gaming music playlist',
          'epic gaming music',
          'video game soundtracks',
          'gaming background music',
        ];
      case ActivityType.reading:
        return [
          'reading music playlist',
          'background music for reading',
          'peaceful reading music',
          'classical reading music',
        ];
    }
  }

  /// Get mood display info
  static MoodInfo getMoodInfo(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return MoodInfo('Energetic', '⚡', 'High energy vibes');
      case MoodType.chill:
        return MoodInfo('Chill', '😌', 'Relaxed and mellow');
      case MoodType.focus:
        return MoodInfo('Focus', '🎯', 'Deep concentration');
      case MoodType.happy:
        return MoodInfo('Happy', '😊', 'Feel good music');
      case MoodType.sad:
        return MoodInfo('Sad', '😢', 'Emotional moments');
      case MoodType.romantic:
        return MoodInfo('Romantic', '💕', 'Love in the air');
      case MoodType.morning:
        return MoodInfo('Morning', '🌅', 'Start your day');
      case MoodType.sleep:
        return MoodInfo('Sleep', '🌙', 'Peaceful rest');
      case MoodType.party:
        return MoodInfo('Party', '🎉', 'Let\'s celebrate');
    }
  }

  /// Get activity display info
  static ActivityInfo getActivityInfo(ActivityType activity) {
    switch (activity) {
      case ActivityType.workout:
        return ActivityInfo('Workout', '💪', 'Get pumped');
      case ActivityType.study:
        return ActivityInfo('Study', '📚', 'Focus and learn');
      case ActivityType.work:
        return ActivityInfo('Work', '💼', 'Productive vibes');
      case ActivityType.cooking:
        return ActivityInfo('Cooking', '🍳', 'Kitchen jams');
      case ActivityType.driving:
        return ActivityInfo('Driving', '🚗', 'Road trip ready');
      case ActivityType.meditation:
        return ActivityInfo('Meditation', '🧘', 'Inner peace');
      case ActivityType.yoga:
        return ActivityInfo('Yoga', '🧘‍♀️', 'Mind and body');
      case ActivityType.gaming:
        return ActivityInfo('Gaming', '🎮', 'Epic soundtrack');
      case ActivityType.reading:
        return ActivityInfo('Reading', '📖', 'Quiet background');
    }
  }
}

enum MoodType {
  energetic,
  chill,
  focus,
  happy,
  sad,
  romantic,
  morning,
  sleep,
  party,
}

enum ActivityType {
  workout,
  study,
  work,
  cooking,
  driving,
  meditation,
  yoga,
  gaming,
  reading,
}

class MoodInfo {
  final String name;
  final String emoji;
  final String description;
  
  const MoodInfo(this.name, this.emoji, this.description);
}

class ActivityInfo {
  final String name;
  final String emoji;
  final String description;
  
  const ActivityInfo(this.name, this.emoji, this.description);
}
