import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/features/search/widgets/genre_card.dart';
import 'package:sangeet/shared/providers/youtube_provider.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/search_models.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/search_history_service.dart';
import 'package:sangeet/features/artist/pages/artist_detail_page.dart';
import 'package:sangeet/features/album/pages/album_detail_page.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Search filter enum
enum SearchFilter { songs, artists, albums }

// Search state providers
final searchLoadingProvider = StateProvider<bool>((ref) => false);
final searchFilterProvider = StateProvider<SearchFilter>((ref) => SearchFilter.songs);
final searchResultsLocalProvider = StateProvider<List<Track>>((ref) => []);
final artistResultsProvider = StateProvider<List<SearchArtist>>((ref) => []);
final albumResultsProvider = StateProvider<List<SearchAlbum>>((ref) => []);
final searchHistoryProvider = StateProvider<List<String>>((ref) => []);

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchHistoryService _historyService = SearchHistoryService.instance;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    await _historyService.init();
    if (mounted) {
      ref.read(searchHistoryProvider.notifier).state = _historyService.getRecentSearches();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query, {SearchFilter? filter, bool saveToHistory = true}) async {
    if (query.isEmpty) {
      ref.read(searchResultsLocalProvider.notifier).state = [];
      ref.read(artistResultsProvider.notifier).state = [];
      ref.read(albumResultsProvider.notifier).state = [];
      return;
    }

    _lastQuery = query;
    final SearchFilter searchFilter = filter ?? ref.read(searchFilterProvider);
    ref.read(searchLoadingProvider.notifier).state = true;
    
    // Save to search history
    if (saveToHistory) {
      await _historyService.addSearch(query);
      ref.read(searchHistoryProvider.notifier).state = _historyService.getRecentSearches();
    }
    
    try {
      final musicSource = ref.read(musicSourceProvider);
      
      if (musicSource == MusicSource.ytMusic) {
        final ytMusic = ref.read(ytMusicServiceProvider);
        
        switch (searchFilter) {
          case SearchFilter.songs:
            final results = await ytMusic.searchSongs(query, limit: 30);
            ref.read(searchResultsLocalProvider.notifier).state = results;
          case SearchFilter.artists:
            final results = await ytMusic.searchArtists(query, limit: 20);
            ref.read(artistResultsProvider.notifier).state = results;
          case SearchFilter.albums:
            final results = await ytMusic.searchAlbums(query, limit: 20);
            ref.read(albumResultsProvider.notifier).state = results;
        }
      } else {
        // YouTube source only supports songs
        final youtube = ref.read(youtubeServiceProvider);
        final results = await youtube.searchMusic(query, limit: 30);
        ref.read(searchResultsLocalProvider.notifier).state = results;
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      ref.read(searchLoadingProvider.notifier).state = false;
    }
  }
  
  void _onFilterChanged(SearchFilter filter) {
    ref.read(searchFilterProvider.notifier).state = filter;
    if (_lastQuery.isNotEmpty) {
      _performSearch(_lastQuery, filter: filter, saveToHistory: false);
    }
  }
  
  void _searchFromHistory(String query) {
    _searchController.text = query;
    _performSearch(query, saveToHistory: false);
  }
  
  Future<void> _removeFromHistory(String query) async {
    await _historyService.removeSearch(query);
    ref.read(searchHistoryProvider.notifier).state = _historyService.getRecentSearches();
  }
  
  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    ref.read(searchHistoryProvider.notifier).state = [];
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(searchLoadingProvider);
    final searchFilter = ref.watch(searchFilterProvider);
    final searchResults = ref.watch(searchResultsLocalProvider);
    final artistResults = ref.watch(artistResultsProvider);
    final albumResults = ref.watch(albumResultsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Search',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_searchController.text.isNotEmpty ? 108 : 60),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Gap(12),
                          const Icon(
                            Iconsax.search_normal,
                            color: Colors.black54,
                          ),
                          const Gap(12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search songs, artists...',
                                hintStyle: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: _performSearch,
                              onChanged: (value) {
                                setState(() {});
                                // Debounced search
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (_searchController.text == value && value.length >= 2) {
                                    _performSearch(value);
                                  }
                                });
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _lastQuery = '';
                                ref.read(searchResultsLocalProvider.notifier).state = [];
                                ref.read(artistResultsProvider.notifier).state = [];
                                ref.read(albumResultsProvider.notifier).state = [];
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black54,
                              ),
                            ),
                          // Music source toggle (YTM/YT)
                          _MusicSourceToggle(
                            onSourceChanged: () {
                              if (_lastQuery.isNotEmpty) {
                                _performSearch(_lastQuery, saveToHistory: false);
                              }
                            },
                          ),
                          const Gap(8),
                        ],
                      ),
                    ),
                  ),
                  // Filter chips - only show when searching
                  if (_searchController.text.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _FilterChip(
                            label: 'Songs',
                            isSelected: searchFilter == SearchFilter.songs,
                            onTap: () => _onFilterChanged(SearchFilter.songs),
                          ),
                          const Gap(8),
                          _FilterChip(
                            label: 'Artists',
                            isSelected: searchFilter == SearchFilter.artists,
                            onTap: () => _onFilterChanged(SearchFilter.artists),
                          ),
                          const Gap(8),
                          _FilterChip(
                            label: 'Albums',
                            isSelected: searchFilter == SearchFilter.albums,
                            onTap: () => _onFilterChanged(SearchFilter.albums),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Content
          if (_searchController.text.isEmpty) ...[
            // Search History Section
            if (ref.watch(searchHistoryProvider).isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent searches',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearHistory,
                        child: Text(
                          'Clear all',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final query = ref.watch(searchHistoryProvider)[index];
                    return ListTile(
                      leading: const Icon(Iconsax.clock, size: 20),
                      title: Text(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeFromHistory(query),
                      ),
                      onTap: () => _searchFromHistory(query),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                    );
                  },
                  childCount: ref.watch(searchHistoryProvider).length,
                ),
              ),
              const SliverGap(16),
            ],
            
            // Browse Categories Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  'Browse all',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            
            // Genre Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                delegate: SliverChildListDelegate([
                  GenreCard(
                    title: 'Pop',
                    color: const Color(0xFFE13300),
                    imageUrl: 'https://i.ytimg.com/vi/JGwWNGJdvx8/maxresdefault.jpg',
                    onTap: () => _searchGenre('pop songs 2024'),
                  ),
                  GenreCard(
                    title: 'Hip-Hop',
                    color: const Color(0xFFBA5D07),
                    imageUrl: 'https://i.ytimg.com/vi/RubBzkZzpUA/maxresdefault.jpg',
                    onTap: () => _searchGenre('hip hop songs 2024'),
                  ),
                  GenreCard(
                    title: 'Rock',
                    color: const Color(0xFFE91429),
                    imageUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/maxresdefault.jpg',
                    onTap: () => _searchGenre('rock songs'),
                  ),
                  GenreCard(
                    title: 'Indie',
                    color: const Color(0xFF8D67AB),
                    imageUrl: 'https://i.ytimg.com/vi/pBkHHoOIIn8/maxresdefault.jpg',
                    onTap: () => _searchGenre('indie music'),
                  ),
                  GenreCard(
                    title: 'Bollywood',
                    color: const Color(0xFF1E3264),
                    imageUrl: 'https://i.ytimg.com/vi/vGJTaP6anOU/maxresdefault.jpg',
                    onTap: () => _searchGenre('bollywood songs 2024'),
                  ),
                  GenreCard(
                    title: 'Punjabi',
                    color: const Color(0xFF477D95),
                    imageUrl: 'https://i.ytimg.com/vi/w0AOGeqOnFY/maxresdefault.jpg',
                    onTap: () => _searchGenre('punjabi songs 2024'),
                  ),
                  GenreCard(
                    title: 'Electronic',
                    color: const Color(0xFF0D73EC),
                    imageUrl: 'https://i.ytimg.com/vi/5qap5aO4i9A/maxresdefault.jpg',
                    onTap: () => _searchGenre('electronic music'),
                  ),
                  GenreCard(
                    title: 'Lofi',
                    color: const Color(0xFF503750),
                    imageUrl: 'https://i.ytimg.com/vi/jfKfPfyJRdk/maxresdefault.jpg',
                    onTap: () => _searchGenre('lofi hip hop'),
                  ),
                  GenreCard(
                    title: 'R&B',
                    color: const Color(0xFFDC148C),
                    imageUrl: 'https://i.ytimg.com/vi/450p7goxZqg/maxresdefault.jpg',
                    onTap: () => _searchGenre('r&b songs'),
                  ),
                  GenreCard(
                    title: 'Classical',
                    color: const Color(0xFF8C1932),
                    imageUrl: 'https://i.ytimg.com/vi/4Tr0otuiQuU/maxresdefault.jpg',
                    onTap: () => _searchGenre('classical music'),
                  ),
                  GenreCard(
                    title: 'Jazz',
                    color: const Color(0xFF1E3264),
                    imageUrl: 'https://i.ytimg.com/vi/Dx5qFachd3A/maxresdefault.jpg',
                    onTap: () => _searchGenre('jazz music'),
                  ),
                  GenreCard(
                    title: 'Workout',
                    color: const Color(0xFF006450),
                    imageUrl: 'https://i.ytimg.com/vi/gCYcHz2k5x0/maxresdefault.jpg',
                    onTap: () => _searchGenre('workout music'),
                  ),
                ]),
              ),
            ),
          ] else if (searchFilter == SearchFilter.songs) ...[
            // Search Results
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
              )
            else if (searchResults.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.search_normal,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const Gap(16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = searchResults[index];
                    return _SearchResultTile(
                      track: track,
                      onTap: () {
                        final audioService = ref.read(audioPlayerServiceProvider);
                        audioService.playAll(searchResults, startIndex: index);
                      },
                    );
                  },
                  childCount: searchResults.length,
                ),
              ),
          ] else if (searchFilter == SearchFilter.artists) ...[
            // Artist Results
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
              )
            else if (artistResults.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.user,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const Gap(16),
                        Text(
                          'No artists found',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final artist = artistResults[index];
                    return _ArtistResultTile(
                      artist: artist,
                      onTap: () {
                        // Use navigation provider on desktop, Navigator on mobile
                        final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
                        if (isDesktop) {
                          ref.read(desktopNavigationProvider.notifier).openArtist(
                            artistId: artist.id,
                            artistName: artist.name,
                            imageUrl: artist.thumbnailUrl,
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistDetailPage(
                                artistId: artist.id,
                                artistName: artist.name,
                                thumbnailUrl: artist.thumbnailUrl,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: artistResults.length,
                ),
              ),
          ] else if (searchFilter == SearchFilter.albums) ...[
            // Album Results
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
              )
            else if (albumResults.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.music_square,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const Gap(16),
                        Text(
                          'No albums found',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final album = albumResults[index];
                    return _AlbumResultTile(
                      album: album,
                      onTap: () {
                        // Use navigation provider on desktop, Navigator on mobile
                        final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
                        if (isDesktop) {
                          ref.read(desktopNavigationProvider.notifier).openAlbum(
                            albumId: album.id,
                            albumName: album.title,
                            imageUrl: album.thumbnailUrl,
                            subtitle: album.artist,
                            isYouTube: true, // Search results are from YouTube
                          );
                        } else {
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
                        }
                      },
                    );
                  },
                  childCount: albumResults.length,
                ),
              ),
          ],
          
          // Bottom padding
          const SliverGap(140),
        ],
      ),
    );
  }

  void _searchGenre(String genre) {
    _searchController.text = genre;
    _performSearch(genre);
  }
}

class _SearchResultTile extends ConsumerWidget {
  final Track track;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.track,
    required this.onTap,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final isCurrentTrack = currentTrack?.id == track.id;
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: track.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                memCacheWidth: 720,
                memCacheHeight: 720,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.darkCard,
                ),
                // Fallback to hqdefault if maxresdefault fails
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: url.contains('maxresdefault.jpg') 
                      ? url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg')
                      : url,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.darkCard,
                child: const Icon(Iconsax.music, color: Colors.grey),
              ),
      ),
      title: Row(
        children: [
          // Show playing indicator for current track
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.duration),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const Gap(8),
          Icon(
            isCurrentTrack ? (isPlaying ? Iconsax.pause5 : Iconsax.play5) : Iconsax.play5, 
            size: 20, 
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ArtistResultTile extends StatelessWidget {
  final SearchArtist artist;
  final VoidCallback onTap;

  const _ArtistResultTile({
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipOval(
        child: artist.thumbnailUrl != null && artist.thumbnailUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: artist.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.user, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.user, color: Colors.grey),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.darkCard,
                child: const Icon(Iconsax.user, color: Colors.grey),
              ),
      ),
      title: Text(
        artist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Artist${artist.subscribersText != null ? ' • ${artist.subscribersText}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
    );
  }
}

class _AlbumResultTile extends StatelessWidget {
  final SearchAlbum album;
  final VoidCallback onTap;

  const _AlbumResultTile({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: album.thumbnailUrl != null && album.thumbnailUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: album.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.music_square, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.music_square, color: Colors.grey),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.darkCard,
                child: const Icon(Iconsax.music_square, color: Colors.grey),
              ),
      ),
      title: Text(
        album.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${album.albumType ?? 'Album'}${album.artist != null ? ' • ${album.artist}' : ''}${album.year != null ? ' • ${album.year}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
    );
  }
}

/// Music source toggle widget for search bar
class _MusicSourceToggle extends ConsumerWidget {
  final VoidCallback? onSourceChanged;

  const _MusicSourceToggle({this.onSourceChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicSource = ref.watch(musicSourceProvider);
    
    return GestureDetector(
      onTap: () async {
        final settingsService = ref.read(settingsServiceProvider.notifier);
        final newSource = musicSource == MusicSource.ytMusic 
            ? MusicSource.youtube 
            : MusicSource.ytMusic;
        await settingsService.setMusicSource(newSource);
        onSourceChanged?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: musicSource == MusicSource.ytMusic 
              ? Colors.red.shade700 
              : Colors.red.shade900,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          musicSource == MusicSource.ytMusic ? 'YTM' : 'YT',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
