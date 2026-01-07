import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import '../../../models/spotify_models.dart';

/// Spotify artist endpoint wrapper
class SpotifyArtistEndpoint {
  final Hetu _hetu;
  
  SpotifyArtistEndpoint(this._hetu);
  
  HTInstance get _hetuArtist =>
      (_hetu.fetch("metadataPlugin") as HTInstance).memberGet("artist") as HTInstance;
  
  /// Get an artist by ID
  Future<SpotifyArtist> getArtist(String id) async {
    final raw = await _hetuArtist.invoke(
      "getArtist",
      positionalArgs: [id],
    ) as Map;
    
    return SpotifyArtist.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Get artist's top tracks
  Future<List<SpotifyTrack>> topTracks(String id) async {
    final raw = await _hetuArtist.invoke(
      "topTracks",
      positionalArgs: [id],
    ) as List;
    
    return raw
        .map((item) => SpotifyTrack.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }
  
  /// Get artist's albums
  Future<SpotifyPaginatedResponse<SpotifySimpleAlbum>> albums(
    String id, {
    int? offset,
    int? limit,
  }) async {
    final raw = await _hetuArtist.invoke(
      "albums",
      positionalArgs: [id],
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
  
  /// Get related artists
  Future<List<SpotifyArtist>> relatedArtists(String id) async {
    final raw = await _hetuArtist.invoke(
      "relatedArtists",
      positionalArgs: [id],
    ) as List;
    
    return raw
        .map((item) => SpotifyArtist.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }
  
  /// Follow an artist
  Future<void> follow(String artistId) async {
    await _hetuArtist.invoke(
      "follow",
      positionalArgs: [artistId],
    );
  }
  
  /// Unfollow an artist
  Future<void> unfollow(String artistId) async {
    await _hetuArtist.invoke(
      "unfollow",
      positionalArgs: [artistId],
    );
  }
}
