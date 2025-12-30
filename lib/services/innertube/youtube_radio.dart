import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';

/// Auto-queue related songs based on the current playing track
/// This fetches related songs based on the current playing track
class YouTubeRadio {
  final InnertubeService _innertube = InnertubeService();
  
  String? _videoId;
  String? _playlistId;
  String? _playlistSetVideoId;
  String? _params;
  String? _nextContinuation;
  
  YouTubeRadio({
    String? videoId,
    String? playlistId,
    String? playlistSetVideoId,
    String? params,
  }) : _videoId = videoId,
       _playlistId = playlistId,
       _playlistSetVideoId = playlistSetVideoId,
       _params = params;

  /// Process and get next batch of songs for radio
  Future<List<Track>> process() async {
    try {
      final tracks = await _innertube.getNextSongs(
        _videoId ?? '',
        playlistId: _playlistId,
      );
      
      print('YouTubeRadio: Got ${tracks.length} tracks');
      return tracks;
    } catch (e) {
      print('YouTubeRadio: Error processing: $e');
      return [];
    }
  }

  /// Start radio from a specific video
  static Future<YouTubeRadio> fromVideoId(String videoId) async {
    return YouTubeRadio(videoId: videoId);
  }

  /// Start radio from a playlist
  static Future<YouTubeRadio> fromPlaylist(String playlistId, {String? videoId}) async {
    return YouTubeRadio(
      videoId: videoId,
      playlistId: playlistId,
    );
  }
}
