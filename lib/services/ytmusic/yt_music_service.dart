import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sangeet/services/ytmusic/nav.dart';
import 'package:sangeet/services/ytmusic/playlist_utils.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/search_models.dart';

/// Music API Service - Based on BlackHole's implementation
/// Uses music service's internal API for better music search results
class YtMusicService {
  static const String _ytmDomain = 'music.youtube.com';
  static const String _httpsMusicDomain = 'https://music.youtube.com';
  static const String _baseApiEndpoint = '/youtubei/v1/';
  static Map<String, String> get _ytmParams => {
    'alt': 'json',
    'key': dotenv.env['YTM_API_KEY'] ?? '',
  };
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0';
  
  static const Map<String, String> _endpoints = {
    'search': 'search',
    'browse': 'browse',
    'get_song': 'player',
    'next': 'next',
  };

  Map<String, String>? _headers;
  int? _signatureTimestamp;
  Map<String, dynamic>? _context;
  
  // Ensure init() is only called once even with concurrent requests
  Future<void>? _initFuture;
  bool _isInitialized = false;

  static final YtMusicService _instance = YtMusicService._internal();
  factory YtMusicService() => _instance;
  YtMusicService._internal();

  Map<String, String> _initializeHeaders() {
    return {
      'user-agent': _userAgent,
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate',
      'content-type': 'application/json',
      'origin': _httpsMusicDomain,
      'cookie': 'CONSENT=YES+1',
    };
  }

  Future<String?> _getVisitorId(Map<String, String>? headers) async {
    try {
      final uri = Uri.https(_ytmDomain, '');
      final response = await http.get(uri, headers: headers);
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(response.body);
      if (matches != null) {
        final ytcfg = json.decode(matches.group(1).toString());
        return ytcfg['VISITOR_DATA']?.toString();
      }
    } catch (e) {
      print('YtMusicService: Error getting visitor ID: $e');
    }
    return null;
  }

  Map<String, dynamic> _initializeContext() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final date = year + month + day;
    return {
      'context': {
        'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.$date.01.00'},
        'user': {},
      },
    };
  }

  Future<Map> _sendRequest(
    String endpoint,
    Map body,
    Map<String, String>? headers,
  ) async {
    final uri = Uri.https(_ytmDomain, _baseApiEndpoint + endpoint, _ytmParams);
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map;
      } else {
        print('YtMusicService: Request failed with status ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('YtMusicService: Request error: $e');
      return {};
    }
  }

  String? _getParam2(String filter) {
    const filterParams = {
      'songs': 'I',
      'videos': 'Q',
      'albums': 'Y',
      'artists': 'g',
      'playlists': 'o',
    };
    return filterParams[filter];
  }

  String? _getSearchParams({String? filter, bool ignoreSpelling = false}) {
    if (!ignoreSpelling && filter == null) return null;

    String? params;
    String? param1;
    String? param2;
    String? param3;

    if (filter != null) {
      if (filter == 'playlists') {
        params = 'Eg-KAQwIABAAGAAgACgB';
        if (!ignoreSpelling) {
          params += 'MABqChAEEAMQCRAFEAo%3D';
        } else {
          params += 'MABCAggBagoQBBADEAkQBRAK';
        }
      } else {
        param1 = 'EgWKAQI';
        param2 = _getParam2(filter);
        if (!ignoreSpelling) {
          param3 = 'AWoMEA4QChADEAQQCRAF';
        } else {
          param3 = 'AUICCAFqDBAOEAoQAxAEEAkQBQ%3D%3D';
        }
      }
    }

    if (filter == null && ignoreSpelling) {
      params = 'EhGKAQ4IARABGAEgASgAOAFAAUICCAE%3D';
    }

    if (params != null) return params;
    if (param1 == null && param2 == null && param3 == null) return null;
    return '${param1 ?? ""}${param2 ?? ""}${param3 ?? ""}';
  }

  /// Initialize the service - ensures only one init happens even with concurrent calls
  Future<void> init() async {
    if (_isInitialized) return;
    
    // If init is already in progress, wait for it
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    
    // Start init and store the future so concurrent calls can wait
    _initFuture = _doInit();
    await _initFuture;
  }
  
  Future<void> _doInit() async {
    _headers = _initializeHeaders();
    if (!_headers!.containsKey('X-Goog-Visitor-Id')) {
      _headers!['X-Goog-Visitor-Id'] = await _getVisitorId(_headers) ?? '';
    }
    _context = _initializeContext();
    _context!['context']['client']['hl'] = 'en';
    _isInitialized = true;
  }

  int _getDatestamp() {
    final now = DateTime.now();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final difference = now.difference(epoch);
    return difference.inDays;
  }

  /// Search for songs on YTMusic
  Future<List<Track>> searchSongs(String query, {int limit = 20}) async {
    // Always ensure init is complete before searching
    if (!_isInitialized) await init();
    
    try {
      final body = Map<String, dynamic>.from(_context!);
      body['query'] = query;
      final params = _getSearchParams(filter: 'songs');
      if (params != null) body['params'] = params;

      final res = await _sendRequest(_endpoints['search']!, body, _headers);
      if (!res.containsKey('contents')) {
        print('YtMusicService: No contents in search response');
        return [];
      }

      final List<Track> tracks = [];
      
      Map<String, dynamic> results = {};
      if ((res['contents'] as Map).containsKey('tabbedSearchResultsRenderer')) {
        results = NavClass.nav(res, [
          'contents',
          'tabbedSearchResultsRenderer',
          'tabs',
          0,
          'tabRenderer',
          'content',
        ]) as Map<String, dynamic>;
      } else {
        results = res['contents'] as Map<String, dynamic>;
      }

      final List finalResults =
          NavClass.nav(results, ['sectionListRenderer', 'contents']) as List? ?? [];

      for (final sectionItem in finalResults) {
        final String sectionSelfRenderer =
            (sectionItem as Map).containsKey('musicCardShelfRenderer')
                ? 'musicCardShelfRenderer'
                : 'musicShelfRenderer';

        // Get section title to filter for "Songs" section only
        final String sectionTitle = NavClass.joinRunTexts(
          NavClass.nav(sectionItem, [
            sectionSelfRenderer,
            ...NavClass.titleRuns,
          ]) as List?,
        );
        
        // Only process "Songs" section, skip "Top result", "Videos", "Albums", etc.
        if (sectionTitle.isNotEmpty && 
            !sectionTitle.toLowerCase().contains('song')) {
          print('YtMusicService: Skipping section: $sectionTitle');
          continue;
        }

        final List sectionChildItems =
            NavClass.nav(sectionItem, [sectionSelfRenderer, 'contents']) as List? ?? [];

        for (final childItem in sectionChildItems) {
          final track = _parseTrackFromItem(childItem as Map, songsOnly: true);
          if (track != null) {
            tracks.add(track);
            if (tracks.length >= limit) break;
          }
        }
        if (tracks.length >= limit) break;
      }

      print('YtMusicService: Found ${tracks.length} songs for query: $query');
      return tracks;
    } catch (e) {
      print('YtMusicService: Search error: $e');
      return [];
    }
  }

  /// Search for artists on YTMusic
  Future<List<SearchArtist>> searchArtists(String query, {int limit = 20}) async {
    if (!_isInitialized) await init();
    
    try {
      final body = Map<String, dynamic>.from(_context!);
      body['query'] = query;
      final params = _getSearchParams(filter: 'artists');
      if (params != null) body['params'] = params;

      final res = await _sendRequest(_endpoints['search']!, body, _headers);
      if (!res.containsKey('contents')) {
        print('YtMusicService: No contents in artist search response');
        return [];
      }

      final List<SearchArtist> artists = [];
      
      Map<String, dynamic> results = {};
      if ((res['contents'] as Map).containsKey('tabbedSearchResultsRenderer')) {
        results = NavClass.nav(res, [
          'contents',
          'tabbedSearchResultsRenderer',
          'tabs',
          0,
          'tabRenderer',
          'content',
        ]) as Map<String, dynamic>;
      } else {
        results = res['contents'] as Map<String, dynamic>;
      }

      final List finalResults =
          NavClass.nav(results, ['sectionListRenderer', 'contents']) as List? ?? [];

      for (final sectionItem in finalResults) {
        final String sectionSelfRenderer =
            (sectionItem as Map).containsKey('musicCardShelfRenderer')
                ? 'musicCardShelfRenderer'
                : 'musicShelfRenderer';

        final List sectionChildItems =
            NavClass.nav(sectionItem, [sectionSelfRenderer, 'contents']) as List? ?? [];

        for (final childItem in sectionChildItems) {
          final artist = _parseArtistFromItem(childItem as Map);
          if (artist != null) {
            artists.add(artist);
            if (artists.length >= limit) break;
          }
        }
        if (artists.length >= limit) break;
      }

      print('YtMusicService: Found ${artists.length} artists for query: $query');
      return artists;
    } catch (e) {
      print('YtMusicService: Artist search error: $e');
      return [];
    }
  }

  /// Search for albums on YTMusic
  Future<List<SearchAlbum>> searchAlbums(String query, {int limit = 20}) async {
    if (!_isInitialized) await init();
    
    try {
      final body = Map<String, dynamic>.from(_context!);
      body['query'] = query;
      final params = _getSearchParams(filter: 'albums');
      if (params != null) body['params'] = params;

      final res = await _sendRequest(_endpoints['search']!, body, _headers);
      if (!res.containsKey('contents')) {
        print('YtMusicService: No contents in album search response');
        return [];
      }

      final List<SearchAlbum> albums = [];
      
      Map<String, dynamic> results = {};
      if ((res['contents'] as Map).containsKey('tabbedSearchResultsRenderer')) {
        results = NavClass.nav(res, [
          'contents',
          'tabbedSearchResultsRenderer',
          'tabs',
          0,
          'tabRenderer',
          'content',
        ]) as Map<String, dynamic>;
      } else {
        results = res['contents'] as Map<String, dynamic>;
      }

      final List finalResults =
          NavClass.nav(results, ['sectionListRenderer', 'contents']) as List? ?? [];

      for (final sectionItem in finalResults) {
        final String sectionSelfRenderer =
            (sectionItem as Map).containsKey('musicCardShelfRenderer')
                ? 'musicCardShelfRenderer'
                : 'musicShelfRenderer';

        final List sectionChildItems =
            NavClass.nav(sectionItem, [sectionSelfRenderer, 'contents']) as List? ?? [];

        for (final childItem in sectionChildItems) {
          final album = _parseAlbumFromItem(childItem as Map);
          if (album != null) {
            albums.add(album);
            if (albums.length >= limit) break;
          }
        }
        if (albums.length >= limit) break;
      }

      print('YtMusicService: Found ${albums.length} albums for query: $query');
      return albums;
    } catch (e) {
      print('YtMusicService: Album search error: $e');
      return [];
    }
  }

  /// Parse artist from search result item
  SearchArtist? _parseArtistFromItem(Map childItem) {
    try {
      final List images = NavClass.runUrls(
        NavClass.nav(childItem, [NavClass.mRLIR, ...NavClass.thumbnails]) as List?,
      );
      
      final String name = NavClass.joinRunTexts(
        NavClass.nav(childItem, [
          ...NavClass.mRLIRFlex,
          0,
          NavClass.mRLIFCR,
          ...NavClass.textRuns,
        ]) as List?,
      );
      
      final String subtitle = NavClass.joinRunTexts(
        NavClass.nav(childItem, [
          ...NavClass.mRLIRFlex,
          1,
          NavClass.mRLIFCR,
          ...NavClass.textRuns,
        ]) as List?,
      );

      if (name.isEmpty) return null;

      // Get browse ID for artist
      final String? browseId = NavClass.nav(childItem, [
        NavClass.mRLIR,
        'navigationEndpoint',
        'browseEndpoint',
        'browseId',
      ])?.toString();
      
      if (browseId == null) return null;

      String? thumbnailUrl;
      if (images.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(images.last.toString(), 226);
      }

      return SearchArtist(
        id: browseId,
        name: name,
        thumbnailUrl: thumbnailUrl,
        subscribersText: subtitle,
      );
    } catch (e) {
      print('YtMusicService: Error parsing artist: $e');
      return null;
    }
  }

  /// Parse album from search result item
  SearchAlbum? _parseAlbumFromItem(Map childItem) {
    try {
      final List images = NavClass.runUrls(
        NavClass.nav(childItem, [NavClass.mRLIR, ...NavClass.thumbnails]) as List?,
      );
      
      final String title = NavClass.joinRunTexts(
        NavClass.nav(childItem, [
          ...NavClass.mRLIRFlex,
          0,
          NavClass.mRLIFCR,
          ...NavClass.textRuns,
        ]) as List?,
      );
      
      final String subtitle = NavClass.joinRunTexts(
        NavClass.nav(childItem, [
          ...NavClass.mRLIRFlex,
          1,
          NavClass.mRLIFCR,
          ...NavClass.textRuns,
        ]) as List?,
      );

      if (title.isEmpty) return null;

      // Get browse ID for album
      final String? browseId = NavClass.nav(childItem, [
        NavClass.mRLIR,
        'navigationEndpoint',
        'browseEndpoint',
        'browseId',
      ])?.toString();
      
      if (browseId == null) return null;

      // Parse subtitle for type and artist (e.g., "Album • Artist • Year")
      final subtitleParts = subtitle.split('•').map((s) => s.trim()).toList();
      String? albumType;
      String? artist;
      String? year;
      
      if (subtitleParts.isNotEmpty) albumType = subtitleParts[0];
      if (subtitleParts.length > 1) artist = subtitleParts[1];
      if (subtitleParts.length > 2) year = subtitleParts[2];

      String? thumbnailUrl;
      if (images.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(images.last.toString(), 226);
      }

      return SearchAlbum(
        id: browseId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        year: year,
        albumType: albumType,
      );
    } catch (e) {
      print('YtMusicService: Error parsing album: $e');
      return null;
    }
  }

  Track? _parseTrackFromItem(Map childItem, {bool songsOnly = true}) {
    try {
      final List images = NavClass.runUrls(
        NavClass.nav(childItem, [NavClass.mRLIR, ...NavClass.thumbnails]) as List?,
      );
      
      final String title = NavClass.joinRunTexts(
        NavClass.nav(childItem, [
          ...NavClass.mRLIRFlex,
          0,
          NavClass.mRLIFCR,
          ...NavClass.textRuns,
        ]) as List?,
      );
      
      final String subtitle = NavClass.joinRunTexts(
        NavClass.nav(childItem, [
          ...NavClass.mRLIRFlex,
          1,
          NavClass.mRLIFCR,
          ...NavClass.textRuns,
        ]) as List?,
      );

      if (title.isEmpty) return null;

      // Parse subtitle to get type and other info
      final subtitleParts = subtitle.split('•');
      String type = subtitleParts.first.trim().toLowerCase();
      
      // Check if this is a valid song/video type
      // Skip playlists, albums, artists, etc.
      if (!['song', 'video'].contains(type)) {
        // If type is not recognized, it might be the artist name (for songs)
        // In that case, assume it's a song if we have a valid video ID
        if (['playlist', 'album', 'artist', 'profile', 'single'].contains(type)) {
          if (songsOnly) return null; // Skip non-song items
        }
        // If type is unrecognized, treat as song
        type = 'song';
        subtitleParts.insert(0, 'Song');
      }

      // Get video ID - for songs/videos use mrlirPlaylistId
      final String? id = NavClass.nav(childItem, NavClass.mrlirPlaylistId)?.toString();
      if (id == null) return null;

      // Parse subtitle for artist and duration based on type
      String artist = '';
      String durationStr = '';
      
      if (type == 'song') {
        // Format: Song • Artist • Album • Duration
        if (subtitleParts.length > 1) artist = subtitleParts[1].trim();
        if (subtitleParts.length > 3) durationStr = subtitleParts[3].trim();
      } else if (type == 'video') {
        // Format: Video • Artist • Views • Duration
        if (subtitleParts.length > 1) artist = subtitleParts[1].trim();
        if (subtitleParts.length > 3) durationStr = subtitleParts[3].trim();
      }

      // Parse duration string (e.g., "3:45" or "1:02:30")
      Duration duration = Duration.zero;
      if (durationStr.isNotEmpty) {
        final parts = durationStr.split(':');
        if (parts.length == 2) {
          duration = Duration(
            minutes: int.tryParse(parts[0]) ?? 0,
            seconds: int.tryParse(parts[1]) ?? 0,
          );
        } else if (parts.length == 3) {
          duration = Duration(
            hours: int.tryParse(parts[0]) ?? 0,
            minutes: int.tryParse(parts[1]) ?? 0,
            seconds: int.tryParse(parts[2]) ?? 0,
          );
        }
      }
      
      // Skip items with very long durations (likely compilations/playlists)
      // Normal songs are typically under 15 minutes
      if (duration.inMinutes > 15) {
        print('YtMusicService: Skipping long duration item: $title (${duration.inMinutes} min)');
        return null;
      }

      // Use actual thumbnail URL from API
      // Apply dynamic sizing for Google CDN thumbnails
      String? thumbnailUrl;
      if (images.isNotEmpty) {
        final rawUrl = images.last.toString();
        thumbnailUrl = _getHighQualityThumbnail(rawUrl, 1080);
      } else {
        // Fallback to video thumbnail - use maxresdefault for best quality
        thumbnailUrl = 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';
      }

      return Track(
        id: id,
        title: title,
        artist: artist.isNotEmpty ? artist : 'Unknown Artist',
        thumbnailUrl: thumbnailUrl,
        duration: duration,
      );
    } catch (e) {
      print('YtMusicService: Error parsing track: $e');
      return null;
    }
  }

  /// Get song data with stream URL
  Future<Map<String, dynamic>> getSongData(String videoId) async {
    if (!_isInitialized) await init();
    
    try {
      _signatureTimestamp ??= _getDatestamp() - 1;
      final body = Map<String, dynamic>.from(_context!);
      body['playbackContext'] = {
        'contentPlaybackContext': {'signatureTimestamp': _signatureTimestamp},
      };
      body['video_id'] = videoId;
      
      final response = await _sendRequest(_endpoints['get_song']!, body, _headers);
      final videoDetails = NavClass.nav(response, ['videoDetails']) as Map?;
      
      if (videoDetails == null) {
        print('YtMusicService: No video details found');
        return {};
      }

      return {
        'id': videoDetails['videoId'],
        'title': videoDetails['title'],
        'artist': (videoDetails['author'] as String?)?.replaceAll('- Topic', '').trim() ?? '',
        'duration': videoDetails['lengthSeconds'],
        'image': NavClass.nav(videoDetails, ['thumbnail', 'thumbnails'])?.last?['url'],
        'channelId': videoDetails['channelId'],
      };
    } catch (e) {
      print('YtMusicService: Error getting song data: $e');
      return {};
    }
  }

  /// Get watch playlist (related songs)
  Future<List<String>> getWatchPlaylist({
    String? videoId,
    String? playlistId,
    int limit = 25,
    bool radio = false,
  }) async {
    if (!_isInitialized) await init();
    
    try {
      final body = Map<String, dynamic>.from(_context!);
      body['enablePersistentPlaylistPanel'] = true;
      body['isAudioOnly'] = true;
      body['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';

      if (videoId == null && playlistId == null) return [];

      if (videoId != null) {
        body['videoId'] = videoId;
        playlistId ??= 'RDAMVM$videoId';
        if (!radio) {
          body['watchEndpointMusicSupportedConfigs'] = {
            'watchEndpointMusicConfig': {
              'hasPersistentPlaylistPanel': true,
              'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV;',
            },
          };
        }
      }

      body['playlistId'] = playlistIdTrimmer(playlistId!);
      if (radio) body['params'] = 'wAEB';

      final response = await _sendRequest(_endpoints['next']!, body, _headers);
      final results = NavClass.nav(response, [
        'contents',
        'singleColumnMusicWatchNextResultsRenderer',
        'tabbedRenderer',
        'watchNextTabbedResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'musicQueueRenderer',
        'content',
        'playlistPanelRenderer',
      ]) as Map? ?? {};

      final playlist = ((results['contents'] as List?) ?? []).where(
        (x) => NavClass.nav(x, [
          'playlistPanelVideoRenderer',
          ...NavClass.navigationPlaylistId,
        ]) != null,
      );

      int count = 0;
      final List<String> songIds = [];
      for (final item in playlist) {
        if (count > limit) break;
        if (count > 0) {
          final id = NavClass.nav(item, ['playlistPanelVideoRenderer', 'videoId'])?.toString();
          if (id != null) songIds.add(id);
        }
        count++;
      }
      return songIds;
    } catch (e) {
      print('YtMusicService: Error getting watch playlist: $e');
      return [];
    }
  }

  /// Get related tracks for a video
  Future<List<Track>> getRelatedTracks(String videoId, {int limit = 10}) async {
    final relatedIds = await getWatchPlaylist(videoId: videoId, limit: limit, radio: true);
    final List<Track> tracks = [];
    
    for (final id in relatedIds) {
      final songData = await getSongData(id);
      if (songData.isNotEmpty) {
        tracks.add(Track(
          id: songData['id'] ?? id,
          title: songData['title'] ?? 'Unknown',
          artist: songData['artist'] ?? 'Unknown Artist',
          thumbnailUrl: songData['image'] ?? '',
          duration: Duration(seconds: int.tryParse(songData['duration']?.toString() ?? '0') ?? 0),
        ));
      }
      if (tracks.length >= limit) break;
    }
    
    return tracks;
  }

  /// Get high quality thumbnail URL with dynamic sizing
  String _getHighQualityThumbnail(String url, int size) {
    // For lh3.googleusercontent.com thumbnails - add size suffix
    if (url.startsWith('https://lh3.googleusercontent.com')) {
      // Remove any existing size params and add new ones
      final baseUrl = url.split('=').first;
      return '$baseUrl=w$size-h$size';
    }
    
    // For yt3.ggpht.com thumbnails
    if (url.startsWith('https://yt3.ggpht.com')) {
      final baseUrl = url.split('=').first;
      return '$baseUrl=s$size';
    }
    
    // For i.ytimg.com thumbnails - extract video ID and use maxresdefault for best quality
    if (url.contains('i.ytimg.com')) {
      final videoIdMatch = RegExp(r'/vi/([^/]+)/').firstMatch(url);
      if (videoIdMatch != null) {
        final videoId = videoIdMatch.group(1);
        return 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
      }
    }
    
    return url;
  }
}
