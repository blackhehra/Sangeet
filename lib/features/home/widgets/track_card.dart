import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';

class TrackCard extends ConsumerWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;

  const TrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.onPlayTap,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get high quality YouTube thumbnail URL
  /// URL is already maxresdefault from service, just return it
  String _getHighQualityThumbnail(String url) {
    return url;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final isCurrentTrack = currentTrack?.id == track.id;
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            Stack(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _getHighQualityThumbnail(track.thumbnailUrl!),
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                            memCacheHeight: 720,
                            fadeInDuration: const Duration(milliseconds: 200),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppTheme.darkCard,
                              highlightColor: AppTheme.darkCardHover,
                              child: Container(
                                color: AppTheme.darkCard,
                              ),
                            ),
                            // Fallback to hqdefault if maxresdefault fails
                            errorWidget: (context, url, error) => CachedNetworkImage(
                              imageUrl: url.contains('maxresdefault.jpg') 
                                  ? url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg')
                                  : url,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.darkCard,
                                child: const Icon(
                                  Iconsax.music,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.darkCard,
                            child: const Icon(
                              Iconsax.music,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                // Duration badge
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(track.duration),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Play button or playing indicator
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: onPlayTap ?? onTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isCurrentTrack
                          ? PlayingIndicator(
                              isPlaying: isPlaying,
                              size: 16,
                              color: Colors.black,
                            )
                          : const Icon(
                              Iconsax.play5,
                              color: Colors.black,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title with playing indicator
            Row(
              children: [
                if (isCurrentTrack) ...[
                  PlayingIndicator(
                    isPlaying: isPlaying,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isCurrentTrack ? AppTheme.primaryColor : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Artist
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
    );
  }
}
