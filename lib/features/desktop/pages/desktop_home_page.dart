import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/features/home/widgets/section_header.dart';
import 'package:sangeet/shared/providers/youtube_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/quick_picks_provider.dart';
import 'package:sangeet/shared/providers/spotify_plugin_provider.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/related_page.dart';
import 'package:sangeet/features/settings/pages/settings_page.dart';
import 'package:sangeet/features/playlist/pages/custom_playlists_page.dart';
import 'package:sangeet/features/playlist/pages/liked_songs_page.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:shimmer/shimmer.dart';

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class DesktopHomePage extends ConsumerWidget {
  const DesktopHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingMusic = ref.watch(trendingMusicProvider);
    final newReleases = ref.watch(newReleasesProvider);
    final topHits = ref.watch(topHitsProvider);
    final chillMusic = ref.watch(chillMusicProvider);
    final bollywoodHits = ref.watch(bollywoodHitsProvider);
    final forYou = ref.watch(forYouProvider);
    final moreFromArtists = ref.watch(moreFromArtistsProvider);
    final userPrefs = ref.watch(userPreferencesServiceProvider);
    final quickPicks = ref.watch(quickPicksProvider);
    final isAuthenticated = ref.watch(isSpotifyPluginAuthenticatedProvider);
    final playlists = ref.watch(spotifyPluginPlaylistsProvider);
    final likedTracks = ref.watch(spotifyPluginLikedTracksProvider);

    // Load quick picks on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!quickPicks.isLoading && quickPicks.relatedPage == null && quickPicks.error == null) {
        ref.read(quickPicksProvider.notifier).load();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // Top bar with search
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            toolbarHeight: 64,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.music,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Gap(12),
                const Text(
                  'Sangeet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Gap(24),
                // Search bar
                Expanded(
                  child: Container(
                    height: 40,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Gap(12),
                        Icon(Iconsax.search_normal, size: 18, color: Colors.grey.shade400),
                        const Gap(8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'What do you want to play?',
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (query) {
                              // TODO: Navigate to search with query
                            },
                          ),
                        ),
                        const Gap(12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.notification),
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
              const Gap(8),
            ],
          ),
          
          // Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Quick Picks Grid - Spotify style small tiles (4 columns on desktop)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 4.0, // Compact tiles
                    children: [
                      // Liked Songs (Sangeet local liked songs)
                      _DesktopQuickTile(
                        title: 'Liked Songs',
                        gradient:  const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF10A139), Color(0xFF82E0AD)],
                        ),
                        icon: Iconsax.heart5,
                        onTap: () {
                          ref.read(desktopNavigationProvider.notifier).setContent(const LikedSongsPage());
                        },
                      ),
                      // My Playlists
                      _DesktopQuickTile(
                        title: 'My Playlists',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                        ),
                        icon: Iconsax.music_playlist,
                        onTap: () {
                          ref.read(desktopNavigationProvider.notifier).setContent(const CustomPlaylistsPage());
                        },
                      ),
                      // Spotify playlists if authenticated
                      if (isAuthenticated && playlists.hasValue) ...[
                        ...playlists.value!.take(6).map((playlist) => _DesktopQuickTile(
                          title: playlist.name,
                          imageUrl: playlist.images.isNotEmpty ? playlist.images.first.url : null,
                          onTap: () {
                            ref.read(desktopNavigationProvider.notifier).openPlaylist(
                              playlistId: playlist.id,
                              playlistName: playlist.name,
                              imageUrl: playlist.images.isNotEmpty ? playlist.images.first.url : null,
                            );
                          },
                        )),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          
          const SliverGap(24),

          // Quick Picks Section
          if (quickPicks.searchSongs != null && quickPicks.searchSongs!.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Quick Picks',
                actionText: 'See all',
              ),
            ),
            SliverToBoxAdapter(
              child: _buildQuickPicksList(context, ref, quickPicks.searchSongs!),
            ),
            const SliverGap(24),
          ] else if (quickPicks.relatedPage != null && quickPicks.relatedPage!.songs != null) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Quick Picks',
                actionText: 'See all',
              ),
            ),
            SliverToBoxAdapter(
              child: _buildQuickPicksList(context, ref, quickPicks.relatedPage!.songs!),
            ),
            const SliverGap(24),
          ] else if (quickPicks.isLoading) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Quick Picks',
                actionText: 'See all',
              ),
            ),
            SliverToBoxAdapter(
              child: _buildLoadingList(),
            ),
            const SliverGap(24),
          ],

          // Similar Artists Section
          if (quickPicks.relatedPage?.artists != null && 
              quickPicks.relatedPage!.artists!.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Similar Artists',
                actionText: 'See all',
              ),
            ),
            SliverToBoxAdapter(
              child: _buildArtistsList(context, ref, quickPicks.relatedPage!.artists!),
            ),
            const SliverGap(24),
          ],

          // Related Albums Section
          if (quickPicks.relatedPage?.albums != null && 
              quickPicks.relatedPage!.albums!.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Related Albums',
                actionText: 'See all',
              ),
            ),
            SliverToBoxAdapter(
              child: _buildAlbumsList(context, ref, quickPicks.relatedPage!.albums!),
            ),
            const SliverGap(24),
          ],
          
          // For You Section
          if (userPrefs.selectedArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Made For You',
                actionText: 'See all',
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTrackList(context, ref, forYou),
            ),
            const SliverGap(24),
          ],
          
          // Trending Section
          SliverToBoxAdapter(
            child: _buildSection(
              title: userPrefs.selectedLanguages.isNotEmpty
                  ? '${userPrefs.selectedLanguages.first.displayName} Trending'
                  : 'Trending Now',
              tracksAsync: trendingMusic,
              context: context,
              ref: ref,
            ),
          ),
          
          // Top Hits Section
          SliverToBoxAdapter(
            child: _buildSection(
              title: userPrefs.selectedLanguages.isNotEmpty
                  ? '${userPrefs.selectedLanguages.first.displayName} Top Hits'
                  : 'Top Hits',
              tracksAsync: topHits,
              context: context,
              ref: ref,
            ),
          ),
          
          // Bollywood Section
          SliverToBoxAdapter(
            child: _buildSection(
              title: userPrefs.selectedLanguages.length > 1
                  ? '${userPrefs.selectedLanguages[1].displayName} Hits'
                  : 'Bollywood Hits',
              tracksAsync: bollywoodHits,
              context: context,
              ref: ref,
            ),
          ),
          
          // More from artists
          if (userPrefs.selectedArtists.length > 2)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'More from ${userPrefs.selectedArtists[2].name}',
                tracksAsync: moreFromArtists,
                context: context,
                ref: ref,
              ),
            ),
          
          // Chill Music
          SliverToBoxAdapter(
            child: _buildSection(
              title: userPrefs.selectedLanguages.isNotEmpty
                  ? '${userPrefs.selectedLanguages.first.displayName} Chill'
                  : 'Chill & Relax',
              tracksAsync: chillMusic,
              context: context,
              ref: ref,
            ),
          ),
          
          // New Releases
          SliverToBoxAdapter(
            child: _buildSection(
              title: userPrefs.selectedLanguages.isNotEmpty
                  ? 'New ${userPrefs.selectedLanguages.first.displayName} Releases'
                  : 'New Releases',
              tracksAsync: newReleases,
              context: context,
              ref: ref,
            ),
          ),
          
          // Bottom padding for player bar
          const SliverGap(100),
        ],
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, WidgetRef ref, AsyncValue<List<Track>> tracksAsync) {
    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _DesktopTrackCard(
                  track: track,
                  onTap: () {
                    // Play single track with auto-queue enabled for home page
                    final audioService = ref.read(audioPlayerServiceProvider);
                    audioService.play(track, source: PlaySource.homeSingleSong);
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingList(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  Widget _buildSection({
    required String title,
    required AsyncValue<List<Track>> tracksAsync,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, actionText: 'See all'),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _DesktopTrackCard(
                      track: track,
                      onTap: () {
                        // Play single track with auto-queue enabled for home page
                        final audioService = ref.read(audioPlayerServiceProvider);
                        audioService.play(track, source: PlaySource.homeSingleSong);
                      },
                    ),
                  );
                },
              ),
            ),
            const Gap(24),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, actionText: 'See all'),
          _buildLoadingList(),
          const Gap(24),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildQuickPicksList(BuildContext context, WidgetRef ref, List<Track> tracks) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _DesktopTrackCard(
              track: track,
              onTap: () {
                final audioService = ref.read(audioPlayerServiceProvider);
                audioService.playAll(tracks, startIndex: index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return SizedBox(
      height: 200,
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

  Widget _buildArtistsList(BuildContext context, WidgetRef ref, List<RelatedArtist> artists) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ref.read(desktopNavigationProvider.notifier).openArtist(
                    artistId: artist.id,
                    artistName: artist.name,
                    imageUrl: artist.thumbnailUrl,
                    subscribersText: artist.subscribersText,
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: artist.thumbnailUrl != null
                            ? DecorationImage(
                                image: NetworkImage(artist.thumbnailUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: AppTheme.darkCard,
                      ),
                      child: artist.thumbnailUrl == null
                          ? const Icon(Iconsax.user, size: 40, color: Colors.grey)
                          : null,
                    ),
                    const Gap(8),
                    SizedBox(
                      width: 120,
                      child: Text(
                        artist.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsList(BuildContext context, WidgetRef ref, List<RelatedAlbum> albums) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ref.read(desktopNavigationProvider.notifier).openAlbum(
                    albumId: album.id,
                    albumName: album.title,
                    imageUrl: album.thumbnailUrl,
                    subtitle: album.artist,
                    isYouTube: true, // Home page albums are from YouTube
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
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
                      width: 140,
                      child: Text(
                        album.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (album.artist != null)
                      SizedBox(
                        width: 140,
                        child: Text(
                          album.artist!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small quick tile for home page
class _DesktopQuickTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Gradient? gradient;
  final IconData? icon;
  final VoidCallback? onTap;

  const _DesktopQuickTile({
    required this.title,
    this.imageUrl,
    this.gradient,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Image/Icon
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                child: gradient != null
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(gradient: gradient),
                        child: icon != null
                            ? Icon(icon, color: Colors.white, size: 20)
                            : null,
                      )
                    : imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: AppTheme.darkCard,
                              child: const Icon(Iconsax.music, color: Colors.grey, size: 20),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music, color: Colors.grey, size: 20),
                          ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smaller track card for desktop
class _DesktopTrackCard extends StatefulWidget {
  final Track track;
  final VoidCallback? onTap;

  const _DesktopTrackCard({
    required this.track,
    this.onTap,
  });

  @override
  State<_DesktopTrackCard> createState() => _DesktopTrackCardState();
}

class _DesktopTrackCardState extends State<_DesktopTrackCard> {
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
          height: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album art with play button overlay
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
                      child: CachedNetworkImage(
                        imageUrl: widget.track.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        memCacheWidth: 280,
                        memCacheHeight: 280,
                        errorWidget: (context, url, error) {
                          if (url.contains('maxresdefault.jpg')) {
                            return CachedNetworkImage(
                              imageUrl: url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg'),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.darkCard,
                                child: const Icon(Iconsax.music, color: Colors.grey, size: 40),
                              ),
                            );
                          }
                          return Container(
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music, color: Colors.grey, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                  // Play button on hover
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
              // Title
              Text(
                widget.track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              // Artist
              Text(
                widget.track.artist,
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
