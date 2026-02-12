import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/track.dart';

/// Service to track the last 50 recently played songs.
/// Stores full Track objects so they can be displayed immediately on the home page.
class RecentlyPlayedService extends ChangeNotifier {
  static final RecentlyPlayedService _instance = RecentlyPlayedService._internal();
  factory RecentlyPlayedService() => _instance;
  RecentlyPlayedService._internal();

  static RecentlyPlayedService get instance => _instance;

  static const String _storageKey = 'recently_played_tracks';
  static const int maxTracks = 50;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  List<Track> _recentTracks = [];

  bool get isInitialized => _isInitialized;
  List<Track> get recentTracks => List.unmodifiable(_recentTracks);
  int get count => _recentTracks.length;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _load();
    _isInitialized = true;
    print('RecentlyPlayedService: Initialized with ${_recentTracks.length} tracks');
  }

  /// Add a track to recently played.
  /// Moves it to the top if already present. Caps at [maxTracks].
  Future<void> addTrack(Track track) async {
    if (!_isInitialized) await init();

    // Remove if already in the list (we'll re-add at top)
    _recentTracks.removeWhere((t) => t.id == track.id);

    // Insert at the beginning (most recent first)
    _recentTracks.insert(0, track);

    // Trim to max
    if (_recentTracks.length > maxTracks) {
      _recentTracks = _recentTracks.sublist(0, maxTracks);
    }

    await _save();
    notifyListeners();
  }

  /// Remove a specific track
  Future<void> removeTrack(String trackId) async {
    _recentTracks.removeWhere((t) => t.id == trackId);
    await _save();
    notifyListeners();
  }

  /// Clear all recently played tracks
  Future<void> clear() async {
    _recentTracks.clear();
    await _save();
    notifyListeners();
    print('RecentlyPlayedService: Cleared');
  }

  // ---- Persistence ----

  Future<void> _load() async {
    try {
      final json = _prefs?.getString(_storageKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _recentTracks = decoded
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('RecentlyPlayedService: Error loading: $e');
      _recentTracks = [];
    }
  }

  Future<void> _save() async {
    try {
      final json = jsonEncode(_recentTracks.map((t) => t.toJson()).toList());
      await _prefs?.setString(_storageKey, json);
    } catch (e) {
      print('RecentlyPlayedService: Error saving: $e');
    }
  }
}

/// Riverpod provider for RecentlyPlayedService
final recentlyPlayedServiceProvider = ChangeNotifierProvider<RecentlyPlayedService>((ref) {
  final service = RecentlyPlayedService.instance;
  // Ensure initialized
  service.init();
  return service;
});
