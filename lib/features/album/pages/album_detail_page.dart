import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/song_tile.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/related_page.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/features/sharing/widgets/share_bottom_sheet.dart';

/// Provider for album page
final albumPageProvider = FutureProvider.family<AlbumPage?, String>((ref, browseId) async {
  final innertube = InnertubeService();
  return await innertube.getAlbumPage(browseId);
});

/// Album detail page - shows all songs in an album
class AlbumDetailPage extends ConsumerStatefulWidget {
  final String albumId;
  final String albumName;
  final String? artistName;
  final String? thumbnailUrl;
  final bool isEmbedded; // When true, don't show MiniPlayer (used in desktop shell)

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    required this.albumName,
    this.artistName,
    this.thumbnailUrl,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends ConsumerState<AlbumDetailPage> {
  bool _isPlayingAll = false;

  Future<void> _playTrack(Track track, List<Track> allTracks) async {
    final startIndex = allTracks.indexOf(track);
    final audioService = ref.read(audioPlayerServiceProvider);
    // Album playback - disable auto-queue
    audioService.playAll(allTracks, startIndex: startIndex, source: PlaySource.album);
  }

  Future<void> _playAll(List<Track> tracks) async {
    if (_isPlayingAll || tracks.isEmpty) return;
    
    setState(() => _isPlayingAll = true);
    
    try {
      final audioService = ref.read(audioPlayerServiceProvider);
      // Album playback - disable auto-queue
      audioService.playAll(tracks, source: PlaySource.album);
    } finally {
      if (mounted) setState(() => _isPlayingAll = false);
    }
  }

  Future<void> _shufflePlay(List<Track> tracks) async {
    if (_isPlayingAll || tracks.isEmpty) return;
    
    setState(() => _isPlayingAll = true);
    
    try {
      final shuffled = List<Track>.from(tracks)..shuffle();
      final audioService = ref.read(audioPlayerServiceProvider);
      // Album playback - disable auto-queue
      audioService.playAll(shuffled, source: PlaySource.album);
    } finally {
      if (mounted) setState(() => _isPlayingAll = false);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final albumPageAsync = ref.watch(albumPageProvider(widget.albumId));

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header with album image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                leading: widget.isEmbedded
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          ref.read(desktopNavigationProvider.notifier).clear();
                        },
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.albumName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: widget.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppTheme.darkCard),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music_square, size: 64, color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music_square, size: 64, color: Colors.grey),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Album page content
              albumPageAsync.when(
                data: (albumPage) {
                  final tracks = albumPage?.songs ?? [];
                  final artistName = albumPage?.artist ?? widget.artistName;
                  final otherInfo = albumPage?.otherInfo;

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Artist name and action buttons
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (artistName != null)
                              Text(
                                artistName,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 16,
                                ),
                              ),
                            if (otherInfo != null) ...[
                              const Gap(4),
                              Text(
                                otherInfo,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const Gap(12),
                            Row(
                              children: [
                                Text(
                                  '${tracks.length} songs',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                const Spacer(),
                                // Share button
                                IconButton(
                                  onPressed: tracks.isEmpty ? null : () {
                                    final shareData = ShareService.instance.createAlbumShare(
                                      name: albumPage?.title ?? widget.albumName,
                                      artist: artistName,
                                      tracks: tracks,
                                    );
                                    ShareBottomSheet.show(context, shareData);
                                  },
                                  icon: const Icon(Iconsax.share),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.darkCard,
                                  ),
                                ),
                                const Gap(8),
                                // Shuffle button
                                IconButton(
                                  onPressed: tracks.isEmpty || _isPlayingAll ? null : () => _shufflePlay(tracks),
                                  icon: const Icon(Iconsax.shuffle),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.darkCard,
                                  ),
                                ),
                                const Gap(8),
                                // Play all button
                                FilledButton.icon(
                                  onPressed: tracks.isEmpty || _isPlayingAll ? null : () => _playAll(tracks),
                                  icon: _isPlayingAll
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Iconsax.play5),
                                  label: const Text('Play'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Track list
                      if (tracks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No songs found in this album',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...tracks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final track = entry.value;
                          return SongTile(
                            track: track,
                            index: index,
                            showThumbnail: false,
                            onTap: () => _playTrack(track, tracks),
                          );
                        }),

                      // Bottom padding for mini player
                      const Gap(140),
                    ]),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildLoadingItem(),
                    childCount: 10,
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.warning_2, size: 48, color: Colors.grey),
                        const Gap(16),
                        Text(
                          'Failed to load album',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const Gap(8),
                        TextButton(
                          onPressed: () => ref.invalidate(albumPageProvider(widget.albumId)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Mini player at bottom (only show when not embedded in desktop shell)
        ],
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkCard,
      highlightColor: AppTheme.darkCardHover,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Container(height: 14, width: 150, color: AppTheme.darkCard),
        subtitle: Container(height: 12, width: 100, color: AppTheme.darkCard),
      ),
    );
  }
}
