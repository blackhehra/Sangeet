import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/spotify_plugin_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/quick_picks_provider.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:sangeet/services/spotify_plugin/spotify_plugin.dart';
import 'package:sangeet/models/spotify_models.dart';
import 'package:sangeet/features/auth/pages/spotify_plugin_login_page.dart';
import 'package:sangeet/features/settings/pages/settings_page.dart';
import 'package:sangeet/features/playlist/pages/playlist_detail_page.dart';
import 'package:sangeet/features/home/widgets/section_header.dart';
import 'package:sangeet/services/spotify_plugin/endpoints/browse_endpoint.dart';

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Desktop Library Page - Shows home data for logged in user
class DesktopLibraryPage extends ConsumerStatefulWidget {
  const DesktopLibraryPage({super.key});

  @override
  ConsumerState<DesktopLibraryPage> createState() => _DesktopLibraryPageState();
}

class _DesktopLibraryPageState extends ConsumerState<DesktopLibraryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Playlists', 'Albums', 'Artists', 'Recently Played'];

  Future<void> _loginToSpotify() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SpotifyPluginLoginPage()),
    );
    // No need to manually invalidate - the auth state stream will trigger updates
    // All providers watch isSpotifyPluginAuthenticatedProvider which watches the stream
  }

  void _openPlaylist(SpotifySimplePlaylist playlist) {
    ref.read(desktopNavigationProvider.notifier).openPlaylist(
      playlistId: playlist.id,
      playlistName: playlist.name,
      imageUrl: playlist.images.isNotEmpty ? playlist.images.first.url : null,
      source: NavigationSource.library,
    );
  }

  void _openLikedSongs() {
    ref.read(desktopNavigationProvider.notifier).openLikedSongs(
      source: NavigationSource.library,
    );
  }

  void _openAlbum(SpotifySimpleAlbum album) {
    ref.read(desktopNavigationProvider.notifier).openAlbum(
      albumId: album.id,
      albumName: album.name,
      imageUrl: album.images.isNotEmpty ? album.images.first.url : null,
      subtitle: album.artists.map((a) => a.name).join(', '),
      source: NavigationSource.library,
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
    
    // Check if we have auth failure (401 errors)
    final hasAuthFailure = plugin?.auth.hasApiFailure ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            toolbarHeight: 64,
            title: Row(
              children: [
                // Profile Avatar
                GestureDetector(
                  onTap: isAuthenticated ? null : _loginToSpotify,
                  child: MouseRegion(
                    cursor: isAuthenticated ? SystemMouseCursors.basic : SystemMouseCursors.click,
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

          // Not logged in state OR auth failure (401 errors)
          if (!isAuthenticated || hasAuthFailure) ...[
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
                          color: hasAuthFailure 
                              ? Colors.orange.withOpacity(0.2)
                              : AppTheme.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasAuthFailure ? Iconsax.warning_2 : Iconsax.music_library_2,
                          size: 40,
                          color: hasAuthFailure ? Colors.orange : AppTheme.primaryColor,
                        ),
                      ),
                      const Gap(24),
                      Text(
                        hasAuthFailure ? 'Spotify Connection Issue' : 'Connect to Spotify',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        hasAuthFailure 
                            ? 'Spotify integration on Windows desktop is currently limited.\nYou can still enjoy music from YouTube Music.'
                            : 'Login to access your playlists, liked songs, and more',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(32),
                      if (!hasAuthFailure)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton.icon(
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
                        ),
                      if (hasAuthFailure) ...[
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // Clear auth failure state and reset
                              if (plugin != null) {
                                await plugin.auth.logout();
                                plugin.auth.resetApiFailure();
                              }
                              ref.invalidate(isSpotifyPluginAuthenticatedProvider);
                            },
                            icon: const Icon(Iconsax.refresh),
                            label: const Text('Reset & Try Again'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
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
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SliverGap(16),

            // Recently Played Section (Spotify Home Data)
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
                                  child: _SpotifyTrackCard(
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
                                  child: _SpotifyTrackCard(
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
                                  child: _SpotifyArtistCard(
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
                                  child: _SpotifyArtistCard(
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
                                data: (tracks) => _SpotifyPlaylistCard(
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
                            child: _SpotifyPlaylistCard(
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
                                  child: _SpotifyAlbumCard(
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
                                          child: _SpotifyBrowseItemCard(
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

            // Bottom padding for player bar
            const SliverGap(100),
          ],
        ],
      ),
    );
  }

  void _openBrowseItem(SpotifyBrowseItem item) {
    if (item.type == 'playlist') {
      ref.read(desktopNavigationProvider.notifier).openPlaylist(
        playlistId: item.id,
        playlistName: item.name,
        imageUrl: item.imageUrl,
        source: NavigationSource.library,
      );
    } else if (item.type == 'album') {
      ref.read(desktopNavigationProvider.notifier).openAlbum(
        albumId: item.id,
        albumName: item.name,
        imageUrl: item.imageUrl,
        subtitle: item.subtitle,
        source: NavigationSource.library,
      );
    } else if (item.type == 'artist') {
      ref.read(desktopNavigationProvider.notifier).openArtist(
        artistId: item.id,
        artistName: item.name,
        imageUrl: item.imageUrl,
        source: NavigationSource.library,
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

/// Spotify-style track card
class _SpotifyTrackCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _SpotifyTrackCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<_SpotifyTrackCard> createState() => _SpotifyTrackCardState();
}

class _SpotifyTrackCardState extends State<_SpotifyTrackCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
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
                  if (_isHovered)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                widget.subtitle,
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
      ),
    );
  }
}

/// Spotify-style artist card (circular)
class _SpotifyArtistCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _SpotifyArtistCard({
    required this.name,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<_SpotifyArtistCard> createState() => _SpotifyArtistCardState();
}

class _SpotifyArtistCardState extends State<_SpotifyArtistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
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
                if (_isHovered)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(8),
            SizedBox(
              width: 120,
              child: Text(
                widget.name,
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
      ),
    );
  }
}

/// Spotify-style playlist card
class _SpotifyPlaylistCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isLikedSongs;
  final VoidCallback? onTap;

  const _SpotifyPlaylistCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.isLikedSongs = false,
    this.onTap,
  });

  @override
  State<_SpotifyPlaylistCard> createState() => _SpotifyPlaylistCardState();
}

class _SpotifyPlaylistCardState extends State<_SpotifyPlaylistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.isLikedSongs
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
                          : widget.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.imageUrl!,
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
                  if (_isHovered)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                widget.subtitle,
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
      ),
    );
  }
}

/// Spotify-style album card
class _SpotifyAlbumCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _SpotifyAlbumCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<_SpotifyAlbumCard> createState() => _SpotifyAlbumCardState();
}

class _SpotifyAlbumCardState extends State<_SpotifyAlbumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
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
                  if (_isHovered)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                widget.subtitle,
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
      ),
    );
  }
}

/// Spotify-style browse item card (for personalized content)
class _SpotifyBrowseItemCard extends StatefulWidget {
  final SpotifyBrowseItem item;
  final VoidCallback? onTap;

  const _SpotifyBrowseItemCard({
    required this.item,
    this.onTap,
  });

  @override
  State<_SpotifyBrowseItemCard> createState() => _SpotifyBrowseItemCardState();
}

class _SpotifyBrowseItemCardState extends State<_SpotifyBrowseItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isArtist = widget.item.type == 'artist';
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isArtist ? 70 : 8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isArtist ? 70 : 8),
                      child: widget.item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.item.imageUrl!,
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
                  if (_isHovered && !isArtist)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(8),
              Text(
                widget.item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                widget.item.subtitle,
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
      ),
    );
  }
}
