import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/recommendation_service.dart';
import 'package:sangeet/services/ytmusic/yt_music_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/models/track.dart';

/// Daily Mixes Page
/// Shows personalized daily mixes like Morning Mix, Chill Mix, Workout Mix, etc.
class DailyMixesPage extends ConsumerStatefulWidget {
  const DailyMixesPage({super.key});

  @override
  ConsumerState<DailyMixesPage> createState() => _DailyMixesPageState();
}

class _DailyMixesPageState extends ConsumerState<DailyMixesPage> {
  final RecommendationService _recommendationService = RecommendationService.instance;
  List<DailyMix> _mixes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMixes();
  }

  Future<void> _loadMixes() async {
    await _recommendationService.init();
    setState(() {
      _mixes = _recommendationService.getDailyMixes();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Daily Mixes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadMixes();
                },
                icon: const Icon(Iconsax.refresh),
              ),
            ],
          ),
          
          // Current mood indicator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _CurrentMoodCard(
                mood: _recommendationService.getCurrentMood(),
              ),
            ),
          ),
          
          // Daily mixes grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mix = _mixes[index];
                    return _DailyMixCard(mix: mix);
                  },
                  childCount: _mixes.length,
                ),
              ),
            ),
          
          const SliverGap(100),
        ],
      ),
    );
  }
}

class _CurrentMoodCard extends StatelessWidget {
  final DayMood mood;

  const _CurrentMoodCard({required this.mood});

  String get _moodText {
    switch (mood) {
      case DayMood.morning:
        return 'Good morning! Start your day with some uplifting tunes.';
      case DayMood.focus:
        return 'Time to focus. Here\'s some music to help you concentrate.';
      case DayMood.afternoon:
        return 'Afternoon vibes. Keep the momentum going!';
      case DayMood.evening:
        return 'Evening time. Wind down with some mellow tracks.';
      case DayMood.chill:
        return 'Chill mode activated. Relax and enjoy.';
      case DayMood.lateNight:
        return 'Late night listening. Peaceful tunes for the night.';
      case DayMood.workout:
        return 'Workout time! Get pumped with high energy tracks.';
      case DayMood.party:
        return 'Party mode! Let\'s get this party started.';
    }
  }

  String get _moodEmoji {
    switch (mood) {
      case DayMood.morning:
        return '☀️';
      case DayMood.focus:
        return '🎯';
      case DayMood.afternoon:
        return '🌤️';
      case DayMood.evening:
        return '🌅';
      case DayMood.chill:
        return '🌙';
      case DayMood.lateNight:
        return '🌃';
      case DayMood.workout:
        return '💪';
      case DayMood.party:
        return '🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            _moodEmoji,
            style: const TextStyle(fontSize: 40),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              _moodText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMixCard extends ConsumerStatefulWidget {
  final DailyMix mix;

  const _DailyMixCard({required this.mix});

  @override
  ConsumerState<_DailyMixCard> createState() => _DailyMixCardState();
}

class _DailyMixCardState extends ConsumerState<_DailyMixCard> {
  bool _isLoading = false;
  List<Track> _tracks = [];

  Future<void> _loadAndPlay() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final ytMusic = YtMusicService();
      await ytMusic.init();
      
      // Search for tracks based on mix queries
      final allTracks = <Track>[];
      for (final query in widget.mix.searchQueries.take(2)) {
        final results = await ytMusic.searchSongs(query, limit: 10);
        allTracks.addAll(results);
      }
      
      // Remove duplicates and shuffle
      final uniqueTracks = <String, Track>{};
      for (final track in allTracks) {
        uniqueTracks[track.id] = track;
      }
      
      _tracks = uniqueTracks.values.toList()..shuffle();
      
      if (_tracks.isNotEmpty) {
        final audioService = ref.read(audioPlayerServiceProvider);
        await audioService.playAll(_tracks);
      }
    } catch (e) {
      debugPrint('DailyMixCard: Error loading mix: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ${widget.mix.name}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loadAndPlay,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(widget.mix.gradient[0]),
              Color(widget.mix.gradient[1]),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(widget.mix.gradient[0]).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Text(
                    widget.mix.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    widget.mix.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(4),
                  // Description
                  Text(
                    widget.mix.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Play button
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(
                        Iconsax.play5,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily Mix Detail Page - shows tracks in a specific mix
class DailyMixDetailPage extends ConsumerStatefulWidget {
  final DailyMix mix;

  const DailyMixDetailPage({super.key, required this.mix});

  @override
  ConsumerState<DailyMixDetailPage> createState() => _DailyMixDetailPageState();
}

class _DailyMixDetailPageState extends ConsumerState<DailyMixDetailPage> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final ytMusic = YtMusicService();
      await ytMusic.init();
      
      final allTracks = <Track>[];
      for (final query in widget.mix.searchQueries) {
        final results = await ytMusic.searchSongs(query, limit: 10);
        allTracks.addAll(results);
      }
      
      // Remove duplicates
      final uniqueTracks = <String, Track>{};
      for (final track in allTracks) {
        uniqueTracks[track.id] = track;
      }
      
      setState(() {
        _tracks = uniqueTracks.values.toList()..shuffle();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DailyMixDetailPage: Error loading tracks: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.mix.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(widget.mix.gradient[0]),
                      Color(widget.mix.gradient[1]).withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.mix.icon,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),
          
          // Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.mix.description,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Play all button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _tracks.isEmpty ? null : () {
                      final audioService = ref.read(audioPlayerServiceProvider);
                      audioService.playAll(_tracks);
                    },
                    icon: const Icon(Iconsax.play5),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Gap(12),
                  OutlinedButton.icon(
                    onPressed: _tracks.isEmpty ? null : () {
                      final audioService = ref.read(audioPlayerServiceProvider);
                      final shuffled = List<Track>.from(_tracks)..shuffle();
                      audioService.playAll(shuffled);
                    },
                    icon: const Icon(Iconsax.shuffle),
                    label: const Text('Shuffle'),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverGap(16),
          
          // Tracks list
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _tracks[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: track.thumbnailUrl ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music, color: Colors.grey),
                        ),
                      ),
                    ),
                    title: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Iconsax.play5, size: 20),
                      onPressed: () {
                        final audioService = ref.read(audioPlayerServiceProvider);
                        audioService.playAll(_tracks, startIndex: index);
                      },
                    ),
                    onTap: () {
                      final audioService = ref.read(audioPlayerServiceProvider);
                      audioService.playAll(_tracks, startIndex: index);
                    },
                  );
                },
                childCount: _tracks.length,
              ),
            ),
          
          const SliverGap(100),
        ],
      ),
    );
  }
}
