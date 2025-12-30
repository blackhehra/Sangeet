import 'package:sangeet/models/track.dart';

/// Custom user-created playlist
class CustomPlaylist {
  final String id;
  final String name;
  final String? description;
  final List<Track> tracks;
  final int createdAt;
  final int updatedAt;
  final String? imageUrl;

  const CustomPlaylist({
    required this.id,
    required this.name,
    this.description,
    required this.tracks,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  CustomPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    List<Track>? tracks,
    int? createdAt,
    int? updatedAt,
    String? imageUrl,
  }) {
    return CustomPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'imageUrl': imageUrl,
    };
  }

  factory CustomPlaylist.fromJson(Map<String, dynamic> json) {
    return CustomPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((t) => Track.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
