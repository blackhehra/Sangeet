import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/services/settings_service.dart';
import 'package:sangeet/services/song_source_preference_service.dart';
import 'package:sangeet/services/track_matcher_service.dart';
import 'package:sangeet/main.dart' show rootNavigatorKey;

/// Shows a bottom sheet menu for selecting the audio source for a song
/// This is used when user long-presses on a song
Future<void> showSongSourceMenu({
  required BuildContext context,
  required String songId,
  required String songTitle,
  required String artistName,
  VoidCallback? onSourceChanged,
}) async {
  final songSourcePrefService = SongSourcePreferenceService();
  await songSourcePrefService.init();
  
  final currentPref = songSourcePrefService.getPreferredSource(songId);
  
  if (!context.mounted) return;
  
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _SongSourceMenuContent(
      songId: songId,
      songTitle: songTitle,
      artistName: artistName,
      currentPreference: currentPref,
      onSourceChanged: onSourceChanged,
    ),
  );
}

class _SongSourceMenuContent extends ConsumerStatefulWidget {
  final String songId;
  final String songTitle;
  final String artistName;
  final MusicSource? currentPreference;
  final VoidCallback? onSourceChanged;

  const _SongSourceMenuContent({
    required this.songId,
    required this.songTitle,
    required this.artistName,
    this.currentPreference,
    this.onSourceChanged,
  });

  @override
  ConsumerState<_SongSourceMenuContent> createState() => _SongSourceMenuContentState();
}

class _SongSourceMenuContentState extends ConsumerState<_SongSourceMenuContent> {
  late MusicSource? _selectedSource;
  final _songSourcePrefService = SongSourcePreferenceService();
  final _trackMatcherService = TrackMatcherService();

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.currentPreference;
  }

  Future<void> _setSource(MusicSource? source) async {
    setState(() => _selectedSource = source);
    
    if (source == null) {
      // Reset to default
      await _songSourcePrefService.removePreference(widget.songId);
    } else {
      await _songSourcePrefService.setPreferredSource(widget.songId, source);
    }
    
    // Clear cache for this song so it will be re-matched
    _trackMatcherService.clearCacheForSong(widget.songId);
    
    widget.onSourceChanged?.call();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == null 
                ? 'Using default source for "${widget.songTitle}"'
                : 'Using ${source.label} for "${widget.songTitle}"',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultSource = ref.watch(musicSourceProvider);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Audio Source',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.songTitle} • ${widget.artistName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Choose where to get audio for this song. Use YouTube if the song is not available on YouTube Music.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Options
            _SourceOption(
              title: 'Default (${defaultSource.label})',
              subtitle: 'Use app default setting',
              icon: Iconsax.setting_2,
              isSelected: _selectedSource == null,
              onTap: () => _setSource(null),
            ),
            const SizedBox(height: 8),
            _SourceOption(
              title: 'YouTube Music',
              subtitle: 'Better for official music releases',
              icon: Iconsax.music,
              isSelected: _selectedSource == MusicSource.ytMusic,
              onTap: () => _setSource(MusicSource.ytMusic),
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 8),
            _SourceOption(
              title: 'YouTube',
              subtitle: 'For music videos and rare songs',
              icon: Iconsax.video,
              isSelected: _selectedSource == MusicSource.youtube,
              onTap: () => _setSource(MusicSource.youtube),
              color: Colors.red.shade900,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _SourceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? Colors.green).withOpacity(0.2)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (color ?? Colors.green)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? Colors.green).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color ?? Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Iconsax.tick_circle5,
                color: color ?? Colors.green,
              ),
          ],
        ),
      ),
    );
  }
}
