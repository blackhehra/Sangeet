import 'package:sangeet/models/track.dart';

/// Types of shareable content
enum ShareType {
  song,
  playlist,
  album,
}

/// Minimal track data for sharing (only essential fields)
/// Full track details will be fetched by recipient from YouTube Music
class ShareableTrack {
  final String id;
  final String title;
  final String artist;
  final int durationMs;

  const ShareableTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'i': id,
    't': title,
    'a': artist,
    'd': durationMs,
  };

  factory ShareableTrack.fromJson(Map<String, dynamic> json) => ShareableTrack(
    id: json['i'] as String,
    title: json['t'] as String,
    artist: json['a'] as String,
    durationMs: json['d'] as int,
  );

  factory ShareableTrack.fromTrack(Track track) => ShareableTrack(
    id: track.id,
    title: track.title,
    artist: track.artist,
    durationMs: track.duration.inMilliseconds,
  );

  Track toTrack() => Track(
    id: id,
    title: title,
    artist: artist,
    duration: Duration(milliseconds: durationMs),
  );
}

/// Unified shareable data format
/// Supports single songs, playlists, and albums
class ShareData {
  /// Schema version for future compatibility
  final int version;
  
  /// Type of content being shared
  final ShareType type;
  
  /// Name of the playlist/album (null for single song)
  final String? name;
  
  /// Description (optional)
  final String? description;
  
  /// List of tracks (single item for song, multiple for playlist/album)
  final List<ShareableTrack> tracks;
  
  /// For chunked sharing: current part number (1-indexed)
  final int part;
  
  /// For chunked sharing: total number of parts
  final int totalParts;
  
  /// Unique ID for this share (used to combine chunks)
  final String? shareId;

  const ShareData({
    this.version = 1,
    required this.type,
    this.name,
    this.description,
    required this.tracks,
    this.part = 1,
    this.totalParts = 1,
    this.shareId,
  });

  bool get isChunked => totalParts > 1;
  bool get isComplete => part == totalParts;

  Map<String, dynamic> toJson() => {
    'v': version,
    'y': type.index,
    if (name != null) 'n': name,
    if (description != null) 'd': description,
    'tr': tracks.map((t) => t.toJson()).toList(),
    if (totalParts > 1) 'p': part,
    if (totalParts > 1) 'tp': totalParts,
    if (shareId != null) 'sid': shareId,
  };

  factory ShareData.fromJson(Map<String, dynamic> json) => ShareData(
    version: json['v'] as int? ?? 1,
    type: ShareType.values[json['y'] as int],
    name: json['n'] as String?,
    description: json['d'] as String?,
    tracks: (json['tr'] as List<dynamic>)
        .map((t) => ShareableTrack.fromJson(t as Map<String, dynamic>))
        .toList(),
    part: json['p'] as int? ?? 1,
    totalParts: json['tp'] as int? ?? 1,
    shareId: json['sid'] as String?,
  );

  /// Create ShareData for a single song
  factory ShareData.song(Track track) => ShareData(
    type: ShareType.song,
    tracks: [ShareableTrack.fromTrack(track)],
  );

  /// Create ShareData for a playlist
  factory ShareData.playlist({
    required String name,
    String? description,
    required List<Track> tracks,
  }) => ShareData(
    type: ShareType.playlist,
    name: name,
    description: description,
    tracks: tracks.map((t) => ShareableTrack.fromTrack(t)).toList(),
  );

  /// Create ShareData for an album
  factory ShareData.album({
    required String name,
    String? artist,
    required List<Track> tracks,
  }) => ShareData(
    type: ShareType.album,
    name: name,
    description: artist,
    tracks: tracks.map((t) => ShareableTrack.fromTrack(t)).toList(),
  );

  /// Split into multiple chunks for large playlists
  List<ShareData> splitIntoChunks(int maxTracksPerChunk) {
    if (tracks.length <= maxTracksPerChunk) {
      return [this];
    }

    final chunks = <ShareData>[];
    final shareId = DateTime.now().millisecondsSinceEpoch.toString();
    final totalChunks = (tracks.length / maxTracksPerChunk).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * maxTracksPerChunk;
      final end = (start + maxTracksPerChunk).clamp(0, tracks.length);
      
      chunks.add(ShareData(
        version: version,
        type: type,
        name: name,
        description: i == 0 ? description : null, // Only include description in first chunk
        tracks: tracks.sublist(start, end),
        part: i + 1,
        totalParts: totalChunks,
        shareId: shareId,
      ));
    }

    return chunks;
  }

  /// Combine multiple chunks into a single ShareData
  static ShareData combineChunks(List<ShareData> chunks) {
    if (chunks.isEmpty) {
      throw ArgumentError('Cannot combine empty chunks list');
    }

    if (chunks.length == 1) {
      return chunks.first;
    }

    // Sort by part number
    chunks.sort((a, b) => a.part.compareTo(b.part));

    // Verify all chunks belong to same share
    final shareId = chunks.first.shareId;
    final totalParts = chunks.first.totalParts;
    
    if (chunks.length != totalParts) {
      throw ArgumentError('Missing chunks: got ${chunks.length}, expected $totalParts');
    }

    for (final chunk in chunks) {
      if (chunk.shareId != shareId) {
        throw ArgumentError('Chunks have different share IDs');
      }
    }

    // Combine all tracks
    final allTracks = <ShareableTrack>[];
    for (final chunk in chunks) {
      allTracks.addAll(chunk.tracks);
    }

    return ShareData(
      version: chunks.first.version,
      type: chunks.first.type,
      name: chunks.first.name,
      description: chunks.first.description,
      tracks: allTracks,
    );
  }
}
