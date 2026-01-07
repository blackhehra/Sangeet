import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/radio_service.dart';
import 'package:sangeet/services/mood_playlist_service.dart';
import 'package:sangeet/services/auto_queue_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/models/track.dart';

class RadioPage extends ConsumerStatefulWidget {
  const RadioPage({super.key});

  @override
  ConsumerState<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends ConsumerState<RadioPage> {
  final RadioService _radioService = RadioService();
  final MoodPlaylistService _moodService = MoodPlaylistService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio & Moods'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_radioService.isRadioActive)
            TextButton.icon(
              onPressed: () {
                _radioService.stopRadio();
                setState(() {});
              },
              icon: const Icon(Iconsax.stop, size: 18),
              label: const Text('Stop Radio'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Status Card
            if (_radioService.isRadioActive)
              _buildRadioStatusCard(),
            
            // Start Radio from Current Track
            if (currentTrack.valueOrNull != null && !_radioService.isRadioActive)
              _buildStartRadioCard(currentTrack.valueOrNull!),
            
            const Gap(24),
            
            // Mood Playlists Section
            _buildSectionHeader('Moods', Iconsax.emoji_happy),
            const Gap(12),
            _buildMoodGrid(),
            
            const Gap(24),
            
            // Activity Playlists Section
            _buildSectionHeader('Activities', Iconsax.activity),
            const Gap(12),
            _buildActivityGrid(),
            
            const Gap(24),
            
            // Time-based Suggestion
            _buildSectionHeader('For You Right Now', Iconsax.clock),
            const Gap(12),
            _buildTimeBasedSuggestion(),
            
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioStatusCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.3), AppTheme.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.radio, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Radio Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  _radioService.mode == RadioMode.track
                      ? 'Based on your current track'
                      : _radioService.mode == RadioMode.artist
                          ? 'Based on ${_radioService.seedArtist}'
                          : 'Genre radio',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Iconsax.music_play,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStartRadioCard(Track track) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: track.thumbnailUrl ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: AppTheme.darkSurface,
                    child: const Icon(Iconsax.music),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Radio',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _startTrackRadio(track),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.radio, size: 18),
                  label: const Text('Track Radio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _startArtistRadio(track.artist),
                  icon: const Icon(Iconsax.microphone, size: 18),
                  label: const Text('Artist Radio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const Gap(8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: MoodType.values.map((mood) {
        final info = MoodPlaylistService.getMoodInfo(mood);
        return _buildMoodCard(mood, info);
      }).toList(),
    );
  }

  Widget _buildMoodCard(MoodType mood, MoodInfo info) {
    return InkWell(
      onTap: () => _playMoodPlaylist(mood),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              info.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const Gap(8),
            Text(
              info.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: ActivityType.values.map((activity) {
        final info = MoodPlaylistService.getActivityInfo(activity);
        return _buildActivityCard(activity, info);
      }).toList(),
    );
  }

  Widget _buildActivityCard(ActivityType activity, ActivityInfo info) {
    return InkWell(
      onTap: () => _playActivityPlaylist(activity),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              info.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const Gap(8),
            Text(
              info.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBasedSuggestion() {
    final hour = DateTime.now().hour;
    String suggestion;
    String emoji;
    MoodType mood;

    if (hour >= 5 && hour < 9) {
      suggestion = 'Start your morning right';
      emoji = '🌅';
      mood = MoodType.morning;
    } else if (hour >= 9 && hour < 12) {
      suggestion = 'Focus and be productive';
      emoji = '🎯';
      mood = MoodType.focus;
    } else if (hour >= 12 && hour < 17) {
      suggestion = 'Keep the energy going';
      emoji = '⚡';
      mood = MoodType.energetic;
    } else if (hour >= 17 && hour < 21) {
      suggestion = 'Wind down and relax';
      emoji = '😌';
      mood = MoodType.chill;
    } else {
      suggestion = 'Time to rest';
      emoji = '🌙';
      mood = MoodType.sleep;
    }

    return InkWell(
      onTap: () => _playMoodPlaylist(mood),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.2),
              AppTheme.darkCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Tap to play ${MoodPlaylistService.getMoodInfo(mood).name} mix',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.play_circle, size: 32, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _startTrackRadio(Track track) async {
    setState(() => _isLoading = true);
    
    try {
      await _radioService.startTrackRadio(track);
      
      // Get initial tracks and start playing
      final tracks = await _radioService.getNextTracks(count: 10);
      if (tracks.isNotEmpty) {
        final audioService = ref.read(audioPlayerServiceProvider);
        // Radio has its own queue management, disable auto-queue
        await audioService.playAll([track, ...tracks], source: PlaySource.playlist);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Radio started! Similar tracks will be added automatically.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting radio: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startArtistRadio(String artist) async {
    setState(() => _isLoading = true);
    
    try {
      await _radioService.startArtistRadio(artist);
      
      final tracks = await _radioService.getNextTracks(count: 10);
      if (tracks.isNotEmpty) {
        final audioService = ref.read(audioPlayerServiceProvider);
        // Radio has its own queue management, disable auto-queue
        await audioService.playAll(tracks, source: PlaySource.playlist);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$artist radio started!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting radio: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playMoodPlaylist(MoodType mood) async {
    final info = MoodPlaylistService.getMoodInfo(mood);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loading ${info.name} playlist...')),
    );
    
    try {
      final tracks = await _moodService.getMoodPlaylist(mood, limit: 20);
      if (tracks.isNotEmpty) {
        final audioService = ref.read(audioPlayerServiceProvider);
        // Mood playlist - disable auto-queue
        await audioService.playAll(tracks, source: PlaySource.playlist);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tracks found for this mood')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlist: $e')),
        );
      }
    }
  }

  Future<void> _playActivityPlaylist(ActivityType activity) async {
    final info = MoodPlaylistService.getActivityInfo(activity);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loading ${info.name} playlist...')),
    );
    
    try {
      final tracks = await _moodService.getActivityPlaylist(activity, limit: 20);
      if (tracks.isNotEmpty) {
        final audioService = ref.read(audioPlayerServiceProvider);
        // Activity playlist - disable auto-queue
        await audioService.playAll(tracks, source: PlaySource.playlist);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tracks found for this activity')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlist: $e')),
        );
      }
    }
  }
}
