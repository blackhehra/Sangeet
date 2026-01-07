import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/spotify_models.dart' as spotify;
import 'package:sangeet/services/youtube_service.dart';
import 'package:sangeet/shared/providers/track_matcher_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/main.dart' show rootNavigatorKey;

/// Shows a bottom sheet to manually select a video for a song
/// Used when the auto-matched video is incorrect
Future<void> showFindManuallySheet({
  required BuildContext context,
  required WidgetRef ref,
  required spotify.SpotifyTrack spotifyTrack,
}) async {
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppTheme.darkSurface,
    isScrollControlled: true,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _FindManuallyContent(
        spotifyTrack: spotifyTrack,
        scrollController: scrollController,
      ),
    ),
  );
}

class _FindManuallyContent extends ConsumerStatefulWidget {
  final spotify.SpotifyTrack spotifyTrack;
  final ScrollController scrollController;

  const _FindManuallyContent({
    required this.spotifyTrack,
    required this.scrollController,
  });

  @override
  ConsumerState<_FindManuallyContent> createState() => _FindManuallyContentState();
}

class _FindManuallyContentState extends ConsumerState<_FindManuallyContent> {
  final YouTubeService _youtubeService = YouTubeService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Track> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  String? _selectedVideoId;

  @override
  void initState() {
    super.initState();
    // Initialize search with song name and artist
    final artistName = widget.spotifyTrack.artists.isNotEmpty 
        ? widget.spotifyTrack.artists.first.name 
        : '';
    _searchController.text = '${widget.spotifyTrack.name} $artistName';
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _error = null;
    });

    try {
      // Search for the query
      final results = await _youtubeService.search(query, limit: 20);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search: $e';
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectVideo(Track youtubeTrack) async {
    setState(() => _selectedVideoId = youtubeTrack.id);
    
    final trackMatcher = ref.read(trackMatcherServiceProvider);
    final audioService = ref.read(audioPlayerServiceProvider);
    
    // Create a track with metadata but video ID
    final artistsString = widget.spotifyTrack.artists.map((a) => a.name).join(', ');
    final albumName = widget.spotifyTrack.album.name;
    final imageUrl = widget.spotifyTrack.album.images.isNotEmpty 
        ? widget.spotifyTrack.album.images.first.url 
        : null;
    
    final matchedTrack = Track(
      id: youtubeTrack.id, // Video ID for playback
      title: widget.spotifyTrack.name, // Use track title
      artist: artistsString,
      album: albumName,
      thumbnailUrl: imageUrl ?? youtubeTrack.thumbnailUrl,
      duration: Duration(milliseconds: widget.spotifyTrack.durationMs),
    );
    
    // Save to cache so this selection is remembered
    await trackMatcher.saveManualSelection(widget.spotifyTrack.id, matchedTrack);
    
    // Play the selected track
    await audioService.play(matchedTrack);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now playing: ${widget.spotifyTrack.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Manually',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(4),
              Text(
                'Select the correct YouTube video for this song',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        
        const Gap(16),
        
        // Song info card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: widget.spotifyTrack.album.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.spotifyTrack.album.images.first.url,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.darkCardHover,
                          child: const Icon(Iconsax.music, color: Colors.grey),
                        ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.spotifyTrack.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      widget.spotifyTrack.artists.map((a) => a.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const Gap(16),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search YouTube...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Iconsax.search_normal, size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Iconsax.search_normal_1),
                      onPressed: _performSearch,
                    ),
              filled: true,
              fillColor: AppTheme.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        
        const Gap(16),
        
        // Results list
        Expanded(
          child: _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: Colors.grey.shade600),
            const Gap(16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            TextButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_normal, size: 48, color: Colors.grey.shade600),
            const Gap(16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final isSelected = _selectedVideoId == track.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: ListTile(
            onTap: () => _selectVideo(track),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 45,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: track.thumbnailUrl ?? '',
                      width: 80,
                      height: 45,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.darkCardHover,
                        child: const Icon(Iconsax.video, color: Colors.grey, size: 20),
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(track.duration),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Text(
              track.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
            subtitle: Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            trailing: isSelected
                ? const Icon(Iconsax.tick_circle5, color: AppTheme.primaryColor)
                : const Icon(Iconsax.play_circle, size: 24),
          ),
        );
      },
    );
  }
}
