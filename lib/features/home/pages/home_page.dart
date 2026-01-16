import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/features/home/widgets/section_header.dart';
import 'package:sangeet/features/home/widgets/track_card.dart';
import 'package:sangeet/features/home/widgets/quick_pick_card.dart';
import 'package:sangeet/shared/providers/youtube_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/quick_picks_provider.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/related_page.dart';
import 'package:sangeet/features/album/pages/album_detail_page.dart';
import 'package:sangeet/features/artist/pages/artist_detail_page.dart';
import 'package:sangeet/features/settings/pages/settings_page.dart';
import 'package:sangeet/features/playlist/pages/liked_songs_page.dart';
import 'package:sangeet/features/playlist/pages/custom_playlists_page.dart';
import 'package:sangeet/features/discover/pages/daily_mixes_page.dart';
import 'package:sangeet/features/discover/pages/music_recognition_page.dart';
import 'package:sangeet/features/stats/pages/analytics_dashboard_page.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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

    // Load quick picks on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!quickPicks.isLoading && quickPicks.relatedPage == null && quickPicks.error == null) {
        ref.read(quickPicksProvider.notifier).load();
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingMusicProvider);
          ref.invalidate(newReleasesProvider);
          ref.invalidate(topHitsProvider);
          ref.invalidate(chillMusicProvider);
          ref.invalidate(bollywoodHitsProvider);
          ref.invalidate(forYouProvider);
          ref.invalidate(moreFromArtistsProvider);
          ref.invalidate(discoveredForYouProvider);
          ref.read(quickPicksProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
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
                      fontSize: 24,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Quick Picks Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.5,
                  children: [
                    QuickPickCard(
                      title: 'Liked Songs',
                      imageUrl: '',
                      imageGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1CAD45), Color(0xFF45BA7A)],
                      ),
                      icon: Icons.favorite,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LikedSongsPage()),
                        );
                      },
                    ),
                    QuickPickCard(
                      title: 'My Playlists',
                      imageUrl: '',
                      imageGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                      ),
                      icon: Icons.playlist_play,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomPlaylistsPage()),
                        );
                      },
                    ),
                    QuickPickCard(
                      title: 'Daily Mixes',
                      imageUrl: '',
                      imageGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
                      ),
                      icon: Icons.auto_awesome,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DailyMixesPage()),
                        );
                      },
                    ),
                    QuickPickCard(
                      title: 'Your Stats',
                      imageUrl: '',
                      imageGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      icon: Icons.bar_chart,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AnalyticsDashboardPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverGap(24),

            // Quick Picks Section (personalized based on listening history)
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

            // Similar Artists Section (from quick picks)
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

            // Related Albums Section (from quick picks)
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
            
            // For You Section (personalized based on artists)
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
            
            // Discovered For You Section (based on listening behavior)
            SliverToBoxAdapter(
              child: _buildDiscoveredSection(context, ref),
            ),
            
            // Trending Section (personalized by language)
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
            
            // Top Hits Section (personalized by language)
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
            
            // Second Language or Bollywood Section
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
            
            // More from artists section
            if (userPrefs.selectedArtists.length > 2)
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'More from ${userPrefs.selectedArtists[2].name}',
                  tracksAsync: moreFromArtists,
                  context: context,
                  ref: ref,
                ),
              ),
            
            // Chill Music Section
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
            
            // New Releases Section
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
            
            // Bottom padding for mini player
            const SliverGap(140),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Track>> tracksAsync,
  ) {
    return tracksAsync.when(
      data: (tracks) {
        // Return empty widget if no tracks
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
                child: TrackCard(
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
      loading: () => SizedBox(
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
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(), // Hide on error
    );
  }
  
  /// Build a section with header only if data is available
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
                    child: TrackCard(
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
          SizedBox(
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
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(24),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  /// Build discovered for you section - only shows if user has listening history
  Widget _buildDiscoveredSection(BuildContext context, WidgetRef ref) {
    final discoveredTracks = ref.watch(discoveredForYouProvider);
    
    return discoveredTracks.when(
      data: (tracks) {
        // Only show if we have discovered tracks
        if (tracks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Discovered For You',
              actionText: 'See all',
            ),
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
                    child: TrackCard(
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
      loading: () => const SizedBox.shrink(), // Don't show loading for discovered
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Build quick picks list from personalized recommendations
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
            child: TrackCard(
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
  }

  /// Build loading shimmer list
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
                width: 150,
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

  /// Build artists list from related page
  Widget _buildArtistsList(BuildContext context, WidgetRef ref, List<RelatedArtist> artists) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
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
              },
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
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
                    width: 100,
                    child: Text(
                      artist.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build albums list from related page
  Widget _buildAlbumsList(BuildContext context, WidgetRef ref, List<RelatedAlbum> albums) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
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
                  if (album.artist != null)
                    SizedBox(
                      width: 130,
                      child: Text(
                        album.artist!,
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
        },
      ),
    );
  }
}
