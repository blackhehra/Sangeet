import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/models/custom_playlist.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/custom_playlist_service.dart';

/// Provider for custom playlist service
final customPlaylistServiceProvider = Provider<CustomPlaylistService>((ref) {
  return CustomPlaylistService.instance;
});

/// State notifier for custom playlists
class CustomPlaylistsNotifier extends StateNotifier<List<CustomPlaylist>> {
  final CustomPlaylistService _service;

  CustomPlaylistsNotifier(this._service) : super([]) {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    state = _service.getPlaylists();
  }

  Future<CustomPlaylist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final playlist = await _service.createPlaylist(
      name: name,
      description: description,
    );
    state = _service.getPlaylists();
    return playlist;
  }

  Future<void> updatePlaylist({
    required String id,
    String? name,
    String? description,
  }) async {
    await _service.updatePlaylist(
      id: id,
      name: name,
      description: description,
    );
    state = _service.getPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _service.deletePlaylist(id);
    state = _service.getPlaylists();
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final result = await _service.addTrackToPlaylist(playlistId, track);
    state = _service.getPlaylists();
    return result;
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    await _service.removeTrackFromPlaylist(playlistId, trackId);
    state = _service.getPlaylists();
  }

  Future<void> reorderTracks(String playlistId, int oldIndex, int newIndex) async {
    await _service.reorderTracks(playlistId, oldIndex, newIndex);
    state = _service.getPlaylists();
  }

  void refresh() {
    state = _service.getPlaylists();
  }
}

/// Provider for custom playlists list
final customPlaylistsProvider = StateNotifierProvider<CustomPlaylistsNotifier, List<CustomPlaylist>>((ref) {
  final service = ref.watch(customPlaylistServiceProvider);
  return CustomPlaylistsNotifier(service);
});

/// Provider for a specific playlist by ID
final customPlaylistByIdProvider = Provider.family<CustomPlaylist?, String>((ref, id) {
  final playlists = ref.watch(customPlaylistsProvider);
  try {
    return playlists.firstWhere((p) => p.id == id);
  } catch (e) {
    return null;
  }
});
