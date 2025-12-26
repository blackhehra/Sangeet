import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:sangeet/models/track.dart';

class SangeetAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioSession? session;
  
  Function()? onPlayPressed;
  Function()? onPausePressed;
  Function()? onSkipNext;
  Function()? onSkipPrevious;
  Function(Duration)? onSeek;
  Function()? onTaskRemovedCallback;
  
  // Current state tracking
  bool _isPlaying = false;
  bool _wasPlayingBeforeInterruption = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;

  SangeetAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Initialize audio session with explicit music configuration
    session = await AudioSession.instance;
    await session?.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
        flags: AndroidAudioFlags.none,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    
    // Handle audio interruptions (phone calls, notifications, etc.)
    session?.interruptionEventStream.listen((event) {
      if (event.begin) {
        // Interruption started
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Lower volume (handled by system)
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Remember if we were playing before interruption
            _wasPlayingBeforeInterruption = _isPlaying;
            onPausePressed?.call();
            break;
        }
      } else {
        // Interruption ended - only resume if we were playing before
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Restore volume (handled by system)
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Only resume if user was actively playing before interruption
            if (_wasPlayingBeforeInterruption) {
              onPlayPressed?.call();
            }
            _wasPlayingBeforeInterruption = false;
            break;
        }
      }
    });
    
    // Handle headphone disconnect
    session?.becomingNoisyEventStream.listen((_) {
      onPausePressed?.call();
    });
    
    // Set initial playback state
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  /// Set the media item shown in notification/lock screen
  Future<void> setCurrentTrack(Track track) async {
    // Activate audio session
    await session?.setActive(true);
    
    final item = MediaItem(
      id: track.id,
      album: track.album ?? 'Unknown Album',
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: track.thumbnailUrl != null ? Uri.parse(track.thumbnailUrl!) : null,
      playable: true,
    );
    mediaItem.add(item);
    
    // Update playback state to show notification
    _updatePlaybackState();
  }

  /// Update playback state based on current values
  void _updatePlaybackState() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      playing: _isPlaying,
      updatePosition: _position,
      bufferedPosition: _bufferedPosition,
      processingState: _isBuffering 
          ? AudioProcessingState.loading 
          : AudioProcessingState.ready,
    ));
  }

  /// Update playing state
  void updatePlaying(bool playing) {
    _isPlaying = playing;
    if (playing) {
      session?.setActive(true);
    }
    _updatePlaybackState();
  }

  /// Update position
  void updatePosition(Duration position) {
    _position = position;
    _updatePlaybackState();
  }

  /// Update buffered position
  void updateBufferedPosition(Duration bufferedPosition) {
    _bufferedPosition = bufferedPosition;
    _updatePlaybackState();
  }

  /// Update buffering state
  void updateBuffering(bool buffering) {
    _isBuffering = buffering;
    _updatePlaybackState();
  }

  @override
  Future<void> play() async {
    onPlayPressed?.call();
  }

  @override
  Future<void> pause() async {
    onPausePressed?.call();
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    playbackState.add(PlaybackState(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await session?.setActive(false);
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    onSeek?.call(position);
  }

  @override
  Future<void> skipToNext() async {
    onSkipNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipPrevious?.call();
  }
  
  @override
  Future<void> onTaskRemoved() async {
    // Stop the actual player when app is removed from recents
    onTaskRemovedCallback?.call();
    await stop();
  }
}
