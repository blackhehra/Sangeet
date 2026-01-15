import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/custom_playlist_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:sangeet/features/playlist/pages/custom_playlists_page.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/features/sharing/widgets/share_bottom_sheet.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum SortOption { recentlyAdded, title, artist }

class CustomPlaylistDetailPage extends ConsumerStatefulWidget {
  final String playlistId;

  const CustomPlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  @override
  ConsumerState<CustomPlaylistDetailPage> createState() => _CustomPlaylistDetailPageState();
}

class _CustomPlaylistDetailPageState extends ConsumerState<CustomPlaylistDetailPage> {
  List<Track> _sortedTracks = [];
  SortOption _currentSort = SortOption.recentlyAdded;
  bool _titleAscending = true;
  bool _artistAscending = true;
  bool _recentlyAddedNewestFirst = true; // true = newest on top (Spotify default)

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  void _sortTracks(List<Track> originalTracks) {
    _sortedTracks = List.from(originalTracks);
    
    switch (_currentSort) {
      case SortOption.recentlyAdded:
        // Tracks are stored in Spotify order (recently added at top)
        // If user wants oldest first, reverse the list
        if (!_recentlyAddedNewestFirst) {
          _sortedTracks = _sortedTracks.reversed.toList();
        }
        break;
      case SortOption.title:
        _sortedTracks.sort((a, b) {
          final comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return _titleAscending ? comparison : -comparison;
        });
        break;
      case SortOption.artist:
        _sortedTracks.sort((a, b) {
          final comparison = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          return _artistAscending ? comparison : -comparison;
        });
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Use root navigator to appear above mini player
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Divider(),
            _buildSortOption(
              sheetContext,
              'Recently Added',
              SortOption.recentlyAdded,
              Iconsax.clock,
            ),
            _buildSortOption(
              sheetContext,
              'Title',
              SortOption.title,
              Iconsax.music_circle,
            ),
            _buildSortOption(
              sheetContext,
              'Artist',
              SortOption.artist,
              Iconsax.microphone,
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext sheetContext, String label, SortOption option, IconData icon) {
    final isSelected = _currentSort == option;
    String displayLabel = label;
    
    if (isSelected) {
      if (option == SortOption.recentlyAdded) {
        displayLabel = _recentlyAddedNewestFirst ? '$label (Newest)' : '$label (Oldest)';
      } else if (option == SortOption.title) {
        displayLabel = _titleAscending ? '$label (A-Z)' : '$label (Z-A)';
      } else if (option == SortOption.artist) {
        displayLabel = _artistAscending ? '$label (A-Z)' : '$label (Z-A)';
      }
    }
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
      ),
      title: Text(
        displayLabel,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Iconsax.tick_circle5,
              color: AppTheme.primaryColor,
            )
          : null,
      onTap: () {
        // Store the sort values before closing
        final newSort = option;
        final shouldToggleRecentlyAdded = _currentSort == option && option == SortOption.recentlyAdded;
        final shouldToggleTitle = _currentSort == option && option == SortOption.title;
        final shouldToggleArtist = _currentSort == option && option == SortOption.artist;
        
        // Close the bottom sheet using root navigator (matches useRootNavigator: true)
        Navigator.of(sheetContext, rootNavigator: true).pop();
        
        // Then update state after the sheet is closed
        setState(() {
          if (shouldToggleRecentlyAdded) {
            _recentlyAddedNewestFirst = !_recentlyAddedNewestFirst;
          } else if (shouldToggleTitle) {
            _titleAscending = !_titleAscending;
          } else if (shouldToggleArtist) {
            _artistAscending = !_artistAscending;
          } else {
            _currentSort = newSort;
            if (newSort == SortOption.recentlyAdded) {
              _recentlyAddedNewestFirst = true;
            } else if (newSort == SortOption.title) {
              _titleAscending = true;
            } else if (newSort == SortOption.artist) {
              _artistAscending = true;
            }
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = ref.watch(customPlaylistByIdProvider(widget.playlistId));

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Playlist'),
        ),
        body: const Center(
          child: Text('Playlist not found'),
        ),
      );
    }

    // Sort tracks
    _sortTracks(playlist.tracks);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: _isDesktop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      // Go back to My Playlists page
                      ref.read(desktopNavigationProvider.notifier).setContent(
                        const CustomPlaylistsPage(),
                      );
                    },
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                playlist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Iconsax.music_playlist,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playlist.description != null) ...[
                    Text(
                      playlist.description!,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(16),
                  ],
                  Row(
                    children: [
                      Text(
                        '${_sortedTracks.length} songs',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_sortedTracks.isNotEmpty) ...[
                        IconButton(
                          onPressed: () {
                            final shareData = ShareService.instance.createPlaylistShare(playlist);
                            ShareBottomSheet.show(context, shareData);
                          },
                          icon: const Icon(Iconsax.share),
                          tooltip: 'Share',
                        ),
                        IconButton(
                          onPressed: _showSortOptions,
                          icon: const Icon(Iconsax.sort),
                          tooltip: 'Sort',
                        ),
                        IconButton(
                          onPressed: () {
                            final audioService = ref.read(audioPlayerServiceProvider);
                            // Playlist playback - disable auto-queue
                            audioService.playAll(_sortedTracks, startIndex: 0, source: PlaySource.playlist);
                            audioService.toggleShuffle();
                          },
                          icon: const Icon(Iconsax.shuffle),
                          tooltip: 'Shuffle',
                        ),
                        const Gap(8),
                        FloatingActionButton(
                          onPressed: () {
                            // Playlist playback - disable auto-queue
                            ref.read(audioPlayerServiceProvider).playAll(
                                  _sortedTracks,
                                  startIndex: 0,
                                  source: PlaySource.playlist,
                                );
                          },
                          backgroundColor: AppTheme.primaryColor,
                          child: const Icon(Iconsax.play5, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  const Gap(16),
                ],
              ),
            ),
          ),
          if (_sortedTracks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.music,
                      size: 64,
                      color: Colors.grey.shade700,
                    ),
                    const Gap(16),
                    Text(
                      'No songs in this playlist',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Add songs from the player menu',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _sortedTracks[index];
                  final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
                  final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
                  // Compare by ID first, then by title+artist (for imported playlists where IDs differ after matching)
                  final isCurrentTrack = currentTrack != null && (
                    currentTrack.id == track.id ||
                    (currentTrack.title.toLowerCase() == track.title.toLowerCase() &&
                     currentTrack.artist.toLowerCase() == track.artist.toLowerCase())
                  );
                  final audioService = ref.watch(audioPlayerServiceProvider);
                  
                  return Dismissible(
                    key: Key(track.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref
                          .read(customPlaylistsProvider.notifier)
                          .removeTrackFromPlaylist(widget.playlistId, track.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${track.title}"'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              ref
                                  .read(customPlaylistsProvider.notifier)
                                  .addTrackToPlaylist(widget.playlistId, track);
                            },
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: track.thumbnailUrl ?? '',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 48,
                            height: 48,
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music, color: Colors.grey),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 48,
                            height: 48,
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music, color: Colors.grey),
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
                            child: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isCurrentTrack ? AppTheme.primaryColor : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                      trailing: isCurrentTrack
                          ? IconButton(
                              onPressed: () {
                                if (isPlaying) {
                                  audioService.pause();
                                } else {
                                  audioService.resume();
                                }
                              },
                              icon: Icon(
                                isPlaying ? Iconsax.pause5 : Iconsax.play5,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : IconButton(
                              onPressed: () {
                                // Show more options menu
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  backgroundColor: AppTheme.darkCard,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  isScrollControlled: true,
                                  barrierColor: Colors.black54,
                                  builder: (context) => Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Iconsax.trash, color: Colors.red),
                                          title: const Text('Remove from playlist'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            ref
                                                .read(customPlaylistsProvider.notifier)
                                                .removeTrackFromPlaylist(widget.playlistId, track.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Removed "${track.title}"')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Iconsax.more, size: 20),
                            ),
                      onTap: isCurrentTrack
                          ? () {
                              if (isPlaying) {
                                audioService.pause();
                              } else {
                                audioService.resume();
                              }
                            }
                          : () {
                              // Playlist source disables auto-queue
                              audioService.playAll(_sortedTracks, startIndex: index, source: PlaySource.playlist);
                            },
                    ),
                  );
                },
                childCount: _sortedTracks.length,
              ),
            ),
          
          // Bottom padding for mini player
          const SliverGap(100),
        ],
      ),
    );
  }
}
