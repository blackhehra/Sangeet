import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangeet/models/custom_playlist.dart';
import 'package:sangeet/models/track.dart';

/// Service for managing custom user-created playlists
class CustomPlaylistService {
  static CustomPlaylistService? _instance;
  static CustomPlaylistService get instance => _instance ??= CustomPlaylistService._();
  
  CustomPlaylistService._();

  static const String _playlistsKey = 'custom_playlists';

  SharedPreferences? _prefs;
  List<CustomPlaylist> _playlists = [];

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPlaylists();
    print('CustomPlaylistService: Initialized with ${_playlists.length} playlists');
  }

  /// Get all playlists
  List<CustomPlaylist> getPlaylists() => List.unmodifiable(_playlists);

  /// Get playlist by ID
  CustomPlaylist? getPlaylist(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create a new playlist
  Future<CustomPlaylist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final playlist = CustomPlaylist(
      id: 'custom_${now}_${name.hashCode}',
      name: name,
      description: description,
      tracks: [],
      createdAt: now,
      updatedAt: now,
    );

    _playlists.add(playlist);
    await _savePlaylists();
    print('CustomPlaylistService: Created playlist "${name}"');
    return playlist;
  }

  /// Update playlist metadata
  Future<void> updatePlaylist({
    required String id,
    String? name,
    String? description,
  }) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final playlist = _playlists[index];
    _playlists[index] = playlist.copyWith(
      name: name ?? playlist.name,
      description: description ?? playlist.description,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _savePlaylists();
    print('CustomPlaylistService: Updated playlist "$id"');
  }

  /// Delete a playlist
  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _savePlaylists();
    print('CustomPlaylistService: Deleted playlist "$id"');
  }

  /// Add track to playlist
  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return false;

    final playlist = _playlists[index];
    
    // Check if track already exists
    if (playlist.tracks.any((t) => t.id == track.id)) {
      print('CustomPlaylistService: Track already in playlist');
      return false;
    }

    final updatedTracks = [...playlist.tracks, track];
    _playlists[index] = playlist.copyWith(
      tracks: updatedTracks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _savePlaylists();
    print('CustomPlaylistService: Added track to playlist "$playlistId"');
    return true;
  }

  /// Remove track from playlist
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final updatedTracks = playlist.tracks.where((t) => t.id != trackId).toList();
    
    _playlists[index] = playlist.copyWith(
      tracks: updatedTracks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _savePlaylists();
    print('CustomPlaylistService: Removed track from playlist "$playlistId"');
  }

  /// Reorder tracks in playlist
  Future<void> reorderTracks(String playlistId, int oldIndex, int newIndex) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    final tracks = List<Track>.from(playlist.tracks);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final track = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, track);

    _playlists[index] = playlist.copyWith(
      tracks: tracks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _savePlaylists();
  }

  // Private methods

  Future<void> _loadPlaylists() async {
    final playlistsJson = _prefs?.getString(_playlistsKey);
    if (playlistsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(playlistsJson);
        _playlists = decoded
            .map((json) => CustomPlaylist.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('CustomPlaylistService: Error loading playlists: $e');
        _playlists = [];
      }
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final playlistsJson = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await _prefs?.setString(_playlistsKey, playlistsJson);
    } catch (e) {
      print('CustomPlaylistService: Error saving playlists: $e');
    }
  }
}
