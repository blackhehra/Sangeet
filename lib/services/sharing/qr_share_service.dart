import 'package:sangeet/services/sharing/share_data_model.dart';
import 'package:sangeet/services/sharing/share_compression_service.dart';

/// Service for generating and parsing QR codes for sharing
/// Supports multi-QR for large playlists
class QrShareService {
  static QrShareService? _instance;
  static QrShareService get instance => _instance ??= QrShareService._();
  
  QrShareService._();

  final _compression = ShareCompressionService.instance;

  /// Generate QR code data string(s) for the given ShareData
  /// Returns a single string if data fits, or multiple strings for chunked QR codes
  List<String> generateQrData(ShareData data) {
    final chunks = _compression.splitToFitSize(
      data,
      ShareSizeLimits.maxQrCodeBytes,
    );

    return chunks.map((chunk) => _compression.compress(chunk)).toList();
  }

  /// Parse QR code data and extract ShareData
  /// Returns null if the data is invalid
  ShareData? parseQrData(String qrData) {
    try {
      return _compression.decompress(qrData);
    } catch (e) {
      print('QrShareService: Error parsing QR data: $e');
      return null;
    }
  }

  /// Check if the scanned data is part of a multi-QR share
  bool isChunkedQr(String qrData) {
    final data = parseQrData(qrData);
    return data?.isChunked ?? false;
  }

  /// Get chunk info from QR data
  /// Returns (currentPart, totalParts, shareId) or null if invalid
  ({int part, int total, String? shareId})? getChunkInfo(String qrData) {
    final data = parseQrData(qrData);
    if (data == null) return null;
    
    return (
      part: data.part,
      total: data.totalParts,
      shareId: data.shareId,
    );
  }

  /// Calculate how many QR codes are needed for the given data
  int calculateQrCount(ShareData data) {
    return generateQrData(data).length;
  }

  /// Get instructions for multi-QR scanning
  String getMultiQrInstructions(int currentPart, int totalParts) {
    if (totalParts == 1) {
      return 'Scan the QR code to import';
    }
    
    if (currentPart < totalParts) {
      return 'Scanned $currentPart of $totalParts QR codes. Scan the next one.';
    }
    
    return 'All $totalParts QR codes scanned! Importing...';
  }
}

/// Helper class to manage multi-QR scanning session
class MultiQrScanSession {
  final Map<int, ShareData> _scannedChunks = {};
  int? _totalParts;
  String? _shareId;
  ShareType? _type;
  String? _name;

  /// Add a scanned chunk to the session
  /// Returns true if this was a new chunk, false if duplicate
  bool addChunk(ShareData chunk) {
    // First chunk - initialize session
    if (_totalParts == null) {
      _totalParts = chunk.totalParts;
      _shareId = chunk.shareId;
      _type = chunk.type;
      _name = chunk.name;
    } else {
      // Verify chunk belongs to this session
      if (chunk.shareId != _shareId) {
        print('MultiQrScanSession: Chunk has different shareId');
        return false;
      }
      if (chunk.totalParts != _totalParts) {
        print('MultiQrScanSession: Chunk has different totalParts');
        return false;
      }
    }

    // Check for duplicate
    if (_scannedChunks.containsKey(chunk.part)) {
      return false;
    }

    _scannedChunks[chunk.part] = chunk;
    return true;
  }

  /// Check if all chunks have been scanned
  bool get isComplete => _totalParts != null && _scannedChunks.length == _totalParts;

  /// Get the number of scanned chunks
  int get scannedCount => _scannedChunks.length;

  /// Get the total number of chunks expected
  int get totalCount => _totalParts ?? 1;

  /// Get the share type
  ShareType? get type => _type;

  /// Get the share name
  String? get name => _name;

  /// Get list of missing part numbers
  List<int> get missingParts {
    if (_totalParts == null) return [];
    
    final missing = <int>[];
    for (int i = 1; i <= _totalParts!; i++) {
      if (!_scannedChunks.containsKey(i)) {
        missing.add(i);
      }
    }
    return missing;
  }

  /// Combine all chunks into final ShareData
  /// Returns null if not all chunks are scanned
  ShareData? combine() {
    if (!isComplete) return null;
    
    final chunks = _scannedChunks.values.toList();
    return ShareData.combineChunks(chunks);
  }

  /// Reset the session
  void reset() {
    _scannedChunks.clear();
    _totalParts = null;
    _shareId = null;
    _type = null;
    _name = null;
  }
}
