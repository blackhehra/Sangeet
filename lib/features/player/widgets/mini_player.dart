import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/features/player/pages/player_page.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/bluetooth_provider.dart';
import 'package:sangeet/features/player/widgets/device_picker_sheet.dart';
import 'package:sangeet/app.dart' show playerNavigatorKey;
import 'package:sangeet/shared/widgets/marquee_text.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  Widget _buildDeviceButton(BuildContext context, WidgetRef ref) {
    final connectedDeviceAsync = ref.watch(connectedAudioDeviceProvider);
    final hasDevice = connectedDeviceAsync.valueOrNull != null;
    
    return IconButton(
      onPressed: () => _showDevicePicker(context),
      icon: Icon(
        hasDevice ? Iconsax.bluetooth5 : Iconsax.monitor,
        size: 20,
        color: hasDevice ? AppTheme.primaryColor : null,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showDevicePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DevicePickerSheet(),
    );
  }

  void _openFullPlayer(BuildContext context) {
    // Push to the player navigator (renders below bottom nav bar)
    playerNavigatorKey.currentState?.push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) => const PlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final isBuffering = ref.watch(isBufferingProvider);
    
    // Hide mini player when keyboard is visible
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible) return const SizedBox.shrink();

    // Don't show mini player if no track
    return currentTrack.when(
      data: (track) {
        if (track == null) return const SizedBox.shrink();
        
        final positionValue = position.valueOrNull ?? Duration.zero;
        final durationValue = duration.valueOrNull ?? Duration.zero;
        final progress = durationValue.inMilliseconds > 0
            ? positionValue.inMilliseconds / durationValue.inMilliseconds
            : 0.0;
        final playing = isPlaying.valueOrNull ?? false;
        final buffering = isBuffering.valueOrNull ?? false;

        return GestureDetector(
          onTap: () => _openFullPlayer(context),
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              // Swipe up to open full player
              if (details.primaryVelocity! < -300) {
                _openFullPlayer(context);
              }
              // Swipe down to clear track and close mini player
              else if (details.primaryVelocity! > 300) {
                final audioService = ref.read(audioPlayerServiceProvider);
                audioService.stop();
                audioService.clearQueue();
              }
            }
          },
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3E3E3E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 2,
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Album Art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: track.thumbnailUrl ?? '',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                            memCacheHeight: 720,
                            // Fallback to hqdefault if maxresdefault fails
                            errorWidget: (context, url, error) => CachedNetworkImage(
                              imageUrl: url.contains('maxresdefault.jpg') 
                                  ? url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg')
                                  : url,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
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
                        
                        // Track Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
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
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  pauseDuration: const Duration(seconds: 2),
                                  velocityFactor: const Duration(milliseconds: 50),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Buffering indicator or device icon
                            if (buffering)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              )
                            else
                              _buildDeviceButton(context, ref),
                            
                            // Play/Pause
                            IconButton(
                              onPressed: () {
                                final audioService = ref.read(audioPlayerServiceProvider);
                                // Check if this is a restored track that needs special handling
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
