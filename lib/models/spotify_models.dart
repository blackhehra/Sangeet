/// Spotify metadata models for the plugin system

library spotify_models;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'spotify_models.freezed.dart';
part 'spotify_models.g.dart';

// ============================================================================
// Image
// ============================================================================

@freezed
class SpotifyImage with _$SpotifyImage {
  factory SpotifyImage({
    required String url,
    int? width,
    int? height,
  }) = _SpotifyImage;

  factory SpotifyImage.fromJson(Map<String, dynamic> json) =>
      _$SpotifyImageFromJson(json);
}

// ============================================================================
// User
// ============================================================================

@freezed
class SpotifyUser with _$SpotifyUser {
  factory SpotifyUser({
    required String id,
    required String name,
    @Default([]) List<SpotifyImage> images,
    required String externalUri,
  }) = _SpotifyUser;

  factory SpotifyUser.fromJson(Map<String, dynamic> json) =>
      _$SpotifyUserFromJson(json);
}

// ============================================================================
// Artist
// ============================================================================

@freezed
class SpotifyArtist with _$SpotifyArtist {
  factory SpotifyArtist({
    required String id,
    required String name,
    required String externalUri,
    List<SpotifyImage>? images,
    List<String>? genres,
    int? followers,
  }) = _SpotifyArtist;

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) =>
      _$SpotifyArtistFromJson(json);
}

@freezed
class SpotifySimpleArtist with _$SpotifySimpleArtist {
  factory SpotifySimpleArtist({
    required String id,
    required String name,
    required String externalUri,
    List<SpotifyImage>? images,
  }) = _SpotifySimpleArtist;

  factory SpotifySimpleArtist.fromJson(Map<String, dynamic> json) =>
      _$SpotifySimpleArtistFromJson(json);
}

// ============================================================================
// Album
// ============================================================================

enum SpotifyAlbumType {
  album,
  single,
  compilation,
}

@freezed
class SpotifyAlbum with _$SpotifyAlbum {
  factory SpotifyAlbum({
    required String id,
    required String name,
    required String externalUri,
    required List<SpotifySimpleArtist> artists,
    @Default([]) List<SpotifyImage> images,
    required SpotifyAlbumType albumType,
    String? releaseDate,
    int? totalTracks,
    String? recordLabel,
    List<String>? genres,
  }) = _SpotifyAlbum;

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) =>
      _$SpotifyAlbumFromJson(json);
}

@freezed
class SpotifySimpleAlbum with _$SpotifySimpleAlbum {
  factory SpotifySimpleAlbum({
    required String id,
    required String name,
    required String externalUri,
    required List<SpotifySimpleArtist> artists,
    @Default([]) List<SpotifyImage> images,
    required SpotifyAlbumType albumType,
    String? releaseDate,
  }) = _SpotifySimpleAlbum;

  factory SpotifySimpleAlbum.fromJson(Map<String, dynamic> json) =>
      _$SpotifySimpleAlbumFromJson(json);
}

// ============================================================================
// Track
// ============================================================================

@freezed
class SpotifyTrack with _$SpotifyTrack {
  factory SpotifyTrack({
    required String id,
    required String name,
    required String externalUri,
    @Default([]) List<SpotifySimpleArtist> artists,
    required SpotifySimpleAlbum album,
    required int durationMs,
    required String isrc,
    required bool explicit,
  }) = _SpotifyTrack;

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) =>
      _$SpotifyTrackFromJson(json);
}

// ============================================================================
// Playlist
// ============================================================================

@freezed
class SpotifyPlaylist with _$SpotifyPlaylist {
  factory SpotifyPlaylist({
    required String id,
    required String name,
    required String description,
    required String externalUri,
    required SpotifyUser owner,
    @Default([]) List<SpotifyImage> images,
    @Default(false) bool collaborative,
    @Default(false) bool public,
  }) = _SpotifyPlaylist;

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) =>
      _$SpotifyPlaylistFromJson(json);
}

@freezed
class SpotifySimplePlaylist with _$SpotifySimplePlaylist {
  factory SpotifySimplePlaylist({
    required String id,
    required String name,
    required String description,
    required String externalUri,
    required SpotifyUser owner,
    @Default([]) List<SpotifyImage> images,
  }) = _SpotifySimplePlaylist;

  factory SpotifySimplePlaylist.fromJson(Map<String, dynamic> json) =>
      _$SpotifySimplePlaylistFromJson(json);
}

// ============================================================================
// Pagination
// ============================================================================

@Freezed(genericArgumentFactories: true)
class SpotifyPaginatedResponse<T> with _$SpotifyPaginatedResponse<T> {
  factory SpotifyPaginatedResponse({
    required int limit,
    required int? nextOffset,
    required int total,
    required bool hasMore,
    required List<T> items,
  }) = _SpotifyPaginatedResponse<T>;

  factory SpotifyPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$SpotifyPaginatedResponseFromJson(json, fromJsonT);
}

// ============================================================================
// Search
// ============================================================================

@freezed
class SpotifySearchResponse with _$SpotifySearchResponse {
  factory SpotifySearchResponse({
    required List<SpotifySimpleAlbum> albums,
    required List<SpotifyArtist> artists,
    required List<SpotifySimplePlaylist> playlists,
    required List<SpotifyTrack> tracks,
  }) = _SpotifySearchResponse;

  factory SpotifySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SpotifySearchResponseFromJson(json);
}

// ============================================================================
// Plugin Configuration
// ============================================================================

enum PluginApi { webview, localstorage, timezone }

enum PluginAbility {
  authentication,
  scrobbling,
  metadata,
  @JsonValue('audio-source')
  audioSource,
}

@freezed
class PluginConfig with _$PluginConfig {
  const PluginConfig._();

  factory PluginConfig({
    required String name,
    required String description,
    required String version,
    required String author,
    required String entryPoint,
    required String pluginApiVersion,
    @Default([]) List<PluginApi> apis,
    @Default([]) List<PluginAbility> abilities,
    String? repository,
  }) = _PluginConfig;

  factory PluginConfig.fromJson(Map<String, dynamic> json) =>
      _$PluginConfigFromJson(json);

  String get slug => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

// ============================================================================
// Extensions for convenience
// ============================================================================

extension SpotifyArtistListExtension on List<SpotifySimpleArtist> {
  String get displayName => map((a) => a.name).join(', ');
}

extension SpotifyImageListExtension on List<SpotifyImage>? {
  String? get smallestUrl {
    if (this == null || this!.isEmpty) return null;
    final sorted = [...this!]..sort((a, b) => (a.width ?? 0).compareTo(b.width ?? 0));
    return sorted.first.url;
  }

  String? get largestUrl {
    if (this == null || this!.isEmpty) return null;
    final sorted = [...this!]..sort((a, b) => (b.width ?? 0).compareTo(a.width ?? 0));
    return sorted.first.url;
  }

  String? get mediumUrl {
    if (this == null || this!.isEmpty) return null;
    final sorted = [...this!]..sort((a, b) => (a.width ?? 0).compareTo(b.width ?? 0));
    final index = sorted.length ~/ 2;
    return sorted[index].url;
  }
}
