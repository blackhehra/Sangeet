import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';

/// Queue History Service
/// Tracks recently played tracks from queue and allows saving queue as playlist
class QueueHistoryService {
  static final QueueHistoryService _instance = QueueHistoryService._internal();
  factory QueueHistoryService() => _instance;
  QueueHistoryService._internal();

  static const String _queueHistoryKey = 'queue_history';
  static const int _maxHistorySize = 50;

  SharedPreferences? _prefs;
  List<Track> _history = [];

  List<Track> get history => List.unmodifiable(_history);

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
    print('QueueHistoryService: Initialized with ${_history.length} items');
  }

  /// Add a track to history (called when track finishes playing)
  Future<void> addToHistory(Track track) async {
    // Remove if already exists to avoid duplicates
    _history.removeWhere((t) => t.id == track.id);
    
    // Add to front
    _history.insert(0, track);
    
    // Trim if too large
    if (_history.length > _maxHistorySize) {
      _history = _history.sublist(0, _maxHistorySize);
    }
    
    await _saveHistory();
  }

  /// Get recent tracks from queue history
  List<Track> getRecentTracks({int limit = 20}) {
    return _history.take(limit).toList();
  }

  /// Clear history
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  /// Check if a track is in recent history
  bool isInHistory(String trackId) {
    return _history.any((t) => t.id == trackId);
  }

  Future<void> _loadHistory() async {
    final historyJson = _prefs?.getString(_queueHistoryKey);
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _history = decoded
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveHistory() async {
    final historyJson = jsonEncode(_history.map((t) => t.toJson()).toList());
    await _prefs?.setString(_queueHistoryKey, historyJson);
  }
}
