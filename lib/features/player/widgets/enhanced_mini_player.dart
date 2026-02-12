import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/bluetooth_provider.dart';
import 'package:sangeet/shared/providers/player_dismiss_provider.dart';
import 'package:sangeet/features/player/widgets/device_picker_sheet.dart';
import 'package:sangeet/services/album_color_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/widgets/marquee_text.dart';

/// Enhanced Mini Player with:
/// - Swipe left/right for next/previous track
/// - Dynamic color theming based on album art
/// - Smooth animations
class EnhancedMiniPlayer extends ConsumerStatefulWidget {
  const EnhancedMiniPlayer({super.key});

  @override
  ConsumerState<EnhancedMiniPlayer> createState() => _EnhancedMiniPlayerState();
}

class _EnhancedMiniPlayerState extends ConsumerState<EnhancedMiniPlayer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  AlbumColors _currentColors = AlbumColors.defaultColors;
  String? _lastThumbnailUrl;
  
  late AnimationController _colorAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  Color _previousColor = const Color(0xFF3E3E3E);
  Color _targetColor = const Color(0xFF3E3E3E);
  
  // Width of the track info area for calculating swipe positions
  double _trackInfoWidth = 200.0;

  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _backgroundColorAnimation = ColorTween(
      begin: _previousColor,
      end: _targetColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  Future<void> _updateColors(String? thumbnailUrl) async {
    if (thumbnailUrl == null || thumbnailUrl == _lastThumbnailUrl) return;
    _lastThumbnailUrl = thumbnailUrl;

    final colors = await AlbumColorService.instance.getColorsForImage(thumbnailUrl);
    
    if (mounted) {
      setState(() {
        _previousColor = _targetColor;
        _targetColor = colors.miniPlayerBackground;
        _currentColors = colors;
        
        _backgroundColorAnimation = ColorTween(
          begin: _previousColor,
          end: _targetColor,
        ).animate(CurvedAnimation(
          parent: _colorAnimationController,
          curve: Curves.easeInOut,
        ));
      });
      
      _colorAnimationController.forward(from: 0);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final audioService = ref.read(audioPlayerServiceProvider);
    
    // Swipe threshold
    const threshold = 100.0;
    const velocityThreshold = 500.0;
    
    if (_dragOffset < -threshold || velocity < -velocityThreshold) {
      // Swipe left -> Next track
      audioService.skipToNext();
    } else if (_dragOffset > threshold || velocity > velocityThreshold) {
      // Swipe right -> Previous track
      audioService.skipToPrevious();
    }
    
    // Reset drag state - the track change will update the UI
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
  }
  
  /// Get the track at a specific offset from current
  Track? _getTrackAtOffset(int offset) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final queue = audioService.queue;
    final currentIndex = audioService.currentIndex;
    final targetIndex = currentIndex + offset;
    
    if (targetIndex >= 0 && targetIndex < queue.length) {
      return queue[targetIndex];
    }
    return null;
  }
  
  /// Build track info widget (title + artist)
  Widget _buildTrackInfo(Track track) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarqueeText(
          text: track.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
          pauseDuration: const Duration(seconds: 2),
          velocityFactor: const Duration(milliseconds: 50),
        ),
        const Gap(2),
        MarqueeText(
          text: track.artist,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          pauseDuration: const Duration(seconds: 2),
          velocityFactor: const Duration(milliseconds: 50),
        ),
      ],
    );
  }

  void _openFullPlayer(WidgetRef ref) {
    final panelController = ref.read(playerPanelControllerProvider);
    panelController.open();
  }

  void _showDevicePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DevicePickerSheet(),
    );
  }

  Widget _buildDeviceButton(BuildContext context, WidgetRef ref) {
    final connectedDeviceAsync = ref.watch(connectedAudioDeviceProvider);
    final hasDevice = connectedDeviceAsync.valueOrNull != null;
    
    return IconButton(
      onPressed: () => _showDevicePicker(context),
      icon: Padding(
        padding: EdgeInsets.only(left: hasDevice ? 4 : 0),
        child: Icon(
          hasDevice ? Iconsax.bluetooth5 : Iconsax.monitor,
          size: 20,
          color: hasDevice ? AppTheme.primaryColor : Colors.white70,
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final isBuffering = ref.watch(isBufferingProvider);
    
    // Hide mini player when keyboard is visible
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible) return const SizedBox.shrink();

    return currentTrack.when(
      data: (track) {
        if (track == null) return const SizedBox.shrink();
        
        // Update colors when track changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateColors(track.thumbnailUrl);
        });
        
        final positionValue = position.valueOrNull ?? Duration.zero;
        final durationValue = duration.valueOrNull ?? Duration.zero;
        final progress = durationValue.inMilliseconds > 0
            ? positionValue.inMilliseconds / durationValue.inMilliseconds
            : 0.0;
        final playing = isPlaying.valueOrNull ?? false;
        final buffering = isBuffering.valueOrNull ?? false;

        return GestureDetector(
          onTap: () => _openFullPlayer(ref),
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -300) {
                _openFullPlayer(ref);
              } else if (details.primaryVelocity! > 300) {
                final audioService = ref.read(audioPlayerServiceProvider);
                audioService.stop();
                audioService.clearQueue();
              }
            }
          },
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: AnimatedBuilder(
            animation: _colorAnimationController,
            builder: (context, child) {
              return AnimatedContainer(
                  duration: _isDragging 
                      ? Duration.zero 
                      : const Duration(milliseconds: 200),
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        (_backgroundColorAnimation.value ?? _targetColor),
                        (_backgroundColorAnimation.value ?? _targetColor).withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (_backgroundColorAnimation.value ?? _targetColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                );
            },
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    minHeight: 2,
                  ),
                ),
                
                // Content
                Expanded(
                  child: Stack(
                    children: [
                      // Swipe indicators
                      if (_isDragging) ...[
                        // Left indicator (next)
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: _dragOffset < -30 ? 1.0 : 0.0,
                            child: const Center(
                              child: Icon(
                                Iconsax.next5,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        // Right indicator (previous)
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: _dragOffset > 30 ? 1.0 : 0.0,
                            child: const Center(
                              child: Icon(
                                Iconsax.previous5,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            // Album Art with animation
                            Hero(
                              tag: 'album_art_${track.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: track.thumbnailUrl ?? '',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 96,
                                  memCacheHeight: 96,
                                  errorWidget: (context, url, error) => Container(
                                    width: 48,
                                    height: 48,
                                    color: AppTheme.darkCard,
                                    child: const Icon(Iconsax.music, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            
                            const Gap(12),
                            
                            // Track Info with Spotify-like swipe animation
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    _trackInfoWidth = constraints.maxWidth;
                                    
                                    // Get adjacent tracks for the swipe preview
                                    final nextTrack = _getTrackAtOffset(1);
                                    final prevTrack = _getTrackAtOffset(-1);
                                    
                                    return ClipRect(
                                      child: Stack(
                                        children: [
                                          // Previous track (slides in from left when swiping right)
                                          if (prevTrack != null && _isDragging && _dragOffset > 0)
                                            Positioned(
                                              left: _dragOffset - _trackInfoWidth,
                                              top: 0,
                                              bottom: 0,
                                              width: _trackInfoWidth,
                                              child: _buildTrackInfo(prevTrack),
                                            ),
                                          
                                          // Next track (slides in from right when swiping left)
                                          if (nextTrack != null && _isDragging && _dragOffset < 0)
                                            Positioned(
                                              left: _trackInfoWidth + _dragOffset,
                                              top: 0,
                                              bottom: 0,
                                              width: _trackInfoWidth,
                                              child: _buildTrackInfo(nextTrack),
                                            ),
                                          
                                          // Current track
                                          Transform.translate(
                                            offset: Offset(_isDragging ? _dragOffset : 0, 0),
                                            child: _buildTrackInfo(track),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // Controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (buffering)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  _buildDeviceButton(context, ref),
                                
                                // Play/Pause
                                IconButton(
                                  onPressed: () {
                                    final audioService = ref.read(audioPlayerServiceProvider);
                                    if (audioService.hasRestoredTrack && !playing) {
                                      audioService.resumeFromRestored();
                                    } else {
                                      audioService.togglePlayPause();
                                    }
                                  },
                                  icon: Icon(
                                    playing ? Iconsax.pause5 : Iconsax.play5,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
