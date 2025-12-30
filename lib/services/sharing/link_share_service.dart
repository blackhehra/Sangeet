import 'package:sangeet/services/sharing/share_data_model.dart';
import 'package:sangeet/services/sharing/share_compression_service.dart';

/// Service for creating and parsing deep links for sharing
/// Supports chunked links for large playlists
class LinkShareService {
  static LinkShareService? _instance;
  static LinkShareService get instance => _instance ??= LinkShareService._();
  
  LinkShareService._();

  final _compression = ShareCompressionService.instance;

  /// URL scheme for Sangeet deep links
  static const String scheme = 'sangeet';
  
  /// Host for share links
  static const String shareHost = 'share';

  /// Web redirect URL for clickable links in messaging apps
  /// This page redirects https:// links to sangeet:// deep links
  static const String webRedirectBase = 'https://blackhehra.github.io/sangeet-share';

  /// Generate share link(s) for the given data
  /// Returns a single link if data fits, or multiple chunked links
  List<String> generateLinks(ShareData data) {
    final chunks = _compression.splitToFitSize(
      data,
      ShareSizeLimits.maxDeepLinkBytes,
    );

    return chunks.map((chunk) => _createLink(chunk)).toList();
  }

  /// Create a single deep link from ShareData
  String _createLink(ShareData data) {
    final encoded = _compression.compress(data);
    
    // Use https:// link for better compatibility in messaging apps
    return '$webRedirectBase#$encoded';
  }

  /// Create a direct deep link (always sangeet://)
  String _createDirectLink(ShareData data) {
    final encoded = _compression.compress(data);
    return '$scheme://$shareHost/$encoded';
  }

  /// Parse a deep link and extract ShareData
  /// Returns null if the link is invalid
  ShareData? parseLink(String link) {
    try {
      final uri = Uri.parse(link);
      
      if (uri.scheme != scheme) {
        print('LinkShareService: Invalid scheme: ${uri.scheme}');
        return null;
      }
      
      if (uri.host != shareHost) {
        print('LinkShareService: Invalid host: ${uri.host}');
        return null;
      }

      // The encoded data is in the path
      final encoded = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (encoded == null || encoded.isEmpty) {
        print('LinkShareService: No data in link');
        return null;
      }

      return _compression.decompress(encoded);
    } catch (e) {
      print('LinkShareService: Error parsing link: $e');
      return null;
    }
  }

  /// Check if a string is a valid Sangeet share link
  bool isValidShareLink(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.scheme == scheme && uri.host == shareHost;
    } catch (e) {
      return false;
    }
  }

  /// Generate a human-readable description of the share links
  String getShareDescription(List<String> links, ShareData data) {
    if (links.length == 1) {
      switch (data.type) {
        case ShareType.song:
          return 'Share this song';
        case ShareType.playlist:
          return 'Share playlist "${data.name}" (${data.tracks.length} songs)';
        case ShareType.album:
          return 'Share album "${data.name}" (${data.tracks.length} songs)';
      }
    } else {
      return 'Share ${data.tracks.length} songs in ${links.length} links';
    }
  }

  /// Generate share text with all links
  String generateShareText(ShareData data) {
    final links = generateLinks(data);
    final buffer = StringBuffer();

    switch (data.type) {
      case ShareType.song:
        final track = data.tracks.first;
        buffer.writeln('🎵 ${track.title} - ${track.artist}');
        buffer.writeln('');
        buffer.writeln('Open in Sangeet app:');
        break;
      case ShareType.playlist:
        buffer.writeln('🎶 Playlist: ${data.name}');
        buffer.writeln('${data.tracks.length} songs');
        buffer.writeln('');
        buffer.writeln('Open in Sangeet app:');
        break;
      case ShareType.album:
        buffer.writeln('💿 Album: ${data.name}');
        if (data.description != null) {
          buffer.writeln('by ${data.description}');
        }
        buffer.writeln('${data.tracks.length} songs');
        buffer.writeln('');
        buffer.writeln('Open in Sangeet app:');
        break;
    }

    if (links.length == 1) {
      buffer.writeln(links.first);
    } else {
      buffer.writeln('');
      for (int i = 0; i < links.length; i++) {
        buffer.writeln('Part ${i + 1}/${links.length}:');
        buffer.writeln(links[i]);
        if (i < links.length - 1) buffer.writeln('');
      }
    }


    return buffer.toString();
  }
}
