import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hetu_otp_util/hetu_otp_util.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_spotube_plugin/hetu_spotube_plugin.dart' as spotube_plugin;
import 'package:hetu_spotube_plugin/hetu_spotube_plugin.dart' hide YouTubeEngine;
import 'package:hetu_std/hetu_std.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'local_storage_impl.dart';
import '../../models/spotify_models.dart';
import 'endpoints/auth_endpoint.dart';
import 'endpoints/user_endpoint.dart';
import 'endpoints/playlist_endpoint.dart';
import 'endpoints/search_endpoint.dart';
import 'endpoints/track_endpoint.dart';
import 'endpoints/album_endpoint.dart';
import 'endpoints/artist_endpoint.dart';
import 'endpoints/browse_endpoint.dart';

/// Global navigator key for plugin webview navigation
final GlobalKey<NavigatorState> pluginNavigatorKey = GlobalKey<NavigatorState>();

/// Main Spotify Plugin service
/// This integrates the Hetu-based Spotify plugin into our app
class SpotifyPluginService {
  static SpotifyPluginService? _instance;
  
  final Hetu _hetu;
  final PluginConfig config;
  
  // Endpoints
  late final SpotifyAuthEndpoint auth;
  late final SpotifyUserEndpoint user;
  late final SpotifyPlaylistEndpoint playlist;
  late final SpotifySearchEndpoint search;
  late final SpotifyTrackEndpoint track;
  late final SpotifyAlbumEndpoint album;
  late final SpotifyArtistEndpoint artist;
  late final SpotifyBrowseEndpoint browse;
  
  SpotifyPluginService._(this._hetu, this.config) {
    auth = SpotifyAuthEndpoint(_hetu);
    user = SpotifyUserEndpoint(_hetu);
    playlist = SpotifyPlaylistEndpoint(_hetu);
    search = SpotifySearchEndpoint(_hetu);
    track = SpotifyTrackEndpoint(_hetu);
    album = SpotifyAlbumEndpoint(_hetu);
    artist = SpotifyArtistEndpoint(_hetu);
    browse = SpotifyBrowseEndpoint(_hetu);
  }
  
  /// Get the singleton instance
  static SpotifyPluginService? get instance => _instance;
  
  /// Check if the plugin is initialized
  static bool get isInitialized => _instance != null;
  
  /// Initialize the Spotify plugin
  /// This should be called once during app startup
  static Future<SpotifyPluginService> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_instance != null) {
      print('SpotifyPlugin: Already initialized');
      return _instance!;
    }
    
    print('SpotifyPlugin: Initializing...');
    
    final sharedPreferences = await SharedPreferences.getInstance();
    final youtubeExplode = YoutubeExplode();
    
    // Load plugin configuration
    final configJson = await rootBundle.loadString('assets/plugins/spotify/plugin.json');
    final config = PluginConfig.fromJson(json.decode(configJson));
    
    print('SpotifyPlugin: Loading plugin "${config.name}" v${config.version}');
    
    // Initialize Hetu interpreter
    final hetu = Hetu();
    hetu.init();
    
    // Load standard library bindings
    HetuStdLoader.loadBindings(hetu);
    
    // Load plugin bindings
    HetuSpotubePluginLoader.loadBindings(
      hetu,
      localStorageImpl: SharedPreferencesLocalStorage(
        sharedPreferences,
        config.slug,
      ),
      onNavigatorPush: (route) {
        return navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Spotify Login'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: route,
            ),
          ),
        );
      },
      onNavigatorPop: () {
        navigatorKey.currentState?.pop();
      },
      onShowForm: (title, fields) async {
        // For now, return empty - can implement form dialogs later if needed
        print('SpotifyPlugin: Form requested: $title');
        return [];
      },
      createYoutubeEngine: () {
        return spotube_plugin.YouTubeEngine(
          search: (query) async {
            final searchList = await youtubeExplode.search.search(query);
            return searchList
                .where((result) => result is Video)
                .cast<Video>()
                .map((video) => {
                      'id': video.id.value,
                      'title': video.title,
                      'author': video.author,
                      'duration': video.duration?.inSeconds,
                      'description': video.description,
                      'uploadDate': video.uploadDate?.toIso8601String(),
                      'viewCount': video.engagement.viewCount,
                      'likeCount': video.engagement.likeCount,
                      'isLive': false,
                    })
                .toList();
          },
          getVideo: (videoId) async {
            final video = await youtubeExplode.videos.get(videoId);
            return {
              'id': video.id.value,
              'title': video.title,
              'author': video.author,
              'duration': video.duration?.inSeconds,
              'description': video.description,
              'uploadDate': video.uploadDate?.toIso8601String(),
              'viewCount': video.engagement.viewCount,
              'likeCount': video.engagement.likeCount,
              'isLive': video.isLive,
            };
          },
          streamManifest: (videoId) async {
            final manifest = await youtubeExplode.videos.streamsClient.getManifest(videoId);
            return manifest.audioOnly
                .map((stream) => {
                      'url': stream.url.toString(),
                      'quality': stream.qualityLabel,
                      'bitrate': stream.bitrate.bitsPerSecond,
                      'container': stream.container.name,
                      'videoId': videoId,
                    })
                .toList();
          },
        );
      },
    );
    
    // Load bytecode files
    print('SpotifyPlugin: Loading bytecode...');
    await HetuStdLoader.loadBytecodeFlutter(hetu);
    await HetuOtpUtilLoader.loadBytecodeFlutter(hetu);
    await HetuSpotubePluginLoader.loadBytecodeFlutter(hetu);
    
    // Load the Spotify plugin bytecode
    final pluginByteCode = await rootBundle.load('assets/plugins/spotify/plugin.out');
    hetu.loadBytecode(
      bytes: pluginByteCode.buffer.asUint8List(),
      moduleName: 'plugin',
    );
    
    // Initialize the plugin
    hetu.eval('''
      import "module:plugin" as plugin
      
      var Plugin = plugin.${config.entryPoint}
      
      var metadataPlugin = Plugin()
    ''');
    
    print('SpotifyPlugin: Plugin initialized successfully');
    
    _instance = SpotifyPluginService._(hetu, config);
    return _instance!;
  }
  
  /// Dispose the plugin
  static void dispose() {
    _instance = null;
  }
}
