import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import '../../../models/spotify_models.dart';

/// Spotify track endpoint wrapper
class SpotifyTrackEndpoint {
  final Hetu _hetu;
  
  SpotifyTrackEndpoint(this._hetu);
  
  HTInstance get _hetuTrack =>
      (_hetu.fetch("metadataPlugin") as HTInstance).memberGet("track") as HTInstance;
  
  /// Get a track by ID
  Future<SpotifyTrack> getTrack(String id) async {
    final raw = await _hetuTrack.invoke(
      "getTrack",
      positionalArgs: [id],
    ) as Map;
    
    return SpotifyTrack.fromJson(raw.cast<String, dynamic>());
  }
  
  /// Save/like tracks
  Future<bool> save(List<String> trackIds) async {
    await _hetuTrack.invoke(
      "save",
      positionalArgs: [trackIds],
    );
    return true;
  }
  
  /// Unsave/unlike tracks
  Future<bool> unsave(List<String> trackIds) async {
    await _hetuTrack.invoke(
      "unsave",
      positionalArgs: [trackIds],
    );
    return true;
  }
  
  /// Get radio tracks based on a track
  Future<List<SpotifyTrack>> radio(String trackId) async {
    final raw = await _hetuTrack.invoke(
      "radio",
      positionalArgs: [trackId],
    ) as List;
    
    return raw
        .map((item) => SpotifyTrack.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }
}
