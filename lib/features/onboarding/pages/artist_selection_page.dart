import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/user_preferences_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart' as ytmusic;

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
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _loadArtistImages();
  }

  Future<void> _loadArtistImages() async {
    setState(() => _isLoadingImages = true);
    
    try {
      final ytMusic = ytmusic.YtMusicService();
      
      // Get all artist names from selected languages
      final allArtistNames = <String>[];
      for (final language in widget.selectedLanguages) {
        allArtistNames.addAll(language.topArtists);
      }
      
      // Fetch images for each artist from YouTube Music
      for (final artistName in allArtistNames) {
        try {
          final searchResults = await ytMusic.searchArtists(artistName);
          if (searchResults.isNotEmpty) {
            final artist = searchResults.first;
            if (artist.thumbnailUrl != null && artist.thumbnailUrl!.isNotEmpty) {
              _artistImages[artistName] = artist.thumbnailUrl!;
            }
          }
        } catch (e) {
          print('Failed to fetch image for $artistName: $e');
        }
      }
    } catch (e) {
      print('Error loading artist images: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingImages = false);
      }
    }
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
                                        child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: artist.imageUrl!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: AppTheme.darkCard,
                                                  child: Center(
                                                    child: Text(
                                                      artist.name.substring(0, 1).toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: AppTheme.darkCard,
                                                  child: Center(
                                                    child: Text(
                                                      artist.name.substring(0, 1).toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(
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
