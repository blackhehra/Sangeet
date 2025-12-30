/// Play event model - tracks when and how long a song was played
class PlayEvent {
  final String id;
  final String songId;
  final int timestamp; // milliseconds since epoch
  final int playTimeMs; // how long the song was played

  const PlayEvent({
    required this.id,
    required this.songId,
    required this.timestamp,
    required this.playTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'songId': songId,
    'timestamp': timestamp,
    'playTimeMs': playTimeMs,
  };

  factory PlayEvent.fromJson(Map<String, dynamic> json) => PlayEvent(
    id: json['id'] as String,
    songId: json['songId'] as String,
    timestamp: json['timestamp'] as int,
    playTimeMs: json['playTimeMs'] as int,
  );
}

/// Song statistics - aggregated play data
class SongStats {
  final String songId;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final int totalPlayTimeMs;
  final int playCount;
  final int lastPlayedAt;

  const SongStats({
    required this.songId,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.totalPlayTimeMs,
    required this.playCount,
    required this.lastPlayedAt,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'title': title,
    'artist': artist,
    'thumbnailUrl': thumbnailUrl,
    'totalPlayTimeMs': totalPlayTimeMs,
    'playCount': playCount,
    'lastPlayedAt': lastPlayedAt,
  };

  factory SongStats.fromJson(Map<String, dynamic> json) => SongStats(
    songId: json['songId'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    totalPlayTimeMs: json['totalPlayTimeMs'] as int,
    playCount: json['playCount'] as int,
    lastPlayedAt: json['lastPlayedAt'] as int,
  );

  SongStats copyWith({
    int? totalPlayTimeMs,
    int? playCount,
    int? lastPlayedAt,
  }) => SongStats(
    songId: songId,
    title: title,
    artist: artist,
    thumbnailUrl: thumbnailUrl,
    totalPlayTimeMs: totalPlayTimeMs ?? this.totalPlayTimeMs,
    playCount: playCount ?? this.playCount,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
  );
}
