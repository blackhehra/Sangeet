import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available music languages
enum MusicLanguage {
  hindi('Hindi', 'hi', [
    'Arijit Singh', 'Shreya Ghoshal', 'Neha Kakkar', 'Atif Aslam', 
    'Jubin Nautiyal', 'Badshah', 'Honey Singh', 'Armaan Malik',
    'Darshan Raval', 'B Praak', 'Guru Randhawa', 'Sonu Nigam'
  ]),
  punjabi('Punjabi', 'pa', [
    'Sidhu Moose Wala', 'Diljit Dosanjh', 'AP Dhillon', 'Karan Aujla',
    'Ammy Virk', 'Harrdy Sandhu', 'Jassie Gill', 'Parmish Verma',
    'Shubh', 'Babbu Maan', 'Gurdas Maan', 'Jazzy B'
  ]),
  english('English', 'en', [
    'Taylor Swift', 'Ed Sheeran', 'The Weeknd', 'Drake',
    'Dua Lipa', 'Billie Eilish', 'Post Malone', 'Ariana Grande',
    'Justin Bieber', 'Bruno Mars', 'Coldplay', 'Imagine Dragons'
  ]),
  tamil('Tamil', 'ta', [
    'Anirudh Ravichander', 'A.R. Rahman', 'Sid Sriram', 'Yuvan Shankar Raja',
    'Vijay Antony', 'Harris Jayaraj', 'D. Imman', 'Santhosh Narayanan'
  ]),
  telugu('Telugu', 'te', [
    'S. Thaman', 'Devi Sri Prasad', 'Anirudh Ravichander', 'Sid Sriram',
    'Armaan Malik', 'Mangli', 'Rahul Sipligunj', 'Karthik'
  ]),
  kannada('Kannada', 'kn', [
    'Sonu Nigam', 'Vijay Prakash', 'Shreya Ghoshal', 'Rajesh Krishnan',
    'Chandan Shetty', 'Arjun Janya', 'B. Ajaneesh Loknath'
  ]),
  malayalam('Malayalam', 'ml', [
    'K.J. Yesudas', 'Vineeth Sreenivasan', 'Sushin Shyam', 'Pradeep Kumar',
    'Haricharan', 'Vidyasagar', 'M.G. Sreekumar'
  ]),
  marathi('Marathi', 'mr', [
    'Ajay-Atul', 'Shankar Mahadevan', 'Avadhoot Gupte', 'Swapnil Bandodkar',
    'Bela Shende', 'Shreya Ghoshal', 'Adarsh Shinde'
  ]),
  bengali('Bengali', 'bn', [
    'Arijit Singh', 'Anupam Roy', 'Shreya Ghoshal', 'Rupam Islam',
    'Nachiketa', 'Anjan Dutt', 'Sidhu', 'Babul Supriyo'
  ]),
  gujarati('Gujarati', 'gu', [
    'Aishwarya Majmudar', 'Kirtidan Gadhvi', 'Geeta Rabari', 'Jignesh Kaviraj',
    'Kinjal Dave', 'Rakesh Barot', 'Vijay Suvada'
  ]),
  korean('Korean (K-Pop)', 'ko', [
    'BTS', 'BLACKPINK', 'Stray Kids', 'TWICE',
    'NewJeans', 'aespa', 'IVE', 'LE SSERAFIM'
  ]),
  spanish('Spanish', 'es', [
    'Bad Bunny', 'J Balvin', 'Shakira', 'Daddy Yankee',
    'Ozuna', 'Maluma', 'Karol G', 'Rosalía'
  ]);

  final String displayName;
  final String code;
  final List<String> topArtists;

  const MusicLanguage(this.displayName, this.code, this.topArtists);
}

/// Artist with image info
class PreferredArtist {
  final String name;
  final String language;
  final String? imageUrl;

  const PreferredArtist({
    required this.name,
    required this.language,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'language': language,
    'imageUrl': imageUrl,
  };

  factory PreferredArtist.fromJson(Map<String, dynamic> json) => PreferredArtist(
    name: json['name'] as String,
    language: json['language'] as String,
    imageUrl: json['imageUrl'] as String?,
  );
}

/// User preferences state
class UserPreferences {
  final bool onboardingCompleted;
  final List<MusicLanguage> selectedLanguages;
  final List<PreferredArtist> selectedArtists;

  const UserPreferences({
    this.onboardingCompleted = false,
    this.selectedLanguages = const [],
    this.selectedArtists = const [],
  });

  UserPreferences copyWith({
    bool? onboardingCompleted,
    List<MusicLanguage>? selectedLanguages,
    List<PreferredArtist>? selectedArtists,
  }) {
    return UserPreferences(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      selectedArtists: selectedArtists ?? this.selectedArtists,
    );
  }

  /// Get search queries for recommendations based on preferences
  List<String> getRecommendationQueries() {
    final queries = <String>[];
    
    // Add artist-based queries (highest priority)
    for (final artist in selectedArtists) {
      queries.add('${artist.name} songs');
      queries.add('${artist.name} latest');
    }
    
    // Add language-based queries
    for (final lang in selectedLanguages) {
      queries.add('${lang.displayName} songs 2024');
      queries.add('${lang.displayName} hits');
      queries.add('new ${lang.displayName} songs');
    }
    
    return queries;
  }
}

/// User preferences service
class UserPreferencesService extends StateNotifier<UserPreferences> {
  static const String _prefsKey = 'user_preferences';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _languagesKey = 'selected_languages';
  static const String _artistsKey = 'selected_artists';

  UserPreferencesService() : super(const UserPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final onboardingCompleted = prefs.getBool(_onboardingKey) ?? false;
      
      // Load languages
      final languagesJson = prefs.getStringList(_languagesKey) ?? [];
      final languages = languagesJson
          .map((code) => MusicLanguage.values.firstWhere(
                (l) => l.code == code,
                orElse: () => MusicLanguage.hindi,
              ))
          .toList();
      
      // Load artists - wrap in try-catch for corrupted JSON
      final artistsJson = prefs.getString(_artistsKey);
      List<PreferredArtist> artists = [];
      if (artistsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(artistsJson);
          artists = decoded.map((e) => PreferredArtist.fromJson(e)).toList();
        } catch (e) {
          print('UserPreferences: Failed to parse artists JSON: $e');
          // Clear corrupted data
          await prefs.remove(_artistsKey);
        }
      }
      
      state = UserPreferences(
        onboardingCompleted: onboardingCompleted,
        selectedLanguages: languages,
        selectedArtists: artists,
      );
      
      print('UserPreferences: Loaded - onboarding: $onboardingCompleted, '
          'languages: ${languages.length}, artists: ${artists.length}');
    } catch (e) {
      print('UserPreferences: Failed to load preferences: $e');
      // Keep default state on error
    }
  }

  Future<void> setLanguages(List<MusicLanguage> languages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_languagesKey, languages.map((l) => l.code).toList());
    state = state.copyWith(selectedLanguages: languages);
    print('UserPreferences: Set ${languages.length} languages');
  }

  Future<void> setArtists(List<PreferredArtist> artists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_artistsKey, jsonEncode(artists.map((a) => a.toJson()).toList()));
    state = state.copyWith(selectedArtists: artists);
    print('UserPreferences: Set ${artists.length} artists');
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    state = state.copyWith(onboardingCompleted: true);
    print('UserPreferences: Onboarding completed');
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, false);
    await prefs.remove(_languagesKey);
    await prefs.remove(_artistsKey);
    state = const UserPreferences();
    print('UserPreferences: Reset');
  }

  bool get needsOnboarding => !state.onboardingCompleted;
  List<MusicLanguage> get selectedLanguages => state.selectedLanguages;
  List<PreferredArtist> get selectedArtists => state.selectedArtists;
}

/// Provider for user preferences service
final userPreferencesServiceProvider = 
    StateNotifierProvider<UserPreferencesService, UserPreferences>((ref) {
  return UserPreferencesService();
});

/// Provider to check if onboarding is needed
final needsOnboardingProvider = Provider<bool>((ref) {
  return !ref.watch(userPreferencesServiceProvider).onboardingCompleted;
});
