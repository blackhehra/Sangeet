import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/playlist.dart' as app;

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for videos/music
  Future<List<Track>> search(String query, {int limit = 20}) async {
    try {
      final searchResults = await _yt.search.search(query);
      final tracks = <Track>[];

      for (var i = 0; i < searchResults.length && i < limit; i++) {
        final video = searchResults[i];
        tracks.add(_videoToTrack(video));
      }

      return tracks;
    } catch (e) {
      print('YouTube search error: $e');
      return [];
    }
  }

  /// Search specifically for music
  Future<List<Track>> searchMusic(String query, {int limit = 20}) async {
    // Add "audio" or "lyrics" to get more music-focused results
    return search('$query audio', limit: limit);
  }

  /// Get video details by ID
  Future<Track?> getTrack(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return _videoToTrack(video);
    } catch (e) {
      print('Get track error: $e');
      return null;
    }
  }

  /// Get stream URL for a video
  Future<String?> getStreamUrl(String videoId) async {
    try {
      print('YouTubeService: Getting stream URL for video: $videoId');
      
      // Validate video ID format
      if (videoId.isEmpty || videoId.length != 11) {
        print('YouTubeService: Invalid video ID format: $videoId');
        return null;
      }
      
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      print('YouTubeService: Got manifest with ${manifest.audioOnly.length} audio streams, ${manifest.muxed.length} muxed streams');
      
      // Get audio-only streams sorted by bitrate (highest first)
      final audioStreams = manifest.audioOnly.sortByBitrate();
      
      if (audioStreams.isNotEmpty) {
        // Prefer webm/opus or mp4a.40.2 (AAC-LC) which are more compatible
        // Avoid mp4a.40.5 (HE-AAC) which may not work on all devices
        AudioOnlyStreamInfo? selectedStream;
        
        // First try to find a compatible stream (webm or AAC-LC)
        for (final stream in audioStreams) {
          final codec = stream.codec.toString().toLowerCase();
          // Prefer opus (webm) or AAC-LC (mp4a.40.2) - avoid HE-AAC (mp4a.40.5)
          if (codec.contains('opus') || codec.contains('mp4a.40.2')) {
            selectedStream = stream;
            break;
          }
        }
        
        // If no compatible stream found, try muxed first, then fallback to any audio
        if (selectedStream == null) {
          // Try muxed streams which are usually more compatible
          final muxedStreams = manifest.muxed.sortByBitrate();
          if (muxedStreams.isNotEmpty) {
            final stream = muxedStreams.last; // Use highest quality muxed
            final streamUrl = stream.url.toString();
            print('YouTubeService: Using muxed stream (better compat): ${stream.bitrate}, codec: ${stream.codec}');
            return streamUrl;
          }
          // Last resort: use highest bitrate audio stream
          selectedStream = audioStreams.first;
        }
        
        final streamUrl = selectedStream.url.toString();
        print('YouTubeService: Using audio stream: ${selectedStream.bitrate}, codec: ${selectedStream.codec}');
        return streamUrl;
      }

      // Fallback to muxed stream
      final muxedStreams = manifest.muxed.sortByBitrate();
      if (muxedStreams.isNotEmpty) {
        final stream = muxedStreams.last; // Use highest quality muxed
        final streamUrl = stream.url.toString();
        print('YouTubeService: Using muxed stream: ${stream.bitrate}');
        return streamUrl;
      }

      print('YouTubeService: No streams found for video: $videoId');
      return null;
    } catch (e, stackTrace) {
      print('YouTubeService: Get stream URL error: $e');
      print('YouTubeService: Stack trace: $stackTrace');
      
      // Try alternative method - get video info first
      try {
        print('YouTubeService: Trying alternative method...');
        final video = await _yt.videos.get(videoId);
        print('YouTubeService: Video found: ${video.title}');
        final manifest = await _yt.videos.streamsClient.getManifest(video.id);
        // Try muxed first for better compatibility
        final muxedStreams = manifest.muxed.sortByBitrate();
        if (muxedStreams.isNotEmpty) {
          return muxedStreams.last.url.toString();
        }
        final audioStreams = manifest.audioOnly.sortByBitrate();
        if (audioStreams.isNotEmpty) {
          return audioStreams.first.url.toString();
        }
      } catch (e2) {
        print('YouTubeService: Alternative method also failed: $e2');
      }
      
      return null;
    }
  }

  /// Get audio stream info
  Future<AudioStreamInfo?> getAudioStreamInfo(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate();
      return audioStreams.isNotEmpty ? audioStreams.last : null;
    } catch (e) {
      print('Get audio stream info error: $e');
      return null;
    }
  }

  /// Get playlist details
  Future<app.Playlist?> getPlaylist(String playlistId) async {
    try {
      final playlist = await _yt.playlists.get(playlistId);
      final videos = await _yt.playlists.getVideos(playlistId).toList();

      return app.Playlist(
        id: playlist.id.value,
        title: playlist.title,
        description: playlist.description,
        thumbnailUrl: playlist.thumbnails.highResUrl,
        author: playlist.author,
        tracks: videos.map(_videoToTrack).toList(),
        trackCount: playlist.videoCount ?? videos.length,
      );
    } catch (e) {
      print('Get playlist error: $e');
      return null;
    }
  }

  /// Get trending music
  Future<List<Track>> getTrendingMusic({int limit = 20}) async {
    // Search for trending music
    return search('trending music 2024', limit: limit);
  }

  /// Get related videos
  Future<List<Track>> getRelated(String videoId, {int limit = 10}) async {
    try {
      // First get the video object
      final video = await _yt.videos.get(videoId);
      final relatedVideos = await _yt.videos.getRelatedVideos(video);
      if (relatedVideos == null) return [];
      
      return relatedVideos
          .take(limit)
          .map(_videoToTrack)
          .toList();
    } catch (e) {
      print('Get related error: $e');
      return [];
    }
  }

  /// Convert Video to Track
  Track _videoToTrack(Video video) {
    return Track(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      thumbnailUrl: _getMaxResThumbnail(video.id.value),
      duration: video.duration ?? Duration.zero,
      viewCount: video.engagement.viewCount,
      likeCount: video.engagement.likeCount,
    );
  }

  /// Get high quality thumbnail URL for a video
  String _getMaxResThumbnail(String videoId) {
    // Use maxresdefault for best quality
    return 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
  }

  /// Get thumbnail with dynamic sizing
  static String? getThumbnailWithSize(String? url, int size) {
    if (url == null || url.isEmpty) return null;
    
    // For lh3.googleusercontent.com thumbnails
    if (url.startsWith('https://lh3.googleusercontent.com')) {
      return '$url-w$size-h$size';
    }
    
    // For yt3.ggpht.com thumbnails
    if (url.startsWith('https://yt3.ggpht.com')) {
      return '$url-w$size-h$size-s$size';
    }
    
    return url;
  }

  /// Dispose resources
  void dispose() {
    _yt.close();
  }
}
