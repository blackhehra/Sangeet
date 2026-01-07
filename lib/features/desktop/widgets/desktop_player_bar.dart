import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/quick_picks_provider.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/features/player/pages/player_page.dart';
import 'package:sangeet/features/desktop/pages/desktop_full_player.dart';

bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class DesktopPlayerBar extends ConsumerStatefulWidget {
  const DesktopPlayerBar({super.key});

  @override
  ConsumerState<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends ConsumerState<DesktopPlayerBar> {
  double _volume = 1.0;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final isBuffering = ref.watch(isBufferingProvider);
    final audioService = ref.watch(audioPlayerServiceProvider);

    return Container(
      height: 90,
      color: const Color(0xFF181818),
      child: currentTrack.when(
        data: (track) {
          if (track == null) {
            return const _EmptyPlayerBar();
          }

          final positionValue = position.valueOrNull ?? Duration.zero;
          final durationValue = duration.valueOrNull ?? Duration.zero;
          final progress = durationValue.inMilliseconds > 0
              ? positionValue.inMilliseconds / durationValue.inMilliseconds
              : 0.0;
          final playing = isPlaying.valueOrNull ?? false;
          final buffering = isBuffering.valueOrNull ?? false;

          return Column(
            children: [
              // Progress slider at top
              SizedBox(
                height: 4,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.grey.shade800,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * durationValue.inMilliseconds).toInt(),
                      );
                      audioService.seek(newPosition);
                    },
                  ),
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Left: Track info
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            // Album art
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: track.thumbnailUrl ?? '',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) {
                                  if (url.contains('maxresdefault.jpg')) {
                                    return CachedNetworkImage(
                                      imageUrl: url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg'),
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: AppTheme.darkCard,
                                        child: const Icon(Iconsax.music, color: Colors.grey),
                                      ),
                                    );
                                  }
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    color: AppTheme.darkCard,
                                    child: const Icon(Iconsax.music, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Gap(2),
                                  Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(8),
                            Builder(
                              builder: (context) {
                                final historyService = ref.watch(playHistoryServiceProvider);
                                final isLiked = historyService.isLiked(track.id);
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: IconButton(
                                    onPressed: () async {
                                      await historyService.toggleLike(track);
                                      // Refresh local liked songs provider
                                      ref.read(localLikedSongsRefreshProvider.notifier).state++;
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      isLiked ? Iconsax.heart5 : Iconsax.heart,
                                      size: 20,
                                      color: isLiked ? AppTheme.primaryColor : null,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Center: Playback controls
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Shuffle
                                IconButton(
                                  onPressed: () => audioService.toggleShuffle(),
                                  icon: Icon(
                                    Iconsax.shuffle,
                                    size: 20,
                                    color: audioService.isShuffled 
                                        ? AppTheme.primaryColor 
                                        : Colors.grey,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Gap(8),
                                
                                // Previous
                                IconButton(
                                  onPressed: () => audioService.skipToPrevious(),
                                  icon: const Icon(Iconsax.previous, size: 24),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Gap(8),
                                
                                // Play/Pause
                                if (buffering)
                                  const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        // Handle restored track - resume from saved position
                                        if (audioService.hasRestoredTrack && !playing) {
                                          audioService.resumeFromRestored();
                                        } else {
                                          audioService.togglePlayPause();
                                        }
                                      },
                                      icon: Icon(
                                        playing ? Icons.pause : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                const Gap(8),
                                
                                // Next
                                IconButton(
                                  onPressed: () => audioService.skipToNext(),
                                  icon: const Icon(Iconsax.next, size: 24),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Gap(8),
                                
                                // Repeat
                                IconButton(
                                  onPressed: () => audioService.cycleRepeatMode(),
                                  icon: Icon(
                                    audioService.repeatMode == RepeatMode.one
                                        ? Iconsax.repeate_one
                                        : Iconsax.repeat,
                                    size: 20,
                                    color: audioService.repeatMode != RepeatMode.off
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const Gap(4),
                            // Time display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDuration(positionValue),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                                const Gap(8),
                                SizedBox(
                                  width: 300,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.grey.shade700,
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: progress.clamp(0.0, 1.0),
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                          milliseconds: (value * durationValue.inMilliseconds).toInt(),
                                        );
                                        audioService.seek(newPosition);
                                      },
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  _formatDuration(durationValue),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Right: Volume and other controls
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Now playing view toggle
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Iconsax.music_playlist, size: 20),
                              visualDensity: VisualDensity.compact,
                              color: Colors.grey,
                            ),
                            
                            // Device picker
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Iconsax.monitor, size: 20),
                              visualDensity: VisualDensity.compact,
                              color: Colors.grey,
                            ),
                            
                            // Volume
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_volume > 0) {
                                      _volume = 0;
                                    } else {
                                      _volume = 1.0;
                                    }
                                    audioService.setVolume(_volume);
                                  });
                                },
                                child: Icon(
                                  _volume == 0 
                                      ? Iconsax.volume_slash 
                                      : _volume < 0.5 
                                          ? Iconsax.volume_low 
                                          : Iconsax.volume_high,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const Gap(8),
                            SizedBox(
                              width: 100,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.grey.shade700,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _volume,
                                  onChanged: (value) {
                                    setState(() {
                                      _volume = value;
                                    });
                                    audioService.setVolume(value);
                                  },
                                ),
                              ),
                            ),
                            
                            // Fullscreen / Full Player
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: true,
                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                          _isDesktop ? const DesktopFullPlayer() : const PlayerPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 200),
                                    ),
                                  );
                                },
                                icon: const Icon(Iconsax.maximize_4, size: 20),
                                visualDensity: VisualDensity.compact,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const _EmptyPlayerBar(),
        error: (_, __) => const _EmptyPlayerBar(),
      ),
    );
  }
}

class _EmptyPlayerBar extends StatelessWidget {
  const _EmptyPlayerBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: const Color(0xFF181818),
      child: Center(
        child: Text(
          'No track playing',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
