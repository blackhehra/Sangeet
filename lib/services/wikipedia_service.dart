import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to fetch artist information from Wikipedia
class WikipediaService {
  static final WikipediaService _instance = WikipediaService._internal();
  factory WikipediaService() => _instance;
  WikipediaService._internal();

  static WikipediaService get instance => _instance;

  static const String _baseUrl = 'https://en.wikipedia.org/api/rest_v1';
  static const String _searchUrl = 'https://en.wikipedia.org/w/api.php';

  /// Fetch artist summary/description from Wikipedia
  /// Returns the extract (description) or null if not found
  Future<String?> getArtistDescription(String artistName) async {
    try {
      // First, search for the artist to get the exact page title
      final searchTitle = await _searchForArtist(artistName);
      if (searchTitle == null) return null;

      // Then fetch the summary
      final summary = await _getPageSummary(searchTitle);
      return summary;
    } catch (e) {
      return null;
    }
  }

  /// Search Wikipedia for an artist and return the best matching page title
  Future<String?> _searchForArtist(String artistName) async {
    try {
      // Add common suffixes to improve search for musicians
      final searchQueries = [
        '$artistName musician',
        '$artistName singer',
        '$artistName band',
        artistName,
      ];

      for (final query in searchQueries) {
        final uri = Uri.parse(_searchUrl).replace(queryParameters: {
          'action': 'query',
          'list': 'search',
          'srsearch': query,
          'format': 'json',
          'srlimit': '5',
        });

        final response = await http.get(uri);
        if (response.statusCode != 200) continue;

        final data = json.decode(response.body);
        final searchResults = data['query']?['search'] as List?;

        if (searchResults != null && searchResults.isNotEmpty) {
          // Look for a result that seems to be about a musician/band
          for (final result in searchResults) {
            final title = result['title'] as String?;
            final snippet = (result['snippet'] as String?)?.toLowerCase() ?? '';
            
            if (title != null) {
              // Check if the snippet mentions music-related terms
              if (snippet.contains('singer') ||
                  snippet.contains('musician') ||
                  snippet.contains('band') ||
                  snippet.contains('rapper') ||
                  snippet.contains('artist') ||
                  snippet.contains('songwriter') ||
                  snippet.contains('composer') ||
                  snippet.contains('record') ||
                  snippet.contains('album') ||
                  snippet.contains('music')) {
                return title;
              }
            }
          }
          
          // If no music-related result found, return the first result
          return searchResults.first['title'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the summary/extract of a Wikipedia page
  Future<String?> _getPageSummary(String pageTitle) async {
    try {
      // URL encode the title
      final encodedTitle = Uri.encodeComponent(pageTitle);
      final uri = Uri.parse('$_baseUrl/page/summary/$encodedTitle');

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      
      // Get the extract (description)
      final extract = data['extract'] as String?;
      
      if (extract != null && extract.isNotEmpty) {
        return extract;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get full artist info including description and image
  Future<WikiArtistInfo?> getArtistInfo(String artistName) async {
    try {
      final searchTitle = await _searchForArtist(artistName);
      if (searchTitle == null) return null;

      final encodedTitle = Uri.encodeComponent(searchTitle);
      final uri = Uri.parse('$_baseUrl/page/summary/$encodedTitle');

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      
      return WikiArtistInfo(
        title: data['title'] as String? ?? artistName,
        description: data['description'] as String?,
        extract: data['extract'] as String?,
        thumbnailUrl: data['thumbnail']?['source'] as String?,
        originalImageUrl: data['originalimage']?['source'] as String?,
        pageUrl: data['content_urls']?['desktop']?['page'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Model for Wikipedia artist information
class WikiArtistInfo {
  final String title;
  final String? description;
  final String? extract;
  final String? thumbnailUrl;
  final String? originalImageUrl;
  final String? pageUrl;

  const WikiArtistInfo({
    required this.title,
    this.description,
    this.extract,
    this.thumbnailUrl,
    this.originalImageUrl,
    this.pageUrl,
  });
}
