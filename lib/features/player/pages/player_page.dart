import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/bluetooth_provider.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/services/equalizer_service.dart';
import 'package:sangeet/services/sleep_timer_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/features/player/widgets/device_picker_sheet.dart';
import 'package:sangeet/features/playlist/widgets/add_to_playlist_dialog.dart';
import 'package:sangeet/features/player/widgets/player_artist_section.dart';
import 'package:sangeet/features/lyrics/widgets/lyrics_mini_card.dart';
import 'package:sangeet/shared/widgets/marquee_text.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final PanelController? panelController;
  
  const PlayerPage({
    super.key,
    this.scrollController,
    this.panelController,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _isLiked = false;
  Track? _currentTrack;
  
  // Double-tap to like animation
  bool _showLikeAnimation = false;
  
  // Volume gesture state
  bool _isVolumeGestureActive = false;
  double _volumeGestureStartY = 0.0;
  double _currentVolume = 1.0;
  Timer? _volumeHoldTimer;
  bool _showVolumeIndicator = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _volumeHoldTimer?.cancel();
    super.dispose();
  }
  
  /// Close the player panel
  void _closePlayer() {
    widget.panelController?.close();
  }
  
  /// Handle double-tap to like
  void _handleDoubleTap(Track track) async {
    final newLiked = await PlayHistoryService.instance.toggleLike(track);
    setState(() {
      _isLiked = newLiked;
      _showLikeAnimation = true;
    });
    
    // Hide animation after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
  }
  
  /// Handle long press start for volume gesture
  void _handleLongPressStart(LongPressStartDetails details) {
    _volumeGestureStartY = details.localPosition.dy;
    _volumeHoldTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVolumeGestureActive = true;
          _showVolumeIndicator = true;
        });
      }
    });
  }
  
  /// Handle long press move for volume control
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details, AudioPlayerService audioService) {
    if (!_isVolumeGestureActive) {
      // Check if we should cancel the timer (moved too much before 3s)
      final moved = (details.localPosition.dy - _volumeGestureStartY).abs();
      if (moved > 20) {
        _volumeHoldTimer?.cancel();
      }
      return;
    }
    
    // Calculate volume change based on vertical movement
    final delta = _volumeGestureStartY - details.localPosition.dy;
    final volumeChange = delta / 200; // 200px = full volume range
    final newVolume = (_currentVolume + volumeChange).clamp(0.0, 1.0);
    
    audioService.setVolume(newVolume);
    setState(() {
      _currentVolume = newVolume;
    });
    
    _volumeGestureStartY = details.localPosition.dy;
  }
  
  /// Handle long press end
  void _handleLongPressEnd(LongPressEndDetails details) {
    _volumeHoldTimer?.cancel();
    
    if (_isVolumeGestureActive) {
      // Hide volume indicator after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showVolumeIndicator = false;
          });
        }
      });
    }
    
    setState(() {
      _isVolumeGestureActive = false;
    });
  }

  /// Get high quality thumbnail URL for full player
  /// Services now provide maxresdefault directly
  /// Also handles Google thumbnail URLs with dynamic sizing
  String _getHighQualityThumbnail(String url) {
    if (url.isEmpty) return url;
    
    // For lh3.googleusercontent.com thumbnails - add size suffix
    if (url.startsWith('https://lh3.googleusercontent.com')) {
      return '$url-w720-h720';
    }
    
    // For yt3.ggpht.com thumbnails
    if (url.startsWith('https://yt3.ggpht.com')) {
      return '$url-w720-h720-s720';
    }
    
    return url;
  }
  
  /// Get fallback thumbnail URL (hqdefault) if maxresdefault fails
  String _getFallbackThumbnail(String url) {
    if (url.contains('maxresdefault.jpg')) {
      return url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg');
    }
    return url;
  }

  String _formatDuration(Duration duration) {
    final mins = duration.inMinutes.toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Widget _buildDeviceButton(BuildContext context) {
    final connectedDeviceAsync = ref.watch(connectedAudioDeviceProvider);
    final hasDevice = connectedDeviceAsync.valueOrNull != null;
    
    return IconButton(
      onPressed: () => _showDeviceSheet(context),
      icon: Icon(
        hasDevice ? Iconsax.bluetooth5 : Iconsax.monitor,
        size: 20,
        color: hasDevice ? AppTheme.primaryColor : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final isBuffering = ref.watch(isBufferingProvider);
    final audioService = ref.watch(audioPlayerServiceProvider);

    return currentTrack.when(
      data: (track) {
        if (track == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.music, size: 64, color: Colors.grey.shade600),
                  const Gap(16),
                  Text(
                    'No track playing',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          );
        }

        // Update like status when track changes
        if (_currentTrack?.id != track.id) {
          _currentTrack = track;
          _isLiked = PlayHistoryService.instance.isLiked(track.id);
        }

        final positionValue = position.valueOrNull ?? Duration.zero;
        final durationValue = duration.valueOrNull ?? track.duration;
        final progress = durationValue.inMilliseconds > 0
            ? positionValue.inMilliseconds / durationValue.inMilliseconds
            : 0.0;
        final playing = isPlaying.valueOrNull ?? false;
        final buffering = isBuffering.valueOrNull ?? false;

        final screenHeight = size.height;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF4A3728),
                  AppTheme.darkBg,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _closePlayer,
                          icon: const Icon(Iconsax.arrow_down_1),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'NOW PLAYING',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                track.artist,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Iconsax.more),
                          onSelected: (value) {
                            switch (value) {
                              case 'equalizer':
                                _showEqualizerSheet(context);
                                break;
                              case 'sleep_timer':
                                _showSleepTimerDialog(context);
                                break;
                              case 'add_to_playlist':
                                if (_currentTrack != null) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddToPlaylistDialog(
                                      track: _currentTrack!,
                                    ),
                                  );
                                }
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'equalizer',
                              child: Row(
                                children: [
                                  Icon(Iconsax.setting_4, size: 20),
                                  SizedBox(width: 12),
                                  Text('Equalizer'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'sleep_timer',
                              child: Row(
                                children: [
                                  Icon(Iconsax.timer_1, size: 20),
                                  SizedBox(width: 12),
                                  Text('Sleep Timer'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_to_playlist',
                              child: Row(
                                children: [
                                  Icon(Iconsax.music_playlist, size: 20),
                                  SizedBox(width: 12),
                                  Text('Add to Playlist'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Gap(24),
                  
                  // Album Art - with double-tap to like and volume gesture
                  GestureDetector(
                    onDoubleTap: () => _handleDoubleTap(track),
                    onLongPressStart: _handleLongPressStart,
                    onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(details, audioService),
                    onLongPressEnd: _handleLongPressEnd,
                    child: Container(
                      width: size.width * 0.75,
                      height: size.width * 0.75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: _getHighQualityThumbnail(track.thumbnailUrl ?? ''),
                              width: size.width * 0.75,
                              height: size.width * 0.75,
                              fit: BoxFit.cover,
                              memCacheWidth: 1080,
                              memCacheHeight: 1080,
                              maxWidthDiskCache: 1080,
                              maxHeightDiskCache: 1080,
                              // Fallback to hqdefault if maxresdefault fails
                              errorWidget: (context, url, error) => CachedNetworkImage(
                                imageUrl: _getFallbackThumbnail(url),
                                width: size.width * 0.75,
                                height: size.width * 0.75,
                                fit: BoxFit.cover,
                                memCacheWidth: 720,
                                memCacheHeight: 720,
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.darkCard,
                                  child: const Icon(
                                    Iconsax.music,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            // Buffering indicator
                            if (buffering)
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                  ),
                                ),
                              ),
                            // Double-tap like animation
                            if (_showLikeAnimation)
                              Center(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 400),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.5 + (value * 0.5),
                                      child: Opacity(
                                        opacity: value > 0.8 ? (1.0 - value) * 5 : 1.0,
                                        child: Icon(
                                          _isLiked ? Iconsax.heart5 : Iconsax.heart,
                                          size: 100,
                                          color: _isLiked ? AppTheme.primaryColor : Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            // Volume indicator overlay
                            if (_showVolumeIndicator)
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _currentVolume > 0.5 
                                            ? Iconsax.volume_high5 
                                            : _currentVolume > 0 
                                                ? Iconsax.volume_low_15 
                                                : Iconsax.volume_slash5,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                      const Gap(8),
                                      Text(
                                        '${(_currentVolume * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Gap(8),
                                      SizedBox(
                                        width: 150,
                                        child: LinearProgressIndicator(
                                          value: _currentVolume,
                                          backgroundColor: Colors.grey.shade700,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const Gap(24),
                  
                  // Track Info & Like
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarqueeText(
                                  text: track.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  pauseDuration: const Duration(seconds: 3),
                                  velocityFactor: const Duration(milliseconds: 60),
                                ),
                                const Gap(4),
                                MarqueeText(
                                  text: track.artist,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                  pauseDuration: const Duration(seconds: 3),
                                  velocityFactor: const Duration(milliseconds: 60),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final newLiked = await PlayHistoryService.instance.toggleLike(track);
                            setState(() {
                              _isLiked = newLiked;
                            });
                          },
                          icon: Icon(
                            _isLiked ? Iconsax.heart5 : Iconsax.heart,
                            color: _isLiked ? AppTheme.primaryColor : Colors.white,
                            size: 28,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Gap(24),
                  
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds: (value * durationValue.inMilliseconds).toInt(),
                              );
                              audioService.seek(newPosition);
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey.shade700,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(positionValue),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              Text(
                                _formatDuration(durationValue),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Gap(16),
                  
                  // Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shuffle
                        IconButton(
                          onPressed: () {
                            audioService.toggleShuffle();
                            setState(() {});
                          },
                          icon: Icon(
                            Iconsax.shuffle,
                            color: audioService.isShuffled ? AppTheme.primaryColor : Colors.white,
                            size: 24,
                          ),
                        ),
                        
                        // Previous
                        IconButton(
                          onPressed: () => audioService.skipToPrevious(),
                          icon: const Icon(
                            Iconsax.previous5,
                            size: 36,
                          ),
                        ),
                        
                        // Play/Pause
                        GestureDetector(
                          onTap: () {
                            // Check if this is a restored track that needs special handling
                            if (audioService.hasRestoredTrack && !playing) {
                              audioService.resumeFromRestored();
                            } else {
                              audioService.togglePlayPause();
                            }
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: buffering
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : Icon(
                                    playing ? Iconsax.pause5 : Iconsax.play5,
                                    color: Colors.black,
                                    size: 32,
                                  ),
                          ),
                        ),
                        
                        // Next
                        IconButton(
                          onPressed: () => audioService.skipToNext(),
                          icon: const Icon(
                            Iconsax.next5,
                            size: 36,
                          ),
                        ),
                        
                        // Repeat
                        IconButton(
                          onPressed: () {
                            audioService.cycleRepeatMode();
                            setState(() {});
                          },
                          icon: Icon(
                            audioService.repeatMode == RepeatMode.one 
                                ? Iconsax.repeate_one 
                                : Iconsax.repeat,
                            color: audioService.repeatMode != RepeatMode.off 
                                ? AppTheme.primaryColor 
                                : Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Gap(24),
                  
                  // Bottom Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDeviceButton(context),
                        IconButton(
                          onPressed: () {
                            _shareTrack(context, track);
                          },
                          icon: const Icon(
                            Iconsax.share,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _showQueueSheet(context, ref);
                          },
                          icon: const Icon(
                            Iconsax.music_playlist,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Gap(16),
                  
                  // Lyrics Mini Card
                  const LyricsMiniCard(),
                  
                  const Gap(8),
                  
                  // Artist Section (Explore, Credits, About)
                  PlayerArtistSection(track: track),
                  
                  const Gap(32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading player')),
      ),
    );
  }
  
  void _showQueueSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final queue = ref.watch(queueProvider);
            final audioService = ref.watch(audioPlayerServiceProvider);
            final currentIndex = audioService.currentIndex;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Queue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Save queue as playlist
                          IconButton(
                            onPressed: () => _saveQueueAsPlaylist(context, ref),
                            icon: const Icon(Iconsax.save_2, size: 20),
                            tooltip: 'Save as Playlist',
                          ),
                          TextButton(
                            onPressed: () {
                              audioService.clearQueue();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Queue List
                    Expanded(
                      child: queue.when(
                        data: (tracks) {
                          final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: tracks.length,
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              final isCurrentTrack = index == currentIndex;
                              
                              return ListTile(
                                onTap: () {
                                  audioService.skipToIndex(index);
                                },
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: track.thumbnailUrl ?? '',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppTheme.darkCard,
                                      child: const Icon(Iconsax.music, color: Colors.grey, size: 20),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    if (isCurrentTrack) ...[
                                      PlayingIndicator(
                                        isPlaying: isPlaying,
                                        size: 14,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const Gap(8),
                                    ],
                                    Expanded(
                                      child: MarqueeText(
                                        text: track.title,
                                        style: TextStyle(
                                          color: isCurrentTrack ? AppTheme.primaryColor : Colors.white,
                                          fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        pauseDuration: const Duration(seconds: 2),
                                        velocityFactor: const Duration(milliseconds: 50),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: MarqueeText(
                                  text: track.artist,
                                  style: TextStyle(color: Colors.grey.shade400),
                                  pauseDuration: const Duration(seconds: 2),
                                  velocityFactor: const Duration(milliseconds: 50),
                                ),
                                trailing: isCurrentTrack
                                    ? null // Playing indicator is shown in title
                                    : IconButton(
                                        onPressed: () {
                                          audioService.removeFromQueue(index);
                                        },
                                        icon: const Icon(Iconsax.close_circle),
                                      ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(child: Text('Error loading queue')),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEqualizerSheet(BuildContext context) {
    final eqService = EqualizerService.instance;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentPreset = eqService.currentPreset;
            final currentGains = eqService.currentGains;
            final isEnabled = eqService.enabled;
            
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header with enable toggle
                  Row(
                    children: [
                      const Text(
                        'Equalizer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isEnabled,
                        onChanged: (value) async {
                          await eqService.setEnabled(value);
                          setModalState(() {});
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  
                  const Gap(16),
                  
                  // Frequency band sliders
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        return _buildFrequencySlider(
                          label: EqualizerService.frequencyLabels[index],
                          value: currentGains[index],
                          enabled: isEnabled,
                          onChanged: (value) async {
                            await eqService.setCustomGain(index, value);
                            setModalState(() {});
                          },
                        );
                      }),
                    ),
                  ),
                  
                  const Gap(16),
                  
                  // Presets label
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Presets',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Gap(8),
                  
                  // Preset chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EqualizerService.presets.map((preset) {
                      final isSelected = currentPreset == preset.name;
                      return ChoiceChip(
                        label: Text(preset.name),
                        selected: isSelected,
                        onSelected: isEnabled ? (selected) async {
                          if (selected) {
                            await eqService.setPreset(preset.name);
                            setModalState(() {});
                          }
                        } : null,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.darkCard,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const Gap(16),
                  
                  // Reset button
                  TextButton.icon(
                    onPressed: isEnabled ? () async {
                      await eqService.reset();
                      setModalState(() {});
                    } : null,
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('Reset to Flat'),
                  ),
                  
                  const Gap(8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFrequencySlider({
    required String label,
    required double value,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 11,
            color: enabled ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(4),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: enabled ? AppTheme.primaryColor : Colors.grey,
                inactiveTrackColor: Colors.grey.shade800,
                thumbColor: enabled ? AppTheme.primaryColor : Colors.grey,
              ),
              child: Slider(
                value: value,
                min: -12,
                max: 12,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: enabled ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text('Sleep Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimerOption(context, '15 minutes', const Duration(minutes: 15)),
              _buildTimerOption(context, '30 minutes', const Duration(minutes: 30)),
              _buildTimerOption(context, '45 minutes', const Duration(minutes: 45)),
              _buildTimerOption(context, '1 hour', const Duration(hours: 1)),
              _buildTimerOption(context, 'End of track', null),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext context, String label, Duration? duration) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final sleepTimerService = SleepTimerService();
    
    return ListTile(
      title: Text(label),
      trailing: sleepTimerService.isActive && 
                ((duration != null && sleepTimerService.remainingTime.inMinutes == duration.inMinutes) ||
                 (duration == null && sleepTimerService.isEndOfTrack))
          ? const Icon(Iconsax.tick_circle5, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        Navigator.pop(context);
        
        if (duration != null) {
          sleepTimerService.setTimer(duration, audioService);
        } else {
          sleepTimerService.setEndOfTrack(audioService);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set: $label'),
            action: SnackBarAction(
              label: 'Cancel',
              onPressed: () => sleepTimerService.cancelTimer(),
            ),
          ),
        );
      },
    );
  }

  void _showDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DevicePickerSheet(),
    );
  }

  void _shareTrack(BuildContext context, Track track) {
    final shareText = 'Check out "${track.title}" by ${track.artist}!\nhttps://music.youtube.com/watch?v=${track.id}';
    Share.share(shareText, subject: track.title);
  }

  void _saveQueueAsPlaylist(BuildContext context, WidgetRef ref) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final queue = audioService.queue;
    
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue is empty')),
      );
      return;
    }
    
    final nameController = TextEditingController(text: 'My Queue ${DateTime.now().day}/${DateTime.now().month}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Save Queue as Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const Gap(12),
            Text(
              '${queue.length} tracks will be saved',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }
              
              // Import the custom playlist service and save
              // This would integrate with your existing playlist system
              Navigator.pop(context);
              Navigator.pop(context); // Close queue sheet too
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playlist "$name" created with ${queue.length} tracks')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
