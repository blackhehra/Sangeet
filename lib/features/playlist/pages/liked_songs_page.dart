import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/song_tile.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:sangeet/main.dart' show rootNavigatorKey;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class LikedSongsPage extends ConsumerStatefulWidget {
  const LikedSongsPage({super.key});

  @override
  ConsumerState<LikedSongsPage> createState() => _LikedSongsPageState();
}

enum SortOption { recentlyAdded, title, artist }

class _LikedSongsPageState extends ConsumerState<LikedSongsPage> {
  List<Track> _likedSongs = [];
  List<Track> _originalOrder = [];
  SortOption _currentSort = SortOption.recentlyAdded;
  bool _titleAscending = true;
  bool _artistAscending = true;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _loadLikedSongs();
  }

  void _loadLikedSongs() {
    setState(() {
      _originalOrder = PlayHistoryService.instance.getLikedSongs();
      _likedSongs = List.from(_originalOrder);
      _sortSongs();
    });
  }

  void _sortSongs() {
    _likedSongs = List.from(_originalOrder);
    
    switch (_currentSort) {
      case SortOption.recentlyAdded:
        _likedSongs = _likedSongs.reversed.toList();
        break;
      case SortOption.title:
        _likedSongs.sort((a, b) {
          final comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return _titleAscending ? comparison : -comparison;
        });
        break;
      case SortOption.artist:
        _likedSongs.sort((a, b) {
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
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(8),
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
      if (option == SortOption.title) {
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
        // Store sort values before closing
        final newSort = option;
        final shouldToggleTitle = _currentSort == option && option == SortOption.title;
        final shouldToggleArtist = _currentSort == option && option == SortOption.artist;
        
        // Close the bottom sheet using root navigator (matches useRootNavigator: true)
        Navigator.of(sheetContext, rootNavigator: true).pop();
        
        // Then update state after the sheet is closed
        setState(() {
          if (shouldToggleTitle) {
            _titleAscending = !_titleAscending;
          } else if (shouldToggleArtist) {
            _artistAscending = !_artistAscending;
          } else {
            _currentSort = newSort;
            if (newSort == SortOption.title) {
              _titleAscending = true;
            } else if (newSort == SortOption.artist) {
              _artistAscending = true;
            }
          }
          _sortSongs();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerServiceProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: _isDesktop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      ref.read(desktopNavigationProvider.notifier).clear();
                    },
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Liked Songs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.darkBg,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Iconsax.heart5,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Song count and play button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_likedSongs.length} songs',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_likedSongs.isNotEmpty) ...[
                    IconButton(
                      onPressed: _showSortOptions,
                      icon: const Icon(Iconsax.sort),
                      tooltip: 'Sort',
                    ),
                    IconButton(
                      onPressed: () {
                        // Shuffle play - playlist source disables auto-queue
                        audioService.playAll(_likedSongs, startIndex: 0, source: PlaySource.playlist);
                        audioService.toggleShuffle();
                      },
                      icon: const Icon(Iconsax.shuffle),
                    ),
                    const Gap(8),
                    FloatingActionButton(
                      onPressed: () {
                        // Playlist source disables auto-queue
                        audioService.playAll(_likedSongs, startIndex: 0, source: PlaySource.playlist);
                      },
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(Iconsax.play5, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Songs list
          if (_likedSongs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.heart,
                      size: 64,
                      color: Colors.grey.shade600,
                    ),
                    const Gap(16),
                    Text(
                      'No liked songs yet',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Tap the heart icon on any song to add it here',
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
                  final track = _likedSongs[index];
                  return _buildSongTile(track, index, audioService);
                },
                childCount: _likedSongs.length,
              ),
            ),
          
          // Bottom padding for mini player
          const SliverGap(100),
        ],
      ),
    );
  }

  Widget _buildSongTile(Track track, int index, dynamic audioService) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final isCurrentTrack = currentTrack?.id == track.id;
    
    return ListTile(
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
              onPressed: () async {
                await PlayHistoryService.instance.toggleLike(track);
                _loadLikedSongs();
              },
              icon: const Icon(
                Iconsax.heart5,
                color: AppTheme.primaryColor,
              ),
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
              audioService.playAll(_likedSongs, startIndex: index, source: PlaySource.playlist);
            },
    );
  }
}
