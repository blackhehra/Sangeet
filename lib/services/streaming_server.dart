import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio_lib;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/innertube/innertube_service.dart';

/// Client contexts for stream resolution - tried sequentially until one works
/// Priority order based on testing results:
/// 1. ANDROID_VR - Most reliable, bypasses most restrictions
/// 2. ANDROID - Good fallback
/// 3. IOS - Alternative fallback
/// 4. TV - Sometimes works for restricted content
/// 5. WEB - Last resort (often requires signature cipher)
enum _ClientContext {
  androidVr,
  android,
  ios,
  tv,
  web,
}

/// Client configuration for each context
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
    required this.clientName,
    required this.clientVersion,
    required this.clientId,
    required this.userAgent,
    this.platform,
    this.androidSdkVersion,
    this.osName,
    this.osVersion,
    this.deviceMake,
    this.deviceModel,
    this.referer,
    this.music = true,
  });

  Map<String, dynamic> toContext() => {
    'client': {
      'clientName': clientName,
      'clientVersion': clientVersion,
      'hl': 'en',
      'gl': 'US',
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

/// Client configurations - matching successful implementations
const _clientConfigs = <_ClientContext, _ClientConfig>{
  _ClientContext.android: _ClientConfig(
    clientName: 'ANDROID',
    clientVersion: '20.10.38',
    clientId: 3,
    userAgent: 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
    osName: 'Android',
    osVersion: '11',
    platform: 'MOBILE',
    androidSdkVersion: 30,
  ),
  _ClientContext.ios: _ClientConfig(
    clientName: 'IOS',
    clientVersion: '20.10.4',
    clientId: 5,
    userAgent: 'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
    deviceMake: 'Apple',
    deviceModel: 'iPhone16,2',
    osName: 'iPhone',
    osVersion: '18.3.2.22D82',
  ),
  _ClientContext.tv: _ClientConfig(
    clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
    clientVersion: '2.0',
    clientId: 85,
    userAgent: 'Mozilla/5.0 (PlayStation; PlayStation 4/12.02) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.4 Safari/605.1.15',
    referer: 'https://www.youtube.com/',
  ),
  _ClientContext.androidVr: _ClientConfig(
    clientName: 'ANDROID_VR',
    clientVersion: '1.61.48',
    clientId: 28,
    userAgent: 'com.google.android.apps.youtube.vr.oculus/1.61.48 (Linux; U; Android 12; en_US; Oculus Quest 3; Build/SQ3A.220605.009.A1; Cronet/132.0.6808.3)',
    music: false,
  ),
  _ClientContext.web: _ClientConfig(
    clientName: 'WEB',
    clientVersion: '2.20250312.04.00',
    clientId: 1,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:141.0) Gecko/20100101 Firefox/141.0',
  ),
};

/// Fallback: youtube_explode clients (used if all Innertube clients fail)
/// ANDROID_VR is first since it's most reliable
final _ytClients = [
  YoutubeApiClient.androidVr,
  YoutubeApiClient.android,
  YoutubeApiClient.ios,
];

/// Cached stream URL data
class _CachedStream {
  final String url;
  final String userAgent;
  final int? contentLength;
  final DateTime expiresAt;
  
  _CachedStream({
    required this.url,
    required this.userAgent,
    this.contentLength,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'url': url,
    'userAgent': userAgent,
    'contentLength': contentLength,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
  };
  
  /// Create from JSON
  factory _CachedStream.fromJson(Map<String, dynamic> json) => _CachedStream(
    url: json['url'] as String,
    userAgent: json['userAgent'] as String,
    contentLength: json['contentLength'] as int?,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
  );
}

/// Result from a stream resolution attempt
class _StreamResult {
  final String url;
  final String userAgent;
  final int? contentLength;
  final String source;
  
  _StreamResult({
    required this.url,
    required this.userAgent,
    this.contentLength,
    required this.source,
  });
}

/// Audio disk cache with LRU eviction
class _AudioDiskCache {
  static const int _defaultMaxSizeBytes = 512 * 1024 * 1024; // 512MB default
  static const int _chunkSize = 512 * 1024; // 512KB chunks
  
  Directory? _cacheDir;
  int _maxSizeBytes;
  final Map<String, int> _accessTimes = {}; // videoId -> last access timestamp
  
  _AudioDiskCache({int? maxSizeBytes}) : _maxSizeBytes = maxSizeBytes ?? _defaultMaxSizeBytes;
  
  Future<void> init() async {
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    print('AudioDiskCache: Initialized at ${_cacheDir!.path}');
    // Load access times from existing files
    await _loadAccessTimes();
    // Run initial cleanup
    await _evictIfNeeded();
  }
  
  Future<void> _loadAccessTimes() async {
    if (_cacheDir == null) return;
    try {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final videoId = entity.path.split('/').last.split('.').first;
          _accessTimes[videoId] = stat.accessed.millisecondsSinceEpoch;
        }
      }
    } catch (e) {
      print('AudioDiskCache: Error loading access times: $e');
    }
  }
  
  File _getCacheFile(String videoId) {
    return File('${_cacheDir!.path}/$videoId.audio');
  }
  
  /// Check if audio is cached
  Future<bool> isCached(String videoId) async {
    if (_cacheDir == null) return false;
    final file = _getCacheFile(videoId);
    return await file.exists();
  }
  
  /// Get cached audio file path
  Future<String?> getCachedPath(String videoId) async {
    if (_cacheDir == null) return null;
    final file = _getCacheFile(videoId);
    if (await file.exists()) {
      // Update access time
      _accessTimes[videoId] = DateTime.now().millisecondsSinceEpoch;
      return file.path;
    }
    return null;
  }
  
  /// Cache audio data
  Future<void> cacheAudio(String videoId, Uint8List data) async {
    if (_cacheDir == null) return;
    try {
      await _evictIfNeeded(additionalBytes: data.length);
      final file = _getCacheFile(videoId);
      await file.writeAsBytes(data);
      _accessTimes[videoId] = DateTime.now().millisecondsSinceEpoch;
      print('AudioDiskCache: Cached $videoId (${data.length ~/ 1024}KB)');
    } catch (e) {
      print('AudioDiskCache: Error caching audio: $e');
    }
  }
  
  /// Cache audio from stream
  Future<File?> cacheFromStream(String videoId, Stream<List<int>> stream) async {
    if (_cacheDir == null) return null;
    try {
      final file = _getCacheFile(videoId);
      final sink = file.openWrite();
      int totalBytes = 0;
      
      await for (final chunk in stream) {
        sink.add(chunk);
        totalBytes += chunk.length;
      }
      
      await sink.close();
      _accessTimes[videoId] = DateTime.now().millisecondsSinceEpoch;
      print('AudioDiskCache: Cached $videoId from stream (${totalBytes ~/ 1024}KB)');
      
      // Evict old files if needed
      await _evictIfNeeded();
      
      return file;
    } catch (e) {
      print('AudioDiskCache: Error caching from stream: $e');
      return null;
    }
  }
  
  /// Get current cache size
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;
    int size = 0;
    try {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      print('AudioDiskCache: Error getting cache size: $e');
    }
    return size;
  }
  
  /// Evict least recently used files if cache exceeds max size
  Future<void> _evictIfNeeded({int additionalBytes = 0}) async {
    if (_cacheDir == null) return;
    
    final currentSize = await getCacheSize();
    final targetSize = _maxSizeBytes - additionalBytes;
    
    if (currentSize <= targetSize) return;
    
    print('AudioDiskCache: Cache size ${currentSize ~/ (1024 * 1024)}MB exceeds limit ${_maxSizeBytes ~/ (1024 * 1024)}MB, evicting...');
    
    // Sort by access time (oldest first)
    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    int freedBytes = 0;
    final bytesToFree = currentSize - targetSize;
    
    for (final entry in sortedEntries) {
      if (freedBytes >= bytesToFree) break;
      
      final file = _getCacheFile(entry.key);
      if (await file.exists()) {
        final fileSize = await file.length();
        await file.delete();
        freedBytes += fileSize;
        _accessTimes.remove(entry.key);
        print('AudioDiskCache: Evicted ${entry.key} (${fileSize ~/ 1024}KB)');
      }
    }
    
    print('AudioDiskCache: Freed ${freedBytes ~/ 1024}KB');
  }
  
  /// Clear all cache
  Future<void> clear() async {
    if (_cacheDir == null) return;
    try {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      _accessTimes.clear();
      print('AudioDiskCache: Cleared');
    } catch (e) {
      print('AudioDiskCache: Error clearing cache: $e');
    }
  }
  
  /// Set max cache size
  void setMaxSize(int bytes) {
    _maxSizeBytes = bytes;
    _evictIfNeeded();
  }
}

/// A local HTTP server that proxies audio streams.
/// Pre-fetches stream URLs before playback for reliability.
class StreamingServer {
  static final StreamingServer _instance = StreamingServer._internal();
  factory StreamingServer() => _instance;
  StreamingServer._internal();

  HttpServer? _server;
  int _port = 0;
  final dio_lib.Dio _dio = dio_lib.Dio();
  final YoutubeExplode _yt = YoutubeExplode();
  final InnertubeService _innertube = InnertubeService();
  
  // URL cache for pre-fetched stream URLs - persisted to disk
  final Map<String, _CachedStream> _streamCache = {};
  bool _streamCacheInitialized = false;
  static const String _streamCacheKey = 'stream_url_cache';
  
  // Audio disk cache with LRU eviction
  final _AudioDiskCache _audioCache = _AudioDiskCache();
  bool _audioCacheInitialized = false;
  
  // Current audio quality setting
  AudioQuality _audioQuality = AudioQuality.high;
  
  int get port => _port;
  String get host => Platform.isWindows ? 'localhost' : '127.0.0.1';
  
  /// Check if audio is cached on disk
  Future<bool> isAudioCached(String videoId) => _audioCache.isCached(videoId);
  
  /// Get audio cache size
  Future<int> getAudioCacheSize() => _audioCache.getCacheSize();
  
  /// Clear audio cache
  Future<void> clearAudioCache() => _audioCache.clear();
  
  /// Set audio cache max size
  void setAudioCacheMaxSize(int bytes) => _audioCache.setMaxSize(bytes);
  
  /// Initialize stream URL cache from persistent storage
  Future<void> initStreamCache() async {
    if (_streamCacheInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_streamCacheKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        int loadedCount = 0;
        int expiredCount = 0;
        
        for (final entry in data.entries) {
          try {
            final cached = _CachedStream.fromJson(entry.value as Map<String, dynamic>);
            if (!cached.isExpired) {
              _streamCache[entry.key] = cached;
              loadedCount++;
            } else {
              expiredCount++;
            }
          } catch (e) {
            // Skip invalid entries
          }
        }
        print('StreamingServer: Loaded $loadedCount cached stream URLs ($expiredCount expired)');
      }
    } catch (e) {
      print('StreamingServer: Error loading stream cache: $e');
    }
    
    _streamCacheInitialized = true;
  }
  
  /// Save stream URL cache to persistent storage
  Future<void> _saveStreamCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      
      // Only save non-expired entries
      for (final entry in _streamCache.entries) {
        if (!entry.value.isExpired) {
          data[entry.key] = entry.value.toJson();
        }
      }
      
      await prefs.setString(_streamCacheKey, jsonEncode(data));
    } catch (e) {
      print('StreamingServer: Error saving stream cache: $e');
    }
  }
  
  /// Set the audio quality for stream selection
  void setAudioQuality(AudioQuality quality) {
    if (_audioQuality != quality) {
      print('StreamingServer: Audio quality changed to ${quality.label}');
      _audioQuality = quality;
      // Clear cache when quality changes
      _streamCache.clear();
    }
  }
  
  /// Get the local URL for a track
  String getStreamUrl(String videoId) {
    return 'http://$host:$_port/stream/$videoId';
  }
  
  /// Pre-fetch and validate stream URL before playback
  /// Uses youtube_explode directly with ANDROID_VR client (most reliable)
  /// Innertube clients are skipped as they consistently fail with 403/bot detection
  Future<bool> prefetchStream(String videoId) async {
    print('StreamingServer: Pre-fetching stream for $videoId');
    final startTime = DateTime.now();
    
    // Check cache first
    final cached = _streamCache[videoId];
    if (cached != null && !cached.isExpired) {
      // Validate cached URL is still working (quick HEAD request)
      try {
        final headResponse = await _dio.head(
          cached.url,
          options: dio_lib.Options(
            headers: {'User-Agent': cached.userAgent},
            validateStatus: (status) => status != null && status < 500,
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        if (headResponse.statusCode == 403) {
          print('StreamingServer: Cached URL returned 403, refreshing...');
          _streamCache.remove(videoId);
        } else {
          print('StreamingServer: Using cached stream URL (validated)');
          return true;
        }
      } catch (e) {
        print('StreamingServer: Cached URL validation failed: $e, refreshing...');
        _streamCache.remove(videoId);
      }
    }
    
    // Use youtube_explode directly - ANDROID_VR is most reliable
    // Innertube clients consistently fail with 403 or bot detection
    for (final client in _ytClients) {
      final result = await _tryYoutubeExplodeStream(videoId, client, () => false);
      if (result != null) {
        _streamCache[videoId] = _CachedStream(
          url: result.url,
          userAgent: result.userAgent,
          contentLength: result.contentLength,
          // Reduced from 5 hours to 3 hours - YouTube URLs can become stale
          // earlier due to network conditions or server-side changes
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        print('StreamingServer: Stream ready via ${result.source} in ${elapsed}ms');
        _saveStreamCache();
        return true;
      }
    }
    
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    print('StreamingServer: All clients failed in ${elapsed}ms');
    return false;
  }
  
  /// Try to get stream URL via Innertube API with a specific client context
  Future<_StreamResult?> _tryInnertubeClient(String videoId, _ClientContext context) async {
    final config = _clientConfigs[context]!;
    
    try {
      print('StreamingServer: [${config.clientName}] Trying...');
      
      // Build request body
      final body = {
        'context': config.toContext(),
        'videoId': videoId,
        'contentCheckOk': true,
        'racyCheckOk': true,
      };
      
      // Determine endpoint based on client
      final endpoint = config.music 
          ? 'https://music.youtube.com/youtubei/v1/player'
          : 'https://www.youtube.com/youtubei/v1/player';
      
      final response = await _dio.post(
        endpoint,
        data: body,
        options: dio_lib.Options(
          headers: {
            'User-Agent': config.userAgent,
            'Content-Type': 'application/json',
            'X-YouTube-Client-Name': config.clientId.toString(),
            'X-YouTube-Client-Version': config.clientVersion,
            if (config.referer != null) 'Referer': config.referer!,
          },
          validateStatus: (status) => status != null && status < 500,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (response.statusCode != 200) {
        print('StreamingServer: [${config.clientName}] Request failed: ${response.statusCode}');
        return null;
      }
      
      final data = response.data as Map<String, dynamic>;
      
      // Check playability
      final playabilityStatus = data['playabilityStatus'] as Map<String, dynamic>?;
      if (playabilityStatus == null) {
        print('StreamingServer: [${config.clientName}] No playability status');
        return null;
      }
      
      final status = playabilityStatus['status'] as String?;
      if (status != 'OK') {
        final reason = playabilityStatus['reason'] as String? ?? 'Unknown';
        print('StreamingServer: [${config.clientName}] Not playable: $reason');
        return null;
      }
      
      // Get streaming data
      final streamingData = data['streamingData'] as Map<String, dynamic>?;
      if (streamingData == null) {
        print('StreamingServer: [${config.clientName}] No streaming data');
        return null;
      }
      
      // Get adaptive formats
      final adaptiveFormats = streamingData['adaptiveFormats'] as List<dynamic>?;
      if (adaptiveFormats == null || adaptiveFormats.isEmpty) {
        print('StreamingServer: [${config.clientName}] No adaptive formats');
        return null;
      }
      
      // Find best audio format
      final audioFormats = adaptiveFormats
          .where((f) => (f['mimeType'] as String?)?.startsWith('audio/') == true)
          .toList();
      
      if (audioFormats.isEmpty) {
        print('StreamingServer: [${config.clientName}] No audio formats');
        return null;
      }
      
      // Sort by bitrate (highest first)
      audioFormats.sort((a, b) => 
          ((b['bitrate'] as int?) ?? 0).compareTo((a['bitrate'] as int?) ?? 0));
      
      // Prefer Opus (itag 251) or AAC (itag 140)
      Map<String, dynamic>? selectedFormat;
      for (final format in audioFormats) {
        final itag = format['itag'] as int?;
        if (itag == 251 || itag == 140) {
          selectedFormat = format as Map<String, dynamic>;
          break;
        }
      }
      selectedFormat ??= audioFormats.first as Map<String, dynamic>;
      
      // Get URL
      String? streamUrl = selectedFormat['url'] as String?;
      
      // Handle signature cipher if URL is not directly available
      if (streamUrl == null) {
        final signatureCipher = selectedFormat['signatureCipher'] as String?;
        if (signatureCipher != null) {
          // Parse cipher - this is complex, skip for now
          print('StreamingServer: [${config.clientName}] Signature cipher required, skipping');
          return null;
        }
        print('StreamingServer: [${config.clientName}] No URL available');
        return null;
      }
      
      final bitrate = selectedFormat['bitrate'] as int? ?? 0;
      final contentLength = int.tryParse(selectedFormat['contentLength']?.toString() ?? '');
      
      print('StreamingServer: [${config.clientName}] Found stream (${bitrate ~/ 1000}kbps)');
      
      // Validate URL with HEAD request
      print('StreamingServer: [${config.clientName}] Validating URL...');
      final headResponse = await _dio.head(
        streamUrl,
        options: dio_lib.Options(
          headers: {'User-Agent': config.userAgent},
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (headResponse.statusCode == 403) {
        print('StreamingServer: [${config.clientName}] URL returned 403, skipping');
        return null;
      }
      
      if (headResponse.statusCode != null && headResponse.statusCode! < 400) {
        print('StreamingServer: [${config.clientName}] Valid stream!');
        return _StreamResult(
          url: streamUrl,
          userAgent: config.userAgent,
          contentLength: contentLength,
          source: config.clientName,
        );
      }
      
      print('StreamingServer: [${config.clientName}] Validation failed: ${headResponse.statusCode}');
      return null;
      
    } catch (e) {
      print('StreamingServer: [${config.clientName}] Error: $e');
      return null;
    }
  }
  
  
  /// Try to get stream URL via youtube_explode (reliable fallback)
  Future<_StreamResult?> _tryYoutubeExplodeStream(
    String videoId, 
    YoutubeApiClient client,
    bool Function() isCancelled,
  ) async {
    try {
      if (isCancelled()) return null;
      
      final clientName = client.payload["context"]["client"]["clientName"] ?? 'unknown';
      print('StreamingServer: [youtube_explode:$clientName] Starting...');
      
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [client],
      );
      
      if (isCancelled()) return null;
      
      if (manifest.audioOnly.isEmpty) {
        print('StreamingServer: [youtube_explode:$clientName] No audio streams');
        return null;
      }
      
      // Select audio stream based on quality setting
      final audioStreams = manifest.audioOnly.toList();
      
      if (audioStreams.isEmpty) {
        print('StreamingServer: [youtube_explode:$clientName] No audio streams');
        return null;
      }
      
      // Sort streams by bitrate (highest first)
      audioStreams.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
      
      AudioOnlyStreamInfo selected;
      
      // Select stream based on quality setting
      switch (_audioQuality) {
        case AudioQuality.low:
          // Low quality: prefer AAC 128kbps (itag 140) or lowest available
          final aac140 = audioStreams.where((s) => s.tag == 140).toList();
          if (aac140.isNotEmpty) {
            selected = aac140.first;
            print('StreamingServer: [youtube_explode:$clientName] Selected AAC itag 140 (Low quality - 128kbps)');
          } else {
            selected = audioStreams.last; // Lowest bitrate
            print('StreamingServer: [youtube_explode:$clientName] Fallback to lowest bitrate itag ${selected.tag} (${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
          }
        case AudioQuality.medium:
          // Medium quality: prefer Opus 160kbps or AAC 128kbps
          final opus251 = audioStreams.where((s) => s.tag == 251).toList();
          final aac140 = audioStreams.where((s) => s.tag == 140).toList();
          if (opus251.isNotEmpty) {
            selected = opus251.first;
            print('StreamingServer: [youtube_explode:$clientName] Selected Opus itag 251 (Medium quality - ~160kbps)');
          } else if (aac140.isNotEmpty) {
            selected = aac140.first;
            print('StreamingServer: [youtube_explode:$clientName] Selected AAC itag 140 (Medium quality - 128kbps)');
          } else {
            selected = audioStreams.length > 1 ? audioStreams[audioStreams.length ~/ 2] : audioStreams.last;
            print('StreamingServer: [youtube_explode:$clientName] Fallback to medium bitrate itag ${selected.tag} (${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
          }
        case AudioQuality.high:
          // High quality: prefer highest bitrate Opus streams
          final opusStreams = audioStreams.where((s) => s.codec.toString().contains('opus')).toList();
          if (opusStreams.isNotEmpty) {
            selected = opusStreams.first; // Highest bitrate Opus
            print('StreamingServer: [youtube_explode:$clientName] Selected Opus itag ${selected.tag} (High quality - ${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
          } else {
            selected = audioStreams.first; // Highest bitrate overall
            print('StreamingServer: [youtube_explode:$clientName] Fallback to highest bitrate itag ${selected.tag} (${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
          }
        case AudioQuality.ultra:
          // Ultra quality: highest bitrate available (for 320kbps preference)
          selected = audioStreams.first;
          print('StreamingServer: [youtube_explode:$clientName] Selected highest bitrate itag ${selected.tag} (Ultra quality - ${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
      }
      
      final streamUrl = selected.url.toString();
      final userAgent = _getUserAgentForClient(client);
      
      if (isCancelled()) return null;
      
      // Validate URL with HEAD request to avoid 403 on actual playback
      print('StreamingServer: [youtube_explode:$clientName] Validating URL...');
      final headResponse = await _dio.head(
        streamUrl,
        options: dio_lib.Options(
          headers: {'User-Agent': userAgent},
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (isCancelled()) return null;
      
      if (headResponse.statusCode == 403) {
        print('StreamingServer: [youtube_explode:$clientName] URL returned 403, skipping');
        return null;
      }
      
      if (headResponse.statusCode != null && headResponse.statusCode! < 400) {
        print('StreamingServer: [youtube_explode:$clientName] Valid stream (${selected.bitrate.bitsPerSecond ~/ 1000}kbps)');
        return _StreamResult(
          url: streamUrl,
          userAgent: userAgent,
          contentLength: selected.size.totalBytes,
          source: 'youtube_explode:$clientName',
        );
      }
      
      print('StreamingServer: [youtube_explode:$clientName] URL validation failed: ${headResponse.statusCode}');
      return null;
    } catch (e) {
      final clientName = client.payload["context"]["client"]["clientName"] ?? 'unknown';
      print('StreamingServer: [youtube_explode:$clientName] Failed: $e');
    }
    return null;
  }
  
  String _getUserAgentForClient(YoutubeApiClient client) {
    try {
      final userAgent = client.payload["context"]["client"]["userAgent"];
      if (userAgent != null && userAgent is String) {
        return userAgent;
      }
    } catch (_) {}
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  }
  
  /// Initialize and start the server
  Future<void> start() async {
    if (_server != null) {
      print('StreamingServer: Already running on port $_port');
      return;
    }
    
    // Initialize audio disk cache
    if (!_audioCacheInitialized) {
      await _audioCache.init();
      _audioCacheInitialized = true;
    }
    
    final router = Router();
    
    router.get('/ping', (shelf.Request request) => shelf.Response.ok('pong'));
    router.get('/stream/<videoId>', _handleStreamRequest);
    router.get('/cached/<videoId>', _handleCachedRequest);
    router.head('/stream/<videoId>', _handleHeadRequest);
    
    _port = await _findAvailablePort();
    
    _server = await shelf_io.serve(
      router.call,
      InternetAddress.loopbackIPv4,
      _port,
    );
    
    print('StreamingServer: Started on http://$host:$_port');
  }
  
  /// Get URL for cached audio (direct file access)
  String? getCachedUrl(String videoId) {
    return 'http://$host:$_port/cached/$videoId';
  }
  
  /// Handle cached audio requests - serve from disk cache
  Future<shelf.Response> _handleCachedRequest(shelf.Request request, String videoId) async {
    try {
      final cachedPath = await _audioCache.getCachedPath(videoId);
      if (cachedPath == null) {
        return shelf.Response.notFound('Not cached');
      }
      
      final file = File(cachedPath);
      if (!await file.exists()) {
        return shelf.Response.notFound('Cache file not found');
      }
      
      final fileLength = await file.length();
      final rangeHeader = request.headers['range'];
      
      if (rangeHeader != null) {
        // Handle range request
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
        if (match != null) {
          final start = int.parse(match.group(1)!);
          final end = match.group(2)!.isNotEmpty 
              ? int.parse(match.group(2)!) 
              : fileLength - 1;
          
          final stream = file.openRead(start, end + 1);
          return shelf.Response(
            206,
            body: stream,
            headers: {
              'Content-Type': 'audio/mp4',
              'Content-Length': '${end - start + 1}',
              'Content-Range': 'bytes $start-$end/$fileLength',
              'Accept-Ranges': 'bytes',
            },
          );
        }
      }
      
      // Full file
      return shelf.Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'audio/mp4',
          'Content-Length': '$fileLength',
          'Accept-Ranges': 'bytes',
        },
      );
    } catch (e) {
      print('StreamingServer: Error serving cached file: $e');
      return shelf.Response.internalServerError(body: 'Error: $e');
    }
  }
  
  Future<int> _findAvailablePort() async {
    final random = Random();
    for (int i = 0; i < 10; i++) {
      final port = 8000 + random.nextInt(1000);
      try {
        final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
        await socket.close();
        return port;
      } catch (_) {
        continue;
      }
    }
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }
  
  /// Handle HEAD requests
  Future<shelf.Response> _handleHeadRequest(shelf.Request request, String videoId) async {
    final cached = _streamCache[videoId];
    if (cached != null && !cached.isExpired) {
      return shelf.Response.ok(
        null,
        headers: {
          'Content-Type': 'audio/mp4',
          'Accept-Ranges': 'bytes',
          if (cached.contentLength != null)
            'Content-Length': cached.contentLength.toString(),
        },
      );
    }
    
    return shelf.Response.ok(
      null,
      headers: {
        'Content-Type': 'audio/mp4',
        'Accept-Ranges': 'bytes',
      },
    );
  }
  
  /// Handle GET requests - stream the pre-fetched URL and cache to disk
  Future<shelf.Response> _handleStreamRequest(shelf.Request request, String videoId) async {
    try {
      print('StreamingServer: GET request for $videoId');
      
      // Check disk cache first - instant playback for cached songs
      final cachedPath = await _audioCache.getCachedPath(videoId);
      if (cachedPath != null) {
        print('StreamingServer: Serving from disk cache');
        // Clear URL cache since we have disk cache - prevents stale URL issues
        _streamCache.remove(videoId);
        final file = File(cachedPath);
        if (await file.exists()) {
          final fileLength = await file.length();
          final rangeHeader = request.headers['range'];
          
          if (rangeHeader != null) {
            final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
            if (match != null) {
              final start = int.parse(match.group(1)!);
              final end = match.group(2)!.isNotEmpty 
                  ? int.parse(match.group(2)!) 
                  : fileLength - 1;
              
              return shelf.Response(
                206,
                body: file.openRead(start, end + 1),
                headers: {
                  'Content-Type': 'audio/mp4',
                  'Content-Length': '${end - start + 1}',
                  'Content-Range': 'bytes $start-$end/$fileLength',
                  'Accept-Ranges': 'bytes',
                },
              );
            }
          }
          
          return shelf.Response.ok(
            file.openRead(),
            headers: {
              'Content-Type': 'audio/mp4',
              'Content-Length': '$fileLength',
              'Accept-Ranges': 'bytes',
            },
          );
        }
      }
      
      // Check URL cache for pre-fetched URL
      var cached = _streamCache[videoId];
      
      // If not cached or expired, try to fetch now (fallback)
      if (cached == null || cached.isExpired) {
        print('StreamingServer: No cached URL, fetching now...');
        final success = await prefetchStream(videoId);
        if (!success) {
          return shelf.Response.notFound('Failed to get stream URL');
        }
        cached = _streamCache[videoId];
      }
      
      if (cached == null) {
        return shelf.Response.notFound('Stream not found');
      }
      
      final rangeHeader = request.headers['range'];
      
      // Fetch from YouTube with the cached URL and User-Agent
      final response = await _dio.get<dio_lib.ResponseBody>(
        cached.url,
        options: dio_lib.Options(
          headers: {
            'User-Agent': cached.userAgent,
            'Accept': '*/*',
            'Accept-Encoding': 'identity',
            'Connection': 'keep-alive',
            if (rangeHeader != null) 'Range': rangeHeader,
          },
          responseType: dio_lib.ResponseType.stream,
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );
      
      print('StreamingServer: YouTube response: ${response.statusCode}');
      
      // If 403, clear cache and return error - let player handle retry
      // Don't recursively retry here as it can interrupt mid-stream playback
      if (response.statusCode == 403) {
        print('StreamingServer: Got 403, clearing cache for next request');
        _streamCache.remove(videoId);
        // Return 403 to signal player to refresh stream on next attempt
        // This prevents mid-stream interruption from recursive retry
        return shelf.Response(403, body: 'Stream URL expired - will refresh on next request');
      }
      
      // Forward response
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        if (values.isNotEmpty) {
          responseHeaders[name] = values.first;
        }
      });
      
      // Wrap the stream to handle errors gracefully
      final sourceStream = response.data?.stream;
      if (sourceStream == null) {
        return shelf.Response.internalServerError(body: 'No stream data');
      }
      
      // Cache audio to disk in background - for all requests (including range)
      // This ensures songs get cached even when media_kit uses range requests
      if (cached.contentLength != null && !(await _audioCache.isCached(videoId))) {
        _cacheAudioInBackground(videoId, cached.url, cached.userAgent);
      }
      
      // Create a stream that handles errors silently (client disconnect)
      final safeStream = sourceStream.handleError((error) {
        // Silently ignore "Bad file descriptor" errors - they happen when client disconnects
        if (error.toString().contains('Bad file descriptor') ||
            error.toString().contains('errno = 9') ||
            error.toString().contains('Connection reset')) {
          // Client disconnected, this is normal
          return;
        }
        print('StreamingServer: Stream error: $error');
      });
      
      return shelf.Response(
        response.statusCode ?? 200,
        body: safeStream,
        headers: responseHeaders,
      );
    } catch (e, stack) {
      // Ignore "Bad file descriptor" errors in catch block too
      final errorStr = e.toString();
      if (errorStr.contains('Bad file descriptor') ||
          errorStr.contains('errno = 9') ||
          errorStr.contains('Connection reset')) {
        return shelf.Response.ok('');
      }
      print('StreamingServer: Error: $e');
      _streamCache.remove(videoId);
      return shelf.Response.internalServerError(body: 'Failed to stream: $e');
    }
  }
  
  /// Cache audio to disk in background
  void _cacheAudioInBackground(String videoId, String url, String userAgent) {
    // Fire and forget - don't block playback
    Future(() async {
      try {
        // Check if already cached
        if (await _audioCache.isCached(videoId)) {
          return;
        }
        
        print('StreamingServer: Caching audio to disk for $videoId');
        
        final response = await _dio.get<dio_lib.ResponseBody>(
          url,
          options: dio_lib.Options(
            headers: {
              'User-Agent': userAgent,
              'Accept': '*/*',
              'Accept-Encoding': 'identity',
            },
            responseType: dio_lib.ResponseType.stream,
            validateStatus: (status) => status != null && status < 500,
            followRedirects: true,
          ),
        );
        
        if (response.statusCode == 200 && response.data?.stream != null) {
          await _audioCache.cacheFromStream(videoId, response.data!.stream);
        }
      } catch (e) {
        print('StreamingServer: Background caching failed: $e');
      }
    });
  }
  
  /// Clear cache for a video
  void clearCache(String videoId) {
    _streamCache.remove(videoId);
  }
  
  /// Clear all cache
  void clearAllCache() {
    _streamCache.clear();
  }
  
  /// Stop the server
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _port = 0;
    _streamCache.clear();
    print('StreamingServer: Stopped');
  }
}
