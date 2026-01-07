import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sangeet/models/track.dart';
import 'package:sangeet/models/related_page.dart';

/// Innertube API service - Direct Music API
/// This provides better audio quality and faster loading than youtube_explode
class InnertubeService {
  static final InnertubeService _instance = InnertubeService._internal();
  factory InnertubeService() => _instance;
  InnertubeService._internal();

  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _playerUrl = 'https://youtubei.googleapis.com/youtubei/v1/player';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  // Client contexts for API requests
  static const Map<String, dynamic> _webContext = {
    'client': {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20250310.01.00',
      'platform': 'DESKTOP',
      'hl': 'en',
      'gl': 'US',
    }
  };

  static const Map<String, dynamic> _androidContext = {
    'client': {
      'clientName': 'ANDROID',
      'clientVersion': '20.10.38',
      'platform': 'MOBILE',
      'androidSdkVersion': 30,
      'hl': 'en',
      'gl': 'US',
    }
  };

  static const Map<String, dynamic> _iosContext = {
    'client': {
      'clientName': 'IOS',
      'clientVersion': '20.10.4',
      'deviceMake': 'Apple',
      'deviceModel': 'iPhone16,2',
      'hl': 'en',
      'gl': 'US',
    }
  };

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:141.0) Gecko/20100101 Firefox/141.0',
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/',
    'X-Goog-Api-Key': _apiKey,
  };

  /// Get player response with highest quality audio stream
  /// Tries multiple clients for reliability
  Future<PlayerResponse?> getPlayer(String videoId) async {
    final contexts = [_webContext, _androidContext, _iosContext];
    
    for (final context in contexts) {
      try {
        final response = await _getPlayerWithContext(videoId, context);
        if (response != null && response.isPlayable) {
          print('InnertubeService: Got playable response with ${context['client']['clientName']}');
          return response;
        }
      } catch (e) {
        print('InnertubeService: ${context['client']['clientName']} failed: $e');
        continue;
      }
    }
    
    print('InnertubeService: All clients failed for $videoId');
    return null;
  }

  Future<PlayerResponse?> _getPlayerWithContext(String videoId, Map<String, dynamic> context) async {
    final body = {
      'context': context,
      'videoId': videoId,
      'contentCheckOk': 'true',
      'racyCheckOk': 'true',
    };

    final response = await http.post(
      Uri.parse('$_playerUrl?key=$_apiKey'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PlayerResponse.fromJson(json);
  }

  /// Search for songs
  Future<List<Track>> search(String query, {int limit = 20}) async {
    try {
      final body = {
        'context': _webContext,
        'query': query,
        'params': 'EgWKAQIIAWoOEAMQBBAJEAoQBRAQEBU%3D', // Song filter
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/search?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('InnertubeService: Search failed with ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseSearchResults(json, limit);
    } catch (e) {
      print('InnertubeService: Search error: $e');
      return [];
    }
  }

  /// Get next/related songs for radio
  /// Uses RDAMVM playlist format to get a full radio queue of similar songs
  Future<List<Track>> getNextSongs(String videoId, {String? playlistId}) async {
    try {
      // Use radio playlist ID format (RDAMVM + videoId) to get more related songs
      // This is the same approach used by YouTube Music for "Start Radio" feature
      final radioPlaylistId = playlistId ?? 'RDAMVM$videoId';
      
      final body = {
        'context': _webContext,
        'videoId': videoId,
        'playlistId': radioPlaylistId,
        'params': 'wAEB', // Radio mode parameter - crucial for getting full radio queue
        'isAudioOnly': true,
        'enablePersistentPlaylistPanel': true,
        'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
      };

      print('InnertubeService: Fetching radio for $videoId with playlist $radioPlaylistId');

      final response = await http.post(
        Uri.parse('$_baseUrl/next?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('InnertubeService: Next failed with ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseNextResults(json);
    } catch (e) {
      print('InnertubeService: Next error: $e');
      return [];
    }
  }

  /// Get album page by browse ID
  Future<AlbumPage?> getAlbumPage(String browseId) async {
    try {
      final body = {
        'context': _webContext,
        'browseId': browseId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/browse?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('InnertubeService: Album browse failed with ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseAlbumPage(json);
    } catch (e) {
      print('InnertubeService: Album page error: $e');
      return null;
    }
  }

  /// Get album tracks by browse ID (wrapper for backward compatibility)
  Future<List<Track>> getAlbumTracks(String browseId) async {
    final albumPage = await getAlbumPage(browseId);
    return albumPage?.songs ?? [];
  }

  /// Get artist page by browse ID
  Future<ArtistPage?> getArtistPage(String browseId) async {
    try {
      final body = {
        'context': _webContext,
        'browseId': browseId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/browse?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('InnertubeService: Artist browse failed with ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseArtistPage(json);
    } catch (e) {
      print('InnertubeService: Artist page error: $e');
      return null;
    }
  }

  /// Get artist songs by browse ID (wrapper for backward compatibility)
  Future<List<Track>> getArtistSongs(String browseId) async {
    final artistPage = await getArtistPage(browseId);
    return artistPage?.songs ?? [];
  }

  /// Get discover/explore page (trending, new releases)
  Future<DiscoverPage?> getDiscoverPage() async {
    try {
      final body = {
        'context': _webContext,
        'browseId': 'FEmusic_explore',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/browse?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('InnertubeService: Discover failed with ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseDiscoverPage(json);
    } catch (e) {
      print('InnertubeService: Discover error: $e');
      return null;
    }
  }

  /// Get related songs for a video
  Future<List<Track>> getRelatedSongs(String videoId) async {
    try {
      final relatedPage = await getRelatedPage(videoId);
      return relatedPage?.songs ?? [];
    } catch (e) {
      print('InnertubeService: Related error: $e');
      return [];
    }
  }

  /// Get full related page with songs, albums, artists, playlists
  Future<RelatedPage?> getRelatedPage(String videoId) async {
    try {
      // First get the browse ID for related tab
      final nextBody = {
        'context': _webContext,
        'videoId': videoId,
        'isAudioOnly': true,
      };

      final nextResponse = await http.post(
        Uri.parse('$_baseUrl/next?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(nextBody),
      );

      if (nextResponse.statusCode != 200) return null;

      final nextJson = jsonDecode(nextResponse.body) as Map<String, dynamic>;
      final browseId = _extractRelatedBrowseId(nextJson);
      
      if (browseId == null) return null;

      // Then browse the related page
      final browseBody = {
        'context': _webContext,
        'browseId': browseId,
      };

      final browseResponse = await http.post(
        Uri.parse('$_baseUrl/browse?key=$_apiKey'),
        headers: _headers,
        body: jsonEncode(browseBody),
      );

      if (browseResponse.statusCode != 200) return null;

      final browseJson = jsonDecode(browseResponse.body) as Map<String, dynamic>;
      return _parseFullRelatedPage(browseJson);
    } catch (e) {
      print('InnertubeService: RelatedPage error: $e');
      return null;
    }
  }

  // Parse search results
  List<Track> _parseSearchResults(Map<String, dynamic> json, int limit) {
    final tracks = <Track>[];
    
    try {
      final contents = json['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      
      if (contents == null) return tracks;

      for (final section in contents) {
        final musicShelf = section['musicShelfRenderer'];
        if (musicShelf == null) continue;

        final items = musicShelf['contents'] as List?;
        if (items == null) continue;

        for (final item in items) {
          if (tracks.length >= limit) break;
          
          final track = _parseMusicResponsiveListItem(item['musicResponsiveListItemRenderer']);
          if (track != null) {
            tracks.add(track);
          }
        }
      }
    } catch (e) {
      print('InnertubeService: Parse search error: $e');
    }

    return tracks;
  }

  // Parse next/radio results
  List<Track> _parseNextResults(Map<String, dynamic> json) {
    final tracks = <Track>[];
    
    try {
      final contents = json['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['musicQueueRenderer']?['content']
          ?['playlistPanelRenderer']?['contents'];
      
      if (contents == null) {
        print('InnertubeService: No contents found in next response');
        return tracks;
      }
      
      print('InnertubeService: Found ${(contents as List).length} items in next response');

      // Skip the first item as it's usually the currently playing song
      bool isFirst = true;
      for (final item in contents) {
        final renderer = item['playlistPanelVideoRenderer'];
        if (renderer == null) continue;

        final track = _parsePlaylistPanelVideo(renderer);
        if (track != null) {
          // Skip the first track (currently playing song)
          if (isFirst) {
            print('InnertubeService: Skipping first track (current): ${track.title}');
            isFirst = false;
            continue;
          }
          tracks.add(track);
        }
      }
      
      print('InnertubeService: Parsed ${tracks.length} related tracks');
    } catch (e) {
      print('InnertubeService: Parse next error: $e');
    }

    return tracks;
  }

  // Parse discover page
  DiscoverPage? _parseDiscoverPage(Map<String, dynamic> json) {
    try {
      final sections = json['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      
      if (sections == null) return null;

      final trending = <Track>[];
      final newReleases = <Track>[];

      for (final section in sections) {
        final carousel = section['musicCarouselShelfRenderer'];
        if (carousel == null) continue;

        final header = carousel['header']?['musicCarouselShelfBasicHeaderRenderer'];
        final browseId = header?['moreContentButton']?['buttonRenderer']
            ?['navigationEndpoint']?['browseEndpoint']?['browseId'];

        final contents = carousel['contents'] as List?;
        if (contents == null) continue;

        // Check if this is trending or new releases
        if (browseId == 'FEmusic_new_releases_albums') {
          // New releases - parse albums
          for (final item in contents) {
            final track = _parseMusicTwoRowItem(item['musicTwoRowItemRenderer']);
            if (track != null) newReleases.add(track);
          }
        } else {
          // Could be trending - parse songs
          for (final item in contents) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer != null) {
              final track = _parseMusicResponsiveListItem(renderer);
              if (track != null) trending.add(track);
            }
            final twoRow = item['musicTwoRowItemRenderer'];
            if (twoRow != null) {
              final track = _parseMusicTwoRowItem(twoRow);
              if (track != null) trending.add(track);
            }
          }
        }
      }

      return DiscoverPage(trending: trending, newReleases: newReleases);
    } catch (e) {
      print('InnertubeService: Parse discover error: $e');
      return null;
    }
  }

  String? _extractRelatedBrowseId(Map<String, dynamic> json) {
    try {
      final tabs = json['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
      
      if (tabs == null || tabs.length < 3) return null;
      
      return tabs[2]?['tabRenderer']?['endpoint']?['browseEndpoint']?['browseId'];
    } catch (e) {
      return null;
    }
  }

  List<Track> _parseRelatedResults(Map<String, dynamic> json) {
    final tracks = <Track>[];
    
    try {
      final contents = json['contents']?['sectionListRenderer']?['contents'];
      if (contents == null) return tracks;

      for (final section in contents) {
        final carousel = section['musicCarouselShelfRenderer'];
        if (carousel == null) continue;

        final items = carousel['contents'] as List?;
        if (items == null) continue;

        for (final item in items) {
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer != null) {
            final track = _parseMusicResponsiveListItem(renderer);
            if (track != null) tracks.add(track);
          }
        }
      }
    } catch (e) {
      print('InnertubeService: Parse related error: $e');
    }

    return tracks;
  }

  /// Parse full related page with all sections
  RelatedPage? _parseFullRelatedPage(Map<String, dynamic> json) {
    try {
      final contents = json['contents']?['sectionListRenderer']?['contents'];
      if (contents == null) return null;

      final songs = <Track>[];
      final albums = <RelatedAlbum>[];
      final artists = <RelatedArtist>[];
      final playlists = <RelatedPlaylist>[];

      for (final section in contents) {
        final carousel = section['musicCarouselShelfRenderer'];
        if (carousel == null) continue;

        // Get section title to determine content type
        final headerTitle = (carousel['header']?['musicCarouselShelfBasicHeaderRenderer']
            ?['title']?['runs']?[0]?['text'] as String?)?.toLowerCase() ?? '';
        final strapline = (carousel['header']?['musicCarouselShelfBasicHeaderRenderer']
            ?['strapline']?['runs']?[0]?['text'] as String?)?.toLowerCase() ?? '';

        final items = carousel['contents'] as List?;
        if (items == null) continue;

        // Parse based on section title
        // More flexible matching for different languages/variations
        if (headerTitle.contains('You might also like') || 
            headerTitle.contains('similar songs') ||
            headerTitle.contains('recommended songs')) {
          // Songs section - try both renderer types
          for (final item in items) {
            Track? track;
            final responsiveRenderer = item['musicResponsiveListItemRenderer'];
            if (responsiveRenderer != null) {
              track = _parseMusicResponsiveListItem(responsiveRenderer);
            }
            // Also try musicTwoRowItemRenderer for songs
            final twoRowRenderer = item['musicTwoRowItemRenderer'];
            if (track == null && twoRowRenderer != null) {
              track = _parseMusicTwoRowItem(twoRowRenderer);
            }
            if (track != null) songs.add(track);
          }
        } else if (headerTitle.contains('playlist') || 
                   headerTitle.contains('recommended')) {
          // Playlists section
          for (final item in items) {
            final renderer = item['musicTwoRowItemRenderer'];
            if (renderer != null) {
              final playlist = _parsePlaylistItem(renderer);
              if (playlist != null) playlists.add(playlist);
            }
          }
        } else if (headerTitle.contains('artist') || 
                   headerTitle.contains('similar') ||
                   headerTitle.contains('fans also like')) {
          // Artists section
          for (final item in items) {
            final renderer = item['musicTwoRowItemRenderer'];
            if (renderer != null) {
              final artist = _parseArtistItem(renderer);
              if (artist != null) artists.add(artist);
            }
          }
        } else if (strapline.contains('more from') || 
                   headerTitle.contains('album') ||
                   headerTitle.contains('from the artist')) {
          // Albums section (MORE FROM [Artist])
          for (final item in items) {
            final renderer = item['musicTwoRowItemRenderer'];
            if (renderer != null) {
              final album = _parseAlbumItem(renderer);
              if (album != null) albums.add(album);
            }
          }
        } else {
          // Unknown section - try to parse as songs first, then albums
          for (final item in items) {
            final responsiveRenderer = item['musicResponsiveListItemRenderer'];
            if (responsiveRenderer != null) {
              final track = _parseMusicResponsiveListItem(responsiveRenderer);
              if (track != null) songs.add(track);
              continue;
            }
            final twoRowRenderer = item['musicTwoRowItemRenderer'];
            if (twoRowRenderer != null) {
              // Check if it's an artist (has subscribers text) or album
              final subtitleRuns = twoRowRenderer['subtitle']?['runs'] as List?;
              final subtitle = subtitleRuns?.map((r) => r['text']).join('') ?? '';
              if (subtitle.toLowerCase().contains('subscriber')) {
                final artist = _parseArtistItem(twoRowRenderer);
                if (artist != null) artists.add(artist);
              } else if (subtitle.toLowerCase().contains('album') || 
                         subtitle.toLowerCase().contains('single') ||
                         subtitle.toLowerCase().contains('ep')) {
                final album = _parseAlbumItem(twoRowRenderer);
                if (album != null) albums.add(album);
              } else {
                final track = _parseMusicTwoRowItem(twoRowRenderer);
                if (track != null) songs.add(track);
              }
            }
          }
        }
      }
      
      print('InnertubeService: RelatedPage parsed - songs: ${songs.length}, albums: ${albums.length}, artists: ${artists.length}, playlists: ${playlists.length}');

      return RelatedPage(
        songs: songs.isNotEmpty ? songs : null,
        albums: albums.isNotEmpty ? albums : null,
        artists: artists.isNotEmpty ? artists : null,
        playlists: playlists.isNotEmpty ? playlists : null,
      );
    } catch (e) {
      print('InnertubeService: Parse full related page error: $e');
      return null;
    }
  }

  /// Parse playlist item from musicTwoRowItemRenderer
  RelatedPlaylist? _parsePlaylistItem(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;

    try {
      final browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
      if (browseId == null) return null;

      final titleRuns = renderer['title']?['runs'] as List?;
      final title = titleRuns?.map((r) => r['text']).join('') ?? '';

      final subtitleRuns = renderer['subtitle']?['runs'] as List?;
      final channelName = subtitleRuns?.map((r) => r['text']).join('') ?? '';

      final thumbnails = renderer['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 226);
      }

      return RelatedPlaylist(
        id: browseId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        channelName: channelName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse artist item from musicTwoRowItemRenderer
  RelatedArtist? _parseArtistItem(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;

    try {
      final browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
      if (browseId == null) return null;

      final titleRuns = renderer['title']?['runs'] as List?;
      final name = titleRuns?.map((r) => r['text']).join('') ?? '';

      final subtitleRuns = renderer['subtitle']?['runs'] as List?;
      final subscribersText = subtitleRuns?.map((r) => r['text']).join('') ?? '';

      final thumbnails = renderer['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 226);
      }

      return RelatedArtist(
        id: browseId,
        name: name,
        thumbnailUrl: thumbnailUrl,
        subscribersText: subscribersText,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse album item from musicTwoRowItemRenderer
  RelatedAlbum? _parseAlbumItem(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;

    try {
      final browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
      if (browseId == null) return null;

      final titleRuns = renderer['title']?['runs'] as List?;
      final title = titleRuns?.map((r) => r['text']).join('') ?? '';

      final subtitleRuns = renderer['subtitle']?['runs'] as List?;
      String? artist;
      String? year;
      if (subtitleRuns != null) {
        final subtitleText = subtitleRuns.map((r) => r['text']).join('');
        // Parse "Artist • Year" format
        final parts = subtitleText.split(' • ');
        if (parts.isNotEmpty) artist = parts[0];
        if (parts.length > 1) year = parts.last;
      }

      final thumbnails = renderer['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 226);
      }

      return RelatedAlbum(
        id: browseId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        year: year,
      );
    } catch (e) {
      return null;
    }
  }

  // Parse individual item renderers
  Track? _parseMusicResponsiveListItem(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;

    try {
      final flexColumns = renderer['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;

      // Get video ID from navigation endpoint
      final navigationEndpoint = renderer['navigationEndpoint'] ??
          flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']
              ?['text']?['runs']?[0]?['navigationEndpoint'];
      
      final videoId = navigationEndpoint?['watchEndpoint']?['videoId'];
      if (videoId == null) return null;

      // Get title
      final titleRuns = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs'] as List?;
      final title = titleRuns?.map((r) => r['text']).join('') ?? '';

      // Get artist and possibly duration from second column
      String artist = '';
      Duration duration = Duration.zero;
      if (flexColumns.length > 1) {
        final artistRuns = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']
            ?['text']?['runs'] as List?;
        if (artistRuns != null) {
          // Parse each run individually - duration is often in a separate run
          final textParts = <String>[];
          for (final run in artistRuns) {
            final text = run['text'] as String?;
            if (text != null && text.trim().isNotEmpty && text.trim() != '•') {
              // Check if this run is a duration
              final trimmed = text.trim();
              if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(trimmed)) {
                duration = _parseDuration(trimmed);
              } else {
                textParts.add(trimmed);
              }
            }
          }
          artist = textParts.isNotEmpty ? textParts.first : '';
        }
      }

      // Get thumbnail with dynamic sizing
      final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 480);
      }

      // Get duration from fixedColumns (primary source - overrides subtitle duration)
      final fixedColumns = renderer['fixedColumns'] as List?;
      if (fixedColumns != null && fixedColumns.isNotEmpty) {
        final durationText = fixedColumns[0]?['musicResponsiveListItemFixedColumnRenderer']
            ?['text']?['runs']?[0]?['text'] as String?;
        if (durationText != null && durationText.isNotEmpty) {
          final parsed = _parseDuration(durationText);
          if (parsed != Duration.zero) {
            duration = parsed;
          }
        }
      }

      // Try overlay for duration (some renderers have it there)
      if (duration == Duration.zero) {
        final overlayDuration = renderer['overlay']?['musicItemThumbnailOverlayRenderer']
            ?['content']?['musicPlayButtonRenderer']?['accessibilityPlayData']
            ?['accessibilityData']?['label'] as String?;
        if (overlayDuration != null) {
          // Extract duration from accessibility label like "Play Song Name 3 minutes 45 seconds"
          final match = RegExp(r'(\d+)\s*minutes?\s*(\d+)?\s*seconds?').firstMatch(overlayDuration);
          if (match != null) {
            final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
            final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
            duration = Duration(minutes: minutes, seconds: seconds);
          }
        }
      }

      // Try playlistItemData for duration
      if (duration == Duration.zero) {
        final lengthSeconds = renderer['playlistItemData']?['videoId'] != null
            ? renderer['lengthSeconds'] as int?
            : null;
        if (lengthSeconds != null) {
          duration = Duration(seconds: lengthSeconds);
        }
      }

      return Track(
        id: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
      );
    } catch (e) {
      return null;
    }
  }

  Track? _parsePlaylistPanelVideo(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;

    try {
      final videoId = renderer['navigationEndpoint']?['watchEndpoint']?['videoId'];
      if (videoId == null) return null;

      final titleRuns = renderer['title']?['runs'] as List?;
      final title = titleRuns?.map((r) => r['text']).join('') ?? '';

      final artistRuns = renderer['shortBylineText']?['runs'] as List?;
      final artist = artistRuns?.map((r) => r['text']).join('') ?? '';

      final thumbnails = renderer['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 480);
      }

      final durationText = renderer['lengthText']?['runs']?[0]?['text'] as String?;
      final duration = durationText != null ? _parseDuration(durationText) : Duration.zero;

      return Track(
        id: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
      );
    } catch (e) {
      return null;
    }
  }

  Track? _parseMusicTwoRowItem(Map<String, dynamic>? renderer) {
    if (renderer == null) return null;

    try {
      final videoId = renderer['navigationEndpoint']?['watchEndpoint']?['videoId'];
      if (videoId == null) return null;

      final titleRuns = renderer['title']?['runs'] as List?;
      final title = titleRuns?.map((r) => r['text']).join('') ?? '';

      final subtitleRuns = renderer['subtitle']?['runs'] as List?;
      String artist = '';
      Duration duration = Duration.zero;
      
      if (subtitleRuns != null) {
        // Parse each run individually - duration is often in a separate run
        final textParts = <String>[];
        for (final run in subtitleRuns) {
          final text = run['text'] as String?;
          if (text != null && text.trim().isNotEmpty && text.trim() != '•') {
            final trimmed = text.trim();
            // Check if this run is a duration (e.g., "3:45" or "1:02:30")
            if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(trimmed)) {
              duration = _parseDuration(trimmed);
            } else {
              textParts.add(trimmed);
            }
          }
        }
        artist = textParts.isNotEmpty ? textParts.first : '';
      }

      final thumbnails = renderer['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 480);
      }

      // Try to get duration from lengthText if available (overrides subtitle)
      final lengthText = renderer['lengthText']?['runs']?[0]?['text'] as String?;
      if (lengthText != null) {
        final parsed = _parseDuration(lengthText);
        if (parsed != Duration.zero) {
          duration = parsed;
        }
      }

      // Try overlay for duration
      if (duration == Duration.zero) {
        final overlayText = renderer['thumbnailOverlay']?['musicItemThumbnailOverlayRenderer']
            ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']
            ?['watchEndpoint']?['watchEndpointMusicSupportedConfigs']
            ?['watchEndpointMusicConfig']?['musicVideoType'] as String?;
        // Also check accessibility
        final accessLabel = renderer['thumbnailOverlay']?['musicItemThumbnailOverlayRenderer']
            ?['content']?['musicPlayButtonRenderer']?['accessibilityPlayData']
            ?['accessibilityData']?['label'] as String?;
        if (accessLabel != null) {
          final match = RegExp(r'(\d+)\s*minutes?\s*(\d+)?\s*seconds?').firstMatch(accessLabel);
          if (match != null) {
            final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
            final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
            duration = Duration(minutes: minutes, seconds: seconds);
          }
        }
      }

      return Track(
        id: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        duration: duration,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get high quality thumbnail URL with dynamic sizing
  /// Appends -w{size}-h{size} for Google/YouTube thumbnails
  String? _getHighQualityThumbnail(String? url, int size) {
    if (url == null || url.isEmpty) return null;
    
    // For lh3.googleusercontent.com thumbnails
    if (url.startsWith('https://lh3.googleusercontent.com')) {
      // Use higher resolution for better quality
      final highResSize = size > 720 ? size : 1080;
      return '$url-w$highResSize-h$highResSize';
    }
    
    // For yt3.ggpht.com thumbnails
    if (url.startsWith('https://yt3.ggpht.com')) {
      // Use higher resolution for better quality
      final highResSize = size > 720 ? size : 1080;
      return '$url-w$highResSize-h$highResSize-s$highResSize';
    }
    
    // For i.ytimg.com thumbnails - use maxresdefault
    if (url.contains('i.ytimg.com')) {
      final videoIdMatch = RegExp(r'/vi/([^/]+)/').firstMatch(url);
      if (videoIdMatch != null) {
        final videoId = videoIdMatch.group(1);
        return 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
      }
    }
    
    return url;
  }

  Duration _parseDuration(String durationText) {
    final parts = durationText.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    return Duration.zero;
  }

  /// Parse album page from browse response
  AlbumPage? _parseAlbumPage(Map<String, dynamic> json) {
    try {
      // Try singleColumnBrowseResultsRenderer first (standard album layout)
      final singleColumn = json['contents']?['singleColumnBrowseResultsRenderer'];
      
      if (singleColumn != null) {
        final header = json['header']?['musicDetailHeaderRenderer'];
        
        // Get album thumbnail
        final thumbnails = header?['thumbnail']?['croppedSquareThumbnailRenderer']
            ?['thumbnail']?['thumbnails'] as List?;
        String? thumbnailUrl;
        if (thumbnails != null && thumbnails.isNotEmpty) {
          thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 480);
        }

        // Get title
        final title = header?['title']?['runs']?[0]?['text'] as String?;
        
        // Get description
        final description = header?['description']?['runs']?[0]?['text'] as String?;

        // Parse subtitle for artist and year
        final subtitleRuns = header?['subtitle']?['runs'] as List?;
        String? artist;
        String? year;
        if (subtitleRuns != null) {
          // Format is usually: "Album • Artist • Year" or similar
          final parts = <String>[];
          for (final run in subtitleRuns) {
            final text = run['text'] as String?;
            if (text != null && text.trim() != '•' && text.trim().isNotEmpty) {
              parts.add(text.trim());
            }
          }
          // Artist is usually at index 1, year at last
          if (parts.length > 1) artist = parts[1];
          if (parts.isNotEmpty) {
            final lastPart = parts.last;
            if (RegExp(r'^\d{4}$').hasMatch(lastPart)) {
              year = lastPart;
            }
          }
        }

        // Get other info (e.g., "12 songs • 45 minutes")
        final otherInfo = header?['secondSubtitle']?['runs']
            ?.map((r) => r['text'])?.join('') as String?;

        // Parse tracks from musicShelfRenderer
        final contents = singleColumn['tabs']?[0]?['tabRenderer']
            ?['content']?['sectionListRenderer']?['contents'] as List?;
        
        final tracks = <Track>[];
        if (contents != null) {
          for (final section in contents) {
            final shelf = section['musicShelfRenderer'];
            if (shelf != null) {
              final items = shelf['contents'] as List?;
              if (items != null) {
                for (final item in items) {
                  final renderer = item['musicResponsiveListItemRenderer'];
                  if (renderer != null) {
                    final track = _parseAlbumTrackItem(renderer, thumbnailUrl, artist ?? '');
                    if (track != null) tracks.add(track);
                  }
                }
              }
            }
          }
        }

        return AlbumPage(
          title: title,
          description: description,
          thumbnailUrl: thumbnailUrl,
          artist: artist,
          year: year,
          otherInfo: otherInfo,
          songs: tracks.isNotEmpty ? tracks : null,
        );
      }

      // Try twoColumnBrowseResultsRenderer (newer layout)
      final twoColumn = json['contents']?['twoColumnBrowseResultsRenderer'];
      if (twoColumn != null) {
        final header = twoColumn['tabs']?[0]?['tabRenderer']?['content']
            ?['sectionListRenderer']?['contents']?[0]?['musicResponsiveHeaderRenderer'];
        
        final title = header?['title']?['runs']?[0]?['text'] as String?;
        final description = header?['description']?['description']?['runs']?[0]?['text'] as String?;
        
        final thumbnails = header?['thumbnail']?['musicThumbnailRenderer']
            ?['thumbnail']?['thumbnails'] as List?;
        String? thumbnailUrl;
        if (thumbnails != null && thumbnails.isNotEmpty) {
          thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 480);
        }

        // Parse artist from straplineTextOne
        final artistRuns = header?['straplineTextOne']?['runs'] as List?;
        String? artist;
        if (artistRuns != null && artistRuns.isNotEmpty) {
          artist = artistRuns.map((r) => r['text']).join('');
        }

        // Parse year from subtitle
        final subtitleRuns = header?['subtitle']?['runs'] as List?;
        String? year;
        if (subtitleRuns != null) {
          for (final run in subtitleRuns) {
            final text = run['text'] as String?;
            if (text != null && RegExp(r'^\d{4}$').hasMatch(text.trim())) {
              year = text.trim();
              break;
            }
          }
        }

        final otherInfo = header?['secondSubtitle']?['runs']
            ?.map((r) => r['text'])?.join('') as String?;

        // Parse tracks from secondary contents
        final secondaryContents = twoColumn['secondaryContents']
            ?['sectionListRenderer']?['contents'] as List?;
        
        final tracks = <Track>[];
        if (secondaryContents != null) {
          for (final section in secondaryContents) {
            final shelf = section['musicShelfRenderer'];
            if (shelf != null) {
              final items = shelf['contents'] as List?;
              if (items != null) {
                for (final item in items) {
                  final renderer = item['musicResponsiveListItemRenderer'];
                  if (renderer != null) {
                    final track = _parseAlbumTrackItem(renderer, thumbnailUrl, artist ?? '');
                    if (track != null) tracks.add(track);
                  }
                }
              }
            }
          }
        }

        return AlbumPage(
          title: title,
          description: description,
          thumbnailUrl: thumbnailUrl,
          artist: artist,
          year: year,
          otherInfo: otherInfo,
          songs: tracks.isNotEmpty ? tracks : null,
        );
      }

      return null;
    } catch (e) {
      print('InnertubeService: Parse album page error: $e');
      return null;
    }
  }

  /// Parse a single album track item
  Track? _parseAlbumTrackItem(Map<String, dynamic> renderer, String? albumThumbnailUrl, String albumArtist) {
    try {
      final flexColumns = renderer['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;

      // Get video ID - try multiple locations
      String? videoId = renderer['playlistItemData']?['videoId'] as String?;
      videoId ??= renderer['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']
          ?['watchEndpoint']?['videoId'] as String?;
      videoId ??= flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'] as String?;
      
      if (videoId == null) return null;

      // Get title
      final titleRuns = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs'] as List?;
      final title = titleRuns?.map((r) => r['text']).join('') ?? '';

      // Get artist from second column or use album artist
      String artist = albumArtist;
      if (flexColumns.length > 1) {
        final artistRuns = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']
            ?['text']?['runs'] as List?;
        if (artistRuns != null && artistRuns.isNotEmpty) {
          artist = artistRuns.map((r) => r['text']).join('');
        }
      }

      // Get duration from fixed columns
      Duration duration = Duration.zero;
      final fixedColumns = renderer['fixedColumns'] as List?;
      if (fixedColumns != null && fixedColumns.isNotEmpty) {
        final durationText = fixedColumns[0]?['musicResponsiveListItemFixedColumnRenderer']
            ?['text']?['runs']?[0]?['text'] as String?;
        if (durationText != null) {
          duration = _parseDuration(durationText);
        }
      }

      // Get thumbnail from renderer if available, otherwise use album thumbnail
      String? trackThumbnailUrl = albumThumbnailUrl;
      final trackThumbnails = renderer['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      if (trackThumbnails != null && trackThumbnails.isNotEmpty) {
        trackThumbnailUrl = _getHighQualityThumbnail(trackThumbnails.last['url'], 480);
      }

      return Track(
        id: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: trackThumbnailUrl,
        duration: duration,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse artist page from browse response
  ArtistPage? _parseArtistPage(Map<String, dynamic> json) {
    try {
      final header = json['header']?['musicImmersiveHeaderRenderer'] ?? 
                     json['header']?['musicVisualHeaderRenderer'];
      
      // Get artist name
      final name = header?['title']?['runs']?[0]?['text'] as String?;
      
      // Get description - try multiple paths as YouTube Music uses different structures
      String? description = header?['description']?['runs']?[0]?['text'] as String?;
      description ??= header?['description']?['description']?['runs']?[0]?['text'] as String?;
      
      // Also try to get description from the contents section
      if (description == null) {
        final contents = json['contents']?['singleColumnBrowseResultsRenderer']
            ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
        if (contents != null) {
          for (final section in contents) {
            final descRenderer = section['musicDescriptionShelfRenderer'];
            if (descRenderer != null) {
              description = descRenderer['description']?['runs']?[0]?['text'] as String?;
              if (description != null) break;
            }
          }
        }
      }
      
      // Get thumbnail
      final thumbnails = (header?['foregroundThumbnail'] ?? header?['thumbnail'])
          ?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
      String? thumbnailUrl;
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnailUrl = _getHighQualityThumbnail(thumbnails.last['url'], 480);
      }

      // Get subscribers count
      final subscribersCountText = header?['subscriptionButton']
          ?['subscribeButtonRenderer']?['subscriberCountText']?['runs']?[0]?['text'] as String?;

      // Parse sections
      final contents = json['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      
      if (contents == null) {
        return ArtistPage(
          name: name,
          description: description,
          thumbnailUrl: thumbnailUrl,
          subscribersCountText: subscribersCountText,
        );
      }

      List<Track>? songs;
      String? songsEndpointBrowseId;
      String? songsEndpointParams;
      List<RelatedAlbum>? albums;
      String? albumsEndpointBrowseId;
      List<RelatedAlbum>? singles;
      String? singlesEndpointBrowseId;

      for (final section in contents) {
        // Find Songs section (musicShelfRenderer)
        final shelf = section['musicShelfRenderer'];
        if (shelf != null) {
          final shelfTitle = shelf['title']?['runs']?[0]?['text'] as String? ?? '';
          if (shelfTitle.toLowerCase().contains('song')) {
            songs = <Track>[];
            final items = shelf['contents'] as List?;
            if (items != null) {
              for (final item in items) {
                final renderer = item['musicResponsiveListItemRenderer'];
                if (renderer != null) {
                  final track = _parseMusicResponsiveListItem(renderer);
                  if (track != null) songs.add(track);
                }
              }
            }
            // Get "See all" endpoint
            final bottomEndpoint = shelf['bottomEndpoint']?['browseEndpoint'];
            songsEndpointBrowseId = bottomEndpoint?['browseId'] as String?;
            songsEndpointParams = bottomEndpoint?['params'] as String?;
          }
        }

        // Find Albums and Singles sections (musicCarouselShelfRenderer)
        final carousel = section['musicCarouselShelfRenderer'];
        if (carousel != null) {
          final carouselHeader = carousel['header']?['musicCarouselShelfBasicHeaderRenderer'];
          final carouselTitle = carouselHeader?['title']?['runs']?[0]?['text'] as String? ?? '';
          
          final items = carousel['contents'] as List?;
          if (items == null) continue;

          if (carouselTitle.toLowerCase().contains('album')) {
            albums = <RelatedAlbum>[];
            for (final item in items) {
              final renderer = item['musicTwoRowItemRenderer'];
              if (renderer != null) {
                final album = _parseAlbumItem(renderer);
                if (album != null) albums.add(album);
              }
            }
            // Get "See all" endpoint
            final moreButton = carouselHeader?['moreContentButton']?['buttonRenderer']
                ?['navigationEndpoint']?['browseEndpoint'];
            albumsEndpointBrowseId = moreButton?['browseId'] as String?;
          } else if (carouselTitle.toLowerCase().contains('single') || 
                     carouselTitle.toLowerCase().contains('ep')) {
            singles = <RelatedAlbum>[];
            for (final item in items) {
              final renderer = item['musicTwoRowItemRenderer'];
              if (renderer != null) {
                final album = _parseAlbumItem(renderer);
                if (album != null) singles.add(album);
              }
            }
            // Get "See all" endpoint
            final moreButton = carouselHeader?['moreContentButton']?['buttonRenderer']
                ?['navigationEndpoint']?['browseEndpoint'];
            singlesEndpointBrowseId = moreButton?['browseId'] as String?;
          }
        }
      }

      return ArtistPage(
        name: name,
        description: description,
        thumbnailUrl: thumbnailUrl,
        subscribersCountText: subscribersCountText,
        songs: songs,
        songsEndpointBrowseId: songsEndpointBrowseId,
        songsEndpointParams: songsEndpointParams,
        albums: albums,
        albumsEndpointBrowseId: albumsEndpointBrowseId,
        singles: singles,
        singlesEndpointBrowseId: singlesEndpointBrowseId,
      );
    } catch (e) {
      print('InnertubeService: Parse artist page error: $e');
      return null;
    }
  }
}

/// Player response model
class PlayerResponse {
  final PlayabilityStatus playabilityStatus;
  final StreamingData? streamingData;
  final VideoDetails? videoDetails;
  final PlayerConfig? playerConfig;

  PlayerResponse({
    required this.playabilityStatus,
    this.streamingData,
    this.videoDetails,
    this.playerConfig,
  });

  bool get isPlayable => playabilityStatus.status == 'OK' && streamingData != null;

  /// Get highest quality audio format
  /// Prefers itag 251 (Opus ~160kbps) or 140 (AAC 128kbps) for best audio quality
  AudioFormat? get highestQualityAudioFormat {
    if (streamingData == null) return null;
    
    final audioFormats = streamingData!.adaptiveFormats
        .where((f) => f.isAudio)
        .toList();
    
    if (audioFormats.isEmpty) return null;
    
    // Prefer itag 251 (Opus) or 140 (AAC)
    // itag 251: Opus ~160kbps VBR - best quality for music
    // itag 140: AAC 128kbps - good fallback
    final preferred = audioFormats.where((f) => f.itag == 251 || f.itag == 140).toList();
    if (preferred.isNotEmpty) {
      // Prefer 251 (Opus) over 140 (AAC) - Opus has better bass and dynamic range
      return preferred.firstWhere((f) => f.itag == 251, orElse: () => preferred.first);
    }
    
    // Fallback to highest bitrate if preferred formats not available
    audioFormats.sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return audioFormats.first;
  }

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    return PlayerResponse(
      playabilityStatus: PlayabilityStatus.fromJson(
        json['playabilityStatus'] as Map<String, dynamic>? ?? {},
      ),
      streamingData: json['streamingData'] != null
          ? StreamingData.fromJson(json['streamingData'] as Map<String, dynamic>)
          : null,
      videoDetails: json['videoDetails'] != null
          ? VideoDetails.fromJson(json['videoDetails'] as Map<String, dynamic>)
          : null,
      playerConfig: json['playerConfig'] != null
          ? PlayerConfig.fromJson(json['playerConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlayabilityStatus {
  final String status;
  final String? reason;

  PlayabilityStatus({required this.status, this.reason});

  factory PlayabilityStatus.fromJson(Map<String, dynamic> json) {
    return PlayabilityStatus(
      status: json['status'] as String? ?? 'ERROR',
      reason: json['reason'] as String?,
    );
  }
}

class StreamingData {
  final List<AudioFormat> adaptiveFormats;
  final int expiresInSeconds;

  StreamingData({required this.adaptiveFormats, required this.expiresInSeconds});

  factory StreamingData.fromJson(Map<String, dynamic> json) {
    final formats = (json['adaptiveFormats'] as List? ?? [])
        .map((f) => AudioFormat.fromJson(f as Map<String, dynamic>))
        .toList();
    
    return StreamingData(
      adaptiveFormats: formats,
      expiresInSeconds: AudioFormat._parseIntSafe(json['expiresInSeconds']),
    );
  }
}

class AudioFormat {
  final int itag;
  final String? url;
  final String mimeType;
  final int bitrate;
  final int? width;
  final int? height;
  final int? contentLength;
  final String? audioQuality;
  final int? audioSampleRate;
  final int? audioChannels;
  final double? loudnessDb;
  final String? signatureCipher;

  AudioFormat({
    required this.itag,
    this.url,
    required this.mimeType,
    required this.bitrate,
    this.width,
    this.height,
    this.contentLength,
    this.audioQuality,
    this.audioSampleRate,
    this.audioChannels,
    this.loudnessDb,
    this.signatureCipher,
  });

  bool get isAudio => width == null;

  factory AudioFormat.fromJson(Map<String, dynamic> json) {
    return AudioFormat(
      itag: _parseIntSafe(json['itag']),
      url: json['url'] as String?,
      mimeType: json['mimeType'] as String? ?? '',
      bitrate: _parseIntSafe(json['bitrate']),
      width: _parseIntSafeNullable(json['width']),
      height: _parseIntSafeNullable(json['height']),
      contentLength: _parseIntSafeNullable(json['contentLength']),
      audioQuality: json['audioQuality'] as String?,
      audioSampleRate: _parseIntSafeNullable(json['audioSampleRate']),
      audioChannels: _parseIntSafeNullable(json['audioChannels']),
      loudnessDb: _parseDoubleSafe(json['loudnessDb']),
      signatureCipher: json['signatureCipher'] as String?,
    );
  }
  
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
  
  static int? _parseIntSafeNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
  
  static double? _parseDoubleSafe(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }
}

class VideoDetails {
  final String videoId;
  final String title;
  final String author;
  final String channelId;
  final int lengthSeconds;

  VideoDetails({
    required this.videoId,
    required this.title,
    required this.author,
    required this.channelId,
    required this.lengthSeconds,
  });

  factory VideoDetails.fromJson(Map<String, dynamic> json) {
    return VideoDetails(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      lengthSeconds: int.tryParse(json['lengthSeconds']?.toString() ?? '0') ?? 0,
    );
  }
}

class PlayerConfig {
  final AudioConfig? audioConfig;

  PlayerConfig({this.audioConfig});

  factory PlayerConfig.fromJson(Map<String, dynamic> json) {
    return PlayerConfig(
      audioConfig: json['audioConfig'] != null
          ? AudioConfig.fromJson(json['audioConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AudioConfig {
  final double? loudnessDb;
  final double? perceptualLoudnessDb;

  AudioConfig({this.loudnessDb, this.perceptualLoudnessDb});

  factory AudioConfig.fromJson(Map<String, dynamic> json) {
    return AudioConfig(
      loudnessDb: (json['loudnessDb'] as num?)?.toDouble(),
      perceptualLoudnessDb: (json['perceptualLoudnessDb'] as num?)?.toDouble(),
    );
  }
}

/// Discover page model
class DiscoverPage {
  final List<Track> trending;
  final List<Track> newReleases;

  DiscoverPage({required this.trending, required this.newReleases});
}
