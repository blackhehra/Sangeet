import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import '../../../models/spotify_models.dart';

/// Spotify user endpoint wrapper
class SpotifyUserEndpoint {
  final Hetu _hetu;
  
  SpotifyUserEndpoint(this._hetu);
  
  HTInstance get _hetuUser =>
      (_hetu.fetch("metadataPlugin") as HTInstance).memberGet("user") as HTInstance;
  
  /// Get current user profile
  Future<SpotifyUser> me() async {
    final raw = await _hetuUser.invoke("me") as Map;
    return SpotifyUser.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Get user's saved/liked tracks
  Future<SpotifyPaginatedResponse<SpotifyTrack>> savedTracks({
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuUser.invoke(
      "savedTracks",
      namedArgs: {
        "offset": offset,
        "limit": limit,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifyTrack>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifyTrack.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Get user's saved playlists
  Future<SpotifyPaginatedResponse<SpotifySimplePlaylist>> savedPlaylists({
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuUser.invoke(
      "savedPlaylists",
      namedArgs: {
        "offset": offset,
        "limit": limit,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifySimplePlaylist>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifySimplePlaylist.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Get user's saved albums
  Future<SpotifyPaginatedResponse<SpotifySimpleAlbum>> savedAlbums({
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuUser.invoke(
      "savedAlbums",
      namedArgs: {
        "offset": offset,
        "limit": limit,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifySimpleAlbum>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifySimpleAlbum.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Get user's followed artists
  Future<SpotifyPaginatedResponse<SpotifyArtist>> savedArtists({
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuUser.invoke(
      "savedArtists",
      namedArgs: {
        "offset": offset,
        "limit": limit,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifyArtist>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifyArtist.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Check if a playlist is saved
  Future<bool> isSavedPlaylist(String playlistId) async {
    return await _hetuUser.invoke(
      "isSavedPlaylist",
      positionalArgs: [playlistId],
    ) as bool;
  }
  
  /// Check if tracks are saved
  Future<List<bool>> isSavedTracks(List<String> ids) async {
    final values = await _hetuUser.invoke(
      "isSavedTracks",
      positionalArgs: [ids],
    );
    return (values as List).cast<bool>();
  }
  
  /// Check if albums are saved
  Future<List<bool>> isSavedAlbums(List<String> ids) async {
    final values = await _hetuUser.invoke(
      "isSavedAlbums",
      positionalArgs: [ids],
    ) as List;
    return values.cast<bool>();
  }
  
  /// Check if artists are saved/followed
  Future<List<bool>> isSavedArtists(List<String> ids) async {
    final values = await _hetuUser.invoke(
      "isSavedArtists",
      positionalArgs: [ids],
    ) as List;
    return values.cast<bool>();
  }
  
  /// Get user's recently played tracks
  Future<SpotifyPaginatedResponse<SpotifyTrack>> recentlyPlayed({
    int? limit,
  }) async {
    try {
      final raw = await _hetuUser.invoke(
        "recentlyPlayed",
        namedArgs: {
          "limit": limit,
        }..removeWhere((key, value) => value == null),
      ) as Map;
      
      return SpotifyPaginatedResponse<SpotifyTrack>.fromJson(
        raw.cast<String, dynamic>(),
        (json) => SpotifyTrack.fromJson((json as Map).cast<String, dynamic>()),
      );
    } catch (e) {
      print('SpotifyUserEndpoint: recentlyPlayed not available: $e');
      return SpotifyPaginatedResponse<SpotifyTrack>(items: [], total: 0, limit: limit ?? 50, nextOffset: null, hasMore: false);
    }
  }
  
  /// Get user's top tracks
  Future<SpotifyPaginatedResponse<SpotifyTrack>> topTracks({
    int? limit,
    int? offset,
    String? timeRange, // short_term, medium_term, long_term
  }) async {
    try {
      final raw = await _hetuUser.invoke(
        "topTracks",
        namedArgs: {
          "limit": limit,
          "offset": offset,
          "timeRange": timeRange,
        }..removeWhere((key, value) => value == null),
      ) as Map;
      
      return SpotifyPaginatedResponse<SpotifyTrack>.fromJson(
        raw.cast<String, dynamic>(),
        (json) => SpotifyTrack.fromJson((json as Map).cast<String, dynamic>()),
      );
    } catch (e) {
      print('SpotifyUserEndpoint: topTracks not available: $e');
      return SpotifyPaginatedResponse<SpotifyTrack>(items: [], total: 0, limit: limit ?? 50, nextOffset: null, hasMore: false);
    }
  }
  
  /// Get user's top artists
  Future<SpotifyPaginatedResponse<SpotifyArtist>> topArtists({
    int? limit,
    int? offset,
    String? timeRange, // short_term, medium_term, long_term
  }) async {
    try {
      final raw = await _hetuUser.invoke(
        "topArtists",
        namedArgs: {
          "limit": limit,
          "offset": offset,
          "timeRange": timeRange,
        }..removeWhere((key, value) => value == null),
      ) as Map;
      
      return SpotifyPaginatedResponse<SpotifyArtist>.fromJson(
        raw.cast<String, dynamic>(),
        (json) => SpotifyArtist.fromJson((json as Map).cast<String, dynamic>()),
      );
    } catch (e) {
      print('SpotifyUserEndpoint: topArtists not available: $e');
      return SpotifyPaginatedResponse<SpotifyArtist>(items: [], total: 0, limit: limit ?? 50, nextOffset: null, hasMore: false);
    }
  }
}
