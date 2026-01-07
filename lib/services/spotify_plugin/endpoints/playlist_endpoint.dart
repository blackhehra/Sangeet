import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import '../../../models/spotify_models.dart';

/// Spotify playlist endpoint wrapper
class SpotifyPlaylistEndpoint {
  final Hetu _hetu;
  
  SpotifyPlaylistEndpoint(this._hetu);
  
  HTInstance get _hetuPlaylist =>
      (_hetu.fetch("metadataPlugin") as HTInstance).memberGet("playlist") as HTInstance;
  
  /// Get a playlist by ID
  Future<SpotifyPlaylist> getPlaylist(String id) async {
    final raw = await _hetuPlaylist.invoke(
      "getPlaylist",
      positionalArgs: [id],
    ) as Map;
    
    return SpotifyPlaylist.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Get tracks in a playlist
  Future<SpotifyPaginatedResponse<SpotifyTrack>> tracks(
    String id, {
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuPlaylist.invoke(
      "tracks",
      positionalArgs: [id],
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
  
  /// Create a new playlist
  Future<SpotifyPlaylist?> create(
    String userId, {
    required String name,
    String? description,
    bool? public,
    bool? collaborative,
  }) async {
    final raw = await _hetuPlaylist.invoke(
      "create",
      positionalArgs: [userId],
      namedArgs: {
        "name": name,
        "description": description,
        "public": public,
        "collaborative": collaborative,
      }..removeWhere((key, value) => value == null),
    ) as Map?;
    
    if (raw == null) return null;
    return SpotifyPlaylist.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Update a playlist
  Future<void> update(
    String playlistId, {
    String? name,
    String? description,
    bool? public,
    bool? collaborative,
  }) async {
    await _hetuPlaylist.invoke(
      "update",
      positionalArgs: [playlistId],
      namedArgs: {
        "name": name,
        "description": description,
        "public": public,
        "collaborative": collaborative,
      }..removeWhere((key, value) => value == null),
    );
  }
  
  /// Add tracks to a playlist
  Future<void> addTracks(
    String playlistId, {
    required List<String> trackIds,
    int? position,
  }) async {
    await _hetuPlaylist.invoke(
      "addTracks",
      positionalArgs: [playlistId],
      namedArgs: {
        "trackIds": trackIds,
        "position": position,
      }..removeWhere((key, value) => value == null),
    );
  }
  
  /// Remove tracks from a playlist
  Future<void> removeTracks(
    String playlistId, {
    required List<String> trackIds,
  }) async {
    await _hetuPlaylist.invoke(
      "removeTracks",
      positionalArgs: [playlistId],
      namedArgs: {
        "trackIds": trackIds,
      },
    );
  }
  
  /// Save/follow a playlist
  Future<void> save(String playlistId) async {
    await _hetuPlaylist.invoke(
      "save",
      positionalArgs: [playlistId],
    );
  }
  
  /// Unsave/unfollow a playlist
  Future<void> unsave(String playlistId) async {
    await _hetuPlaylist.invoke(
      "unsave",
      positionalArgs: [playlistId],
    );
  }
  
  /// Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    await _hetuPlaylist.invoke(
      "deletePlaylist",
      positionalArgs: [playlistId],
    );
  }
}
