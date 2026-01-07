// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spotify_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SpotifyImageImpl _$$SpotifyImageImplFromJson(Map<String, dynamic> json) =>
    _$SpotifyImageImpl(
      url: json['url'] as String,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SpotifyImageImplToJson(_$SpotifyImageImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };

_$SpotifyUserImpl _$$SpotifyUserImplFromJson(Map<String, dynamic> json) =>
    _$SpotifyUserImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      externalUri: json['externalUri'] as String,
    );

Map<String, dynamic> _$$SpotifyUserImplToJson(_$SpotifyUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'images': instance.images,
      'externalUri': instance.externalUri,
    };

_$SpotifyArtistImpl _$$SpotifyArtistImplFromJson(Map<String, dynamic> json) =>
    _$SpotifyArtistImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      externalUri: json['externalUri'] as String,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      followers: (json['followers'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SpotifyArtistImplToJson(_$SpotifyArtistImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'externalUri': instance.externalUri,
      'images': instance.images,
      'genres': instance.genres,
      'followers': instance.followers,
    };

_$SpotifySimpleArtistImpl _$$SpotifySimpleArtistImplFromJson(
  Map<String, dynamic> json,
) => _$SpotifySimpleArtistImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  externalUri: json['externalUri'] as String,
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$SpotifySimpleArtistImplToJson(
  _$SpotifySimpleArtistImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'externalUri': instance.externalUri,
  'images': instance.images,
};

_$SpotifyAlbumImpl _$$SpotifyAlbumImplFromJson(Map<String, dynamic> json) =>
    _$SpotifyAlbumImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      externalUri: json['externalUri'] as String,
      artists: (json['artists'] as List<dynamic>)
          .map((e) => SpotifySimpleArtist.fromJson(e as Map<String, dynamic>))
          .toList(),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      albumType: $enumDecode(_$SpotifyAlbumTypeEnumMap, json['albumType']),
      releaseDate: json['releaseDate'] as String?,
      totalTracks: (json['totalTracks'] as num?)?.toInt(),
      recordLabel: json['recordLabel'] as String?,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$SpotifyAlbumImplToJson(_$SpotifyAlbumImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'externalUri': instance.externalUri,
      'artists': instance.artists,
      'images': instance.images,
      'albumType': _$SpotifyAlbumTypeEnumMap[instance.albumType]!,
      'releaseDate': instance.releaseDate,
      'totalTracks': instance.totalTracks,
      'recordLabel': instance.recordLabel,
      'genres': instance.genres,
    };

const _$SpotifyAlbumTypeEnumMap = {
  SpotifyAlbumType.album: 'album',
  SpotifyAlbumType.single: 'single',
  SpotifyAlbumType.compilation: 'compilation',
};

_$SpotifySimpleAlbumImpl _$$SpotifySimpleAlbumImplFromJson(
  Map<String, dynamic> json,
) => _$SpotifySimpleAlbumImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  externalUri: json['externalUri'] as String,
  artists: (json['artists'] as List<dynamic>)
      .map((e) => SpotifySimpleArtist.fromJson(e as Map<String, dynamic>))
      .toList(),
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  albumType: $enumDecode(_$SpotifyAlbumTypeEnumMap, json['albumType']),
  releaseDate: json['releaseDate'] as String?,
);

Map<String, dynamic> _$$SpotifySimpleAlbumImplToJson(
  _$SpotifySimpleAlbumImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'externalUri': instance.externalUri,
  'artists': instance.artists,
  'images': instance.images,
  'albumType': _$SpotifyAlbumTypeEnumMap[instance.albumType]!,
  'releaseDate': instance.releaseDate,
};

_$SpotifyTrackImpl _$$SpotifyTrackImplFromJson(Map<String, dynamic> json) =>
    _$SpotifyTrackImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      externalUri: json['externalUri'] as String,
      artists:
          (json['artists'] as List<dynamic>?)
              ?.map(
                (e) => SpotifySimpleArtist.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      album: SpotifySimpleAlbum.fromJson(json['album'] as Map<String, dynamic>),
      durationMs: (json['durationMs'] as num).toInt(),
      isrc: json['isrc'] as String,
      explicit: json['explicit'] as bool,
    );

Map<String, dynamic> _$$SpotifyTrackImplToJson(_$SpotifyTrackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'externalUri': instance.externalUri,
      'artists': instance.artists,
      'album': instance.album,
      'durationMs': instance.durationMs,
      'isrc': instance.isrc,
      'explicit': instance.explicit,
    };

_$SpotifyPlaylistImpl _$$SpotifyPlaylistImplFromJson(
  Map<String, dynamic> json,
) => _$SpotifyPlaylistImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  externalUri: json['externalUri'] as String,
  owner: SpotifyUser.fromJson(json['owner'] as Map<String, dynamic>),
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  collaborative: json['collaborative'] as bool? ?? false,
  public: json['public'] as bool? ?? false,
);

Map<String, dynamic> _$$SpotifyPlaylistImplToJson(
  _$SpotifyPlaylistImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'externalUri': instance.externalUri,
  'owner': instance.owner,
  'images': instance.images,
  'collaborative': instance.collaborative,
  'public': instance.public,
};

_$SpotifySimplePlaylistImpl _$$SpotifySimplePlaylistImplFromJson(
  Map<String, dynamic> json,
) => _$SpotifySimplePlaylistImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  externalUri: json['externalUri'] as String,
  owner: SpotifyUser.fromJson(json['owner'] as Map<String, dynamic>),
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => SpotifyImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$SpotifySimplePlaylistImplToJson(
  _$SpotifySimplePlaylistImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'externalUri': instance.externalUri,
  'owner': instance.owner,
  'images': instance.images,
};

_$SpotifyPaginatedResponseImpl<T> _$$SpotifyPaginatedResponseImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _$SpotifyPaginatedResponseImpl<T>(
  limit: (json['limit'] as num).toInt(),
  nextOffset: (json['nextOffset'] as num?)?.toInt(),
  total: (json['total'] as num).toInt(),
  hasMore: json['hasMore'] as bool,
  items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
);

Map<String, dynamic> _$$SpotifyPaginatedResponseImplToJson<T>(
  _$SpotifyPaginatedResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'limit': instance.limit,
  'nextOffset': instance.nextOffset,
  'total': instance.total,
  'hasMore': instance.hasMore,
  'items': instance.items.map(toJsonT).toList(),
};

_$SpotifySearchResponseImpl _$$SpotifySearchResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SpotifySearchResponseImpl(
  albums: (json['albums'] as List<dynamic>)
      .map((e) => SpotifySimpleAlbum.fromJson(e as Map<String, dynamic>))
      .toList(),
  artists: (json['artists'] as List<dynamic>)
      .map((e) => SpotifyArtist.fromJson(e as Map<String, dynamic>))
      .toList(),
  playlists: (json['playlists'] as List<dynamic>)
      .map((e) => SpotifySimplePlaylist.fromJson(e as Map<String, dynamic>))
      .toList(),
  tracks: (json['tracks'] as List<dynamic>)
      .map((e) => SpotifyTrack.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$SpotifySearchResponseImplToJson(
  _$SpotifySearchResponseImpl instance,
) => <String, dynamic>{
  'albums': instance.albums,
  'artists': instance.artists,
  'playlists': instance.playlists,
  'tracks': instance.tracks,
};

_$PluginConfigImpl _$$PluginConfigImplFromJson(Map<String, dynamic> json) =>
    _$PluginConfigImpl(
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      entryPoint: json['entryPoint'] as String,
      pluginApiVersion: json['pluginApiVersion'] as String,
      apis:
          (json['apis'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$PluginApiEnumMap, e))
              .toList() ??
          const [],
      abilities:
          (json['abilities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$PluginAbilityEnumMap, e))
              .toList() ??
          const [],
      repository: json['repository'] as String?,
    );

Map<String, dynamic> _$$PluginConfigImplToJson(_$PluginConfigImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'author': instance.author,
      'entryPoint': instance.entryPoint,
      'pluginApiVersion': instance.pluginApiVersion,
      'apis': instance.apis.map((e) => _$PluginApiEnumMap[e]!).toList(),
      'abilities': instance.abilities
          .map((e) => _$PluginAbilityEnumMap[e]!)
          .toList(),
      'repository': instance.repository,
    };

const _$PluginApiEnumMap = {
  PluginApi.webview: 'webview',
  PluginApi.localstorage: 'localstorage',
  PluginApi.timezone: 'timezone',
};

const _$PluginAbilityEnumMap = {
  PluginAbility.authentication: 'authentication',
  PluginAbility.scrobbling: 'scrobbling',
  PluginAbility.metadata: 'metadata',
  PluginAbility.audioSource: 'audio-source',
};
