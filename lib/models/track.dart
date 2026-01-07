/// Artist info for credits display
class ArtistInfo {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? role;

  const ArtistInfo({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'thumbnailUrl': thumbnailUrl,
    'role': role,
  };

  factory ArtistInfo.fromJson(Map<String, dynamic> json) => ArtistInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    role: json['role'] as String?,
  );
}

class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnailUrl;
  final Duration duration;
  final String? streamUrl;
  final List<ArtistInfo>? artists;
  final int? viewCount;
  final int? likeCount;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnailUrl,
    required this.duration,
    this.streamUrl,
    this.artists,
    this.viewCount,
    this.likeCount,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    Duration? duration,
    String? streamUrl,
    List<ArtistInfo>? artists,
    int? viewCount,
    int? likeCount,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
      artists: artists ?? this.artists,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration.inMilliseconds,
      'streamUrl': streamUrl,
      'artists': artists?.map((a) => a.toJson()).toList(),
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: Duration(milliseconds: json['duration'] as int),
      streamUrl: json['streamUrl'] as String?,
      artists: (json['artists'] as List<dynamic>?)
          ?.map((a) => ArtistInfo.fromJson(a as Map<String, dynamic>))
          .toList(),
      viewCount: json['viewCount'] as int?,
      likeCount: json['likeCount'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track(id: $id, title: $title, artist: $artist)';
}
