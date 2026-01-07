import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import '../../../models/spotify_models.dart';

/// Spotify search endpoint wrapper
class SpotifySearchEndpoint {
  final Hetu _hetu;
  
  SpotifySearchEndpoint(this._hetu);
  
  HTInstance get _hetuSearch =>
      (_hetu.fetch("metadataPlugin") as HTInstance).memberGet("search") as HTInstance;
  
  /// Get available search chips/filters
  List<String> get chips {
    return (_hetuSearch.memberGet("chips") as List).cast<String>();
  }
  
  /// Search all categories
  Future<SpotifySearchResponse> all(String query) async {
    if (query.isEmpty) {
      return SpotifySearchResponse(
        albums: [],
        artists: [],
        playlists: [],
        tracks: [],
      );
    }
    
    final raw = await _hetuSearch.invoke(
      "all",
      positionalArgs: [query],
    ) as Map;
    
    return SpotifySearchResponse.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Search albums
  Future<SpotifyPaginatedResponse<SpotifySimpleAlbum>> albums(
    String query, {
    int? limit,
    int? offset,
  }) async {
    if (query.isEmpty) {
      return SpotifyPaginatedResponse<SpotifySimpleAlbum>(
        items: [],
        total: 0,
        limit: limit ?? 20,
        hasMore: false,
        nextOffset: null,
      );
    }
    
    final raw = await _hetuSearch.invoke(
      "albums",
      positionalArgs: [query],
      namedArgs: {
        "limit": limit,
        "offset": offset,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifySimpleAlbum>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifySimpleAlbum.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Search artists
  Future<SpotifyPaginatedResponse<SpotifyArtist>> artists(
    String query, {
    int? limit,
    int? offset,
  }) async {
    if (query.isEmpty) {
      return SpotifyPaginatedResponse<SpotifyArtist>(
        items: [],
        total: 0,
        limit: limit ?? 20,
        hasMore: false,
        nextOffset: null,
      );
    }
    
    final raw = await _hetuSearch.invoke(
      "artists",
      positionalArgs: [query],
      namedArgs: {
        "limit": limit,
        "offset": offset,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifyArtist>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifyArtist.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Search playlists
  Future<SpotifyPaginatedResponse<SpotifySimplePlaylist>> playlists(
    String query, {
    int? limit,
    int? offset,
  }) async {
    if (query.isEmpty) {
      return SpotifyPaginatedResponse<SpotifySimplePlaylist>(
        items: [],
        total: 0,
        limit: limit ?? 20,
        hasMore: false,
        nextOffset: null,
      );
    }
    
    final raw = await _hetuSearch.invoke(
      "playlists",
      positionalArgs: [query],
      namedArgs: {
        "limit": limit,
        "offset": offset,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifySimplePlaylist>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifySimplePlaylist.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
  
  /// Search tracks
  Future<SpotifyPaginatedResponse<SpotifyTrack>> tracks(
    String query, {
    int? limit,
    int? offset,
  }) async {
    if (query.isEmpty) {
      return SpotifyPaginatedResponse<SpotifyTrack>(
        items: [],
        total: 0,
        limit: limit ?? 20,
        hasMore: false,
        nextOffset: null,
      );
    }
    
    final raw = await _hetuSearch.invoke(
      "tracks",
      positionalArgs: [query],
      namedArgs: {
        "limit": limit,
        "offset": offset,
      }..removeWhere((key, value) => value == null),
    ) as Map;
    
    return SpotifyPaginatedResponse<SpotifyTrack>.fromJson(
      raw.cast<String, dynamic>(),
      (json) => SpotifyTrack.fromJson((json as Map).cast<String, dynamic>()),
    );
  }
}
