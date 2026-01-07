import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';

/// Enum to track the source of playback
/// Used to determine if auto-queue should be enabled
enum PlaySource {
  /// Single song played from home page (quick picks, trending, etc.)
  homeSingleSong,
  
  /// Single song played from search results
  searchSingleSong,
  
  /// Single song played from lyrics search
  lyricsSearch,
  
  /// Single song played from music recognition (Shazam-like)
  musicRecognition,
  
  /// Playing from a playlist (user playlist or system playlist)
  playlist,
  
  /// Playing from an album
  album,
  
  /// Playing from artist page
  artist,
  
  /// Playing from search results list (multiple songs)
  searchResults,
  
  /// Unknown or default source
  unknown,
}

/// Service to manage auto-queue functionality
/// Automatically fetches and queues similar songs when:
/// - A single song is played from home page
/// - A single song is played from search (not from search results list)
/// 
/// Auto-queue is DISABLED when:
/// - Playing from a playlist
/// - Playing from an album
/// - Playing from search results (multiple songs)
class AutoQueueService {
  static final AutoQueueService _instance = AutoQueueService._internal();
  factory AutoQueueService() => _instance;
  AutoQueueService._internal();

  final InnertubeService _innertube = InnertubeService();
  
  /// Current play source
  PlaySource _currentSource = PlaySource.unknown;
  
  /// Whether auto-queue is enabled for current playback
  bool _isAutoQueueEnabled = false;
  
  /// The video ID that auto-queue is based on (the seed song)
  String? _seedVideoId;
  
  /// Tracks that have already been added via auto-queue (to avoid duplicates)
  final Set<String> _autoQueuedTrackIds = {};
  
  /// Whether we're currently fetching more songs
  bool _isFetching = false;
  
  /// Get current play source
  PlaySource get currentSource => _currentSource;
  
  /// Check if auto-queue is enabled
  bool get isAutoQueueEnabled => _isAutoQueueEnabled;
  
  /// Check if currently fetching
  bool get isFetching => _isFetching;

  /// Start auto-queue for a single song
  /// Call this when user plays a single song from home or search
  void startAutoQueue(String videoId, PlaySource source) {
    // Only enable auto-queue for single song plays from home, search, lyrics search, or music recognition
    if (source == PlaySource.homeSingleSong || 
        source == PlaySource.searchSingleSong ||
        source == PlaySource.lyricsSearch ||
        source == PlaySource.musicRecognition) {
      _isAutoQueueEnabled = true;
      _seedVideoId = videoId;
      _currentSource = source;
      _autoQueuedTrackIds.clear();
      _autoQueuedTrackIds.add(videoId); // Don't re-add the seed song
      print('AutoQueue: Started for $videoId (source: $source)');
    } else {
      // Disable auto-queue for playlists, albums, search results
      stopAutoQueue();
      _currentSource = source;
      print('AutoQueue: Disabled for source: $source');
    }
  }

  /// Stop auto-queue
  void stopAutoQueue() {
    _isAutoQueueEnabled = false;
    _seedVideoId = null;
    _autoQueuedTrackIds.clear();
    _isFetching = false;
    print('AutoQueue: Stopped');
  }

  /// Fetch similar songs for auto-queue
  /// Returns list of tracks to add to queue (excludes already queued tracks)
  /// 
  /// [currentVideoId] - The currently playing video ID
  /// [existingQueueIds] - Set of video IDs already in the queue
  Future<List<Track>> fetchSimilarSongs(String currentVideoId, Set<String> existingQueueIds) async {
    if (!_isAutoQueueEnabled) {
      print('AutoQueue: Not enabled, skipping fetch');
      return [];
    }
    
    if (_isFetching) {
      print('AutoQueue: Already fetching, skipping');
      return [];
    }
    
    _isFetching = true;
    
    try {
      print('AutoQueue: Fetching similar songs for $currentVideoId');
      
      // Use the current video ID to get related songs
      final relatedTracks = await _innertube.getNextSongs(currentVideoId);
      
      if (relatedTracks.isEmpty) {
        print('AutoQueue: No related tracks found');
        return [];
      }
      
      // Filter out tracks that are already in queue or already auto-queued
      final newTracks = relatedTracks.where((track) {
        // Skip if already in queue
        if (existingQueueIds.contains(track.id)) {
          return false;
        }
        // Skip if already auto-queued before
        if (_autoQueuedTrackIds.contains(track.id)) {
          return false;
        }
        // Validate YouTube ID (must be 11 characters)
        if (track.id.length != 11) {
          return false;
        }
        return true;
      }).toList();
      
      // Mark these tracks as auto-queued
      for (final track in newTracks) {
        _autoQueuedTrackIds.add(track.id);
      }
      
      print('AutoQueue: Found ${newTracks.length} new tracks to add (filtered from ${relatedTracks.length})');
      
      return newTracks;
    } catch (e) {
      print('AutoQueue: Error fetching similar songs: $e');
      return [];
    } finally {
      _isFetching = false;
    }
  }

  /// Check if we should fetch more songs
  /// Returns true if auto-queue is enabled and we're near the end of queue
  bool shouldFetchMore(int currentIndex, int queueLength) {
    if (!_isAutoQueueEnabled) return false;
    
    // Fetch more when we're within 2 songs of the end
    final remainingSongs = queueLength - currentIndex - 1;
    return remainingSongs <= 2;
  }

  /// Update the seed video ID (when user manually changes track)
  void updateSeedVideo(String videoId) {
    if (_isAutoQueueEnabled) {
      _seedVideoId = videoId;
      print('AutoQueue: Updated seed video to $videoId');
    }
  }
}
