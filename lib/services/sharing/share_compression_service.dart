import 'dart:convert';
import 'dart:io';
import 'package:sangeet/services/sharing/share_data_model.dart';

/// Service for compressing and encoding share data
/// Uses GZIP compression + Base64 URL-safe encoding
class ShareCompressionService {
  static ShareCompressionService? _instance;
  static ShareCompressionService get instance => _instance ??= ShareCompressionService._();
  
  ShareCompressionService._();

  /// Compress and encode ShareData to a URL-safe string
  String compress(ShareData data) {
    final jsonString = jsonEncode(data.toJson());
    final bytes = utf8.encode(jsonString);
    final compressed = gzip.encode(bytes);
    // Use URL-safe Base64 encoding
    return base64Url.encode(compressed);
  }

  /// Decode and decompress a string back to ShareData
  ShareData decompress(String encoded) {
    final compressed = base64Url.decode(encoded);
    final bytes = gzip.decode(compressed);
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ShareData.fromJson(json);
  }

  /// Estimate the compressed size of ShareData in bytes
  int estimateSize(ShareData data) {
    return compress(data).length;
  }

  /// Calculate how many tracks can fit in a given byte limit
  /// Returns approximate number based on average track size
  int calculateTracksPerChunk(ShareData data, int maxBytes) {
    if (data.tracks.isEmpty) return 0;
    
    // Create a sample with just one track to measure overhead
    final singleTrackData = ShareData(
      version: data.version,
      type: data.type,
      name: data.name,
      description: data.description,
      tracks: [data.tracks.first],
      part: 1,
      totalParts: 1,
    );
    
    final baseSize = estimateSize(singleTrackData);
    
    // Measure size with two tracks to get per-track overhead
    if (data.tracks.length > 1) {
      final twoTrackData = ShareData(
        version: data.version,
        type: data.type,
        name: data.name,
        description: data.description,
        tracks: [data.tracks.first, data.tracks[1]],
        part: 1,
        totalParts: 1,
      );
      final twoTrackSize = estimateSize(twoTrackData);
      final perTrackSize = twoTrackSize - baseSize;
      
      if (perTrackSize > 0) {
        // Leave some margin for safety
        final availableBytes = maxBytes - baseSize - 50;
        return (availableBytes / perTrackSize).floor().clamp(1, data.tracks.length);
      }
    }
    
    // Fallback: estimate based on average
    final avgTrackSize = baseSize / 1;
    return (maxBytes / avgTrackSize).floor().clamp(1, 100);
  }

  /// Split ShareData into chunks that fit within the byte limit
  List<ShareData> splitToFitSize(ShareData data, int maxBytes) {
    final singleChunkSize = estimateSize(data);
    
    if (singleChunkSize <= maxBytes) {
      return [data];
    }
    
    // Calculate optimal tracks per chunk
    final tracksPerChunk = calculateTracksPerChunk(data, maxBytes);
    return data.splitIntoChunks(tracksPerChunk);
  }
}

/// Constants for size limits
class ShareSizeLimits {
  /// Maximum URL length for deep links (conservative estimate)
  /// Most platforms support 2000+ chars, but we use 1800 to be safe
  static const int maxDeepLinkBytes = 1800;
  
  /// Maximum data for a single QR code (using alphanumeric mode)
  /// QR Version 40 can hold ~4296 alphanumeric chars
  /// We use 3000 to ensure reliable scanning
  static const int maxQrCodeBytes = 3000;
  
  /// No limit for file sharing
  static const int maxFileBytes = -1; // unlimited
}
