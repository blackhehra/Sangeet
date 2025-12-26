import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/models/track.dart';

class DesktopNowPlayingPanel extends ConsumerWidget {
  const DesktopNowPlayingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);

    return Container(
      width: 280,
      color: const Color(0xFF121212),
      child: currentTrack.when(
        data: (track) {
          if (track == null) {
            return const SizedBox.shrink();
          }
          return _NowPlayingContent(track: track);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.music,
            size: 48,
            color: Colors.grey.shade700,
          ),
          const Gap(16),
          Text(
            'No track playing',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingContent extends StatelessWidget {
  final Track track;

  const _NowPlayingContent({required this.track});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  track.album ?? 'Now Playing',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.more, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          
          const Gap(16),
          
          // Album Art
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                memCacheWidth: 560,
                memCacheHeight: 560,
                errorWidget: (context, url, error) {
                  // Try hqdefault if maxresdefault fails
                  if (url.contains('maxresdefault.jpg')) {
                    return CachedNetworkImage(
                      imageUrl: url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg'),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Iconsax.music, color: Colors.grey, size: 64),
                      ),
                    );
                  }
                  return Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, color: Colors.grey, size: 64),
                  );
                },
              ),
            ),
          ),
          
          const Gap(16),
          
          // Track Title
          Text(
            track.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Gap(4),
          
          // Artist
          Text(
            track.artist,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Gap(24),
          
          // About the artist section
          const Text(
            'About the artist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const Gap(12),
          
          // Artist info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Artist avatar
                ClipOval(
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.darkCardHover,
                    child: const Icon(Iconsax.user, color: Colors.grey),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.artist,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        'Artist',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Gap(24),
          
          // Credits section
          if (track.album != null) ...[
            const Text(
              'Credits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            
            const Gap(12),
            
            _CreditItem(
              label: 'Album',
              value: track.album!,
            ),
            
            if (track.artist.isNotEmpty)
              _CreditItem(
                label: 'Artist',
                value: track.artist,
              ),
          ],
          
          const Gap(100), // Bottom padding for player bar
        ],
      ),
    );
  }
}

class _CreditItem extends StatelessWidget {
  final String label;
  final String value;

  const _CreditItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
