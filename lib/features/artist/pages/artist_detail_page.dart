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
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/followed_artists_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/features/album/pages/album_detail_page.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';

/// Sort options for artist songs
enum ArtistSongSort {
  playTime('Play time'),
  name('Name'),
  dateAdded('Date added');

  final String displayName;
  const ArtistSongSort(this.displayName);
}

/// Provider for artist page
/// Uses browse API for albums/singles, search API for songs (to get duration)
final artistPageProvider = FutureProvider.family<ArtistPage?, String>((ref, browseId) async {
  final innertube = InnertubeService();
  return await innertube.getArtistPage(browseId);
});

/// Provider for artist songs using search API (to get duration)
final artistSongsSearchProvider = FutureProvider.family<List<Track>, String>((ref, artistName) async {
  final ytMusic = YtMusicService();
  await ytMusic.init();
  return await ytMusic.searchSongs('$artistName songs', limit: 15);
});

/// Artist detail page - shows all songs by an artist with sort options
class ArtistDetailPage extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? thumbnailUrl;
  final String? subscribersText;
  final bool isEmbedded; // When true, don't show MiniPlayer (used in desktop shell)

  const ArtistDetailPage({
    super.key,
    required this.artistId,
    required this.artistName,
    this.thumbnailUrl,
    this.subscribersText,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends ConsumerState<ArtistDetailPage> {
  bool _isPlayingAll = false;
  ArtistSongSort _sortBy = ArtistSongSort.playTime;
  bool _sortAscending = false;
  bool _isFollowing = false;
  final _followedArtistsService = FollowedArtistsService.instance;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    await _followedArtistsService.init();
    if (mounted) {
      setState(() {
        _isFollowing = _followedArtistsService.isFollowing(widget.artistId);
      });
    }
  }

  Future<void> _toggleFollow() async {
    final artist = FollowedArtist(
      id: widget.artistId,
      name: widget.artistName,
      thumbnailUrl: widget.thumbnailUrl,
    );
    final isNowFollowing = await _followedArtistsService.toggleFollow(artist);
    if (mounted) {
      setState(() {
        _isFollowing = isNowFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowFollowing 
            ? 'Following ${widget.artistName}' 
            : 'Unfollowed ${widget.artistName}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<Track> _sortTracks(List<Track> tracks) {
    final sorted = List<Track>.from(tracks);
    switch (_sortBy) {
      case ArtistSongSort.playTime:
        // Default order from API (usually by popularity/play count)
        break;
      case ArtistSongSort.name:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ArtistSongSort.dateAdded:
        // Keep original order (API order is usually by date)
        break;
    }
    if (_sortAscending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  Future<void> _playTrack(Track track, List<Track> allTracks) async {
    final sortedTracks = _sortTracks(allTracks);
    final startIndex = sortedTracks.indexOf(track);
    final audioService = ref.read(audioPlayerServiceProvider);
    // Artist page playback - disable auto-queue
    audioService.playAll(sortedTracks, startIndex: startIndex, source: PlaySource.artist);
  }

  Future<void> _playAll(List<Track> tracks) async {
    if (_isPlayingAll || tracks.isEmpty) return;
    
    setState(() => _isPlayingAll = true);
    
    try {
      final sortedTracks = _sortTracks(tracks);
      final audioService = ref.read(audioPlayerServiceProvider);
      // Artist page playback - disable auto-queue
      audioService.playAll(sortedTracks, source: PlaySource.artist);
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
      // Artist page playback - disable auto-queue
      audioService.playAll(shuffled, source: PlaySource.artist);
    } finally {
      if (mounted) setState(() => _isPlayingAll = false);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...ArtistSongSort.values.map((sort) => ListTile(
              leading: Icon(
                _sortBy == sort ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                color: _sortBy == sort ? AppTheme.primaryColor : Colors.grey,
              ),
              title: Text(sort.displayName),
              onTap: () {
                setState(() {
                  if (_sortBy == sort) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = sort;
                    _sortAscending = false;
                  }
                });
                Navigator.pop(context);
              },
              trailing: _sortBy == sort
                  ? Icon(
                      _sortAscending ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                      size: 20,
                    )
                  : null,
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artistPageAsync = ref.watch(artistPageProvider(widget.artistId));
    // Use search API for songs to get duration
    final songsAsync = ref.watch(artistSongsSearchProvider(widget.artistName));

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header with artist image
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
                    widget.artistName,
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
                            child: const Icon(Iconsax.user, size: 64, color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.user, size: 64, color: Colors.grey),
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

              // Artist page content
              artistPageAsync.when(
                data: (artistPage) {
                  if (artistPage == null) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('Failed to load artist')),
                    );
                  }

                  // Use songs from search API (has duration), fallback to browse API
                  final songs = songsAsync.valueOrNull ?? artistPage.songs ?? [];
                  final albums = artistPage.albums ?? [];
                  final singles = artistPage.singles ?? [];

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Subscribers and action buttons
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (artistPage.subscribersCountText != null || widget.subscribersText != null)
                              Text(
                                artistPage.subscribersCountText ?? widget.subscribersText ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            const Gap(12),
                            // Follow button row
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _toggleFollow,
                                  icon: Icon(
                                    _isFollowing ? Iconsax.tick_circle5 : Iconsax.add,
                                    size: 18,
                                  ),
                                  label: Text(_isFollowing ? 'Following' : 'Follow'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _isFollowing ? AppTheme.primaryColor : Colors.white,
                                    side: BorderSide(
                                      color: _isFollowing ? AppTheme.primaryColor : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(12),
                            Row(
                              children: [
                                Text(
                                  '${songs.length} songs',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                const Gap(8),
                                // Sort button
                                TextButton.icon(
                                  onPressed: _showSortOptions,
                                  icon: const Icon(Iconsax.sort, size: 18),
                                  label: Text(_sortBy.displayName),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade300,
                                  ),
                                ),
                                const Spacer(),
                                // Shuffle button
                                IconButton(
                                  onPressed: _isPlayingAll ? null : () => _shufflePlay(songs),
                                  icon: const Icon(Iconsax.shuffle),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.darkCard,
                                  ),
                                ),
                                const Gap(8),
                                // Play all button
                                FilledButton.icon(
                                  onPressed: _isPlayingAll ? null : () => _playAll(songs),
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

                      // Songs section header
                      if (songs.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Songs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        // Song list with playing indicator
                        ..._sortTracks(songs).map((track) => SongTile(
                          track: track,
                          onTap: () => _playTrack(track, songs),
                        )),
                      ],

                      // Albums section
                      if (albums.isNotEmpty) ...[
                        const Gap(16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Albums',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: albums.length,
                            itemBuilder: (context, index) {
                              final album = albums[index];
                              return _buildAlbumItem(album);
                            },
                          ),
                        ),
                      ],

                      // Singles section
                      if (singles.isNotEmpty) ...[
                        const Gap(16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Singles & EPs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: singles.length,
                            itemBuilder: (context, index) {
                              final single = singles[index];
                              return _buildAlbumItem(single);
                            },
                          ),
                        ),
                      ],

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
                          'Failed to load artist',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const Gap(8),
                        TextButton(
                          onPressed: () => ref.invalidate(artistPageProvider(widget.artistId)),
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

  Widget _buildAlbumItem(RelatedAlbum album) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumDetailPage(
                albumId: album.id,
                albumName: album.title,
                artistName: album.artist,
                thumbnailUrl: album.thumbnailUrl,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: album.thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(album.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: AppTheme.darkCard,
              ),
              child: album.thumbnailUrl == null
                  ? const Icon(Iconsax.music_square, size: 40, color: Colors.grey)
                  : null,
            ),
            const Gap(8),
            SizedBox(
              width: 130,
              child: Text(
                album.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (album.year != null)
              SizedBox(
                width: 130,
                child: Text(
                  album.year!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkCard,
      highlightColor: AppTheme.darkCardHover,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
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
