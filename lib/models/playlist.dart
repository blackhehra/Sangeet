import 'package:sangeet/models/track.dart';

class Playlist {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? author;
  final List<Track> tracks;
  final int trackCount;

  const Playlist({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.author,
    this.tracks = const [],
    this.trackCount = 0,
  });

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? author,
    List<Track>? tracks,
    int? trackCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      author: author ?? this.author,
      tracks: tracks ?? this.tracks,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  String toString() => 'Playlist(id: $id, title: $title, tracks: ${tracks.length})';
}
