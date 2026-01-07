import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/features/desktop/pages/desktop_home_page.dart';
import 'package:sangeet/features/desktop/pages/desktop_library_page.dart';
import 'package:sangeet/features/search/pages/search_page.dart';
import 'package:sangeet/features/playlist/pages/playlist_detail_page.dart';
import 'package:sangeet/features/artist/pages/artist_detail_page.dart';
import 'package:sangeet/features/album/pages/album_detail_page.dart';
import 'package:sangeet/features/desktop/widgets/desktop_sidebar.dart';
import 'package:sangeet/features/desktop/widgets/desktop_now_playing_panel.dart';
import 'package:sangeet/features/desktop/widgets/desktop_player_bar.dart';
import 'package:sangeet/models/spotify_models.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  int _selectedNavIndex = 0;
  String? _selectedPlaylistId;
  bool _isLikedSongsSelected = false;
  String? _selectedPlaylistName;
  String? _selectedPlaylistImageUrl;
  
  // Content to show in center panel
  Widget _centerContent = const DesktopHomePage();

  void _handleNavigationChange(DesktopNavigationState navState) {
    if (navState.contentOverride != null) {
      setState(() {
        _centerContent = navState.contentOverride!;
      });
    } else if (navState.isLikedSongs) {
      setState(() {
        _selectedPlaylistId = null;
        _isLikedSongsSelected = true;
        _centerContent = const PlaylistDetailPage.likedSongs(
          key: ValueKey('liked_songs'),
          isEmbedded: true,
        );
      });
    } else if (navState.isArtist) {
      setState(() {
        _selectedPlaylistId = null;
        _isLikedSongsSelected = false;
        _centerContent = ArtistDetailPage(
          key: ValueKey('artist_${navState.artistId}'),
          artistId: navState.artistId!,
          artistName: navState.artistName!,
          thumbnailUrl: navState.imageUrl,
          subscribersText: navState.artistSubscribersText,
          isEmbedded: true,
        );
      });
    } else if (navState.playlistId != null) {
      setState(() {
        _selectedPlaylistId = navState.playlistId;
        _isLikedSongsSelected = false;
        if (navState.isAlbum) {
          if (navState.isMusicAlbum) {
            // YouTube album - use AlbumDetailPage
            _centerContent = AlbumDetailPage(
              key: ValueKey('yt_album_${navState.playlistId}'),
              albumId: navState.playlistId!,
              albumName: navState.playlistName!,
              artistName: navState.albumSubtitle,
              thumbnailUrl: navState.imageUrl,
              isEmbedded: true,
            );
          } else {
            // Spotify album - use PlaylistDetailPage.album
            _centerContent = PlaylistDetailPage.album(
              key: ValueKey('album_${navState.playlistId}'),
              playlistId: navState.playlistId!,
              playlistName: navState.playlistName!,
              imageUrl: navState.imageUrl,
              subtitle: navState.albumSubtitle,
              isEmbedded: true,
            );
          }
        } else {
          _centerContent = PlaylistDetailPage(
            key: ValueKey('playlist_${navState.playlistId}'),
            playlistId: navState.playlistId!,
            playlistName: navState.playlistName!,
            imageUrl: navState.imageUrl,
            isEmbedded: true,
          );
        }
      });
    } else {
      // Navigation cleared - return to appropriate page based on source
      // Note: source is already consumed by goBack(), so we check _selectedNavIndex
      // to determine where to go back to
      setState(() {
        _selectedPlaylistId = null;
        _isLikedSongsSelected = false;
        // Return to the page based on current nav index
        switch (_selectedNavIndex) {
          case 0:
            _centerContent = const DesktopHomePage();
            break;
          case 1:
            _centerContent = const SearchPage();
            break;
          case 2:
            _centerContent = const DesktopLibraryPage();
            break;
          default:
            _centerContent = const DesktopHomePage();
        }
      });
    }
  }

  void _onNavSelected(int index) {
    ref.read(desktopNavigationProvider.notifier).clear();
    setState(() {
      _selectedNavIndex = index;
      _selectedPlaylistId = null;
      _isLikedSongsSelected = false;
      
      switch (index) {
        case 0:
          _centerContent = const DesktopHomePage();
          break;
        case 1:
          _centerContent = const SearchPage();
          break;
        case 2:
          _centerContent = const DesktopLibraryPage();
          break;
      }
    });
  }

  void _onPlaylistSelected(SpotifySimplePlaylist playlist) {
    final imageUrl = playlist.images.isNotEmpty ? playlist.images.first.url : null;
    ref.read(desktopNavigationProvider.notifier).openPlaylist(
      playlistId: playlist.id,
      playlistName: playlist.name,
      imageUrl: imageUrl,
    );
  }

  void _onLikedSongsSelected() {
    ref.read(desktopNavigationProvider.notifier).openLikedSongs();
  }

  void _onHomeSelected() {
    ref.read(desktopNavigationProvider.notifier).clear();
    setState(() {
      _selectedPlaylistId = null;
      _isLikedSongsSelected = false;
      _centerContent = const DesktopHomePage();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to navigation provider changes
    ref.listen<DesktopNavigationState>(desktopNavigationProvider, (previous, next) {
      _handleNavigationChange(next);
    });
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left Sidebar (narrow icon bar)
                DesktopSidebar(
                  selectedNavIndex: _selectedNavIndex,
                  onNavSelected: _onNavSelected,
                  selectedPlaylistId: _selectedPlaylistId,
                  isLikedSongsSelected: _isLikedSongsSelected,
                  onPlaylistSelected: _onPlaylistSelected,
                  onLikedSongsSelected: _onLikedSongsSelected,
                  onHomeSelected: _onHomeSelected,
                ),
                
                // Center Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _centerContent,
                  ),
                ),
                
                // Right Panel (Now Playing)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const DesktopNowPlayingPanel(),
                ),
              ],
            ),
          ),
          
          // Bottom Player Bar
          const DesktopPlayerBar(),
        ],
      ),
    );
  }
}
