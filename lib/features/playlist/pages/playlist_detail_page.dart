import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/spotify_plugin_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';
import 'package:sangeet/models/spotify_models.dart';
import 'package:sangeet/shared/providers/track_matcher_provider.dart';
import 'package:sangeet/services/track_matcher_service.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:sangeet/shared/widgets/find_manually_sheet.dart';
import 'package:sangeet/services/custom_playlist_service.dart';
import 'package:sangeet/shared/providers/custom_playlist_provider.dart';

/// Special ID for liked songs
const String likedSongsId = 'liked_songs';

enum PlaylistType { playlist, likedSongs, album }

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final String playlistId;
  final String playlistName;
  final String? imageUrl;
  final PlaylistType type;
  final String? subtitle; // For albums: artist name
  final bool isEmbedded; // When true, don't show MiniPlayer (used in desktop shell)

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
    this.imageUrl,
    this.type = PlaylistType.playlist,
    this.subtitle,
    this.isEmbedded = false,
  });

  // Convenience constructor for liked songs
  const PlaylistDetailPage.likedSongs({
    super.key,
    this.isEmbedded = false,
  })  : playlistId = likedSongsId,
        playlistName = 'Liked Songs',
        imageUrl = null,
        type = PlaylistType.likedSongs,
        subtitle = null;

  // Convenience constructor for albums
  const PlaylistDetailPage.album({
    super.key,
    required this.playlistId,
    required this.playlistName,
    this.imageUrl,
    this.subtitle,
    this.isEmbedded = false,
  }) : type = PlaylistType.album;

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  bool _isPlayingAll = false;
  List<SpotifyTrack>? _loadedTracks; // Cache tracks for background matching

  @override
  void dispose() {
    // Note: Don't use ref.read() in dispose - it causes StateError
    // Background matching will be cancelled when a new playlist is opened
    super.dispose();
  }
  
  /// Called when tracks are loaded - starts background pre-matching
  void _onTracksLoaded(List<SpotifyTrack> tracks) {
    if (_loadedTracks == tracks) return; // Already started for these tracks
    _loadedTracks = tracks;
    
    // Start background pre-matching for all tracks
    final trackMatcher = ref.read(trackMatcherServiceProvider);
    trackMatcher.startBackgroundMatching(tracks);
  }

  /// Show track options bottom sheet
  void _showTrackOptions(BuildContext context, SpotifyTrack track) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Track info header
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: track.album.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: track.album.images.first.url,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.darkCardHover,
                          child: const Icon(Iconsax.music, color: Colors.grey),
                        ),
                ),
              ),
              title: Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                track.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
            const Divider(height: 1),
            // Find manually option
            ListTile(
              leading: const Icon(Iconsax.search_normal, color: Colors.white70),
              title: const Text('Find manually'),
              subtitle: Text(
                'Select a different YouTube video',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                showFindManuallySheet(
                  context: this.context,
                  ref: ref,
                  spotifyTrack: track,
                );
              },
            ),
            // Clear cache option
            ListTile(
              leading: const Icon(Iconsax.refresh, color: Colors.white70),
              title: const Text('Clear cache'),
              subtitle: Text(
                'Re-match YouTube video on next play',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              onTap: () {
                final trackMatcher = ref.read(trackMatcherServiceProvider);
                trackMatcher.clearCacheForSong(track.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Cache cleared for "${track.name}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  Future<void> _playTrack(SpotifyTrack track, List<SpotifyTrack> allTracks) async {
    final trackMatcher = ref.read(trackMatcherServiceProvider);
    final audioService = ref.read(audioPlayerServiceProvider);
    
    // Check if this is the same playlist that's currently playing
    final isSamePlaylist = audioService.currentPlaylistId == widget.playlistId;
    
    // FAST PATH: Check if track is already cached AND in queue - instant playback!
    // This avoids calling matchWithPriority which can be slow if not cached
    if (isSamePlaylist) {
      final cachedTrack = trackMatcher.getMatchedTrack(track.id);
      if (cachedTrack != null) {
        final queueIndex = audioService.findTrackInQueue(cachedTrack.id);
        if (queueIndex >= 0) {
          // Track is cached AND in queue - play instantly without any matching!
          print('SpotifyPlaylist: FAST PATH - Track "${track.name}" cached & in queue at $queueIndex');
          await audioService.playAtIndex(queueIndex);
          return;
        }
      }
    }
    
    // Create a pending track with Spotify metadata for IMMEDIATE UI feedback
    final pendingTrack = Track(
      id: track.id,
      title: track.name,
      artist: track.artists.map((a) => a.name).join(', '),
      album: track.album.name,
      thumbnailUrl: track.album.images.isNotEmpty ? track.album.images.first.url : null,
      duration: Duration(milliseconds: track.durationMs),
    );
    
    // Show mini player immediately with pending track (buffering state)
    // Pass playlist ID so queue is only cleared when switching playlists
    audioService.setPendingTrack(pendingTrack, playlistId: widget.playlistId);
    
    // Capture the session ID AFTER setPendingTrack (which increments it)
    final globalSessionId = audioService.playbackSessionId;
    print('SpotifyPlaylist: Playing ${track.name} (session $globalSessionId, samePlaylist: $isSamePlaylist)');

    try {
      // Use matchWithPriority - this checks cache first (instant if pre-matched)
      // and pauses background matching if needed
      final matchedTrack = await trackMatcher.matchWithPriority(track);
      
      // Check if session is still valid
      if (globalSessionId != audioService.playbackSessionId) {
        print('SpotifyPlaylist: Session $globalSessionId cancelled, skipping playback');
        return;
      }
      
      print('SpotifyPlaylist: Matched to YouTube ID: ${matchedTrack.id}');
      
      // Get the index of the selected track in the playlist
      final startIndex = allTracks.indexOf(track);
      
      if (isSamePlaylist) {
        // SAME PLAYLIST: Try to find and play the track in existing queue
        final queueIndex = audioService.findTrackInQueue(matchedTrack.id);
        if (queueIndex >= 0) {
          // Track found in queue - just play it
          print('SpotifyPlaylist: Track found in queue at index $queueIndex, playing directly');
          await audioService.playAtIndex(queueIndex);
          return;
        }
        // Track not in queue yet - fall through to add it
        print('SpotifyPlaylist: Track not in queue, adding at position $startIndex');
      }
      
      // DIFFERENT PLAYLIST or track not in queue: Build queue from scratch
      // Queue tracks BEFORE the clicked song first (for previous button)
      if (startIndex > 0) {
        final previousTracks = allTracks.sublist(0, startIndex);
        print('SpotifyPlaylist: Queueing ${previousTracks.length} previous tracks...');
        await _queuePreviousTracks(previousTracks, trackMatcher, audioService, globalSessionId);
      }
      
      // Check session still valid after queueing previous tracks
      if (globalSessionId != audioService.playbackSessionId) {
        print('SpotifyPlaylist: Session $globalSessionId cancelled after queueing previous');
        return;
      }
      
      // Now add the current track and start playing at its index
      final currentIndex = audioService.queueLength;
      audioService.addToQueue(matchedTrack, forSession: globalSessionId);
      
      // Start playing at the current track's position
      await audioService.playAtIndex(currentIndex);
      print('SpotifyPlaylist: Started playback at index $currentIndex');
      
      // Queue tracks AFTER the clicked song (for next button)
      if (startIndex < allTracks.length - 1) {
        final remainingTracks = allTracks.sublist(startIndex + 1);
        print('SpotifyPlaylist: Queueing ${remainingTracks.length} remaining tracks...');
        _queueRemainingTracks(remainingTracks, trackMatcher, audioService, globalSessionId);
      }
    } catch (e) {
      print('SpotifyPlaylist: Error playing track: $e');
      if (mounted && globalSessionId == audioService.playbackSessionId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading track: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }
  
  /// Queue previous tracks (before clicked song) - for previous button to work
  Future<void> _queuePreviousTracks(
    List<SpotifyTrack> tracks,
    TrackMatcherService trackMatcher,
    AudioPlayerService audioService,
    int globalSessionId,
  ) async {
    for (final spotifyTrack in tracks) {
      // Check session is still valid
      if (globalSessionId != audioService.playbackSessionId) {
        print('SpotifyPlaylist: Previous queue cancelled - session changed');
        return;
      }
      
      try {
        // Check if already matched by background pre-matching (instant)
        Track? matchedTrack = trackMatcher.getMatchedTrack(spotifyTrack.id);
        
        if (matchedTrack == null) {
          // Not yet matched - match it now
          matchedTrack = await trackMatcher.matchSpotifyPluginTrack(spotifyTrack);
        }
        
        // Add to queue with session check
        final added = audioService.addToQueue(matchedTrack, forSession: globalSessionId);
        if (!added) {
          print('SpotifyPlaylist: Previous queue cancelled - stale session');
          return;
        }
      } catch (e) {
        print('SpotifyPlaylist: Error matching ${spotifyTrack.name}: $e');
      }
    }
    print('SpotifyPlaylist: Finished queueing ${tracks.length} previous tracks');
  }
  
  /// Queue remaining tracks - uses cache from background pre-matching
  Future<void> _queueRemainingTracks(
    List<SpotifyTrack> tracks,
    TrackMatcherService trackMatcher,
    AudioPlayerService audioService,
    int globalSessionId,
  ) async {
    for (final spotifyTrack in tracks) {
      // Check session is still valid
      if (globalSessionId != audioService.playbackSessionId) {
        print('SpotifyPlaylist: Queue building cancelled - session changed');
        return;
      }
      
      try {
        // Check if already matched by background pre-matching (instant)
        Track? matchedTrack = trackMatcher.getMatchedTrack(spotifyTrack.id);
        
        if (matchedTrack == null) {
          // Not yet matched - match it now
          matchedTrack = await trackMatcher.matchSpotifyPluginTrack(spotifyTrack);
        }
        
        // Add to queue with session check
        final added = audioService.addToQueue(matchedTrack, forSession: globalSessionId);
        if (!added) {
          print('SpotifyPlaylist: Queue building cancelled - stale session');
          return;
        }
      } catch (e) {
        print('SpotifyPlaylist: Error matching ${spotifyTrack.name}: $e');
      }
    }
    print('SpotifyPlaylist: Finished queueing all tracks (session $globalSessionId)');
  }

  Future<void> _playAll(List<SpotifyTrack> tracks) async {
    if (_isPlayingAll || tracks.isEmpty) return;
    
    setState(() => _isPlayingAll = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading playlist...')),
    );

    try {
      final trackMatcher = ref.read(trackMatcherServiceProvider);
      final matchedTracks = await trackMatcher.matchSpotifyPluginTracks(tracks.take(50).toList());
      final audioService = ref.read(audioPlayerServiceProvider);
      // Playlist playback - disable auto-queue
      audioService.playAll(matchedTracks, source: PlaySource.playlist);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPlayingAll = false);
    }
  }

  Future<void> _shufflePlay(List<SpotifyTrack> tracks) async {
    if (_isPlayingAll || tracks.isEmpty) return;
    
    setState(() => _isPlayingAll = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shuffling playlist...')),
    );

    try {
      final shuffled = List<SpotifyTrack>.from(tracks)..shuffle();
      final trackMatcher = ref.read(trackMatcherServiceProvider);
      final matchedTracks = await trackMatcher.matchSpotifyPluginTracks(shuffled.take(50).toList());
      final audioService = ref.read(audioPlayerServiceProvider);
      // Playlist playback - disable auto-queue
      audioService.playAll(matchedTracks, source: PlaySource.playlist);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPlayingAll = false);
    }
  }

  /// Show dialog to import Spotify playlist to Sangeet
  Future<void> _showImportPlaylistDialog(List<SpotifyTrack> tracks) async {
    // Use special name for liked songs
    final importName = widget.type == PlaylistType.likedSongs 
        ? 'Spoti-Liked Songs' 
        : widget.playlistName;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Add to Sangeet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import "$importName" with ${tracks.length} songs to your Sangeet playlists?',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const Gap(16),
            Text(
              'This will match all songs with audio sources. This may take a moment.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'import'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == 'import') {
      await _importPlaylist(tracks);
    }
  }

  /// Import Spotify playlist to Sangeet local playlists
  Future<void> _importPlaylist(List<SpotifyTrack> tracks) async {
    if (!mounted) return;
    
    // Use special name for liked songs
    final importName = widget.type == PlaylistType.likedSongs 
        ? 'Spoti-Liked Songs' 
        : widget.playlistName;

    try {
      final customPlaylistService = CustomPlaylistService.instance;
      
      // Instant import: Save Spotify metadata only (no matching yet)
      // Matching happens on-demand when user clicks to play
      // Reverse the list so recently added songs appear at top
      final importedTracks = tracks.reversed.map((spotifyTrack) => Track(
        id: spotifyTrack.id, // Spotify ID - will be matched to YouTube on play
        title: spotifyTrack.name,
        artist: spotifyTrack.artists.map((a) => a.name).join(', '),
        album: spotifyTrack.album.name,
        thumbnailUrl: spotifyTrack.album.images.isNotEmpty 
            ? spotifyTrack.album.images.first.url 
            : null,
        duration: Duration(milliseconds: spotifyTrack.durationMs),
      )).toList();
      
      // Create the playlist instantly with Spotify metadata
      await customPlaylistService.importSpotifyPlaylist(
        name: importName,
        tracks: importedTracks,
        description: widget.type == PlaylistType.likedSongs 
            ? 'Imported from Spotify Liked Songs' 
            : 'Imported from Spotify',
        imageUrl: widget.imageUrl,
      );
      
      // Refresh the playlists provider so UI updates immediately
      ref.read(customPlaylistsProvider.notifier).refresh();
      
      if (!mounted) return;
      
      // Show success immediately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "$importName" with ${tracks.length} songs',
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing playlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the correct provider based on type
    final tracksAsync = switch (widget.type) {
      PlaylistType.likedSongs => ref.watch(spotifyPluginLikedTracksProvider),
      PlaylistType.album => ref.watch(spotifyPluginAlbumTracksProvider(widget.playlistId)),
      PlaylistType.playlist => ref.watch(spotifyPluginPlaylistTracksProvider(widget.playlistId)),
    };

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          // Header with playlist image
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
                widget.playlistName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.type == PlaylistType.likedSongs)
                    // Liked songs gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4B01D0), Color(0xFF9DBAFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Iconsax.heart5, color: Colors.white, size: 80),
                      ),
                    )
                  else if (widget.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.darkCard),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Iconsax.music, size: 64, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.darkCard,
                      child: const Icon(Iconsax.music_playlist, size: 64, color: Colors.grey),
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

          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: tracksAsync.when(
                data: (tracks) => Row(
                  children: [
                    // Track count
                    Text(
                      '${tracks.length} songs',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const Spacer(),
                    // Add to Sangeet button (import playlist or liked songs)
                    if (widget.type == PlaylistType.playlist || widget.type == PlaylistType.likedSongs)
                      IconButton(
                        onPressed: () => _showImportPlaylistDialog(tracks),
                        icon: const Icon(Iconsax.add_circle),
                        tooltip: 'Add to Sangeet',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.darkCard,
                        ),
                      ),
                    if (widget.type == PlaylistType.playlist || widget.type == PlaylistType.likedSongs) const Gap(8),
                    // Shuffle button
                    IconButton(
                      onPressed: _isPlayingAll ? null : () => _shufflePlay(tracks),
                      icon: const Icon(Iconsax.shuffle),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.darkCard,
                      ),
                    ),
                    const Gap(8),
                    // Play all button
                    FilledButton.icon(
                      onPressed: _isPlayingAll ? null : () => _playAll(tracks),
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
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Track list
          tracksAsync.when(
            data: (tracks) {
              // Start background pre-matching when tracks are loaded
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onTracksLoaded(tracks);
              });
              
              return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = tracks[index];
                  final artistNames = track.artists.map((a) => a.name).join(', ');
                  final imageUrl = track.album.images.isNotEmpty 
                      ? track.album.images.first.url 
                      : null;
                  
                  // Check if this track is currently playing
                  final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
                  final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
                  // Match by title since Spotify track IDs differ from YouTube IDs
                  final isCurrentTrack = currentTrack?.title.toLowerCase() == track.name.toLowerCase();

                  return ListTile(
                    onTap: isCurrentTrack 
                        ? () {
                            // Toggle play/pause for current track
                            final audioService = ref.read(audioPlayerServiceProvider);
                            if (isPlaying) {
                              audioService.pause();
                            } else {
                              audioService.resume();
                            }
                          }
                        : () => _playTrack(track, tracks),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppTheme.darkCard),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppTheme.darkCard,
                                  child: const Icon(Iconsax.music, color: Colors.grey),
                                ),
                              )
                            : Container(
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
                            track.name,
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
                      artistNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                    trailing: isCurrentTrack 
                        ? IconButton(
                            onPressed: () {
                              final audioService = ref.read(audioPlayerServiceProvider);
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
                            onPressed: () => _showTrackOptions(context, track),
                            icon: const Icon(Iconsax.more, size: 20),
                          ),
                  );
                },
                childCount: tracks.length,
              ),
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
                      'Failed to load tracks',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const Gap(8),
                    TextButton(
                      onPressed: () {
                        switch (widget.type) {
                          case PlaylistType.likedSongs:
                            ref.invalidate(spotifyPluginLikedTracksProvider);
                          case PlaylistType.album:
                            ref.invalidate(spotifyPluginAlbumTracksProvider(widget.playlistId));
                          case PlaylistType.playlist:
                            ref.invalidate(spotifyPluginPlaylistTracksProvider(widget.playlistId));
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

            // Bottom padding for mini player
            const SliverGap(140),
          ],
        ),
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
