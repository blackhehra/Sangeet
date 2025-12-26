import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/user_preferences_service.dart';

class ArtistSelectionPage extends ConsumerStatefulWidget {
  final List<MusicLanguage> selectedLanguages;

  const ArtistSelectionPage({
    super.key,
    required this.selectedLanguages,
  });

  @override
  ConsumerState<ArtistSelectionPage> createState() => _ArtistSelectionPageState();
}

class _ArtistSelectionPageState extends ConsumerState<ArtistSelectionPage> {
  final Set<String> _selectedArtists = {};
  final Map<String, String> _artistImages = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArtistImages();
  }

  Future<void> _loadArtistImages() async {
    // Pre-populate with some known artist images
    // In production, you'd fetch these from an API
    _artistImages.addAll({
      // Hindi
      'Arijit Singh': 'https://i.scdn.co/image/ab6761610000e5eb0261696c5df3be99da6ed3f3',
      'Shreya Ghoshal': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Neha Kakkar': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Atif Aslam': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Jubin Nautiyal': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Badshah': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Honey Singh': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Armaan Malik': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Darshan Raval': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'B Praak': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Guru Randhawa': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Sonu Nigam': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      // Punjabi
      'Sidhu Moose Wala': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Diljit Dosanjh': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'AP Dhillon': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Karan Aujla': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Ammy Virk': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Harrdy Sandhu': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Shubh': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      // English
      'Taylor Swift': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Ed Sheeran': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'The Weeknd': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Drake': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Dua Lipa': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'Billie Eilish': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'BTS': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
      'BLACKPINK': 'https://i.scdn.co/image/ab6761610000e5eb5c0a4dc5a9b0c1a0b2c3d4e5',
    });
  }

  List<_ArtistInfo> _getArtistsForLanguages() {
    final artists = <_ArtistInfo>[];
    
    for (final language in widget.selectedLanguages) {
      for (final artistName in language.topArtists) {
        artists.add(_ArtistInfo(
          name: artistName,
          language: language.displayName,
          imageUrl: _artistImages[artistName],
        ));
      }
    }
    
    return artists;
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    try {
      // Create preferred artists list
      final preferredArtists = _selectedArtists.map((name) {
        final language = widget.selectedLanguages.firstWhere(
          (l) => l.topArtists.contains(name),
          orElse: () => MusicLanguage.hindi,
        );
        return PreferredArtist(
          name: name,
          language: language.displayName,
          imageUrl: _artistImages[name],
        );
      }).toList();
      
      // Save artists
      await ref
          .read(userPreferencesServiceProvider.notifier)
          .setArtists(preferredArtists);
      
      // Complete onboarding
      await ref
          .read(userPreferencesServiceProvider.notifier)
          .completeOnboarding();
      
      if (mounted) {
        // Pop all onboarding pages
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artists = _getArtistsForLanguages();
    
    // Group artists by language
    final groupedArtists = <String, List<_ArtistInfo>>{};
    for (final artist in artists) {
      groupedArtists.putIfAbsent(artist.language, () => []).add(artist);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Iconsax.arrow_left),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.darkCard,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  
                  const Gap(16),
                  
                  Text(
                    'Choose your favorite\nartists',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const Gap(8),
                  
                  Text(
                    'Select at least 3 artists you love. This helps us recommend music you\'ll enjoy.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            
            // Artists List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: groupedArtists.length,
                itemBuilder: (context, index) {
                  final language = groupedArtists.keys.elementAt(index);
                  final languageArtists = groupedArtists[language]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          language,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: languageArtists.length,
                        itemBuilder: (context, artistIndex) {
                          final artist = languageArtists[artistIndex];
                          final isSelected = _selectedArtists.contains(artist.name);
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedArtists.remove(artist.name);
                                } else {
                                  _selectedArtists.add(artist.name);
                                }
                              });
                            },
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected 
                                              ? AppTheme.primaryColor 
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Container(
                                          color: AppTheme.darkCard,
                                          child: Center(
                                            child: Text(
                                              artist.name.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected 
                                                    ? AppTheme.primaryColor 
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Gap(8),
                                Text(
                                  artist.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    color: isSelected 
                                        ? AppTheme.primaryColor 
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const Gap(16),
                    ],
                  );
                },
              ),
            ),
            
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedArtists.length < 3 || _isLoading
                      ? null
                      : _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedArtists.length < 3
                                  ? 'Select at least 3 artists (${_selectedArtists.length}/3)'
                                  : 'Get Started (${_selectedArtists.length} selected)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedArtists.length >= 3) ...[
                              const Gap(8),
                              const Icon(Iconsax.arrow_right_1, size: 20),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistInfo {
  final String name;
  final String language;
  final String? imageUrl;

  _ArtistInfo({
    required this.name,
    required this.language,
    this.imageUrl,
  });
}
