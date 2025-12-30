import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/custom_playlist.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';
import 'package:sangeet/services/sharing/link_share_service.dart';
import 'package:sangeet/services/sharing/file_share_service.dart';
import 'package:sangeet/services/sharing/qr_share_service.dart';
import 'package:sangeet/services/custom_playlist_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';

/// Main service for sharing content in Sangeet
/// Provides unified API for all sharing methods
class ShareService {
  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._();
  
  ShareService._();

  final _linkService = LinkShareService.instance;
  final _fileService = FileShareService.instance;
  final _qrService = QrShareService.instance;

  // ============ SHARE CREATION ============

  /// Create ShareData for a single song
  ShareData createSongShare(Track track) {
    return ShareData.song(track);
  }

  /// Create ShareData for a custom playlist
  ShareData createPlaylistShare(CustomPlaylist playlist) {
    return ShareData.playlist(
      name: playlist.name,
      description: playlist.description,
      tracks: playlist.tracks,
    );
  }

  /// Create ShareData for an album
  ShareData createAlbumShare({
    required String name,
    String? artist,
    required List<Track> tracks,
  }) {
    return ShareData.album(
      name: name,
      artist: artist,
      tracks: tracks,
    );
  }

  /// Create ShareData for a list of tracks (generic)
  ShareData createTracksShare({
    required String name,
    String? description,
    required List<Track> tracks,
    ShareType type = ShareType.playlist,
  }) {
    return ShareData(
      type: type,
      name: name,
      description: description,
      tracks: tracks.map((t) => ShareableTrack.fromTrack(t)).toList(),
    );
  }

  // ============ LINK SHARING ============

  /// Generate share links for the data
  List<String> generateLinks(ShareData data) {
    return _linkService.generateLinks(data);
  }

  /// Generate formatted share text with links
  String generateShareText(ShareData data) {
    return _linkService.generateShareText(data);
  }

  /// Parse a share link
  ShareData? parseLink(String link) {
    return _linkService.parseLink(link);
  }

  /// Check if a string is a valid share link
  bool isValidShareLink(String link) {
    return _linkService.isValidShareLink(link);
  }

  // ============ FILE SHARING ============

  /// Export data to a .sangeet file
  Future<String> exportToFile(ShareData data) {
    return _fileService.exportToFile(data);
  }

  /// Import data from a .sangeet file
  Future<ShareData?> importFromFile(String filePath) {
    return _fileService.importFromFile(filePath);
  }

  /// Import data from file bytes
  ShareData? importFromBytes(List<int> bytes) {
    return _fileService.importFromBytes(bytes);
  }

  /// Check if a file is a valid .sangeet file
  bool isValidSangeetFile(String filePath) {
    return _fileService.isValidSangeetFile(filePath);
  }

  // ============ QR CODE SHARING ============

  /// Generate QR code data strings
  List<String> generateQrData(ShareData data) {
    return _qrService.generateQrData(data);
  }

  /// Parse QR code data
  ShareData? parseQrData(String qrData) {
    return _qrService.parseQrData(qrData);
  }

  /// Calculate number of QR codes needed
  int calculateQrCount(ShareData data) {
    return _qrService.calculateQrCount(data);
  }

  /// Create a new multi-QR scan session
  MultiQrScanSession createScanSession() {
    return MultiQrScanSession();
  }

  // ============ IMPORT TO LIBRARY ============

  /// Fetch full track metadata from YouTube Music (including thumbnails)
  Future<Track?> _fetchTrackMetadata(String trackId) async {
    try {
      final ytMusic = YtMusicService();
      final songData = await ytMusic.getSongData(trackId);
      
      if (songData.isNotEmpty && songData['image'] != null) {
        return Track(
          id: trackId,
          title: songData['title'] ?? '',
          artist: songData['artist'] ?? '',
          thumbnailUrl: songData['image'] as String?,
          duration: songData['duration'] != null 
              ? Duration(seconds: int.tryParse(songData['duration'].toString()) ?? 0)
              : Duration.zero,
        );
      }
    } catch (e) {
      print('ShareService: Error fetching metadata for $trackId: $e');
    }
    return null;
  }

  /// Fetch thumbnails for a playlist in background and update it
  Future<void> _fetchThumbnailsInBackground(String playlistId, List<Track> tracks) async {
    final playlistService = CustomPlaylistService.instance;
    final ytMusic = YtMusicService();
    
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      if (track.thumbnailUrl == null || track.thumbnailUrl!.isEmpty) {
        try {
          final songData = await ytMusic.getSongData(track.id);
          if (songData.isNotEmpty && songData['image'] != null) {
            final enrichedTrack = Track(
              id: track.id,
              title: songData['title'] ?? track.title,
              artist: songData['artist'] ?? track.artist,
              album: track.album,
              thumbnailUrl: songData['image'] as String?,
              duration: songData['duration'] != null 
                  ? Duration(seconds: int.tryParse(songData['duration'].toString()) ?? 0)
                  : track.duration,
            );
            // Update the track in the playlist
            await playlistService.updateTrackInPlaylist(playlistId, i, enrichedTrack);
          }
        } catch (e) {
          print('ShareService: Background fetch error for ${track.id}: $e');
        }
      }
    }
  }

  /// Import shared data into the user's library
  /// Creates a new playlist or adds songs to existing
  /// Thumbnails are fetched in background after import
  Future<ImportResult> importToLibrary(ShareData data) async {
    final playlistService = CustomPlaylistService.instance;

    switch (data.type) {
      case ShareType.song:
        // For single song, create a "Shared Songs" playlist or add to it
        final track = data.tracks.first.toTrack();
        var sharedPlaylist = playlistService.getPlaylists().firstWhere(
          (p) => p.name == 'Shared Songs',
          orElse: () => const CustomPlaylist(
            id: '',
            name: '',
            tracks: [],
            createdAt: 0,
            updatedAt: 0,
          ),
        );

        if (sharedPlaylist.id.isEmpty) {
          // Create the playlist
          sharedPlaylist = await playlistService.createPlaylist(
            name: 'Shared Songs',
            description: 'Songs shared with you',
          );
        }

        final added = await playlistService.addTrackToPlaylist(
          sharedPlaylist.id,
          track,
        );

        // Fetch thumbnail in background
        if (added) {
          _fetchThumbnailsInBackground(sharedPlaylist.id, [track]);
        }

        return ImportResult(
          success: true,
          type: data.type,
          name: track.title,
          trackCount: 1,
          playlistId: sharedPlaylist.id,
          message: added 
              ? 'Added "${track.title}" to Shared Songs'
              : 'Song already in Shared Songs',
        );

      case ShareType.playlist:
      case ShareType.album:
        // Import tracks immediately without thumbnails
        final tracks = data.tracks.map((t) => t.toTrack()).toList();
        final name = data.name ?? (data.type == ShareType.album ? 'Shared Album' : 'Shared Playlist');
        
        final playlist = await playlistService.importSpotifyPlaylist(
          name: name,
          tracks: tracks,
          description: data.description ?? 'Shared via Sangeet',
        );

        // Fetch thumbnails in background (don't await)
        _fetchThumbnailsInBackground(playlist.id, tracks);

        return ImportResult(
          success: true,
          type: data.type,
          name: name,
          trackCount: tracks.length,
          playlistId: playlist.id,
          message: 'Imported "$name" with ${tracks.length} songs',
        );
    }
  }

  // ============ SHARE INFO ============

  /// Get a summary of what will be shared
  ShareSummary getShareSummary(ShareData data) {
    final links = generateLinks(data);
    final qrCodes = generateQrData(data);

    return ShareSummary(
      type: data.type,
      name: data.name,
      trackCount: data.tracks.length,
      linkCount: links.length,
      qrCount: qrCodes.length,
      requiresMultipleLinks: links.length > 1,
      requiresMultipleQr: qrCodes.length > 1,
    );
  }
}

/// Result of importing shared content
class ImportResult {
  final bool success;
  final ShareType type;
  final String name;
  final int trackCount;
  final String? playlistId;
  final String message;
  final String? error;

  const ImportResult({
    required this.success,
    required this.type,
    required this.name,
    required this.trackCount,
    this.playlistId,
    required this.message,
    this.error,
  });
}

/// Summary of share data for UI display
class ShareSummary {
  final ShareType type;
  final String? name;
  final int trackCount;
  final int linkCount;
  final int qrCount;
  final bool requiresMultipleLinks;
  final bool requiresMultipleQr;

  const ShareSummary({
    required this.type,
    this.name,
    required this.trackCount,
    required this.linkCount,
    required this.qrCount,
    required this.requiresMultipleLinks,
    required this.requiresMultipleQr,
  });

  String get typeLabel {
    switch (type) {
      case ShareType.song:
        return 'Song';
      case ShareType.playlist:
        return 'Playlist';
      case ShareType.album:
        return 'Album';
    }
  }

  String get description {
    if (type == ShareType.song) {
      return '1 song';
    }
    return '$trackCount songs';
  }
}
