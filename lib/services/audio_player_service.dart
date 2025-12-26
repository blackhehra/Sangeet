import 'dart:async';
import 'dart:ui';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:audio_service/audio_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/streaming_server.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/services/audio_handler_service.dart';
import 'package:sangeet/services/track_matcher_service.dart';

enum RepeatMode { off, all, one }

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  
  AudioPlayerService._internal() {
    _init();
  }

  late final Player _player;
  final StreamingServer _streamingServer = StreamingServer();
  final PlayHistoryService _historyService = PlayHistoryService.instance;
  SangeetAudioHandler? _audioHandler;
  
  // Track play time for history
  DateTime? _playStartTime;
  String? _currentPlayingId;
  
  // Global playback session ID - incremented each time a new track/playlist starts
  // Used to cancel stale background operations (like track matching from old playlists)
  int _playbackSessionId = 0;
  
  // Track which playlist is currently playing
  String? _currentPlaylistId;
  
  /// Get current playback session ID
  int get playbackSessionId => _playbackSessionId;
  
  /// Get current playlist ID
  String? get currentPlaylistId => _currentPlaylistId;

  // State
  final List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isShuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<int> _shuffledIndices = [];

  // Stream controllers
  final _currentTrackController = StreamController<Track?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _queueController = StreamController<List<Track>>.broadcast();

  // Getters for streams
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<bool> get bufferingStream => _bufferingController.stream;
  Stream<List<Track>> get queueStream => _queueController.stream;

  // Getters for current state
  Track? get currentTrack => _currentIndex >= 0 && _currentIndex < _queue.length 
      ? _queue[_currentIndex] 
      : null;
  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.state.playing;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;

  /// Initialize audio handler for lock screen controls
  Future<void> initAudioHandler() async {
    if (_audioHandler != null) {
      print('AudioPlayer: Audio handler already initialized');
      return;
    }
    
    try {
      _audioHandler = await AudioService.init(
        builder: () => SangeetAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.sangeet.audio',
          androidNotificationChannelName: 'Sangeet Music',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          notificationColor: Color(0xFF1DB954),
        ),
      );
      print('AudioPlayer: Audio handler initialized successfully');
      _setupAudioHandlerCallbacks();
    } catch (e, stack) {
      print('AudioPlayer: Failed to initialize audio handler: $e');
      print('AudioPlayer: Stack trace: $stack');
    }
  }

  /// Setup callbacks from audio handler (lock screen controls)
  void _setupAudioHandlerCallbacks() {
    if (_audioHandler == null) return;
    
    // Connect lock screen controls to player actions
    _audioHandler!.onPlayPressed = () {
      resume();
    };
    
    _audioHandler!.onPausePressed = () {
      pause();
    };
    
    _audioHandler!.onSkipNext = () {
      skipToNext();
    };
    
    _audioHandler!.onSkipPrevious = () {
      skipToPrevious();
    };
    
    _audioHandler!.onSeek = (position) {
      seek(position);
    };
    
    _audioHandler!.onTaskRemovedCallback = () {
      // Stop the player when app is removed from recents
      _player.stop();
      print('AudioPlayer: App removed from recents, stopping playback');
    };
  }

  void _init() {
    // Configure player with proper audio output settings
    _player = Player(
      configuration: const PlayerConfiguration(
        // Use default audio output (media speaker, not earpiece)
        title: 'Sangeet Music Player',
        bufferSize: 32 * 1024 * 1024, // 32MB buffer for smooth playback
      ),
    );

    // Listen to player state changes
    _player.stream.playing.listen((playing) {
      print('AudioPlayer: Playing state changed: $playing');
      _playingController.add(playing);
      
      // Update lock screen notification
      _audioHandler?.updatePlaying(playing);
    });

    _player.stream.position.listen((position) {
      _positionController.add(position);
      
      // Update lock screen position (throttle to avoid too many updates)
      _audioHandler?.updatePosition(position);
    });

    _player.stream.buffer.listen((bufferedPosition) {
      // Update lock screen buffered position
      _audioHandler?.updateBufferedPosition(bufferedPosition);
    });

    _player.stream.duration.listen((duration) {
      print('AudioPlayer: Duration changed: $duration');
      _durationController.add(duration);
    });

    _player.stream.buffering.listen((buffering) {
      print('AudioPlayer: Buffering state: $buffering');
      _bufferingController.add(buffering);
      
      // Update lock screen buffering state
      _audioHandler?.updateBuffering(buffering);
    });

    // Handle errors
    _player.stream.error.listen((error) {
      print('AudioPlayer: Player error: $error');
    });

    // Handle track completion
    _player.stream.completed.listen((completed) {
      if (completed) {
        print('AudioPlayer: Track completed');
        _recordPlayTime(); // Record play time before moving to next track
        _onTrackCompleted();
      }
    });

    // Track play/pause for history
    _player.stream.playing.listen((playing) {
      if (playing && _currentPlayingId != null) {
        _playStartTime = DateTime.now();
      } else if (!playing && _playStartTime != null) {
        _recordPlayTime();
      }
    });
  }

  /// Record play time to history service (like ViMusic Event tracking)
  void _recordPlayTime() {
    if (_currentPlayingId != null && _playStartTime != null) {
      final playTimeMs = DateTime.now().difference(_playStartTime!).inMilliseconds;
      if (playTimeMs > 1000) { // Only record if played for more than 1 second
        _historyService.updatePlayTime(_currentPlayingId!, playTimeMs);
        print('AudioPlayer: Recorded ${playTimeMs}ms play time for $_currentPlayingId');
      }
      _playStartTime = null;
    }
  }

  void _onTrackCompleted() {
    switch (_repeatMode) {
      case RepeatMode.one:
        // Replay current track
        _player.seek(Duration.zero);
        _player.play();
        break;
      case RepeatMode.all:
        // Play next, loop to start if at end
        skipToNext();
        break;
      case RepeatMode.off:
        // Play next if available
        if (_currentIndex < _queue.length - 1) {
          skipToNext();
        }
        break;
    }
  }

  /// Play a single track
  Future<void> play(Track track) async {
    // Increment session ID to cancel any stale background operations
    _playbackSessionId++;
    print('AudioPlayer: New playback session $_playbackSessionId for track: ${track.title}');
    
    _queue.clear();
    _queue.add(track);
    _currentIndex = 0;
    _queueController.add(_queue);
    await _playCurrentTrack();
  }
  
  /// Set a pending track to show in UI immediately (before stream is ready)
  /// This provides instant feedback when user clicks a song
  /// Only clears queue when clicking a song in a DIFFERENT playlist
  void setPendingTrack(Track track, {String? playlistId}) {
    // Check if this is a different playlist
    final isDifferentPlaylist = playlistId != null && playlistId != _currentPlaylistId;
    
    // Stop current playback immediately so user doesn't hear two songs
    _player.stop();
    
    // Increment session ID to cancel any stale background operations
    _playbackSessionId++;
    print('AudioPlayer: New playback session $_playbackSessionId (pending) for track: ${track.title}');
    
    // Only clear queue if playing from a different playlist
    if (isDifferentPlaylist) {
      print('AudioPlayer: Different playlist detected, clearing queue (old: $_currentPlaylistId, new: $playlistId)');
      _queue.clear();
      _currentIndex = -1;
      _currentPlaylistId = playlistId;
      _queueController.add(_queue);
    }
    
    // Immediately update UI with track info
    _currentTrackController.add(track);
    _bufferingController.add(true);
    
    // Update lock screen notification immediately
    _audioHandler?.setCurrentTrack(track);
    _audioHandler?.updateBuffering(true);
  }

  /// Play a list of tracks
  Future<void> playAll(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      print('AudioPlayer: playAll called with empty tracks list');
      return;
    }
    
    // Increment session ID to cancel any stale background operations
    _playbackSessionId++;
    print('AudioPlayer: New playback session $_playbackSessionId for ${tracks.length} tracks');
    print('AudioPlayer: First track: ${tracks[startIndex].title} (ID: ${tracks[startIndex].id})');
    
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = startIndex.clamp(0, tracks.length - 1);
    _updateShuffledIndices();
    _queueController.add(_queue);
    await _playCurrentTrack();
  }

  /// Get current queue length
  int get queueLength => _queue.length;
  
  /// Find a track in the queue by its ID
  /// Returns the index if found, -1 if not found
  int findTrackInQueue(String trackId) {
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].id == trackId) {
        return i;
      }
    }
    return -1;
  }
  
  /// Play track at specific index in queue
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) {
      print('AudioPlayer: Invalid index $index for queue of length ${_queue.length}');
      return;
    }
    _currentIndex = index;
    await _playCurrentTrack();
  }
  
  /// Add track to queue
  /// Returns false if the session has changed (track should not be added)
  /// Also validates that the track has a valid YouTube ID (11 characters)
  bool addToQueue(Track track, {int? forSession}) {
    // If a session ID is provided, check if it's still valid
    if (forSession != null && forSession != _playbackSessionId) {
      print('AudioPlayer: Ignoring addToQueue for stale session $forSession (current: $_playbackSessionId)');
      return false;
    }
    
    // Validate YouTube ID - must be exactly 11 characters
    if (track.id.length != 11) {
      print('AudioPlayer: Rejecting track with invalid YouTube ID: ${track.id} (${track.title})');
      return false;
    }
    
    _queue.add(track);
    _updateShuffledIndices();
    _queueController.add(_queue);
    return true;
  }

  /// Add track to play next
  void playNext(Track track) {
    if (_currentIndex < _queue.length - 1) {
      _queue.insert(_currentIndex + 1, track);
    } else {
      _queue.add(track);
    }
    _updateShuffledIndices();
    _queueController.add(_queue);
  }

  /// Remove track from queue
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      // Current track removed, play next or stop
      if (_queue.isEmpty) {
        _currentIndex = -1;
        _player.stop();
        _currentTrackController.add(null);
      } else {
        _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
        _playCurrentTrack();
      }
    }
    _updateShuffledIndices();
    _queueController.add(_queue);
  }

  /// Clear queue
  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _player.stop();
    _currentTrackController.add(null);
    _queueController.add(_queue);
  }

  /// Play current track - with disk caching for instant replay
  Future<void> _playCurrentTrack({int retryCount = 0}) async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final track = _queue[_currentIndex];
    print('AudioPlayer: Playing track: ${track.title} (ID: ${track.id})');
    _currentTrackController.add(track);
    _bufferingController.add(true);
    
    // Initialize audio handler if not already done
    if (_audioHandler == null) {
      print('AudioPlayer: Audio handler not initialized, initializing now...');
      await initAudioHandler();
    }
    
    // Update lock screen notification with track info
    await _audioHandler?.setCurrentTrack(track);
    // Set initial state to buffering
    _audioHandler?.updateBuffering(true);
    print('AudioPlayer: Media item updated for lock screen');
    
    // Set a timeout to prevent infinite loading
    const timeoutDuration = Duration(seconds: 30);

    // Record play start for history (like ViMusic Event tracking)
    _recordPlayTime(); // Record previous track's play time first
    _currentPlayingId = track.id;
    _playStartTime = DateTime.now();
    await _historyService.recordPlayStart(track);

    try {
      // Wrap the entire playback logic in a timeout
      await Future.any([
        _attemptPlayback(track),
        Future.delayed(timeoutDuration).then((_) => throw TimeoutException('Track loading timeout', timeoutDuration)),
      ]);
    } on TimeoutException catch (e) {
      print('AudioPlayer: Timeout loading track: $e');
      _bufferingController.add(false);
      
      // Retry once before skipping
      if (retryCount < 1) {
        print('AudioPlayer: Retrying track (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(seconds: 1));
        return _playCurrentTrack(retryCount: retryCount + 1);
      }
      
      // After retry, skip to next track
      print('AudioPlayer: Skipping track after timeout');
      if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
        await skipToNext();
      }
    } catch (e, stackTrace) {
      print('AudioPlayer: Error playing track: $e');
      print('AudioPlayer: Stack trace: $stackTrace');
      _bufferingController.add(false);
      
      // Check if this is an unplayable video error (age-restricted, etc.)
      final errorStr = e.toString();
      final isUnplayable = errorStr.contains('unplayable') || 
                           errorStr.contains('age') ||
                           errorStr.contains('inappropriate') ||
                           errorStr.contains('Failed to pre-fetch');
      
      if (isUnplayable) {
        // Clear the bad cache entry so next time it will re-match
        print('AudioPlayer: Clearing bad cache entry for ${track.id}');
        // Find the Spotify ID for this track and clear its cache
        // The track.id is the YouTube ID, we need to find which Spotify track mapped to it
        await TrackMatcherService().clearCacheForYouTubeId(track.id);
      }
      
      // Retry once on error
      if (retryCount < 1) {
        print('AudioPlayer: Retrying track after error (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(seconds: 1));
        return _playCurrentTrack(retryCount: retryCount + 1);
      }
      
      // Only skip to next if there's actually a next track
      if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
        print('AudioPlayer: Trying next track after error');
        await skipToNext();
      } else {
        print('AudioPlayer: No next track available after error');
      }
    }
  }
  
  /// Attempt to play the track with proper error handling
  Future<void> _attemptPlayback(Track track) async {
    try {
      // Ensure streaming server is running
      await _streamingServer.start();
      
      // Check if audio is cached on disk - instant playback like ViMusic
      final isCached = await _streamingServer.isAudioCached(track.id);
      
      if (isCached) {
        // Instant playback from disk cache - no network needed
        print('AudioPlayer: Playing from disk cache (instant)');
        final streamUrl = _streamingServer.getStreamUrl(track.id);
        await _player.open(Media(streamUrl));
        await _player.play();
        print('AudioPlayer: Playback started from cache');
        
        _prefetchNextTrack();
        return;
      }
      
      // Pre-fetch and validate stream URL BEFORE telling media_kit to play
      print('AudioPlayer: Pre-fetching stream...');
      final success = await _streamingServer.prefetchStream(track.id);
      
      if (!success) {
        print('AudioPlayer: Failed to pre-fetch stream for ${track.title}');
        throw Exception('Failed to pre-fetch stream');
      }
      
      // Now get local stream URL from our proxy server
      final streamUrl = _streamingServer.getStreamUrl(track.id);
      print('AudioPlayer: Using local stream URL: $streamUrl');
      
      await _player.open(Media(streamUrl));
      print('AudioPlayer: Player opened, starting playback...');
      await _player.play();
      print('AudioPlayer: Playback started');
      
      // Prefetch next track in background for faster loading (like ViMusic)
      _prefetchNextTrack();
    } catch (e) {
      print('AudioPlayer: Error in _attemptPlayback: $e');
      rethrow;
    }
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_player.state.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Skip to next track
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    // Stop current playback immediately
    _player.stop();

    if (_isShuffled && _shuffledIndices.isNotEmpty) {
      final currentShuffleIndex = _shuffledIndices.indexOf(_currentIndex);
      if (currentShuffleIndex < _shuffledIndices.length - 1) {
        _currentIndex = _shuffledIndices[currentShuffleIndex + 1];
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _shuffledIndices.first;
      } else {
        return;
      }
    } else {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
      } else {
        return;
      }
    }

    await _playCurrentTrack();
  }

  /// Skip to previous track
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

    // If more than 3 seconds in, restart current track
    if (_player.state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    // Stop current playback immediately
    _player.stop();

    if (_isShuffled && _shuffledIndices.isNotEmpty) {
      final currentShuffleIndex = _shuffledIndices.indexOf(_currentIndex);
      if (currentShuffleIndex > 0) {
        _currentIndex = _shuffledIndices[currentShuffleIndex - 1];
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _shuffledIndices.last;
      } else {
        await seek(Duration.zero);
        return;
      }
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _queue.length - 1;
      } else {
        await seek(Duration.zero);
        return;
      }
    }

    await _playCurrentTrack();
  }

  /// Skip to specific index
  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrentTrack();
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    _updateShuffledIndices();
  }

  void _updateShuffledIndices() {
    if (_isShuffled && _queue.isNotEmpty) {
      _shuffledIndices = List.generate(_queue.length, (i) => i);
      _shuffledIndices.shuffle();
      // Move current track to front
      if (_currentIndex >= 0) {
        _shuffledIndices.remove(_currentIndex);
        _shuffledIndices.insert(0, _currentIndex);
      }
    } else {
      _shuffledIndices.clear();
    }
  }

  /// Cycle repeat mode
  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0) * 100);
  }

  /// Set audio quality
  void setAudioQuality(AudioQuality quality) {
    _streamingServer.setAudioQuality(quality);
  }

  /// Prefetch next track in background for faster loading (like ViMusic)
  void _prefetchNextTrack() {
    if (_queue.isEmpty) return;
    
    int nextIndex;
    if (_isShuffled && _shuffledIndices.isNotEmpty) {
      final currentShuffleIndex = _shuffledIndices.indexOf(_currentIndex);
      if (currentShuffleIndex < _shuffledIndices.length - 1) {
        nextIndex = _shuffledIndices[currentShuffleIndex + 1];
      } else {
        nextIndex = _shuffledIndices.first;
      }
    } else {
      nextIndex = (_currentIndex + 1) % _queue.length;
    }
    
    if (nextIndex >= 0 && nextIndex < _queue.length && nextIndex != _currentIndex) {
      final nextTrack = _queue[nextIndex];
      print('AudioPlayer: Prefetching next track: ${nextTrack.title}');
      // Fire and forget - don't await
      _streamingServer.prefetchStream(nextTrack.id).then((success) {
        if (success) {
          print('AudioPlayer: Next track prefetched successfully');
        }
      }).catchError((e) {
        print('AudioPlayer: Failed to prefetch next track: $e');
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
    _currentTrackController.close();
    _playingController.close();
    _positionController.close();
    _durationController.close();
    _bufferingController.close();
    _queueController.close();
    _streamingServer.stop();
  }
}
