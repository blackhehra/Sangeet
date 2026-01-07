import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing followed artists with persistence
class FollowedArtistsService {
  static const String _followedArtistsKey = 'followed_artists';
  
  static final FollowedArtistsService _instance = FollowedArtistsService._internal();
  factory FollowedArtistsService() => _instance;
  FollowedArtistsService._internal();
  
  static FollowedArtistsService get instance => _instance;
  
  final List<FollowedArtist> _followedArtists = [];
  bool _isLoaded = false;
  
  List<FollowedArtist> get followedArtists => List.unmodifiable(_followedArtists);
  
  /// Initialize and load followed artists from storage
  Future<void> init() async {
    if (_isLoaded) return;
    await _loadFollowedArtists();
    _isLoaded = true;
  }
  
  Future<void> _loadFollowedArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_followedArtistsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _followedArtists.clear();
        _followedArtists.addAll(
          jsonList.map((j) => FollowedArtist.fromJson(j)).toList(),
        );
      }
      print('FollowedArtistsService: Loaded ${_followedArtists.length} followed artists');
    } catch (e) {
      print('FollowedArtistsService: Error loading followed artists: $e');
    }
  }
  
  Future<void> _saveFollowedArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        _followedArtists.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(_followedArtistsKey, jsonString);
    } catch (e) {
      print('FollowedArtistsService: Error saving followed artists: $e');
    }
  }
  
  /// Check if an artist is followed
  bool isFollowing(String artistId) {
    return _followedArtists.any((a) => a.id == artistId);
  }
  
  /// Follow an artist
  Future<void> followArtist(FollowedArtist artist) async {
    if (!isFollowing(artist.id)) {
      _followedArtists.add(artist);
      await _saveFollowedArtists();
      print('FollowedArtistsService: Followed ${artist.name}');
    }
  }
  
  /// Unfollow an artist
  Future<void> unfollowArtist(String artistId) async {
    _followedArtists.removeWhere((a) => a.id == artistId);
    await _saveFollowedArtists();
    print('FollowedArtistsService: Unfollowed artist $artistId');
  }
  
  /// Toggle follow status
  Future<bool> toggleFollow(FollowedArtist artist) async {
    if (isFollowing(artist.id)) {
      await unfollowArtist(artist.id);
      return false;
    } else {
      await followArtist(artist);
      return true;
    }
  }
  
  /// Get a random selection of followed artist names for recommendations
  /// Returns 20-30% of followed artists
  List<String> getArtistsForRecommendations() {
    if (_followedArtists.isEmpty) return [];
    
    // Get 20-30% of followed artists (minimum 1 if any exist)
    final count = (_followedArtists.length * 0.25).ceil().clamp(1, _followedArtists.length);
    
    // Shuffle and take the count
    final shuffled = List<FollowedArtist>.from(_followedArtists)..shuffle();
    return shuffled.take(count).map((a) => a.name).toList();
  }
}

/// Model for a followed artist
class FollowedArtist {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final DateTime followedAt;

  FollowedArtist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    DateTime? followedAt,
  }) : followedAt = followedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'thumbnailUrl': thumbnailUrl,
    'followedAt': followedAt.toIso8601String(),
  };

  factory FollowedArtist.fromJson(Map<String, dynamic> json) => FollowedArtist(
    id: json['id'] as String,
    name: json['name'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    followedAt: DateTime.tryParse(json['followedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
