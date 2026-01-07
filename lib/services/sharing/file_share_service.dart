import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';

/// Service for exporting and importing .sangeet files
class FileShareService {
  static FileShareService? _instance;
  static FileShareService get instance => _instance ??= FileShareService._();
  
  FileShareService._();

  /// File extension for Sangeet share files
  static const String fileExtension = '.sangeet';
  
  /// MIME type for Sangeet share files
  static const String mimeType = 'application/x-sangeet';

  /// Export ShareData to a .sangeet file
  /// Returns the file path
  Future<String> exportToFile(ShareData data) async {
    final directory = await getTemporaryDirectory();
    final fileName = _generateFileName(data);
    final filePath = '${directory.path}/$fileName$fileExtension';
    
    final file = File(filePath);
    final jsonString = jsonEncode(data.toJson());
    
    // Compress with GZIP for smaller file size
    final compressed = gzip.encode(utf8.encode(jsonString));
    await file.writeAsBytes(compressed);
    
    print('FileShareService: Exported to $filePath');
    return filePath;
  }

  /// Import ShareData from a .sangeet file
  Future<ShareData?> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('FileShareService: File not found: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      
      // Try to decompress (GZIP)
      List<int> decompressed;
      try {
        decompressed = gzip.decode(bytes);
      } catch (e) {
        // File might not be compressed (legacy or manual edit)
        decompressed = bytes;
      }
      
      final jsonString = utf8.decode(decompressed);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return ShareData.fromJson(json);
    } catch (e) {
      print('FileShareService: Error importing file: $e');
      return null;
    }
  }

  /// Import ShareData from file bytes (for when file is received via share intent)
  ShareData? importFromBytes(List<int> bytes) {
    try {
      // Try to decompress (GZIP)
      List<int> decompressed;
      try {
        decompressed = gzip.decode(bytes);
      } catch (e) {
        // File might not be compressed
        decompressed = bytes;
      }
      
      final jsonString = utf8.decode(decompressed);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return ShareData.fromJson(json);
    } catch (e) {
      print('FileShareService: Error importing from bytes: $e');
      return null;
    }
  }

  /// Generate a filename based on the share data
  String _generateFileName(ShareData data) {
    String baseName;
    
    switch (data.type) {
      case ShareType.song:
        final track = data.tracks.first;
        baseName = '${track.title} - ${track.artist}';
        break;
      case ShareType.playlist:
        baseName = data.name ?? 'Playlist';
        break;
      case ShareType.album:
        baseName = data.name ?? 'Album';
        break;
    }
    
    // Sanitize filename
    return _sanitizeFileName(baseName);
  }

  /// Remove invalid characters from filename
  String _sanitizeFileName(String name) {
    // Remove or replace invalid characters
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Check if a file is a valid .sangeet file
  bool isValidSangeetFile(String filePath) {
    return filePath.toLowerCase().endsWith(fileExtension);
  }

  /// Get file info for display
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    final data = await importFromFile(filePath);
    if (data == null) return null;

    return {
      'type': data.type.name,
      'name': data.name,
      'trackCount': data.tracks.length,
      'isChunked': data.isChunked,
    };
  }
}
