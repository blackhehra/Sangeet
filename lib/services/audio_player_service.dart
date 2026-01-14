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
import 'package:sangeet/services/playback_state_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/services/listening_stats_service.dart';

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
  final PlaybackStateService _playbackStateService = PlaybackStateService.instance;
  final AutoQueueService _autoQueueService = AutoQueueService();
  final ListeningStatsService _listeningStatsService = ListeningStatsService.instance;
  
  // Timer for periodic state saving
  Timer? _stateSaveTimer;
  SangeetAudioHandler? _audioHandler;
  
  // Track play time for history
  DateTime? _playStartTime;
  String? _currentPlayingId;
  
  // Global playback session ID - incremented each time a new track/playlist starts
  // Used to cancel stale background operations (like track matching from old playlists)
  int _playbackSessionId = 0;
  
  // Track when we're seeking to ignore spurious completion events
  bool _isSeeking = false;
  DateTime? _lastSeekTime;
  
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
  
  // Last known position/duration for restored tracks (so streams can emit initial value)
  Duration _lastKnownPosition = Duration.zero;
  Duration _lastKnownDuration = Duration.zero;
  
  // Seek recovery state - suppress UI changes during recovery
  bool _isSeekRecovering = false;
  Duration _seekRecoveryTargetPosition = Duration.zero;
  DateTime? _lastSeekRecoveryTime; // Track when seek recovery completed to ignore spurious completions
  Duration _lastSeekTargetPosition = Duration.zero; // Track user's intended seek position for spurious completion recovery

  // Getters for streams - emit current value immediately then stream updates
  Stream<Track?> get currentTrackStream async* {
    yield currentTrack; // Emit current value first
    yield* _currentTrackController.stream;
  }
  Stream<bool> get playingStream async* {
    yield isPlaying;
    yield* _playingController.stream;
  }
  Stream<Duration> get positionStream async* {
    yield _lastKnownPosition; // Emit last known position first (for restored tracks)
    yield* _positionController.stream;
  }
  Stream<Duration> get durationStream async* {
    yield _lastKnownDuration; // Emit last known duration first (for restored tracks)
    yield* _durationController.stream;
  }
  Stream<bool> get bufferingStream async* {
    yield false; // Emit initial non-buffering state
    yield* _bufferingController.stream;
  }
  Stream<List<Track>> get queueStream async* {
    yield queue;
    yield* _queueController.stream;
  }

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
    try {
      // Configure player with proper audio output settings
      _player = Player(
        configuration: const PlayerConfiguration(
          // Use default audio output (media speaker, not earpiece)
          title: 'Sangeet Music Player',
          bufferSize: 64 * 1024 * 1024, // 64MB buffer for smooth playback
        ),
      );
    } catch (e, stack) {
      print('AudioPlayer: CRITICAL - Failed to initialize Player: $e');
      print('AudioPlayer: Stack: $stack');
      // Create a fallback player with minimal config
      _player = Player();
    }

    // Listen to player state changes - wrap in try-catch to handle rare initialization failures
    try {
      _setupPlayerListeners();
    } catch (e) {
      print('AudioPlayer: Failed to setup player listeners: $e');
    }
    
    // Start periodic state saving (every 10 seconds while playing)
    _startStateSaveTimer();
  }
  
  /// Setup all player stream listeners
  void _setupPlayerListeners() {
    _player.stream.playing.listen((playing) {
      print('AudioPlayer: Playing state changed: $playing');
      
      // During seek recovery, suppress pause state to UI (keep showing loading)
      if (_isSeekRecovering && !playing) {
        print('AudioPlayer: Suppressing pause during seek recovery');
        return;
      }
      
      _playingController.add(playing);
      
      // Update lock screen notification
      _audioHandler?.updatePlaying(playing);
      
      // Track play/pause for history (consolidated here to avoid duplicate listeners)
      if (playing && _currentPlayingId != null) {
        _playStartTime = DateTime.now();
      } else if (!playing && _playStartTime != null) {
        _recordPlayTime();
      }
    });

    _player.stream.position.listen((position) {
      // During seek recovery, emit the target position instead of actual position
      // This prevents the seek bar from jumping to 0 and back
      if (_isSeekRecovering) {
        _positionController.add(_seekRecoveryTargetPosition);
        return;
      }
      
      _lastKnownPosition = position; // Keep track of last known position
      _positionController.add(position);
      
      // Update lock screen position (throttle to avoid too many updates)
      _audioHandler?.updatePosition(position);
    });

    _player.stream.buffer.listen((bufferedPosition) {
      // Update lock screen buffered position
      _audioHandler?.updateBufferedPosition(bufferedPosition);
      
      // Buffer prefetching: Monitor buffer health and maintain safety margin
      final position = _player.state.position;
      final duration = _player.state.duration;
      
      // Calculate buffer ahead (how much is buffered ahead of current position)
      final bufferAhead = bufferedPosition - position;
      
      // If buffer ahead is less than 10 seconds and we're not near the end, trigger prefetch
      // This keeps a healthy buffer margin to prevent interruptions
      if (bufferAhead.inSeconds < 10 && 
          duration.inSeconds > 0 && 
          position.inSeconds < duration.inSeconds - 15) {
        // Player will automatically buffer more, but we log it for monitoring
        if (bufferAhead.inSeconds < 5) {
          print('AudioPlayer: Low buffer detected (${bufferAhead.inSeconds}s ahead), prefetching...');
        }
      }
    });

    _player.stream.duration.listen((duration) {
      print('AudioPlayer: Duration changed: $duration');
      
      // During seek recovery, suppress duration reset to 0 (keep showing original duration)
      if (_isSeekRecovering && duration == Duration.zero) {
        print('AudioPlayer: Suppressing duration reset during seek recovery');
        return;
      }
      
      _lastKnownDuration = duration; // Keep track of last known duration
      _durationController.add(duration);
    });

    _player.stream.buffering.listen((buffering) {
      print('AudioPlayer: Buffering state: $buffering');
      _bufferingController.add(buffering);
      
      // Update lock screen buffering state
      _audioHandler?.updateBuffering(buffering);
    });

    // Handle errors
    _player.stream.error.listen((error) async {
      print('AudioPlayer: Player error: $error');
      
      // Handle corrupted cache file - clear and retry
      if (error.toString().contains('Failed to recognize file format') ||
          error.toString().contains('Failed to open')) {
        if (_currentIndex >= 0 && _currentIndex < _queue.length) {
          final track = _queue[_currentIndex];
          print('AudioPlayer: Corrupted cache detected for ${track.title}, clearing and retrying...');
          await _streamingServer.clearCachedStream(track.id);
          // Retry playback with fresh stream
          await _playCurrentTrack();
        }
      }
    });

    // Handle track completion
    _player.stream.completed.listen((completed) async {
      if (completed) {
        final pos = _player.state.position;
        final dur = _player.state.duration;
        
        // Ignore spurious completion events during/after seeking
        if (_isSeeking) {
          print('AudioPlayer: Ignoring completion during seek (pos: ${pos.inSeconds}s, dur: ${dur.inSeconds}s)');
          return;
        }
        
        // Also ignore if we just seeked within the last second
        if (_lastSeekTime != null && 
            DateTime.now().difference(_lastSeekTime!).inMilliseconds < 1000) {
          print('AudioPlayer: Ignoring completion shortly after seek (pos: ${pos.inSeconds}s, dur: ${dur.inSeconds}s)');
          return;
        }
        
        // Ignore spurious completions shortly after seek recovery (within 3 seconds)
        // This prevents the reload loop where seek recovery triggers another spurious completion
        if (_lastSeekRecoveryTime != null &&
            DateTime.now().difference(_lastSeekRecoveryTime!).inMilliseconds < 3000) {
          print('AudioPlayer: Ignoring completion shortly after seek recovery (pos: ${pos.inSeconds}s, dur: ${dur.inSeconds}s)');
          return;
        }
        
        // Detect spurious completions where position is far from duration
        // This can happen when cache file is incomplete or stream failed
        if (dur.inSeconds > 0 && pos.inSeconds < dur.inSeconds - 3) {
          // Use the last seek target position if we recently seeked (within 10 seconds)
          // Otherwise use current position. This prevents restarting from 0 when user seeked to e.g. 96s
          final recoveryPosition = (_lastSeekTime != null && 
              DateTime.now().difference(_lastSeekTime!).inSeconds < 10 &&
              _lastSeekTargetPosition.inSeconds > pos.inSeconds)
              ? _lastSeekTargetPosition
              : pos;
          print('AudioPlayer: Spurious completion detected (pos: ${pos.inSeconds}s far from dur: ${dur.inSeconds}s) - reloading track at ${recoveryPosition.inSeconds}s');
          // Reload the track from the recovery position with a fresh stream
          _reloadCurrentTrackAtPosition(recoveryPosition);
          return;
        }
        
        print('AudioPlayer: Track completed (pos: ${pos.inSeconds}s, dur: ${dur.inSeconds}s)');
        _recordPlayTime(); // Record play time before moving to next track
        _onTrackCompleted();
      }
    });
    
    // Note: We don't use media_kit's playlist feature - we manage our own queue
    // and open single Media objects. This gives us full control over track transitions.

    // Note: Play time tracking is handled in the main playing listener above
    // to avoid duplicate listeners causing race conditions
  }
  
  /// Start timer to periodically save playback state
  void _startStateSaveTimer() {
    _stateSaveTimer?.cancel();
    _stateSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Only save state when actually playing
      if (isPlaying) {
        _saveCurrentState();
      }
    });
  }
  
  /// Save current playback state for restoration on next app launch
  Future<void> _saveCurrentState() async {
    final track = currentTrack;
    if (track == null) return;
    
    await _playbackStateService.savePlaybackState(
      track: track,
      position: position,
      queue: _queue,
      queueIndex: _currentIndex,
    );
  }

  /// Record play time to history service and listening stats
  void _recordPlayTime() {
    if (_currentPlayingId != null && _playStartTime != null) {
      final playTimeMs = DateTime.now().difference(_playStartTime!).inMilliseconds;
      if (playTimeMs > 1000) { // Only record if played for more than 1 second
        _historyService.updatePlayTime(_currentPlayingId!, playTimeMs);
        
        // Record to listening stats only if listened > 50% of the song
        final track = currentTrack;
        final durationMs = _player.state.duration.inMilliseconds;
        if (track != null && durationMs > 0) {
          final percentListened = playTimeMs / durationMs;
          if (percentListened >= 0.5) {
            _listeningStatsService.recordPlay(
              track: track,
              playTimeMs: playTimeMs,
            );
            print('AudioPlayer: Recorded stats (${(percentListened * 100).toInt()}% listened)');
          } else {
            print('AudioPlayer: Skipped stats (only ${(percentListened * 100).toInt()}% listened, need 50%)');
          }
        }
        
        print('AudioPlayer: Recorded ${playTimeMs}ms play time for $_currentPlayingId');
      }
      _playStartTime = null;
    }
  }

  void _onTrackCompleted() {
    print('AudioPlayer: Track completed, handling next action...');
    
    // Cancel any pending buffering timeout
    _cancelBufferingTimeout();
    
    // Clear buffering state
    _bufferingController.add(false);
    
    switch (_repeatMode) {
      case RepeatMode.one:
        // Replay current track
        print('AudioPlayer: Repeat mode ONE - replaying current track');
        _player.seek(Duration.zero);
        _player.play();
        break;
      case RepeatMode.all:
        // Play next, loop to start if at end
        print('AudioPlayer: Repeat mode ALL - playing next track');
        skipToNext();
        break;
      case RepeatMode.off:
        // Play next if available
        if (_currentIndex < _queue.length - 1) {
          print('AudioPlayer: Repeat mode OFF - playing next track');
          skipToNext();
        } else {
          // Queue ended - try to auto-queue more songs if enabled
          print('AudioPlayer: Queue ended - checking auto-queue');
          _tryAutoQueueMoreSongs();
        }
        break;
    }
  }
  
  /// Try to fetch and add more songs via auto-queue
  Future<void> _tryAutoQueueMoreSongs() async {
    if (!_autoQueueService.isAutoQueueEnabled) {
      print('AudioPlayer: Auto-queue not enabled, playback stopped');
      return;
    }
    
    final currentTrack = this.currentTrack;
    if (currentTrack == null) return;
    
    print('AudioPlayer: Attempting to auto-queue more songs...');
    
    // Get existing queue IDs to avoid duplicates
    final existingIds = _queue.map((t) => t.id).toSet();
    
    // Fetch similar songs
    final newTracks = await _autoQueueService.fetchSimilarSongs(
      currentTrack.id,
      existingIds,
    );
    
    if (newTracks.isEmpty) {
      print('AudioPlayer: No new tracks from auto-queue, playback stopped');
      return;
    }
    
    // Add new tracks to queue
    print('AudioPlayer: Auto-queuing ${newTracks.length} similar songs');
    for (final track in newTracks) {
      _queue.add(track);
    }
    _updateShuffledIndices();
    _queueController.add(_queue);
    
    // Continue playing
    skipToNext();
  }
  
  /// Check and prefetch auto-queue songs when nearing end of queue
  void _checkAutoQueuePrefetch() {
    if (_autoQueueService.shouldFetchMore(_currentIndex, _queue.length)) {
      final currentTrack = this.currentTrack;
      if (currentTrack != null) {
        // Prefetch in background
        final existingIds = _queue.map((t) => t.id).toSet();
        _autoQueueService.fetchSimilarSongs(currentTrack.id, existingIds).then((newTracks) {
          if (newTracks.isNotEmpty) {
            print('AudioPlayer: Pre-fetched ${newTracks.length} auto-queue songs');
            for (final track in newTracks) {
              _queue.add(track);
            }
            _updateShuffledIndices();
            _queueController.add(_queue);
          }
        });
      }
    }
  }

  /// Play a single track
  Future<void> play(Track track, {PlaySource source = PlaySource.unknown}) async {
    // Cancel any pending timeouts
    _cancelBufferingTimeout();
    _resumeTimeoutTimer?.cancel();
    _resumeTimeoutTimer = null;
    
    // Increment session ID to cancel any stale background operations
    _playbackSessionId++;
    final sessionId = _playbackSessionId;
    print('AudioPlayer: New playback session $sessionId for track: ${track.title} (source: $source)');
    
    _queue.clear();
    _queue.add(track);
    _currentIndex = 0;
    _queueController.add(_queue);
    
    // Start auto-queue for single song plays from home or search
    _autoQueueService.startAutoQueue(track.id, source);
    
    // Start playback immediately
    await _playCurrentTrack();
    
    // If auto-queue is enabled, immediately fetch similar songs in background
    if (_autoQueueService.isAutoQueueEnabled) {
      _fetchAutoQueueSongsInBackground(track.id, sessionId);
    }
  }
  
  /// Fetch auto-queue songs in background without blocking playback
  void _fetchAutoQueueSongsInBackground(String videoId, int sessionId) {
    print('AutoQueue: Fetching similar songs for $videoId in background...');
    
    final existingIds = _queue.map((t) => t.id).toSet();
    _autoQueueService.fetchSimilarSongs(videoId, existingIds).then((newTracks) {
      // Check if session is still valid
      if (sessionId != _playbackSessionId) {
        print('AutoQueue: Session changed, discarding fetched songs');
        return;
      }
      
      if (newTracks.isNotEmpty) {
        print('AutoQueue: Adding ${newTracks.length} similar songs to queue');
        for (final track in newTracks) {
          _queue.add(track);
        }
        _updateShuffledIndices();
        _queueController.add(_queue);
      } else {
        print('AutoQueue: No similar songs found');
      }
    }).catchError((e) {
      print('AutoQueue: Error fetching similar songs: $e');
    });
  }
  
  /// Set a pending track to show in UI immediately (before stream is ready)
  /// This provides instant feedback when user clicks a song
  /// Only clears queue when clicking a song in a DIFFERENT playlist
  void setPendingTrack(Track track, {String? playlistId}) {
    // Check if this is a different playlist
    final isDifferentPlaylist = playlistId != null && playlistId != _currentPlaylistId;
    
    // Cancel any pending timeouts
    _cancelBufferingTimeout();
    _resumeTimeoutTimer?.cancel();
    _resumeTimeoutTimer = null;
    
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
  Future<void> playAll(List<Track> tracks, {int startIndex = 0, PlaySource source = PlaySource.unknown}) async {
    if (tracks.isEmpty) {
      print('AudioPlayer: playAll called with empty tracks list');
      return;
    }
    
    // Cancel any pending timeouts
    _cancelBufferingTimeout();
    _resumeTimeoutTimer?.cancel();
    _resumeTimeoutTimer = null;
    
    // Increment session ID to cancel any stale background operations
    _playbackSessionId++;
    print('AudioPlayer: New playback session $_playbackSessionId for ${tracks.length} tracks (source: $source)');
    print('AudioPlayer: First track: ${tracks[startIndex].title} (ID: ${tracks[startIndex].id})');
    
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = startIndex.clamp(0, tracks.length - 1);
    _updateShuffledIndices();
    _queueController.add(_queue);
    
    // Disable auto-queue for playlists/albums/search results (multiple tracks)
    _autoQueueService.startAutoQueue(tracks[startIndex].id, source);
    
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

  // Timer to detect stuck buffering state and auto-retry
  Timer? _bufferingTimeoutTimer;
  int _autoRetryCount = 0;
  static const int _maxAutoRetries = 3;
  
  /// Cancel any pending buffering timeout
  void _cancelBufferingTimeout() {
    _bufferingTimeoutTimer?.cancel();
    _bufferingTimeoutTimer = null;
  }
  
  /// Reset auto-retry counter (call when track changes or playback succeeds)
  void _resetAutoRetry() {
    _autoRetryCount = 0;
  }
  
  /// Start a buffering timeout - auto-retry if buffering doesn't complete in time
  void _startBufferingTimeout({Duration timeout = const Duration(seconds: 12)}) {
    _cancelBufferingTimeout();
    
    // Capture current session ID to validate when timer fires
    final expectedSessionId = _playbackSessionId;
    
    // Capture current position to preserve on retry (don't restart from beginning)
    final currentPosition = _player.state.position;
    
    _bufferingTimeoutTimer = Timer(timeout, () async {
      // Validate this timeout is for the current session - ignore stale timeouts
      if (expectedSessionId != _playbackSessionId) {
        print('AudioPlayer: Ignoring stale buffering timeout (session changed)');
        return;
      }
      
      print('AudioPlayer: Buffering timeout detected (auto-retry $_autoRetryCount/$_maxAutoRetries)');
      
      // Auto-retry if we haven't exceeded max retries
      if (_autoRetryCount < _maxAutoRetries && _currentIndex >= 0 && _currentIndex < _queue.length) {
        _autoRetryCount++;
        print('AudioPlayer: Auto-retrying track at position ${currentPosition.inSeconds}s (attempt $_autoRetryCount)');
        // Use position-aware playback to resume from where we were, not from beginning
        if (currentPosition.inSeconds > 0) {
          await _playCurrentTrackAtPosition(currentPosition);
        } else {
          await _playCurrentTrack(retryCount: 0);
        }
      } else {
        // Max retries exceeded - stop buffering and try next track
        print('AudioPlayer: Max auto-retries exceeded, skipping to next track');
        _bufferingController.add(false);
        _autoRetryCount = 0;
        if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
          skipToNext();
        }
      }
    });
  }
  
  /// Play current track - with disk caching for instant replay
  Future<void> _playCurrentTrack({int retryCount = 0}) async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      _bufferingController.add(false);
      return;
    }

    // Cancel any pending resume timeout (in case we're playing new track while stuck)
    _resumeTimeoutTimer?.cancel();
    _resumeTimeoutTimer = null;
    
    // Capture the current session ID at the start
    final currentSessionId = _playbackSessionId;
    print('AudioPlayer: _playCurrentTrack starting [session $currentSessionId, index $_currentIndex]');
    
    // Only stop player if it's actually stuck (buffering for too long or in a bad state)
    // Don't stop if it's just not playing - that's normal during track switch
    if (_player.state.buffering && _player.state.position > Duration.zero) {
      print('AudioPlayer: Stopping player to reset stuck buffering state');
      await _player.stop();
    }
    
    // Early session check - abort if session changed during stop
    if (currentSessionId != _playbackSessionId) {
      print('AudioPlayer: Session changed early ($currentSessionId != $_playbackSessionId), aborting...');
      return;
    }

    var track = _queue[_currentIndex];
    
    // Check if track needs YouTube matching (Spotify ID is not 11 chars)
    if (track.id.length != 11) {
      print('AudioPlayer: Track "${track.title}" has non-YouTube ID (${track.id.length} chars), matching...');
      final matchedTrack = await _matchTrackToYouTube(track);
      
      // Check if this track load was cancelled while matching
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Track load cancelled (session changed), aborting...');
        _bufferingController.add(false);
        return;
      }
      
      if (matchedTrack != null) {
        track = matchedTrack;
        // Update the queue with matched track so future plays are instant
        _queue[_currentIndex] = track;
        _queueController.add(_queue);
      } else {
        print('AudioPlayer: Failed to match track to YouTube, skipping...');
        _bufferingController.add(false);
        if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
          await skipToNext();
        }
        return;
      }
    }
    
    // Check again if this track load was cancelled
    if (currentSessionId != _playbackSessionId) {
      print('AudioPlayer: Track load cancelled (session $currentSessionId != $_playbackSessionId), aborting...');
      _bufferingController.add(false);
      return;
    }
    
    print('AudioPlayer: Playing track: ${track.title} (ID: ${track.id}) [session $currentSessionId]');
    _currentTrackController.add(track);
    _bufferingController.add(true);
    
    // Check if we should prefetch auto-queue songs
    _checkAutoQueuePrefetch();
    
    // Start buffering timeout to detect stuck states
    _startBufferingTimeout();
    
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
    
    // Set a timeout to prevent infinite loading (reduced from 30s to 15s for faster recovery)
    const timeoutDuration = Duration(seconds: 15);

    // Record play start for history
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
      // Validate this error handling is for the current session
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Ignoring stale timeout (session changed)');
        return;
      }
      
      print('AudioPlayer: Timeout loading track: $e');
      _cancelBufferingTimeout();
      _bufferingController.add(false);
      
      // Retry once before skipping (with shorter delay)
      if (retryCount < 1) {
        print('AudioPlayer: Retrying track (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(milliseconds: 500));
        // Re-validate after delay
        if (currentSessionId != _playbackSessionId) {
          print('AudioPlayer: Ignoring stale retry after timeout');
          return;
        }
        return _playCurrentTrack(retryCount: retryCount + 1);
      }
      
      // After retry, skip to next track
      print('AudioPlayer: Skipping track after timeout');
      if (_queue.length > 1 && _currentIndex < _queue.length - 1) {
        await skipToNext();
      }
    } catch (e, stackTrace) {
      // Validate this error handling is for the current session
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Ignoring stale error (session changed)');
        return;
      }
      
      print('AudioPlayer: Error playing track: $e');
      print('AudioPlayer: Stack trace: $stackTrace');
      _cancelBufferingTimeout();
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
      
      // Retry once on error (with shorter delay)
      if (retryCount < 1) {
        print('AudioPlayer: Retrying track after error (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(milliseconds: 500));
        // Re-validate after delay
        if (currentSessionId != _playbackSessionId) {
          print('AudioPlayer: Ignoring stale retry after error');
          return;
        }
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
    // Capture the current session ID
    final currentSessionId = _playbackSessionId;
    
    try {
      // Ensure streaming server is running
      await _streamingServer.start();
      
      // Check if this track load was cancelled
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Track load cancelled during server start, aborting...');
        return;
      }
      
      // Check if audio is cached on disk - instant playback
      final isCached = await _streamingServer.isAudioCached(track.id);
      
      // Check if this track load was cancelled
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Track load cancelled during cache check, aborting...');
        return;
      }
      
      if (isCached) {
        // Instant playback from disk cache - no network needed
        print('AudioPlayer: Playing from disk cache (instant)');
        final streamUrl = _streamingServer.getStreamUrl(track.id);
        await _player.open(Media(streamUrl));
        
        // Check if this track load was cancelled
        if (currentSessionId != _playbackSessionId) {
          print('AudioPlayer: Track load cancelled after opening cached media, aborting...');
          _player.stop();
          return;
        }
        
        await _player.play();
        
        // Final session check after playback started
        if (currentSessionId != _playbackSessionId) {
          print('AudioPlayer: Session changed after cached play started, stopping...');
          _player.stop();
          return;
        }
        
        print('AudioPlayer: Playback started from cache [session $currentSessionId]');
        
        // Cancel buffering timeout and reset auto-retry - playback started successfully
        _cancelBufferingTimeout();
        _resetAutoRetry();
        _prefetchNextTrack();
        return;
      }
      
      // Pre-fetch and validate stream URL BEFORE telling media_kit to play
      print('AudioPlayer: Pre-fetching stream...');
      final success = await _streamingServer.prefetchStream(track.id);
      
      // Check if this track load was cancelled
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Track load cancelled during stream prefetch, aborting...');
        return;
      }
      
      if (!success) {
        print('AudioPlayer: Failed to pre-fetch stream for ${track.title}');
        throw Exception('Failed to pre-fetch stream');
      }
      
      // Now get local stream URL from our proxy server
      final streamUrl = _streamingServer.getStreamUrl(track.id);
      print('AudioPlayer: Using local stream URL: $streamUrl');
      
      await _player.open(Media(streamUrl));
      
      // Check if this track load was cancelled
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Track load cancelled after opening media, aborting...');
        _player.stop();
        return;
      }
      
      print('AudioPlayer: Player opened, starting playback...');
      await _player.play();
      
      // Final session check after playback started
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Session changed after play started, stopping...');
        _player.stop();
        return;
      }
      
      print('AudioPlayer: Playback started [session $currentSessionId]');
      
      // Cancel buffering timeout and reset auto-retry - playback started successfully
      _cancelBufferingTimeout();
      _resetAutoRetry();
      
      // Prefetch next track in background for faster loading
      _prefetchNextTrack();
    } catch (e) {
      print('AudioPlayer: Error in _attemptPlayback: $e');
      rethrow;
    }
  }

  /// Match a track to YouTube by its metadata (title/artist)
  /// Used for imported Spotify playlists where tracks have Spotify IDs
  /// Returns matched track with YouTube ID, or null if no match found
  Future<Track?> _matchTrackToYouTube(Track track) async {
    final trackMatcher = TrackMatcherService();
    
    // Check if already cached (Spotify ID -> YouTube track)
    final cachedTrack = trackMatcher.getMatchedTrack(track.id);
    if (cachedTrack != null) {
      print('AudioPlayer: Cache hit for "${track.title}" -> YouTube ID: ${cachedTrack.id}');
      return cachedTrack;
    }
    
    try {
      // Search YouTube for this track by title and artist
      print('AudioPlayer: Searching YouTube for "${track.title}" by "${track.artist}"');
      
      // Use YT Music service to search
      final ytMusicService = YtMusicService();
      final query = '${track.title} ${track.artist}';
      final results = await ytMusicService.searchSongs(query);
      
      if (results.isEmpty) {
        print('AudioPlayer: No YouTube results for "${track.title}"');
        return null;
      }
      
      // Take the best match (first result)
      final bestMatch = results.first;
      print('AudioPlayer: Matched "${track.title}" -> "${bestMatch.title}" [${bestMatch.id}]');
      
      // Create new track with YouTube ID but keep original metadata
      final matchedTrack = Track(
        id: bestMatch.id, // YouTube ID for playback
        title: track.title, // Keep original title
        artist: track.artist, // Keep original artist
        album: track.album,
        thumbnailUrl: track.thumbnailUrl ?? bestMatch.thumbnailUrl,
        duration: track.duration,
      );
      
      // Cache the match (Spotify ID -> YouTube track) for future plays
      await trackMatcher.saveMatchToCache(track.id, matchedTrack);
      
      return matchedTrack;
    } catch (e) {
      print('AudioPlayer: Error matching track to YouTube: $e');
      return null;
    }
  }

  // Timer to detect stuck resume and refresh stream
  Timer? _resumeTimeoutTimer;
  
  // Track if fade-in is in progress
  bool _isFadingIn = false;
  
  /// Resume playback with stale stream detection and smooth fade-in
  /// If resuming after a long pause, the stream URL may have expired
  /// This detects stuck buffering and refreshes the stream
  Future<void> resume() async {
    // Check if we have a restored track that needs to be loaded first
    if (_isRestoredTrackPending) {
      print('AudioPlayer: Resuming restored track');
      await resumeFromRestored();
      return;
    }
    
    final track = currentTrack;
    if (track == null) {
      print('AudioPlayer: No track to resume');
      return;
    }
    
    // Store current position before attempting resume
    final currentPosition = _player.state.position;
    
    // Cancel any existing resume timeout
    _resumeTimeoutTimer?.cancel();
    
    // Capture current session ID to validate timeout
    final expectedSessionId = _playbackSessionId;
    
    // Start a timeout to detect stuck resume (stale stream)
    _resumeTimeoutTimer = Timer(const Duration(seconds: 8), () async {
      // Validate this timeout is for the current session
      if (expectedSessionId != _playbackSessionId) {
        print('AudioPlayer: Ignoring stale resume timeout (session changed)');
        return;
      }
      
      // Check if we're still buffering after 8 seconds - likely stale stream
      if (!_player.state.playing && _player.state.buffering) {
        print('AudioPlayer: Resume stuck (stale stream detected), refreshing...');
        await _refreshAndResumeTrack(track, currentPosition);
      }
    });
    
    // Start with volume at 0 for fade-in effect
    final targetVolume = _originalVolume > 0 ? _originalVolume : 1.0;
    await _player.setVolume(0);
    
    // Try normal resume first
    await _player.play();
    
    // Smooth fade-in effect
    _fadeInVolume(targetVolume);
    
    // If playback started successfully, cancel the timeout
    // Listen for playing state change
    _player.stream.playing.first.then((playing) {
      if (playing) {
        _resumeTimeoutTimer?.cancel();
        _resumeTimeoutTimer = null;
      }
    });
  }
  
  /// Smooth volume fade-in effect
  Future<void> _fadeInVolume(double targetVolume) async {
    if (_isFadingIn) return;
    _isFadingIn = true;
    
    try {
      // Smooth fade in over 250ms (25 steps of 10ms) for ultra-smooth effect
      const fadeSteps = 25;
      const stepDuration = Duration(milliseconds: 10);
      
      for (int i = 1; i <= fadeSteps; i++) {
        if (!_player.state.playing) break; // Paused during fade
        // Use smooth S-curve (ease in-out) for natural feel
        final t = i / fadeSteps;
        final easedProgress = t < 0.5 
            ? 2 * t * t 
            : 1 - ((-2 * t + 2) * (-2 * t + 2)) / 2;
        await _player.setVolume(easedProgress * targetVolume * 100);
        await Future.delayed(stepDuration);
      }
      
      // Ensure we reach target volume
      await _player.setVolume(targetVolume * 100);
    } finally {
      _isFadingIn = false;
    }
  }
  
  /// Refresh stream URL and resume track at given position
  /// Called when resume detects a stale stream
  Future<void> _refreshAndResumeTrack(Track track, Duration position) async {
    print('AudioPlayer: Refreshing stream for ${track.title} at ${position.inSeconds}s');
    
    // Stop the player to reset its state
    await _player.stop();
    
    // Clear the cached stream URL to force a fresh fetch
    _streamingServer.clearCache(track.id);
    
    // Show buffering state
    _bufferingController.add(true);
    
    try {
      // Pre-fetch a fresh stream URL
      final success = await _streamingServer.prefetchStream(track.id);
      if (!success) {
        print('AudioPlayer: Failed to refresh stream, trying full reload');
        _bufferingController.add(false);
        // Fall back to full track reload
        await _playCurrentTrack();
        return;
      }
      
      // Get fresh stream URL and play
      final streamUrl = _streamingServer.getStreamUrl(track.id);
      await _player.open(Media(streamUrl), play: true);
      
      // Wait for stream to be ready then seek to position
      int attempts = 0;
      while (_player.state.duration == Duration.zero && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // Seek back to where we were
      if (position.inSeconds > 0) {
        print('AudioPlayer: Seeking to ${position.inSeconds}s after refresh');
        await _player.seek(position);
      }
      
      print('AudioPlayer: Stream refreshed and resumed successfully');
    } catch (e) {
      print('AudioPlayer: Error refreshing stream: $e');
      _bufferingController.add(false);
    }
  }

  // Store original volume for fade effect restoration
  double _originalVolume = 1.0;
  bool _isFadingOut = false;
  
  /// Pause playback with smooth volume fade out effect
  /// UI reacts instantly, fade runs in background for smooth audio
  Future<void> pause() async {
    if (_isFadingOut) return; // Prevent multiple fade calls
    _isFadingOut = true;
    
    // Store current volume to restore later
    _originalVolume = _player.state.volume / 100.0;
    
    // Run fade-out in background (non-blocking for UI)
    // Don't await - let it run while UI updates immediately
    _fadeOutAndPause();
  }
  
  /// Background fade-out and pause
  Future<void> _fadeOutAndPause() async {
    try {
      // Smooth fade out over 200ms (20 steps of 10ms) for ultra-smooth effect
      const fadeSteps = 20;
      const stepDuration = Duration(milliseconds: 10);
      
      for (int i = fadeSteps - 1; i >= 0; i--) {
        if (!_player.state.playing && !_isFadingOut) break; // Already paused externally
        // Use smooth S-curve (ease in-out) for natural feel
        final t = i / fadeSteps;
        final easedProgress = t < 0.5 
            ? 2 * t * t 
            : 1 - ((-2 * t + 2) * (-2 * t + 2)) / 2;
        await _player.setVolume(easedProgress * _originalVolume * 100);
        await Future.delayed(stepDuration);
      }
      
      // Now pause
      await _player.pause();
      
      // Restore volume immediately (so resume plays at normal volume)
      await _player.setVolume(_originalVolume * 100);
      
      // Save state when pausing so it can be restored on app restart
      await _saveCurrentState();
    } finally {
      _isFadingOut = false;
    }
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
    // Check if player was playing OR buffering (buffering means it's trying to play)
    final wasPlaying = _player.state.playing;
    final wasBuffering = _player.state.buffering;
    final shouldResume = wasPlaying || wasBuffering;
    
    _isSeeking = true;
    _lastSeekTime = DateTime.now();
    _lastSeekTargetPosition = position; // Track target for spurious completion recovery
    print('AudioPlayer: Seeking to ${position.inSeconds}s (wasPlaying: $wasPlaying, wasBuffering: $wasBuffering)');
    
    // Cancel any existing seek timeout
    _seekTimeoutTimer?.cancel();
    
    await _player.seek(position);
    
    // Resume playback if it was playing or buffering before seek
    if (shouldResume) {
      await _player.play();
      
      // Start a timeout to detect stuck seek (buffering doesn't complete)
      _startSeekTimeout(position);
    }
    
    // Give a small delay before allowing completion events again
    Future.delayed(const Duration(milliseconds: 500), () {
      _isSeeking = false;
    });
  }
  
  // Timer to detect stuck seek and auto-recover
  Timer? _seekTimeoutTimer;
  
  /// Start a seek timeout - auto-recover if playback doesn't resume after seek
  void _startSeekTimeout(Duration seekPosition) {
    _seekTimeoutTimer?.cancel();
    
    // Capture current session ID to validate when timer fires
    final expectedSessionId = _playbackSessionId;
    int retryCount = 0;
    const maxRetries = 3;
    
    void scheduleRetry() {
      // Use shorter timeout for first retry (500ms), then 500ms for subsequent
      final timeout = Duration(milliseconds: retryCount == 0 ? 500 : 500);
      
      _seekTimeoutTimer = Timer(timeout, () async {
        // Validate this timeout is for the current session
        if (expectedSessionId != _playbackSessionId) {
          print('AudioPlayer: Ignoring stale seek timeout (session changed)');
          return;
        }
        
        // Check if we're still not playing
        if (!_player.state.playing) {
          retryCount++;
          print('AudioPlayer: Seek stuck, retry $retryCount/$maxRetries - play+seek to ${seekPosition.inSeconds}s');
          
          // Enable seek recovery mode to suppress UI changes
          _isSeekRecovering = true;
          _seekRecoveryTargetPosition = seekPosition;
          
          // Try play() then re-seek to the target position
          await _player.play();
          await _player.seek(seekPosition);
          
          if (retryCount < maxRetries) {
            // Schedule another retry
            scheduleRetry();
          } else {
            // Max retries reached, do full reload (but keep cache - don't clear it)
            _seekTimeoutTimer = Timer(const Duration(milliseconds: 500), () async {
              if (expectedSessionId != _playbackSessionId) return;
              
              if (!_player.state.playing) {
                print('AudioPlayer: All retries failed, reloading track at ${seekPosition.inSeconds}s');
                _bufferingController.add(true);
                // Reload track but DON'T clear cache - just re-open the stream
                await _player.stop();
                await _playCurrentTrackAtPosition(seekPosition);
              } else {
                _isSeekRecovering = false;
                _lastSeekRecoveryTime = DateTime.now();
                print('AudioPlayer: Seek recovery complete after $retryCount retries');
              }
            });
          }
        } else {
          // Playing successfully
          _isSeekRecovering = false;
          _lastSeekRecoveryTime = DateTime.now();
          print('AudioPlayer: Seek recovery complete after $retryCount retries');
        }
      });
    }
    
    // Start the retry loop
    scheduleRetry();
    
    // Cancel timeout and recovery mode if playback starts successfully
    _player.stream.playing.first.then((playing) {
      if (playing && expectedSessionId == _playbackSessionId) {
        _seekTimeoutTimer?.cancel();
        _seekTimeoutTimer = null;
        // Clear seek recovery mode when playback resumes
        if (_isSeekRecovering) {
          _isSeekRecovering = false;
          _lastSeekRecoveryTime = DateTime.now();
          print('AudioPlayer: Seek recovery complete, playback resumed');
        }
      }
    });
  }

  /// Skip to next track
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    // Increment session ID to cancel any pending track loads
    _playbackSessionId++;
    print('AudioPlayer: skipToNext - new session $_playbackSessionId');
    
    // Cancel any pending timeouts and recovery state from previous track
    _cancelBufferingTimeout();
    _seekTimeoutTimer?.cancel();
    _isSeekRecovering = false;
    _lastSeekRecoveryTime = null;
    _lastSeekTargetPosition = Duration.zero;
    _resetAutoRetry();
    
    // Stop current playback immediately
    await _player.stop();

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
  /// If [forceSkip] is true, always go to previous track (used for swipe gesture)
  /// If false (default), restart current track if more than 3 seconds in (used for button)
  Future<void> skipToPrevious({bool forceSkip = false}) async {
    if (_queue.isEmpty) return;

    // If more than 3 seconds in and not forcing skip, restart current track
    if (!forceSkip && _player.state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    // Increment session ID to cancel any pending track loads
    _playbackSessionId++;
    print('AudioPlayer: skipToPrevious - new session $_playbackSessionId');
    
    // Cancel any pending timeouts and recovery state from previous track
    _cancelBufferingTimeout();
    _seekTimeoutTimer?.cancel();
    _isSeekRecovering = false;
    _lastSeekRecoveryTime = null;
    _lastSeekTargetPosition = Duration.zero;
    _resetAutoRetry();
    
    // Stop current playback immediately
    await _player.stop();

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
    
    // Increment session ID to cancel any pending track loads
    _playbackSessionId++;
    print('AudioPlayer: skipToIndex($index) - new session $_playbackSessionId');
    
    // Cancel any pending timeouts and recovery state from previous track
    _cancelBufferingTimeout();
    _seekTimeoutTimer?.cancel();
    _isSeekRecovering = false;
    _lastSeekRecoveryTime = null;
    _lastSeekTargetPosition = Duration.zero;
    _resetAutoRetry();
    
    // Stop current playback immediately
    await _player.stop();
    
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

  /// Prefetch next track in background for faster loading
  void _prefetchNextTrack() {
    if (_queue.isEmpty) return;
    
    // Prefetch multiple upcoming tracks (up to 3) for smoother playback
    _prefetchUpcomingTracks(count: 3);
  }
  
  /// Prefetch multiple upcoming tracks in background
  /// This ensures next songs start instantly without loading or buffering
  /// Prefetches and caches to disk for instant playback
  void _prefetchUpcomingTracks({int count = 3}) {
    if (_queue.isEmpty) return;
    
    final sessionId = _playbackSessionId;
    final indicesToPrefetch = <int>[];
    
    // Calculate which indices to prefetch - get next N tracks
    if (_isShuffled && _shuffledIndices.isNotEmpty) {
      final currentShuffleIndex = _shuffledIndices.indexOf(_currentIndex);
      for (int offset = 1; offset <= count; offset++) {
        final nextShuffleIndex = currentShuffleIndex + offset;
        if (nextShuffleIndex >= _shuffledIndices.length) break;
        indicesToPrefetch.add(_shuffledIndices[nextShuffleIndex]);
      }
    } else {
      for (int offset = 1; offset <= count; offset++) {
        final nextIndex = _currentIndex + offset;
        if (nextIndex >= _queue.length) break;
        indicesToPrefetch.add(nextIndex);
      }
    }
    
    if (indicesToPrefetch.isEmpty) return;
    
    print('AudioPlayer: Prefetching next ${indicesToPrefetch.length} tracks in background');
    
    // Prefetch each track in sequence (to avoid overwhelming the network)
    _prefetchTracksSequentially(indicesToPrefetch, sessionId);
  }
  
  /// Prefetch tracks one by one to avoid network congestion
  /// Downloads and caches each track to disk for instant playback
  Future<void> _prefetchTracksSequentially(List<int> indices, int sessionId) async {
    for (int i = 0; i < indices.length; i++) {
      final index = indices[i];
      
      // Check if session is still valid
      if (sessionId != _playbackSessionId) {
        print('AudioPlayer: Prefetch cancelled - session changed');
        return;
      }
      
      if (index < 0 || index >= _queue.length) continue;
      
      var track = _queue[index];
      
      // Yield to UI thread before each prefetch operation
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if track needs YouTube matching first
      if (track.id.length != 11) {
        print('AudioPlayer: Prefetch [${i + 1}/${indices.length}] - matching: ${track.title}');
        final matchedTrack = await _matchTrackToYouTube(track);
        if (matchedTrack != null && sessionId == _playbackSessionId) {
          _queue[index] = matchedTrack;
          _queueController.add(_queue);
          track = matchedTrack;
        } else {
          print('AudioPlayer: Prefetch - failed to match: ${track.title}');
          continue;
        }
      }
      
      // Skip if already cached on disk
      final isCached = await _streamingServer.isAudioCached(track.id);
      if (isCached) {
        print('AudioPlayer: Prefetch [${i + 1}/${indices.length}] - already cached: ${track.title}');
        continue;
      }
      
      // Prefetch and cache to disk
      print('AudioPlayer: Prefetch [${i + 1}/${indices.length}] - downloading: ${track.title}');
      await _streamingServer.prefetchAndCacheTrack(track.id);
      
      // Yield to UI thread after each prefetch to prevent frame drops
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    print('AudioPlayer: Prefetch complete');
  }

  /// Restore last played track from saved state (call on app startup)
  /// Returns true if a track was restored
  Future<bool> restoreLastPlayedTrack() async {
    try {
      await _playbackStateService.init();
      
      if (!_playbackStateService.hasSavedState()) {
        print('AudioPlayer: No saved state to restore');
        return false;
      }
      
      final savedState = _playbackStateService.getSavedState();
      if (savedState == null || savedState.track == null) {
        return false;
      }
      
      final track = savedState.track!;
      final position = savedState.position;
      final queue = savedState.queue;
      final queueIndex = savedState.queueIndex;
      
      print('AudioPlayer: Restoring "${track.title}" at ${position.inSeconds}s');
      
      // Restore queue if available
      if (queue != null && queue.isNotEmpty) {
        _queue.clear();
        _queue.addAll(queue);
        _currentIndex = queueIndex.clamp(0, queue.length - 1);
        _queueController.add(_queue);
      } else {
        // Just restore single track
        _queue.clear();
        _queue.add(track);
        _currentIndex = 0;
        _queueController.add(_queue);
      }
      
      // Update UI with restored track (but don't start playing)
      _currentTrackController.add(track);
      
      // Update lock screen notification
      await _audioHandler?.setCurrentTrack(track);
      
      // Store the position to seek to when user presses play
      _restoredPosition = position;
      _isRestoredTrackPending = true; // Mark that we have a pending restored track
      
      // Store and emit the restored position and duration to UI so progress bar shows correctly
      _lastKnownPosition = position;
      _lastKnownDuration = track.duration;
      _positionController.add(position);
      _durationController.add(track.duration);
      
      print('AudioPlayer: Restored state - ready to resume from ${position.inSeconds}s');
      return true;
    } catch (e) {
      print('AudioPlayer: Error restoring state: $e');
      return false;
    }
  }
  
  // Position to seek to after restoration
  Duration? _restoredPosition;
  
  // Flag to track if we have a restored track that hasn't been loaded into player yet
  bool _isRestoredTrackPending = false;
  
  /// Resume playback from restored position
  Future<void> resumeFromRestored() async {
    if (currentTrack == null) {
      print('AudioPlayer: No current track to resume');
      return;
    }
    
    final seekPosition = _restoredPosition;
    _restoredPosition = null; // Clear so it only seeks once
    _isRestoredTrackPending = false; // Mark as no longer pending
    
    if (seekPosition != null && seekPosition.inSeconds > 0) {
      print('AudioPlayer: Resuming from restored position ${seekPosition.inSeconds}s');
      // Play the track with the saved position
      await _playCurrentTrackAtPosition(seekPosition);
    } else {
      print('AudioPlayer: Resuming restored track from beginning');
      await _playCurrentTrack();
    }
  }
  
  /// Play current track and seek to a specific position once loaded
  Future<void> _playCurrentTrackAtPosition(Duration startPosition) async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    // Capture the current session ID
    final currentSessionId = _playbackSessionId;
    
    var track = _queue[_currentIndex];
    
    // Check if track needs YouTube matching (Spotify ID is not 11 chars)
    if (track.id.length != 11) {
      print('AudioPlayer: Track "${track.title}" has non-YouTube ID, matching...');
      final matchedTrack = await _matchTrackToYouTube(track);
      if (matchedTrack != null) {
        track = matchedTrack;
        _queue[_currentIndex] = track;
        _queueController.add(_queue);
      } else {
        print('AudioPlayer: Failed to match track to YouTube');
        return;
      }
    }
    
    // Check if session changed during matching
    if (currentSessionId != _playbackSessionId) {
      print('AudioPlayer: Session changed during track matching, aborting...');
      return;
    }
    
    print('AudioPlayer: Playing track at position ${startPosition.inSeconds}s: ${track.title}');
    _currentTrackController.add(track);
    _bufferingController.add(true);
    
    // Initialize audio handler if needed
    if (_audioHandler == null) {
      await initAudioHandler();
    }
    await _audioHandler?.setCurrentTrack(track);
    _audioHandler?.updateBuffering(true);
    
    // Record play start for history
    _recordPlayTime();
    _currentPlayingId = track.id;
    _playStartTime = DateTime.now();
    await _historyService.recordPlayStart(track);

    try {
      await _streamingServer.start();
      
      // Check if cached
      final isCached = await _streamingServer.isAudioCached(track.id);
      
      if (!isCached) {
        // Pre-fetch stream first
        print('AudioPlayer: Pre-fetching stream...');
        final success = await _streamingServer.prefetchStream(track.id);
        if (!success) {
          print('AudioPlayer: Failed to pre-fetch stream');
          throw Exception('Failed to pre-fetch stream');
        }
      }
      
      // Check if session changed
      if (currentSessionId != _playbackSessionId) {
        print('AudioPlayer: Session changed during prefetch, aborting...');
        return;
      }
      
      final streamUrl = _streamingServer.getStreamUrl(track.id);
      print('AudioPlayer: Opening media at $streamUrl');
      
      // Open the media and start playing
      await _player.open(Media(streamUrl), play: true);
      
      // Wait for duration to be available (indicates stream is ready)
      int attempts = 0;
      while (_player.state.duration == Duration.zero && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // Now seek to the saved position
      print('AudioPlayer: Seeking to ${startPosition.inSeconds}s (duration: ${_player.state.duration.inSeconds}s)');
      await _player.seek(startPosition);
      
      print('AudioPlayer: Playback started at ${startPosition.inSeconds}s');
      
      // Clear seek recovery mode - playback successfully resumed
      if (_isSeekRecovering) {
        _isSeekRecovering = false;
        _lastSeekRecoveryTime = DateTime.now(); // Track recovery time to ignore spurious completions
        print('AudioPlayer: Seek recovery complete');
      }
      
      _prefetchNextTrack();
    } catch (e) {
      print('AudioPlayer: Error playing track at position: $e');
      _isSeekRecovering = false; // Clear recovery mode on error
      _bufferingController.add(false);
      // Fallback to regular playback
      await _playCurrentTrack();
    }
  }
  
  /// Check if there's a restored track ready to play (track restored but not yet loaded into player)
  bool get hasRestoredTrack => _isRestoredTrackPending;
  
  /// Reload current track at a specific position with a fresh stream
  /// Used when spurious completion is detected (e.g., incomplete cache file)
  Future<void> _reloadCurrentTrackAtPosition(Duration position) async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    
    final track = _queue[_currentIndex];
    print('AudioPlayer: Reloading track "${track.title}" at ${position.inSeconds}s with fresh stream');
    
    // Enable seek recovery mode to suppress UI changes during reload
    _isSeekRecovering = true;
    _seekRecoveryTargetPosition = position;
    _bufferingController.add(true);
    
    // Clear the potentially corrupted cache for this track
    await _streamingServer.clearCachedStream(track.id);
    
    // Stop current playback
    await _player.stop();
    
    // Reload with fresh stream
    await _playCurrentTrackAtPosition(position);
  }

  /// Dispose resources
  void dispose() {
    _stateSaveTimer?.cancel();
    _resumeTimeoutTimer?.cancel();
    _seekTimeoutTimer?.cancel();
    _cancelBufferingTimeout();
    _saveCurrentState(); // Save state before disposing
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
