import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/services/spotify_plugin/spotify_plugin.dart';
import 'package:sangeet/models/spotify_models.dart';
import 'package:sangeet/services/spotify_plugin/endpoints/browse_endpoint.dart';

/// Provider for the Plugin Service
/// This is the main entry point for all plugin functionality
final spotifyPluginProvider = Provider<SpotifyPluginService?>((ref) {
  return SpotifyPluginService.instance;
});

/// Auth state stream from the plugin - reactive updates when auth changes
final spotifyPluginAuthStateProvider = StreamProvider<bool>((ref) {
  final plugin = ref.watch(spotifyPluginProvider);
  if (plugin == null) {
    return const Stream.empty();
  }
  return plugin.auth.authStateStream;
});

/// Is authenticated check - watches the stream for reactive updates
final isSpotifyPluginAuthenticatedProvider = Provider<bool>((ref) {
  final plugin = ref.watch(spotifyPluginProvider);
  if (plugin == null) return false;
  
  // Watch the auth state stream for reactive updates
  // This ensures providers refresh when auth state changes
  final authState = ref.watch(spotifyPluginAuthStateProvider);
  
  // If stream has data, use it; otherwise fall back to direct check
  return authState.when(
    data: (isAuth) => isAuth,
    loading: () {
      try {
        return plugin.auth.isAuthenticated();
      } catch (e) {
        return false;
      }
    },
    error: (_, __) {
      try {
        return plugin.auth.isAuthenticated();
      } catch (e) {
        return false;
      }
    },
  );
});

/// Current user profile
final spotifyPluginUserProvider = FutureProvider<SpotifyUser?>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return null;
  
  try {
    return await plugin.user.me();
  } catch (e) {
    print('SpotifyPlugin: Error getting user: $e');
    return null;
  }
});

/// User's saved/liked tracks (fetches all with pagination)
final spotifyPluginLikedTracksProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  print('SpotifyPlugin: Fetching liked tracks - plugin: ${plugin != null}, isAuth: $isAuth');
  
  if (plugin == null || !isAuth) {
    print('SpotifyPlugin: Skipping liked tracks fetch - not authenticated');
    return [];
  }
  
  try {
    final allTracks = <SpotifyTrack>[];
    int offset = 0;
    const limit = 50;
    
    while (true) {
      print('SpotifyPlugin: Fetching liked tracks page at offset $offset');
      final response = await plugin.user.savedTracks(limit: limit, offset: offset);
      print('SpotifyPlugin: Got ${response.items.length} liked tracks in this page');
      allTracks.addAll(response.items);
      
      // Stop if we got fewer items than requested (no more pages)
      if (response.items.length < limit) break;
      offset += limit;
      
      // Safety limit to prevent infinite loops
      if (offset > 2000) break;
    }
    
    print('SpotifyPlugin: Total liked tracks: ${allTracks.length}');
    return allTracks;
  } catch (e, stack) {
    print('SpotifyPlugin: Error getting liked tracks: $e');
    // Check for 401 errors - mark auth as failed
    if (e.toString().contains('401')) {
      plugin.auth.markAuthFailed();
    }
    return [];
  }
});

/// User's playlists
final spotifyPluginPlaylistsProvider = FutureProvider<List<SpotifySimplePlaylist>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  print('SpotifyPlugin: Fetching playlists - plugin: ${plugin != null}, isAuth: $isAuth');
  
  if (plugin == null || !isAuth) {
    print('SpotifyPlugin: Skipping playlists fetch - not authenticated');
    return [];
  }
  
  try {
    final response = await plugin.user.savedPlaylists(limit: 50);
    print('SpotifyPlugin: Got ${response.items.length} playlists');
    return response.items;
  } catch (e, stack) {
    print('SpotifyPlugin: Error getting playlists: $e');
    // Check for 401 errors - mark auth as failed
    if (e.toString().contains('401')) {
      plugin.auth.markAuthFailed();
    }
    return [];
  }
});

/// User's saved albums
final spotifyPluginSavedAlbumsProvider = FutureProvider<List<SpotifySimpleAlbum>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  print('SpotifyPlugin: Fetching saved albums - plugin: ${plugin != null}, isAuth: $isAuth');
  
  if (plugin == null || !isAuth) {
    print('SpotifyPlugin: Skipping albums fetch - not authenticated');
    return [];
  }
  
  try {
    final response = await plugin.user.savedAlbums(limit: 50);
    print('SpotifyPlugin: Got ${response.items.length} saved albums');
    return response.items;
  } catch (e, stack) {
    print('SpotifyPlugin: Error getting saved albums: $e');
    // Check for 401 errors - mark auth as failed
    if (e.toString().contains('401')) {
      plugin.auth.markAuthFailed();
    }
    return [];
  }
});

/// User's followed artists
final spotifyPluginFollowedArtistsProvider = FutureProvider<List<SpotifyArtist>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  print('SpotifyPlugin: Fetching followed artists - plugin: ${plugin != null}, isAuth: $isAuth');
  
  if (plugin == null || !isAuth) {
    print('SpotifyPlugin: Skipping artists fetch - not authenticated');
    return [];
  }
  
  try {
    final response = await plugin.user.savedArtists(limit: 50);
    print('SpotifyPlugin: Got ${response.items.length} followed artists');
    return response.items;
  } catch (e, stack) {
    print('SpotifyPlugin: Error getting followed artists: $e');
    // Check for 401 errors - mark auth as failed
    if (e.toString().contains('401')) {
      plugin.auth.markAuthFailed();
    }
    return [];
  }
});

/// Playlist tracks (with parameter) - fetches all with pagination
final spotifyPluginPlaylistTracksProvider = FutureProvider.family<List<SpotifyTrack>, String>((ref, playlistId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    final allTracks = <SpotifyTrack>[];
    int offset = 0;
    const limit = 100;
    
    while (true) {
      final response = await plugin.playlist.tracks(playlistId, limit: limit, offset: offset);
      allTracks.addAll(response.items);
      
      // Stop if we got fewer items than requested (no more pages)
      if (response.items.length < limit) break;
      offset += limit;
      
      // Safety limit to prevent infinite loops
      if (offset > 2000) break;
    }
    
    return allTracks;
  } catch (e) {
    print('SpotifyPlugin: Error getting playlist tracks: $e');
    return [];
  }
});

/// Album tracks (with parameter)
final spotifyPluginAlbumTracksProvider = FutureProvider.family<List<SpotifyTrack>, String>((ref, albumId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    final response = await plugin.album.tracks(albumId, limit: 50);
    return response.items;
  } catch (e) {
    print('SpotifyPlugin: Error getting album tracks: $e');
    return [];
  }
});

/// Artist top tracks (with parameter)
final spotifyPluginArtistTopTracksProvider = FutureProvider.family<List<SpotifyTrack>, String>((ref, artistId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    return await plugin.artist.topTracks(artistId);
  } catch (e) {
    print('SpotifyPlugin: Error getting artist top tracks: $e');
    return [];
  }
});

/// Search query state
final spotifyPluginSearchQueryProvider = StateProvider<String>((ref) => '');

/// Search results
final spotifyPluginSearchResultsProvider = FutureProvider<SpotifySearchResponse?>((ref) async {
  final query = ref.watch(spotifyPluginSearchQueryProvider);
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (query.isEmpty || plugin == null || !isAuth) {
    return null;
  }
  
  try {
    return await plugin.search.all(query);
  } catch (e) {
    print('SpotifyPlugin: Error searching: $e');
    return null;
  }
});

/// Get a specific playlist
final spotifyPluginPlaylistProvider = FutureProvider.family<SpotifyPlaylist?, String>((ref, playlistId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return null;
  
  try {
    return await plugin.playlist.getPlaylist(playlistId);
  } catch (e) {
    print('SpotifyPlugin: Error getting playlist: $e');
    return null;
  }
});

/// Get a specific album
final spotifyPluginAlbumProvider = FutureProvider.family<SpotifyAlbum?, String>((ref, albumId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return null;
  
  try {
    return await plugin.album.getAlbum(albumId);
  } catch (e) {
    print('SpotifyPlugin: Error getting album: $e');
    return null;
  }
});

/// Get a specific artist
final spotifyPluginArtistProvider = FutureProvider.family<SpotifyArtist?, String>((ref, artistId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return null;
  
  try {
    return await plugin.artist.getArtist(artistId);
  } catch (e) {
    print('SpotifyPlugin: Error getting artist: $e');
    return null;
  }
});

/// Get a specific track
final spotifyPluginTrackProvider = FutureProvider.family<SpotifyTrack?, String>((ref, trackId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return null;
  
  try {
    return await plugin.track.getTrack(trackId);
  } catch (e) {
    print('SpotifyPlugin: Error getting track: $e');
    return null;
  }
});

/// Radio tracks based on a track
final spotifyPluginRadioTracksProvider = FutureProvider.family<List<SpotifyTrack>, String>((ref, trackId) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    return await plugin.track.radio(trackId);
  } catch (e) {
    print('SpotifyPlugin: Error getting radio tracks: $e');
    return [];
  }
});

/// User's recently played tracks
final spotifyPluginRecentlyPlayedProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    final response = await plugin.user.recentlyPlayed(limit: 50);
    return response.items;
  } catch (e) {
    print('SpotifyPlugin: Error getting recently played: $e');
    return [];
  }
});

/// User's top tracks
final spotifyPluginTopTracksProvider = FutureProvider<List<SpotifyTrack>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    final response = await plugin.user.topTracks(limit: 50);
    return response.items;
  } catch (e) {
    print('SpotifyPlugin: Error getting top tracks: $e');
    return [];
  }
});

/// User's top artists
final spotifyPluginTopArtistsProvider = FutureProvider<List<SpotifyArtist>>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) return [];
  
  try {
    final response = await plugin.user.topArtists(limit: 50);
    return response.items;
  } catch (e) {
    print('SpotifyPlugin: Error getting top artists: $e');
    return [];
  }
});

/// Browse sections (personalized home content)
final spotifyPluginBrowseSectionsProvider = FutureProvider<SpotifyBrowseSectionsResponse>((ref) async {
  final plugin = ref.watch(spotifyPluginProvider);
  final isAuth = ref.watch(isSpotifyPluginAuthenticatedProvider);
  
  if (plugin == null || !isAuth) {
    return SpotifyBrowseSectionsResponse(items: [], hasMore: false, total: 0);
  }
  
  try {
    return await plugin.browse.sections(limit: 20);
  } catch (e) {
    print('SpotifyPlugin: Error getting browse sections: $e');
    return SpotifyBrowseSectionsResponse(items: [], hasMore: false, total: 0);
  }
});
