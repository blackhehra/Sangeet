import 'dart:async';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/audio_player_service.dart';

/// Radio/Endless Mix Service
/// Creates endless radio based on track/artist using YouTube's recommendation algorithm
class RadioService {
  static final RadioService _instance = RadioService._internal();
  factory RadioService() => _instance;
  RadioService._internal();

  final YtMusicService _ytMusicService = YtMusicService();
  
  bool _isRadioActive = false;
  String? _seedTrackId;
  String? _seedArtist;
  RadioMode _mode = RadioMode.track;
  
  // Track IDs we've already played to avoid repetition
  final Set<String> _playedTrackIds = {};
  
  // Pending tracks to add to queue
  final List<Track> _pendingTracks = [];
  
  bool get isRadioActive => _isRadioActive;
  String? get seedTrackId => _seedTrackId;
  String? get seedArtist => _seedArtist;
  RadioMode get mode => _mode;

  /// Start radio based on a track
  Future<void> startTrackRadio(Track seedTrack) async {
    _isRadioActive = true;
    _seedTrackId = seedTrack.id;
    _seedArtist = seedTrack.artist;
    _mode = RadioMode.track;
    _playedTrackIds.clear();
    _pendingTracks.clear();
    _playedTrackIds.add(seedTrack.id);
    
    print('RadioService: Starting track radio for "${seedTrack.title}"');
    
    // Fetch initial recommendations
    await _fetchMoreTracks();
  }

  /// Start radio based on an artist
  Future<void> startArtistRadio(String artistName) async {
    _isRadioActive = true;
    _seedTrackId = null;
    _seedArtist = artistName;
    _mode = RadioMode.artist;
    _playedTrackIds.clear();
    _pendingTracks.clear();
    
    print('RadioService: Starting artist radio for "$artistName"');
    
    // Search for artist's top tracks first
    final tracks = await _ytMusicService.searchSongs('$artistName top songs', limit: 5);
    if (tracks.isNotEmpty) {
      _seedTrackId = tracks.first.id;
      _playedTrackIds.add(tracks.first.id);
      await _fetchMoreTracks();
    }
  }

  /// Start radio based on a genre/mood
  Future<void> startGenreRadio(String genre) async {
    _isRadioActive = true;
    _seedTrackId = null;
    _seedArtist = null;
    _mode = RadioMode.genre;
    _playedTrackIds.clear();
    _pendingTracks.clear();
    
    print('RadioService: Starting genre radio for "$genre"');
    
    // Search for genre tracks
    final tracks = await _ytMusicService.searchSongs('$genre music', limit: 5);
    if (tracks.isNotEmpty) {
      _seedTrackId = tracks.first.id;
      _playedTrackIds.add(tracks.first.id);
      await _fetchMoreTracks();
    }
  }

  /// Stop radio mode
  void stopRadio() {
    _isRadioActive = false;
    _seedTrackId = null;
    _seedArtist = null;
    _playedTrackIds.clear();
    _pendingTracks.clear();
    print('RadioService: Radio stopped');
  }

  /// Get next tracks for the queue
  /// Called when queue is running low
  Future<List<Track>> getNextTracks({int count = 5}) async {
    if (!_isRadioActive) return [];
    
    // Return from pending if available
    if (_pendingTracks.length >= count) {
      final tracks = _pendingTracks.take(count).toList();
      _pendingTracks.removeRange(0, count);
      return tracks;
    }
    
    // Fetch more tracks
    await _fetchMoreTracks();
    
    final available = _pendingTracks.length.clamp(0, count);
    final tracks = _pendingTracks.take(available).toList();
    _pendingTracks.removeRange(0, available);
    return tracks;
  }

  /// Check if we need to fetch more tracks and add to queue
  Future<void> checkAndRefillQueue(AudioPlayerService audioService) async {
    if (!_isRadioActive) return;
    
    final queue = audioService.queue;
    final currentIndex = audioService.currentIndex;
    final remainingTracks = queue.length - currentIndex - 1;
    
    // If less than 3 tracks remaining, fetch more
    if (remainingTracks < 3) {
      print('RadioService: Queue running low ($remainingTracks remaining), fetching more...');
      final newTracks = await getNextTracks(count: 5);
      
      for (final track in newTracks) {
        audioService.addToQueue(track);
      }
      
      print('RadioService: Added ${newTracks.length} tracks to queue');
    }
  }

  /// Fetch more tracks from YouTube recommendations
  Future<void> _fetchMoreTracks() async {
    if (_seedTrackId == null) return;
    
    try {
      // Get watch playlist (related tracks) from YouTube
      final relatedIds = await _ytMusicService.getWatchPlaylist(
        videoId: _seedTrackId,
        limit: 20,
        radio: true,
      );
      
      print('RadioService: Got ${relatedIds.length} related track IDs');
      
      // Filter out already played tracks
      final newIds = relatedIds.where((id) => !_playedTrackIds.contains(id)).toList();
      
      // Fetch track details for new IDs
      for (final id in newIds.take(10)) {
        try {
          final songData = await _ytMusicService.getSongData(id);
          if (songData.isNotEmpty) {
            final track = Track(
              id: songData['id'] ?? id,
              title: songData['title'] ?? 'Unknown',
              artist: songData['artist'] ?? 'Unknown Artist',
              thumbnailUrl: songData['image'],
              duration: Duration(seconds: int.tryParse(songData['duration']?.toString() ?? '0') ?? 0),
            );
            
            _pendingTracks.add(track);
            _playedTrackIds.add(track.id);
            
            // Update seed for next fetch to get varied recommendations
            if (_pendingTracks.length == 3) {
              _seedTrackId = track.id;
            }
          }
        } catch (e) {
          print('RadioService: Error fetching track $id: $e');
        }
      }
      
      print('RadioService: Fetched ${_pendingTracks.length} pending tracks');
    } catch (e) {
      print('RadioService: Error fetching more tracks: $e');
    }
  }
}

enum RadioMode { track, artist, genre }
