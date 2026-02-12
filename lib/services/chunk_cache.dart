import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Chunk-based audio cache (like ExoPlayer SimpleCache)
class ChunkCache {
  static const int defaultMaxSize = 512 * 1024 * 1024;
  static const int chunkSize = 512 * 1024; // 512KB

  Directory? _cacheDir;
  int _maxSizeBytes;
  final Map<String, int> _accessTimes = {};
  final Map<String, int> _contentLengths = {};

  ChunkCache({int? maxSizeBytes})
      : _maxSizeBytes = maxSizeBytes ?? defaultMaxSize;

  Future<void> init() async {
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/audio_chunks');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    print('ChunkCache: Init at ${_cacheDir!.path}');
    await _loadExisting();
    await _evictIfNeeded();
  }

  Future<void> _loadExisting() async {
    if (_cacheDir == null) return;
    final seen = <String>{};
    try {
      await for (final e in _cacheDir!.list()) {
        if (e is File) {
          final n = e.uri.pathSegments.last;
          if (!n.endsWith('.chunk')) continue;
          final b = n.replaceAll('.chunk', '');
          final i = b.lastIndexOf('_');
          if (i < 0) continue;
          final vid = b.substring(0, i);
          if (seen.add(vid)) {
            final s = await e.stat();
            _accessTimes[vid] = s.accessed.millisecondsSinceEpoch;
          }
        }
      }
    } catch (_) {}
    print('ChunkCache: ${seen.length} cached videos');
  }

  File _file(String vid, int idx) =>
      File('${_cacheDir!.path}/${vid}_$idx.chunk');

  void setContentLength(String vid, int len) =>
      _contentLengths[vid] = len;

  int? getContentLength(String vid) => _contentLengths[vid];

  int? totalChunks(String vid) {
    final l = _contentLengths[vid];
    return l == null ? null : (l / chunkSize).ceil();
  }

  Future<bool> hasChunk(String vid, int idx) async {
    if (_cacheDir == null) return false;
    return _file(vid, idx).exists();
  }

  Future<Uint8List?> readChunk(String vid, int idx) async {
    if (_cacheDir == null) return null;
    final f = _file(vid, idx);
    if (await f.exists()) {
      _accessTimes[vid] = DateTime.now().millisecondsSinceEpoch;
      return f.readAsBytes();
    }
    return null;
  }

  Future<void> writeChunk(String vid, int idx, Uint8List data) async {
    if (_cacheDir == null) return;
    try {
      await _evictIfNeeded(extra: data.length);
      await _file(vid, idx).writeAsBytes(data, flush: true);
      _accessTimes[vid] = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      print('ChunkCache: write error chunk $idx/$vid: $e');
    }
  }

  Future<bool> isFullyCached(String vid) async {
    final t = totalChunks(vid);
    if (t == null) return false;
    for (int i = 0; i < t; i++) {
      if (!await hasChunk(vid, i)) return false;
    }
    return true;
  }

  Future<Uint8List?> readRange(String vid, int start, int end) async {
    final sc = start ~/ chunkSize;
    final ec = (end - 1) ~/ chunkSize;
    for (int i = sc; i <= ec; i++) {
      if (!await hasChunk(vid, i)) return null;
    }
    final bb = BytesBuilder(copy: false);
    for (int i = sc; i <= ec; i++) {
      final c = await readChunk(vid, i);
      if (c == null) return null;
      final cs = i * chunkSize;
      final ss = start > cs ? start - cs : 0;
      final se = end < cs + c.length ? end - cs : c.length;
      bb.add(ss > 0 || se < c.length ? c.sublist(ss, se) : c);
    }
    return bb.toBytes();
  }

  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;
    int s = 0;
    try {
      await for (final e in _cacheDir!.list()) {
        if (e is File) s += await e.length();
      }
    } catch (_) {}
    return s;
  }

  Future<void> _evictIfNeeded({int extra = 0}) async {
    if (_cacheDir == null) return;
    final cur = await getCacheSize();
    final target = _maxSizeBytes - extra;
    if (cur <= target) return;
    final sorted = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    int freed = 0;
    for (final entry in sorted) {
      if (freed >= cur - target) break;
      freed += await _deleteAll(entry.key);
    }
    print('ChunkCache: Freed ${freed ~/ 1024}KB');
  }

  Future<int> _deleteAll(String vid) async {
    if (_cacheDir == null) return 0;
    int freed = 0;
    try {
      await for (final e in _cacheDir!.list()) {
        if (e is File) {
          final n = e.uri.pathSegments.last;
          if (n.startsWith('${vid}_') && n.endsWith('.chunk')) {
            freed += await e.length();
            await e.delete();
          }
        }
      }
      _accessTimes.remove(vid);
      _contentLengths.remove(vid);
    } catch (_) {}
    return freed;
  }

  Future<void> clear() async {
    if (_cacheDir == null) return;
    try {
      await for (final e in _cacheDir!.list()) {
        if (e is File) await e.delete();
      }
      _accessTimes.clear();
      _contentLengths.clear();
    } catch (_) {}
  }

  Future<void> delete(String vid) async => _deleteAll(vid);

  void setMaxSize(int bytes) {
    _maxSizeBytes = bytes;
    _evictIfNeeded();
  }
}
