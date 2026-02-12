import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio_lib;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';
import 'package:sangeet/services/chunk_cache.dart';

enum _ClientContext { androidVr, android, ios, tv, web }

class _ClientConfig {
  final String clientName;
  final String clientVersion;
  final int clientId;
  final String userAgent;
  final String? platform;
  final int? androidSdkVersion;
  final String? osName;
  final String? osVersion;
  final String? deviceMake;
  final String? deviceModel;
  final String? referer;
  final bool music;
  const _ClientConfig({
    required this.clientName, required this.clientVersion,
    required this.clientId, required this.userAgent,
    this.platform, this.androidSdkVersion, this.osName, this.osVersion,
    this.deviceMake, this.deviceModel, this.referer, this.music = true,
  });
  Map<String, dynamic> toContext() => {
    'client': {
      'clientName': clientName, 'clientVersion': clientVersion,
      'hl': 'en', 'gl': 'US',
      if (platform != null) 'platform': platform,
      if (androidSdkVersion != null) 'androidSdkVersion': androidSdkVersion,
      if (osName != null) 'osName': osName,
      if (osVersion != null) 'osVersion': osVersion,
      if (deviceMake != null) 'deviceMake': deviceMake,
      if (deviceModel != null) 'deviceModel': deviceModel,
    },
    'user': {'lockedSafetyMode': false},
  };
}

const _clientConfigs = <_ClientContext, _ClientConfig>{
  _ClientContext.android: _ClientConfig(
    clientName: 'ANDROID', clientVersion: '20.10.38', clientId: 3,
    userAgent: 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
    osName: 'Android', osVersion: '11', platform: 'MOBILE', androidSdkVersion: 30,
  ),
  _ClientContext.ios: _ClientConfig(
    clientName: 'IOS', clientVersion: '20.10.4', clientId: 5,
    userAgent: 'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
    deviceMake: 'Apple', deviceModel: 'iPhone16,2', osName: 'iPhone', osVersion: '18.3.2.22D82',
  ),
  _ClientContext.tv: _ClientConfig(
    clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER', clientVersion: '2.0', clientId: 85,
    userAgent: 'Mozilla/5.0 (PlayStation; PlayStation 4/12.02) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.4 Safari/605.1.15',
    referer: 'https://www.youtube.com/',
  ),
  _ClientContext.androidVr: _ClientConfig(
    clientName: 'ANDROID_VR', clientVersion: '1.61.48', clientId: 28,
    userAgent: 'com.google.android.apps.youtube.vr.oculus/1.61.48 (Linux; U; Android 12; en_US; Oculus Quest 3; Build/SQ3A.220605.009.A1; Cronet/132.0.6808.3)',
    music: false,
  ),
  _ClientContext.web: _ClientConfig(
    clientName: 'WEB', clientVersion: '2.20250312.04.00', clientId: 1,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:141.0) Gecko/20100101 Firefox/141.0',
  ),
};

final _ytClients = [
  YoutubeApiClient.androidVr,
  YoutubeApiClient.android,
  YoutubeApiClient.ios,
];

class _UriEntry {
  final String url;
  final String userAgent;
  final int? contentLength;
  final DateTime expiresAt;
  _UriEntry({required this.url, required this.userAgent, this.contentLength, required this.expiresAt});
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class _StreamResult {
  final String url;
  final String userAgent;
  final int? contentLength;
  final String source;
  _StreamResult({required this.url, required this.userAgent, this.contentLength, required this.source});
}

class StreamingServer {
  static final StreamingServer _instance = StreamingServer._internal();
  factory StreamingServer() => _instance;
  StreamingServer._internal();

  HttpServer? _server;
  int _port = 0;
  final dio_lib.Dio _dio = dio_lib.Dio();
  final YoutubeExplode _yt = YoutubeExplode();
  final InnertubeService _innertube = InnertubeService();
  final Map<String, _UriEntry> _uriCache = {};
  final ChunkCache _chunkCache = ChunkCache();
  bool _cacheInitialized = false;
  AudioQuality _audioQuality = AudioQuality.high;

  int get port => _port;
  String get host => Platform.isWindows ? 'localhost' : '127.0.0.1';

  Future<bool> isAudioCached(String videoId) => _chunkCache.isFullyCached(videoId);
  Future<int> getAudioCacheSize() => _chunkCache.getCacheSize();
  Future<void> clearAudioCache() => _chunkCache.clear();

  Future<void> clearCachedStream(String videoId) async {
    await _chunkCache.delete(videoId);
    _uriCache.remove(videoId);
  }

  void setAudioCacheMaxSize(int bytes) => _chunkCache.setMaxSize(bytes);

  void setAudioQuality(AudioQuality quality) {
    if (_audioQuality != quality) {
      print('StreamingServer: Audio quality changed to ${quality.label}');
      _audioQuality = quality;
      _uriCache.clear();
    }
  }

  String getStreamUrl(String videoId) => 'http://$host:$_port/stream/$videoId';

  // ─── Lazy URI Resolution (like ViMusic's UriCache) ───

  Future<_UriEntry?> _resolveUri(String videoId) async {
    final cached = _uriCache[videoId];
    if (cached != null && !cached.isExpired) return cached;
    print('StreamingServer: Resolving URI for $videoId');
    for (final client in _ytClients) {
      final result = await _tryYoutubeExplodeStream(videoId, client, () => false);
      if (result != null) {
        final entry = _UriEntry(
          url: result.url, userAgent: result.userAgent,
          contentLength: result.contentLength,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        );
        _uriCache[videoId] = entry;
        if (result.contentLength != null) {
          _chunkCache.setContentLength(videoId, result.contentLength!);
        }
        print('StreamingServer: URI resolved via ${result.source}');
        return entry;
      }
    }
    print('StreamingServer: All clients failed for $videoId');
    return null;
  }

  Future<_UriEntry?> _refreshUri(String videoId) async {
    _uriCache.remove(videoId);
    return _resolveUri(videoId);
  }

  /// Legacy prefetchStream — now just pre-warms the URI cache
  Future<bool> prefetchStream(String videoId) async {
    final entry = await _resolveUri(videoId);
    return entry != null;
  }

  // ─── YouTube stream resolution methods ───

  Future<_StreamResult?> _tryYoutubeExplodeStream(
    String videoId, YoutubeApiClient client, bool Function() isCancelled,
  ) async {
    try {
      if (isCancelled()) return null;
      final clientName = client.payload["context"]["client"]["clientName"] ?? 'unknown';
      print('StreamingServer: [yt_explode:$clientName] Starting...');
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId, ytClients: [client],
      );
      if (isCancelled()) return null;
      if (manifest.audioOnly.isEmpty) {
        print('StreamingServer: [yt_explode:$clientName] No audio streams');
        return null;
      }
      final audioStreams = manifest.audioOnly.toList();
      if (audioStreams.isEmpty) return null;
      audioStreams.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

      AudioOnlyStreamInfo selected;
      switch (_audioQuality) {
        case AudioQuality.low:
          final aac140 = audioStreams.where((s) => s.tag == 140).toList();
          selected = aac140.isNotEmpty ? aac140.first : audioStreams.last;
        case AudioQuality.medium:
          final opus251 = audioStreams.where((s) => s.tag == 251).toList();
          final aac140 = audioStreams.where((s) => s.tag == 140).toList();
          if (opus251.isNotEmpty) { selected = opus251.first; }
          else if (aac140.isNotEmpty) { selected = aac140.first; }
          else { selected = audioStreams.length > 1 ? audioStreams[audioStreams.length ~/ 2] : audioStreams.last; }
        case AudioQuality.high:
          final opusStreams = audioStreams.where((s) => s.codec.toString().contains('opus')).toList();
          selected = opusStreams.isNotEmpty ? opusStreams.first : audioStreams.first;
        case AudioQuality.ultra:
          selected = audioStreams.first;
      }

      final streamUrl = selected.url.toString();
      final userAgent = _getUserAgentForClient(client);
      if (isCancelled()) return null;
      print('StreamingServer: [yt_explode:$clientName] Got stream (${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
      return _StreamResult(
        url: streamUrl, userAgent: userAgent,
        contentLength: selected.size.totalBytes,
        source: 'yt_explode:$clientName',
      );
    } catch (e) {
      final clientName = client.payload["context"]["client"]["clientName"] ?? 'unknown';
      print('StreamingServer: [yt_explode:$clientName] Failed: $e');
    }
    return null;
  }

  String _getUserAgentForClient(YoutubeApiClient client) {
    try {
      final ua = client.payload["context"]["client"]["userAgent"];
      if (ua != null && ua is String) return ua;
    } catch (_) {}
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
  }

  // ─── Server lifecycle ───

  Future<void> start() async {
    if (_server != null) return;
    if (!_cacheInitialized) {
      await _chunkCache.init();
      _cacheInitialized = true;
    }
    final router = Router();
    router.get('/ping', (shelf.Request r) => shelf.Response.ok('pong'));
    router.get('/stream/<videoId>', _handleStreamRequest);
    router.head('/stream/<videoId>', _handleHeadRequest);
    _port = await _findAvailablePort();
    _server = await shelf_io.serve(router.call, InternetAddress.loopbackIPv4, _port);
    print('StreamingServer: Started on http://$host:$_port');
  }

  Future<int> _findAvailablePort() async {
    final rng = Random();
    for (int i = 0; i < 10; i++) {
      final p = 8000 + rng.nextInt(1000);
      try {
        final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, p);
        await s.close();
        return p;
      } catch (_) {}
    }
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final p = s.port;
    await s.close();
    return p;
  }

  Future<shelf.Response> _handleHeadRequest(shelf.Request request, String videoId) async {
    final uri = _uriCache[videoId];
    return shelf.Response.ok(null, headers: {
      'Content-Type': 'audio/mp4',
      'Accept-Ranges': 'bytes',
      if (uri?.contentLength != null) 'Content-Length': uri!.contentLength.toString(),
    });
  }

  /// Core stream handler — chunk-based caching (like ViMusic/ExoPlayer SimpleCache)
  /// 1. Parse range request to determine which chunks are needed
  /// 2. Serve cached chunks instantly from disk
  /// 3. Fetch uncached chunks from YouTube, cache them, then serve
  /// 4. Handle 403 by refreshing URI transparently
  Future<shelf.Response> _handleStreamRequest(
      shelf.Request request, String videoId) async {
    try {
      // Resolve URI lazily (from cache or fresh fetch)
      var uri = await _resolveUri(videoId);
      if (uri == null) {
        return shelf.Response.notFound('Failed to resolve stream URL');
      }

      final contentLength = uri.contentLength;
      if (contentLength == null || contentLength <= 0) {
        // No content length — fall back to simple proxy
        return _proxyStreamSimple(request, videoId, uri);
      }

      // Parse range header
      final rangeHeader = request.headers['range'];
      int startByte = 0;
      int endByte = contentLength - 1;
      bool isRangeRequest = false;

      if (rangeHeader != null) {
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
        if (match != null) {
          startByte = int.parse(match.group(1)!);
          endByte = match.group(2)!.isNotEmpty
              ? int.parse(match.group(2)!)
              : contentLength - 1;
          isRangeRequest = true;
        }
      }

      // Clamp
      endByte = endByte.clamp(0, contentLength - 1);
      if (startByte > endByte) {
        return shelf.Response(416, body: 'Range not satisfiable');
      }

      // Try to serve entirely from chunk cache
      final cachedBytes =
          await _chunkCache.readRange(videoId, startByte, endByte + 1);
      if (cachedBytes != null) {
        print('StreamingServer: Serving $videoId from chunk cache '
            '[$startByte-$endByte]');
        return _buildResponse(
            cachedBytes, startByte, endByte, contentLength, isRangeRequest);
      }

      // Fetch the needed range from YouTube and cache chunks along the way
      final bytes = await _fetchAndCacheRange(
          videoId, uri, startByte, endByte);
      if (bytes == null) {
        return shelf.Response.internalServerError(
            body: 'Failed to fetch stream data');
      }

      return _buildResponse(
          bytes, startByte, endByte, contentLength, isRangeRequest);
    } catch (e) {
      final es = e.toString();
      if (es.contains('Bad file descriptor') ||
          es.contains('errno = 9') ||
          es.contains('Connection reset')) {
        return shelf.Response.ok('');
      }
      print('StreamingServer: Error: $e');
      return shelf.Response.internalServerError(body: 'Stream error: $e');
    }
  }

  shelf.Response _buildResponse(Uint8List bytes, int startByte, int endByte,
      int contentLength, bool isRangeRequest) {
    if (isRangeRequest) {
      return shelf.Response(206, body: bytes, headers: {
        'Content-Type': 'audio/mp4',
        'Content-Length': '${bytes.length}',
        'Content-Range': 'bytes $startByte-$endByte/$contentLength',
        'Accept-Ranges': 'bytes',
        'Connection': 'close',
      });
    }
    return shelf.Response.ok(bytes, headers: {
      'Content-Type': 'audio/mp4',
      'Content-Length': '$contentLength',
      'Accept-Ranges': 'bytes',
      'Connection': 'close',
    });
  }

  /// Fetch a byte range from YouTube, caching each 512KB chunk as it arrives.
  /// On 403, refreshes URI and retries once.
  Future<Uint8List?> _fetchAndCacheRange(
      String videoId, _UriEntry uri, int startByte, int endByte) async {
    // Align to chunk boundaries for caching efficiency
    final cs = ChunkCache.chunkSize;
    final alignedStart = (startByte ~/ cs) * cs;
    // Fetch up to end of the last needed chunk (or content length)
    final alignedEnd = uri.contentLength != null
        ? min(((endByte ~/ cs) + 1) * cs - 1, uri.contentLength! - 1)
        : endByte;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.get<dio_lib.ResponseBody>(
          uri.url,
          options: dio_lib.Options(
            headers: {
              'User-Agent': uri.userAgent,
              'Accept': '*/*',
              'Accept-Encoding': 'identity',
              'Range': 'bytes=$alignedStart-$alignedEnd',
            },
            responseType: dio_lib.ResponseType.stream,
            validateStatus: (s) => s != null && s < 500,
            followRedirects: true,
            maxRedirects: 5,
          ),
        );

        if (response.statusCode == 403) {
          print('StreamingServer: 403 for $videoId, refreshing URI...');
          final refreshed = await _refreshUri(videoId);
          if (refreshed == null) return null;
          uri = refreshed;
          continue; // retry with fresh URI
        }

        if (response.statusCode == 416) {
          // Range not satisfiable — retry without range
          print('StreamingServer: 416 for $videoId, retrying without range');
          return _fetchAndCacheRange(videoId, uri, 0, endByte);
        }

        final stream = response.data?.stream;
        if (stream == null) return null;

        // Read all bytes from the response
        final builder = BytesBuilder(copy: false);
        await for (final chunk in stream) {
          builder.add(chunk);
        }
        final allBytes = builder.toBytes();

        // Write chunks to cache in background
        _cacheChunksInBackground(videoId, alignedStart, allBytes);

        // Extract the originally requested range from the fetched data
        final offsetInFetched = startByte - alignedStart;
        final lengthNeeded = endByte - startByte + 1;
        if (offsetInFetched >= 0 &&
            offsetInFetched + lengthNeeded <= allBytes.length) {
          return Uint8List.sublistView(
              allBytes, offsetInFetched, offsetInFetched + lengthNeeded);
        }
        // If we got less data than expected, return what we have
        if (offsetInFetched < allBytes.length) {
          return Uint8List.sublistView(allBytes, offsetInFetched);
        }
        return allBytes;
      } catch (e) {
        print('StreamingServer: Fetch error (attempt $attempt): $e');
        if (attempt == 0) {
          final refreshed = await _refreshUri(videoId);
          if (refreshed != null) { uri = refreshed; continue; }
        }
        return null;
      }
    }
    return null;
  }

  /// Write fetched bytes into chunk cache files (background, non-blocking)
  void _cacheChunksInBackground(
      String videoId, int startOffset, Uint8List data) {
    Future(() async {
      final cs = ChunkCache.chunkSize;
      int pos = 0;
      int chunkIdx = startOffset ~/ cs;
      // Handle partial first chunk
      final firstChunkOffset = startOffset % cs;
      if (firstChunkOffset > 0) {
        // Skip partial first chunk — don't cache incomplete chunks
        final skip = cs - firstChunkOffset;
        pos += skip;
        chunkIdx++;
      }
      while (pos + cs <= data.length) {
        if (!await _chunkCache.hasChunk(videoId, chunkIdx)) {
          await _chunkCache.writeChunk(
              videoId, chunkIdx, Uint8List.sublistView(data, pos, pos + cs));
        }
        pos += cs;
        chunkIdx++;
      }
      // Cache final partial chunk only if it's the last chunk of the file
      if (pos < data.length) {
        final contentLen = _chunkCache.getContentLength(videoId);
        if (contentLen != null) {
          final totalChunks = (contentLen / cs).ceil();
          if (chunkIdx == totalChunks - 1) {
            if (!await _chunkCache.hasChunk(videoId, chunkIdx)) {
              await _chunkCache.writeChunk(
                  videoId, chunkIdx, Uint8List.sublistView(data, pos));
            }
          }
        }
      }
    }).catchError((e) {
      print('StreamingServer: Background cache error: $e');
    });
  }

  /// Simple proxy fallback when content-length is unknown
  Future<shelf.Response> _proxyStreamSimple(
      shelf.Request request, String videoId, _UriEntry uri) async {
    final rangeHeader = request.headers['range'];
    final response = await _dio.get<dio_lib.ResponseBody>(
      uri.url,
      options: dio_lib.Options(
        headers: {
          'User-Agent': uri.userAgent,
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          if (rangeHeader != null) 'Range': rangeHeader,
        },
        responseType: dio_lib.ResponseType.stream,
        validateStatus: (s) => s != null && s < 500,
        followRedirects: true,
      ),
    );
    if (response.statusCode == 403) {
      final refreshed = await _refreshUri(videoId);
      if (refreshed != null) return _proxyStreamSimple(request, videoId, refreshed);
      return shelf.Response.internalServerError(body: 'Stream expired');
    }
    final headers = <String, String>{};
    response.headers.forEach((k, v) { if (v.isNotEmpty) headers[k] = v.first; });
    final safeStream = response.data!.stream.handleError((e) {
      final es = e.toString();
      if (!es.contains('Bad file descriptor') && !es.contains('errno = 9')) {
        print('StreamingServer: Stream error: $e');
      }
    });
    return shelf.Response(response.statusCode ?? 200, body: safeStream, headers: headers);
  }

  /// Prefetch and cache a track to disk for instant playback
  Future<bool> prefetchAndCacheTrack(String videoId) async {
    try {
      if (await _chunkCache.isFullyCached(videoId)) {
        print('StreamingServer: Track $videoId already fully cached');
        return true;
      }
      final uri = await _resolveUri(videoId);
      if (uri == null) return false;
      final contentLength = uri.contentLength;
      if (contentLength == null || contentLength <= 0) return false;

      print('StreamingServer: Prefetching $videoId (${contentLength ~/ 1024}KB)');
      final cs = ChunkCache.chunkSize;
      final totalChunks = (contentLength / cs).ceil();

      for (int i = 0; i < totalChunks; i++) {
        if (await _chunkCache.hasChunk(videoId, i)) continue;
        final start = i * cs;
        final end = min(start + cs - 1, contentLength - 1);
        try {
          final resp = await _dio.get<dio_lib.ResponseBody>(
            uri.url,
            options: dio_lib.Options(
              headers: {
                'User-Agent': uri.userAgent,
                'Range': 'bytes=$start-$end',
                'Accept-Encoding': 'identity',
              },
              responseType: dio_lib.ResponseType.stream,
              validateStatus: (s) => s != null && s < 500,
              followRedirects: true,
            ),
          );
          if (resp.statusCode == 403) {
            final refreshed = await _refreshUri(videoId);
            if (refreshed == null) return false;
            // Retry this chunk with refreshed URI — restart loop
            i--;
            continue;
          }
          if (resp.data?.stream == null) continue;
          final bb = BytesBuilder(copy: false);
          await for (final chunk in resp.data!.stream) {
            bb.add(chunk);
          }
          await _chunkCache.writeChunk(videoId, i, bb.toBytes());
        } catch (e) {
          print('StreamingServer: Prefetch chunk $i error: $e');
        }
      }
      print('StreamingServer: Prefetch complete for $videoId');
      return true;
    } catch (e) {
      print('StreamingServer: Prefetch error for $videoId: $e');
      return false;
    }
  }

  /// Initialize stream cache (no-op, kept for API compatibility)
  Future<void> initStreamCache() async {}

  void clearCache(String videoId) => _uriCache.remove(videoId);
  void clearAllCache() => _uriCache.clear();

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _port = 0;
    _uriCache.clear();
    print('StreamingServer: Stopped');
  }
}
