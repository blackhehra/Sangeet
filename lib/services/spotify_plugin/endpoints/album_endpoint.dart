import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import '../../../models/spotify_models.dart';

/// Spotify album endpoint wrapper
class SpotifyAlbumEndpoint {
  final Hetu _hetu;
  
  SpotifyAlbumEndpoint(this._hetu);
  
  HTInstance get _hetuAlbum =>
      (_hetu.fetch("metadataPlugin") as HTInstance).memberGet("album") as HTInstance;
  
  /// Get an album by ID
  Future<SpotifyAlbum> getAlbum(String id) async {
    final raw = await _hetuAlbum.invoke(
      "getAlbum",
      positionalArgs: [id],
    ) as Map;
    
    return SpotifyAlbum.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Get tracks in an album
  Future<SpotifyPaginatedResponse<SpotifyTrack>> tracks(
    String id, {
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuAlbum.invoke(
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
  
  /// Save an album to library
  Future<void> save(String albumId) async {
    await _hetuAlbum.invoke(
      "save",
      positionalArgs: [albumId],
    );
  }
  
  /// Remove an album from library
  Future<void> unsave(String albumId) async {
    await _hetuAlbum.invoke(
      "unsave",
      positionalArgs: [albumId],
    );
  }
}
