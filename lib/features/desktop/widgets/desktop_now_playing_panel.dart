import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';
import 'package:sangeet/features/lyrics/widgets/lyrics_mini_card.dart';

class DesktopNowPlayingPanel extends ConsumerWidget {
  const DesktopNowPlayingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final panelView = ref.watch(desktopPanelViewProvider);
    final panelWidth = ref.watch(desktopPanelWidthProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Resize handle on the left edge
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final newWidth = panelWidth - details.delta.dx;
              ref.read(desktopPanelWidthProvider.notifier).state = 
                  newWidth.clamp(kMinPanelWidth, kMaxPanelWidth);
            },
            child: Container(
              width: 4,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Panel content
        Container(
          width: panelWidth - 4,
          color: const Color(0xFF121212),
          child: currentTrack.when(
            data: (track) {
              if (track == null) {
                return const SizedBox.shrink();
              }
              // Show queue or now playing based on panel view state
              if (panelView == DesktopPanelView.queue) {
                return const _QueueContent();
              }
              return _NowPlayingContent(track: track);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
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
          
          const Gap(16),
          
          // Lyrics Mini Card
          const LyricsMiniCard(),
          
          const Gap(16),
          
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

class _QueueContent extends ConsumerWidget {
  const _QueueContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
    final audioService = ref.watch(audioPlayerServiceProvider);
    final currentIndex = audioService.currentIndex;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Queue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  audioService.clearQueue();
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Queue List
        Expanded(
          child: queue.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.music_playlist,
                        size: 48,
                        color: Colors.grey.shade700,
                      ),
                      const Gap(16),
                      Text(
                        'Queue is empty',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isCurrentTrack = index == currentIndex;
                  
                  return ListTile(
                    dense: true,
                    onTap: () {
                      audioService.skipToIndex(index);
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: track.thumbnailUrl ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 40,
                          height: 40,
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music, color: Colors.grey, size: 16),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        if (isCurrentTrack) ...[
                          PlayingIndicator(
                            isPlaying: isPlaying,
                            size: 12,
                            color: AppTheme.primaryColor,
                          ),
                          const Gap(6),
                        ],
                        Expanded(
                          child: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCurrentTrack ? AppTheme.primaryColor : Colors.white,
                              fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    trailing: isCurrentTrack
                        ? null
                        : IconButton(
                            onPressed: () {
                              audioService.removeFromQueue(index);
                            },
                            icon: Icon(
                              Iconsax.close_circle,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            visualDensity: VisualDensity.compact,
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
  }
}
