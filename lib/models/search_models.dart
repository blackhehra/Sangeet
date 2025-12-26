/// Model for artist search results
class SearchArtist {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? subscribersText;

  const SearchArtist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.subscribersText,
  });
}

/// Model for album search results
class SearchAlbum {
  final String id;
  final String title;
  final String? artist;
  final String? thumbnailUrl;
  final String? year;
  final String? albumType;

  const SearchAlbum({
    required this.id,
    required this.title,
    this.artist,
    this.thumbnailUrl,
    this.year,
    this.albumType,
  });
}
