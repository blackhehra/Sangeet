import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/related_page.dart';
import 'package:sangeet/models/search_models.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';
import 'package:sangeet/services/followed_artists_service.dart';
import 'package:sangeet/features/artist/pages/artist_detail_page.dart';

/// Provider for fetching artist info by name
final artistSearchProvider = FutureProvider.family<SearchArtist?, String>((ref, artistName) async {
  if (artistName.isEmpty) return null;
  final ytMusic = YtMusicService();
  await ytMusic.init();
  final artists = await ytMusic.searchArtists(artistName, limit: 1);
  return artists.isNotEmpty ? artists.first : null;
});


/// Provider for fetching artist page data
final playerArtistPageProvider = FutureProvider.family<ArtistPage?, String>((ref, browseId) async {
  if (browseId.isEmpty) return null;
  final innertube = InnertubeService();
  return await innertube.getArtistPage(browseId);
});

/// Spotify-like artist section for full player
/// Shows: Explore Artist cards, Credits with Follow buttons, About the Artist
class PlayerArtistSection extends ConsumerStatefulWidget {
  final Track track;

  const PlayerArtistSection({
    super.key,
    required this.track,
  });

  @override
  ConsumerState<PlayerArtistSection> createState() => _PlayerArtistSectionState();
}

class _PlayerArtistSectionState extends ConsumerState<PlayerArtistSection> {
  final _followedArtistsService = FollowedArtistsService.instance;
  bool _isDescriptionExpanded = false;
  List<SearchArtist> _allArtists = [];
  bool _artistsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initFollowStatus();
    _loadAllArtists();
  }

  Future<void> _initFollowStatus() async {
    await _followedArtistsService.init();
    if (mounted) setState(() {});
  }

  Future<void> _loadAllArtists() async {
    final artistNames = widget.track.artist.split(RegExp(r',\s*|&\s*|\s+feat\.?\s+|\s+ft\.?\s+'));
    final ytMusic = YtMusicService();
    await ytMusic.init();
    
    final List<SearchArtist> results = [];
    for (final name in artistNames) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) continue;
      try {
        final artists = await ytMusic.searchArtists(trimmedName, limit: 1);
        if (artists.isNotEmpty) {
          results.add(artists.first);
        }
      } catch (e) {
        // Skip failed artist searches
      }
    }
    
    if (mounted) {
      setState(() {
        _allArtists = results;
        _artistsLoaded = true;
      });
    }
  }

  bool _isFollowing(String artistId) {
    return _followedArtistsService.isFollowing(artistId);
  }

  Future<void> _toggleFollow(SearchArtist artist) async {
    final followedArtist = FollowedArtist(
      id: artist.id,
      name: artist.name,
      thumbnailUrl: artist.thumbnailUrl,
    );
    await _followedArtistsService.toggleFollow(followedArtist);
    if (mounted) setState(() {});
  }

  void _navigateToArtist(SearchArtist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailPage(
          artistId: artist.id,
          artistName: artist.name,
          thumbnailUrl: artist.thumbnailUrl,
          subscribersText: artist.subscribersText,
        ),
      ),
    );
  }

  void _showCreditsBottomSheet(List<SearchArtist> artists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CreditsBottomSheet(
        track: widget.track,
        artists: artists,
        onToggleFollow: _toggleFollow,
        isFollowing: _isFollowing,
        onArtistTap: _navigateToArtist,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parse artist names from track
    final artistNames = widget.track.artist.split(RegExp(r',\s*|&\s*|\s+feat\.?\s+|\s+ft\.?\s+'));
    final primaryArtistName = artistNames.isNotEmpty ? artistNames.first.trim() : widget.track.artist;

    // Fetch primary artist info
    final primaryArtistAsync = ref.watch(artistSearchProvider(primaryArtistName));

    return primaryArtistAsync.when(
      data: (primaryArtist) {
        if (primaryArtist == null) {
          return const SizedBox.shrink();
        }

        // Fetch artist page for description and explore content
        final artistPageAsync = ref.watch(playerArtistPageProvider(primaryArtist.id));
        
        // Use loaded artists or fallback to primary artist
        final allArtists = _artistsLoaded && _allArtists.isNotEmpty ? _allArtists : [primaryArtist];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explore Artist Section
            _buildExploreSection(primaryArtist, artistPageAsync),
            
            const Gap(16),
            
            // Credits Section
            _buildCreditsSection(artistNames, allArtists),
            
            const Gap(16),
            
            // About the Artist Section
            _buildAboutSection(primaryArtist, artistPageAsync),
            
            const Gap(24),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildExploreSection(SearchArtist artist, AsyncValue<ArtistPage?> artistPageAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore ${artist.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Songs by Artist card
                _buildExploreCard(
                  title: 'Songs by\n${artist.name}',
                  imageUrl: artist.thumbnailUrl,
                  onTap: () => _navigateToArtist(artist),
                ),
                const Gap(12),
                // Similar to Artist card
                _buildExploreCard(
                  title: 'Similar to\n${artist.name}',
                  imageUrl: artist.thumbnailUrl,
                  onTap: () => _navigateToArtist(artist),
                  isGrayscale: true,
                ),
                const Gap(12),
                // Similar to Track card
                _buildExploreCard(
                  title: 'Similar to\n${widget.track.title}',
                  imageUrl: widget.track.thumbnailUrl,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard({
    required String title,
    String? imageUrl,
    required VoidCallback onTap,
    bool isGrayscale = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.darkCard,
        ),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? ColorFiltered(
                      colorFilter: isGrayscale
                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 160,
                      color: AppTheme.darkCard,
                      child: const Icon(Iconsax.music, color: Colors.grey),
                    ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Title
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsSection(List<String> artistNames, List<SearchArtist> allArtists) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showCreditsBottomSheet(allArtists),
                child: Text(
                  'Show all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          // Show first 2 artists
          ...artistNames.take(2).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            // Find matching artist from allArtists list
            final matchingArtist = index < allArtists.length ? allArtists[index] : null;
            final isFollowing = matchingArtist != null ? _isFollowing(matchingArtist.id) : false;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: matchingArtist != null ? () => _navigateToArtist(matchingArtist) : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.trim(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Main Artist',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFollowButton(
                    isFollowing: isFollowing,
                    onTap: matchingArtist != null ? () => _toggleFollow(matchingArtist) : () {},
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFollowButton({
    required bool isFollowing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? Colors.grey.shade600 : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isFollowing ? Colors.grey.shade400 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(SearchArtist artist, AsyncValue<ArtistPage?> artistPageAsync) {
    return artistPageAsync.when(
      data: (artistPage) {
        // Use YouTube Music description from artist page
        final description = artistPage?.description;
        final subscribersText = artistPage?.subscribersCountText ?? artist.subscribersText;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.darkCard.withOpacity(0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist image with "About the artist" label - tappable to go to artist page
              GestureDetector(
                onTap: () => _navigateToArtist(artist),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: artistPage?.thumbnailUrl ?? artist.thumbnailUrl ?? '',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.user, size: 64, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                    ),
                    // "About the artist" label
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Text(
                        'About the artist',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Artist info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToArtist(artist),
                          child: Row(
                            children: [
                              Text(
                                artist.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(4),
                              Icon(
                                Iconsax.verify5,
                                size: 18,
                                color: Colors.blue.shade400,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildFollowButton(
                          isFollowing: _isFollowing(artist.id),
                          onTap: () => _toggleFollow(artist),
                        ),
                      ],
                    ),
                    if (subscribersText != null) ...[
                      const Gap(4),
                      Text(
                        subscribersText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                    if (description != null && description.isNotEmpty) ...[
                      const Gap(12),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                          height: 1.4,
                        ),
                        maxLines: _isDescriptionExpanded ? null : 3,
                        overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'see less' : 'see more',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.darkCard.withOpacity(0.3),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Credits bottom sheet (shown when "Show all" is tapped)
class _CreditsBottomSheet extends StatelessWidget {
  final Track track;
  final List<SearchArtist> artists;
  final Function(SearchArtist) onToggleFollow;
  final bool Function(String) isFollowing;
  final Function(SearchArtist) onArtistTap;

  const _CreditsBottomSheet({
    required this.track,
    required this.artists,
    required this.onToggleFollow,
    required this.isFollowing,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    // Parse all artist names
    final artistNames = track.artist.split(RegExp(r',\s*|&\s*|\s+feat\.?\s+|\s+ft\.?\s+'));
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Track title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(4),
                    Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Credits list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Artist section
                    const Text(
                      'Artist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(12),
                    ...artistNames.asMap().entries.map((entry) {
                      final index = entry.key;
                      final name = entry.value;
                      // Find matching artist from artists list by index
                      final matchingArtist = index < artists.length ? artists[index] : null;
                      final isArtistFollowing = matchingArtist != null 
                          ? isFollowing(matchingArtist.id) 
                          : false;
                      
                      return _buildCreditItem(
                        context,
                        name: name.trim(),
                        role: 'Main Artist',
                        isFollowing: isArtistFollowing,
                        onFollowTap: matchingArtist != null 
                            ? () => onToggleFollow(matchingArtist) 
                            : null,
                        onTap: matchingArtist != null 
                            ? () {
                                Navigator.pop(context);
                                onArtistTap(matchingArtist);
                              }
                            : null,
                      );
                    }),
                    
                    const Gap(24),
                    
                    // Writing & Arrangement section
                    const Text(
                      'Writing & Arrangement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(12),
                    ...artistNames.take(1).map((name) => _buildCreditItem(
                      context,
                      name: name.trim(),
                      role: 'Lyricist',
                      showFollowButton: false,
                    )),
                    if (artistNames.length > 1)
                      ...artistNames.skip(1).take(1).map((name) => _buildCreditItem(
                        context,
                        name: name.trim(),
                        role: 'Composer',
                        showFollowButton: false,
                      )),
                    
                    const Gap(24),
                    
                    // Sources section
                    const Text(
                      'Sources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(12),
                    _buildCreditItem(
                      context,
                      name: track.album ?? 'YouTube Music',
                      role: null,
                      showFollowButton: false,
                    ),
                    
                    const Gap(24),
                    
                    // Report error button
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thanks for your feedback')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade600),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Report error'),
                      ),
                    ),
                    
                    const Gap(32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditItem(
    BuildContext context, {
    required String name,
    String? role,
    bool isFollowing = false,
    VoidCallback? onFollowTap,
    VoidCallback? onTap,
    bool showFollowButton = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (role != null) ...[
                    const Gap(2),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showFollowButton && onFollowTap != null)
              GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFollowing ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? Colors.grey.shade400 : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
