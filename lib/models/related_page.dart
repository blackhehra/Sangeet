import 'package:sangeet/models/track.dart';

/// Related page model for personalized recommendations
/// Contains personalized recommendations based on a seed song
class RelatedPage {
  final List<Track>? songs;
  final List<RelatedPlaylist>? playlists;
  final List<RelatedAlbum>? albums;
  final List<RelatedArtist>? artists;

  const RelatedPage({
    this.songs,
    this.playlists,
    this.albums,
    this.artists,
  });

  bool get isEmpty =>
      (songs?.isEmpty ?? true) &&
      (playlists?.isEmpty ?? true) &&
      (albums?.isEmpty ?? true) &&
      (artists?.isEmpty ?? true);

  Map<String, dynamic> toJson() => {
    'songs': songs?.map((s) => s.toJson()).toList(),
    'playlists': playlists?.map((p) => p.toJson()).toList(),
    'albums': albums?.map((a) => a.toJson()).toList(),
    'artists': artists?.map((a) => a.toJson()).toList(),
  };

  factory RelatedPage.fromJson(Map<String, dynamic> json) => RelatedPage(
    songs: (json['songs'] as List<dynamic>?)
        ?.map((s) => Track.fromJson(s as Map<String, dynamic>))
        .toList(),
    playlists: (json['playlists'] as List<dynamic>?)
        ?.map((p) => RelatedPlaylist.fromJson(p as Map<String, dynamic>))
        .toList(),
    albums: (json['albums'] as List<dynamic>?)
        ?.map((a) => RelatedAlbum.fromJson(a as Map<String, dynamic>))
        .toList(),
    artists: (json['artists'] as List<dynamic>?)
        ?.map((a) => RelatedArtist.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}

/// Related playlist model
class RelatedPlaylist {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? channelName;
  final int? songCount;

  const RelatedPlaylist({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.channelName,
    this.songCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'channelName': channelName,
    'songCount': songCount,
  };

  factory RelatedPlaylist.fromJson(Map<String, dynamic> json) => RelatedPlaylist(
    id: json['id'] as String,
    title: json['title'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    channelName: json['channelName'] as String?,
    songCount: json['songCount'] as int?,
  );
}

/// Related album model
class RelatedAlbum {
  final String id;
  final String title;
  final String? artist;
  final String? thumbnailUrl;
  final String? year;

  const RelatedAlbum({
    required this.id,
    required this.title,
    this.artist,
    this.thumbnailUrl,
    this.year,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'thumbnailUrl': thumbnailUrl,
    'year': year,
  };

  factory RelatedAlbum.fromJson(Map<String, dynamic> json) => RelatedAlbum(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    year: json['year'] as String?,
  );
}

/// Related artist model
class RelatedArtist {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? subscribersText;

  const RelatedArtist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.subscribersText,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'thumbnailUrl': thumbnailUrl,
    'subscribersText': subscribersText,
  };

  factory RelatedArtist.fromJson(Map<String, dynamic> json) => RelatedArtist(
    id: json['id'] as String,
    name: json['name'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    subscribersText: json['subscribersText'] as String?,
  );
}

/// Discover page model for trending content
/// Contains global trending content (not personalized)
class DiscoverPage {
  final List<RelatedAlbum> newReleaseAlbums;
  final List<MoodItem> moods;
  final TrendingSection trending;

  const DiscoverPage({
    required this.newReleaseAlbums,
    required this.moods,
    required this.trending,
  });

  Map<String, dynamic> toJson() => {
    'newReleaseAlbums': newReleaseAlbums.map((a) => a.toJson()).toList(),
    'moods': moods.map((m) => m.toJson()).toList(),
    'trending': trending.toJson(),
  };

  factory DiscoverPage.fromJson(Map<String, dynamic> json) => DiscoverPage(
    newReleaseAlbums: (json['newReleaseAlbums'] as List<dynamic>)
        .map((a) => RelatedAlbum.fromJson(a as Map<String, dynamic>))
        .toList(),
    moods: (json['moods'] as List<dynamic>)
        .map((m) => MoodItem.fromJson(m as Map<String, dynamic>))
        .toList(),
    trending: TrendingSection.fromJson(json['trending'] as Map<String, dynamic>),
  );
}

/// Mood/Genre item for browse categories
class MoodItem {
  final String title;
  final String browseId;
  final String? params;
  final int? stripeColor;

  const MoodItem({
    required this.title,
    required this.browseId,
    this.params,
    this.stripeColor,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'browseId': browseId,
    'params': params,
    'stripeColor': stripeColor,
  };

  factory MoodItem.fromJson(Map<String, dynamic> json) => MoodItem(
    title: json['title'] as String,
    browseId: json['browseId'] as String,
    params: json['params'] as String?,
    stripeColor: json['stripeColor'] as int?,
  );
}

/// Trending section with songs and browse endpoint
class TrendingSection {
  final List<Track> songs;
  final String? browseId;

  const TrendingSection({
    required this.songs,
    this.browseId,
  });

  Map<String, dynamic> toJson() => {
    'songs': songs.map((s) => s.toJson()).toList(),
    'browseId': browseId,
  };

  factory TrendingSection.fromJson(Map<String, dynamic> json) => TrendingSection(
    songs: (json['songs'] as List<dynamic>)
        .map((s) => Track.fromJson(s as Map<String, dynamic>))
        .toList(),
    browseId: json['browseId'] as String?,
  );
}

/// Artist page model with artist info and content
/// Contains artist info, top songs, albums, and singles
class ArtistPage {
  final String? name;
  final String? description;
  final String? thumbnailUrl;
  final String? subscribersCountText;
  final List<Track>? songs;
  final String? songsEndpointBrowseId;
  final String? songsEndpointParams;
  final List<RelatedAlbum>? albums;
  final String? albumsEndpointBrowseId;
  final List<RelatedAlbum>? singles;
  final String? singlesEndpointBrowseId;

  const ArtistPage({
    this.name,
    this.description,
    this.thumbnailUrl,
    this.subscribersCountText,
    this.songs,
    this.songsEndpointBrowseId,
    this.songsEndpointParams,
    this.albums,
    this.albumsEndpointBrowseId,
    this.singles,
    this.singlesEndpointBrowseId,
  });
}

/// Album/Playlist page model with tracks and metadata
class AlbumPage {
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final String? artist;
  final String? year;
  final String? otherInfo;
  final List<Track>? songs;
  final List<RelatedAlbum>? otherVersions;

  const AlbumPage({
    this.title,
    this.description,
    this.thumbnailUrl,
    this.artist,
    this.year,
    this.otherInfo,
    this.songs,
    this.otherVersions,
  });
}
