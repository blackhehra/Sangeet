import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/spotify_plugin_provider.dart';
import 'package:sangeet/services/spotify_plugin/spotify_plugin.dart';
import 'package:sangeet/models/spotify_models.dart';
import 'package:sangeet/features/auth/pages/spotify_plugin_login_page.dart';
import 'package:sangeet/features/settings/pages/settings_page.dart';
import 'package:sangeet/features/playlist/pages/playlist_detail_page.dart';
import 'package:sangeet/features/home/widgets/section_header.dart';
import 'package:sangeet/services/spotify_plugin/endpoints/browse_endpoint.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Playlists', 'Albums', 'Artists', 'Recently Played'];

  Future<void> _loginToSpotify() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SpotifyPluginLoginPage()),
    );
    
    if (result == true && mounted) {
      // Refresh all Spotify providers
      ref.invalidate(isSpotifyPluginAuthenticatedProvider);
      ref.invalidate(spotifyPluginPlaylistsProvider);
      ref.invalidate(spotifyPluginLikedTracksProvider);
      ref.invalidate(spotifyPluginSavedAlbumsProvider);
      ref.invalidate(spotifyPluginUserProvider);
      ref.invalidate(spotifyPluginFollowedArtistsProvider);
      
      // Force rebuild
      setState(() {});
    }
  }

  void _openPlaylist(SpotifySimplePlaylist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailPage(
          playlistId: playlist.id,
          playlistName: playlist.name,
          imageUrl: playlist.images.isNotEmpty ? playlist.images.first.url : null,
        ),
      ),
    );
  }

  void _openLikedSongs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlaylistDetailPage.likedSongs(),
      ),
    );
  }

  void _openAlbum(SpotifySimpleAlbum album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailPage.album(
          playlistId: album.id,
          playlistName: album.name,
          imageUrl: album.images.isNotEmpty ? album.images.first.url : null,
          subtitle: album.artists.map((a) => a.name).join(', '),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isSpotifyPluginAuthenticatedProvider);
    final user = ref.watch(spotifyPluginUserProvider);
    final playlists = ref.watch(spotifyPluginPlaylistsProvider);
    final likedTracks = ref.watch(spotifyPluginLikedTracksProvider);
    final savedAlbums = ref.watch(spotifyPluginSavedAlbumsProvider);
    final followedArtists = ref.watch(spotifyPluginFollowedArtistsProvider);
    final recentlyPlayed = ref.watch(spotifyPluginRecentlyPlayedProvider);
    final topTracks = ref.watch(spotifyPluginTopTracksProvider);
    final topArtists = ref.watch(spotifyPluginTopArtistsProvider);
    final browseSections = ref.watch(spotifyPluginBrowseSectionsProvider);
    final plugin = SpotifyPluginService.instance;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(
              children: [
                // Profile Avatar
                GestureDetector(
                  onTap: isAuthenticated ? null : _loginToSpotify,
                  child: user.when(
                    data: (userData) => userData != null && userData.images.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: userData.images.first.url,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userData?.name.substring(0, 1).toUpperCase() ?? 'S',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                    loading: () => Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.darkCard,
                        shape: BoxShape.circle,
                      ),
                    ),
                    error: (_, __) => Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.user, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const Gap(12),
                const Text(
                  'Your Library',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.search_normal),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                icon: const Icon(Iconsax.setting_2),
              ),
              if (isAuthenticated)
                IconButton(
                  onPressed: () async {
                    await plugin?.auth.logout();
                    ref.invalidate(spotifyPluginPlaylistsProvider);
                    ref.invalidate(spotifyPluginUserProvider);
                    ref.invalidate(isSpotifyPluginAuthenticatedProvider);
                  },
                  icon: const Icon(Iconsax.logout),
                )
              else
                IconButton(
                  onPressed: _loginToSpotify,
                  icon: const Icon(Iconsax.login),
                ),
              const Gap(8),
            ],
          ),

          // Not logged in state
          if (!isAuthenticated) ...[
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.music_library_2,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Gap(24),
                      const Text(
                        'Connect to Spotify',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Login to access your playlists, liked songs, and more',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(32),
                      ElevatedButton.icon(
                        onPressed: _loginToSpotify,
                        icon: const Icon(Iconsax.login),
                        label: const Text('Login with Spotify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Filter Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        backgroundColor: AppTheme.darkCard,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SliverGap(16),

            // Recently Played Section
            if (_selectedFilter == 'All' || _selectedFilter == 'Recently Played')
              SliverToBoxAdapter(
                child: recentlyPlayed.when(
                  data: (tracks) => tracks.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSection(
                          title: 'Recently Played',
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: tracks.length,
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _TrackCard(
                                    title: track.name,
                                    subtitle: track.artists.map((a) => a.name).join(', '),
                                    imageUrl: track.album.images.isNotEmpty 
                                        ? track.album.images.first.url 
                                        : null,
                                    onTap: () {},
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  loading: () => _buildLoadingHorizontalList(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            // Top Tracks Section
            if (_selectedFilter == 'All')
              SliverToBoxAdapter(
                child: topTracks.when(
                  data: (tracks) => tracks.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSection(
                          title: 'Your Top Tracks',
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: tracks.length,
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _TrackCard(
                                    title: track.name,
                                    subtitle: track.artists.map((a) => a.name).join(', '),
                                    imageUrl: track.album.images.isNotEmpty 
                                        ? track.album.images.first.url 
                                        : null,
                                    onTap: () {},
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            // Top Artists Section
            if (_selectedFilter == 'All' || _selectedFilter == 'Artists')
              SliverToBoxAdapter(
                child: topArtists.when(
                  data: (artists) => artists.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSection(
                          title: 'Your Top Artists',
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: artists.length,
                              itemBuilder: (context, index) {
                                final artist = artists[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _ArtistCard(
                                    name: artist.name,
                                    imageUrl: (artist.images?.isNotEmpty ?? false) 
                                        ? artist.images!.first.url 
                                        : null,
                                    onTap: () {},
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            // Followed Artists
            if (_selectedFilter == 'Artists')
              SliverToBoxAdapter(
                child: followedArtists.when(
                  data: (artists) => artists.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSection(
                          title: 'Followed Artists',
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: artists.length,
                              itemBuilder: (context, index) {
                                final artist = artists[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _ArtistCard(
                                    name: artist.name,
                                    imageUrl: (artist.images?.isNotEmpty ?? false) 
                                        ? artist.images!.first.url 
                                        : null,
                                    onTap: () {},
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            // Your Playlists Section
            if (_selectedFilter == 'All' || _selectedFilter == 'Playlists')
              SliverToBoxAdapter(
                child: playlists.when(
                  data: (items) => _buildSection(
                    title: 'Your Playlists',
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length + 1, // +1 for Liked Songs
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Liked Songs
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: likedTracks.when(
                                data: (tracks) => _PlaylistCard(
                                  title: 'Liked Songs',
                                  subtitle: '${tracks.length} songs',
                                  isLikedSongs: true,
                                  onTap: _openLikedSongs,
                                ),
                                loading: () => const SizedBox(width: 140),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            );
                          }
                          final playlist = items[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _PlaylistCard(
                              title: playlist.name,
                              subtitle: 'Playlist',
                              imageUrl: playlist.images.isNotEmpty 
                                  ? playlist.images.first.url 
                                  : null,
                              onTap: () => _openPlaylist(playlist),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            // Saved Albums Section
            if (_selectedFilter == 'All' || _selectedFilter == 'Albums')
              SliverToBoxAdapter(
                child: savedAlbums.when(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSection(
                          title: 'Saved Albums',
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final album = items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _AlbumCard(
                                    title: album.name,
                                    subtitle: album.artists.map((a) => a.name).join(', '),
                                    imageUrl: album.images.isNotEmpty 
                                        ? album.images.first.url 
                                        : null,
                                    onTap: () => _openAlbum(album),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            
            // Browse Sections (Personalized Spotify Home Content)
            if (_selectedFilter == 'All')
              SliverToBoxAdapter(
                child: browseSections.when(
                  data: (response) => response.items.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final section in response.items)
                              if (section.items.isNotEmpty)
                                _buildSection(
                                  title: section.title,
                                  child: SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: section.items.length,
                                      itemBuilder: (context, index) {
                                        final item = section.items[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: _BrowseItemCard(
                                            item: item,
                                            onTap: () => _openBrowseItem(item),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                          ],
                        ),
                  loading: () => _buildLoadingHorizontalList(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            // Bottom padding for mini player
            const SliverGap(140),
          ],
        ],
      ),
    );
  }

  void _openBrowseItem(SpotifyBrowseItem item) {
    if (item.type == 'playlist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailPage(
            playlistId: item.id,
            playlistName: item.name,
            imageUrl: item.imageUrl,
          ),
        ),
      );
    } else if (item.type == 'album') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailPage.album(
            playlistId: item.id,
            playlistName: item.name,
            imageUrl: item.imageUrl,
            subtitle: item.subtitle,
          ),
        ),
      );
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, actionText: 'See all'),
        child,
        const Gap(24),
      ],
    );
  }

  Widget _buildLoadingHorizontalList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: AppTheme.darkCard,
              highlightColor: AppTheme.darkCardHover,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

/// Track card for horizontal lists
class _TrackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _TrackCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music, color: Colors.grey, size: 40),
                        ),
                      )
                    : Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Iconsax.music, color: Colors.grey, size: 40),
                      ),
              ),
            ),
            const Gap(8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
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

/// Artist card (circular) for horizontal lists
class _ArtistCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _ArtistCard({
    required this.name,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Iconsax.user, color: Colors.grey, size: 40),
                      ),
                    )
                  : Container(
                      color: AppTheme.darkCard,
                      child: const Icon(Iconsax.user, color: Colors.grey, size: 40),
                    ),
            ),
          ),
          const Gap(8),
          SizedBox(
            width: 120,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            'Artist',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Playlist card for horizontal lists
class _PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isLikedSongs;
  final VoidCallback? onTap;

  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.isLikedSongs = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isLikedSongs
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4B01D0), Color(0xFF9DBAFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Iconsax.heart5, color: Colors.white, size: 48),
                        ),
                      )
                    : imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.darkCard,
                              child: const Icon(Iconsax.music_playlist, color: Colors.grey, size: 40),
                            ),
                          )
                        : Container(
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music_playlist, color: Colors.grey, size: 40),
                          ),
              ),
            ),
            const Gap(8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
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

/// Album card for horizontal lists
class _AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _AlbumCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music_square, color: Colors.grey, size: 40),
                        ),
                      )
                    : Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Iconsax.music_square, color: Colors.grey, size: 40),
                      ),
              ),
            ),
            const Gap(8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
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

/// Browse item card for personalized content
class _BrowseItemCard extends StatelessWidget {
  final SpotifyBrowseItem item;
  final VoidCallback? onTap;

  const _BrowseItemCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArtist = item.type == 'artist';
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isArtist ? 70 : 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isArtist ? 70 : 8),
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.darkCard,
                          child: Icon(
                            isArtist ? Iconsax.user : Iconsax.music_playlist,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.darkCard,
                        child: Icon(
                          isArtist ? Iconsax.user : Iconsax.music_playlist,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const Gap(8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              item.subtitle,
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
