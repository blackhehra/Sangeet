import 'package:hetu_script/hetu_script.dart';
import 'package:sangeet/models/spotify_models.dart';

/// Browse endpoint for Spotify home/personalized content
class SpotifyBrowseEndpoint {
  final Hetu _hetu;
  
  SpotifyBrowseEndpoint(this._hetu);
  
  dynamic get _hetuBrowse {
    final plugin = _hetu.fetch('metadataPlugin');
    return (plugin as dynamic).memberGet('browse');
  }
  
  /// Get personalized home sections
  Future<SpotifyBrowseSectionsResponse> sections({int? limit, int? offset}) async {
    try {
      final namedArgs = <String, dynamic>{};
      if (limit != null) namedArgs['limit'] = limit;
      if (offset != null) namedArgs['offset'] = offset;
      
      final result = await _hetuBrowse.invoke('sections', namedArgs: namedArgs);
      
      if (result == null) {
        return SpotifyBrowseSectionsResponse(items: [], hasMore: false, total: 0);
      }
      
      final Map<String, dynamic> data = Map<String, dynamic>.from(result as Map);
      return SpotifyBrowseSectionsResponse.fromJson(data);
    } catch (e) {
      print('SpotifyBrowseEndpoint: Error getting sections: $e');
      return SpotifyBrowseSectionsResponse(items: [], hasMore: false, total: 0);
    }
  }
}

/// Response for browse sections
class SpotifyBrowseSectionsResponse {
  final List<SpotifyBrowseSection> items;
  final bool hasMore;
  final int total;
  final int? nextOffset;
  
  SpotifyBrowseSectionsResponse({
    required this.items,
    required this.hasMore,
    required this.total,
    this.nextOffset,
  });
  
  factory SpotifyBrowseSectionsResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return SpotifyBrowseSectionsResponse(
      items: itemsList.map((item) => SpotifyBrowseSection.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      total: json['total'] as int? ?? 0,
      nextOffset: json['nextOffset'] as int?,
    );
  }
}

/// A browse section containing playlists, albums, or artists
class SpotifyBrowseSection {
  final String id;
  final String title;
  final String? externalUri;
  final bool browseMore;
  final List<SpotifyBrowseItem> items;
  
  SpotifyBrowseSection({
    required this.id,
    required this.title,
    this.externalUri,
    this.browseMore = false,
    required this.items,
  });
  
  factory SpotifyBrowseSection.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return SpotifyBrowseSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      externalUri: json['externalUri'] as String?,
      browseMore: json['browseMore'] as bool? ?? false,
      items: itemsList.map((item) => SpotifyBrowseItem.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
    );
  }
}

/// A browse item (can be playlist, album, or artist)
class SpotifyBrowseItem {
  final String id;
  final String name;
  final String? description;
  final List<SpotifyImage> images;
  final String type; // 'playlist', 'album', 'artist'
  final String? ownerName; // For playlists
  final List<SpotifySimpleArtist>? artists; // For albums
  
  SpotifyBrowseItem({
    required this.id,
    required this.name,
    this.description,
    required this.images,
    required this.type,
    this.ownerName,
    this.artists,
  });
  
  factory SpotifyBrowseItem.fromJson(Map<String, dynamic> json) {
    // Determine type based on fields
    String type = 'playlist';
    if (json['artists'] != null) {
      type = 'album';
    } else if (json['owner'] == null && json['followers'] != null) {
      type = 'artist';
    }
    
    // Parse images
    final imagesList = json['images'] as List? ?? [];
    final images = imagesList.map((img) => SpotifyImage.fromJson(Map<String, dynamic>.from(img as Map))).toList();
    
    // Parse artists for albums
    List<SpotifySimpleArtist>? artists;
    if (json['artists'] != null) {
      final artistsList = json['artists'] as List;
      artists = artistsList.map((a) => SpotifySimpleArtist.fromJson(Map<String, dynamic>.from(a as Map))).toList();
    }
    
    // Get owner name for playlists
    String? ownerName;
    if (json['owner'] != null) {
      final owner = json['owner'] as Map;
      ownerName = owner['display_name'] as String? ?? owner['name'] as String?;
    }
    
    return SpotifyBrowseItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      images: images,
      type: type,
      ownerName: ownerName,
      artists: artists,
    );
  }
  
  String? get imageUrl => images.isNotEmpty ? images.first.url : null;
  
  String get subtitle {
    if (type == 'album' && artists != null && artists!.isNotEmpty) {
      return artists!.map((a) => a.name).join(', ');
    } else if (type == 'playlist' && ownerName != null) {
      return 'By $ownerName';
    }
    return description ?? '';
  }
}
