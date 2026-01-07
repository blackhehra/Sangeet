import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/music_recognition_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/auto_queue_service.dart';

/// Music Recognition Page
/// Shazam-like interface for identifying music
class MusicRecognitionPage extends ConsumerStatefulWidget {
  const MusicRecognitionPage({super.key});

  @override
  ConsumerState<MusicRecognitionPage> createState() => _MusicRecognitionPageState();
}

class _MusicRecognitionPageState extends ConsumerState<MusicRecognitionPage>
    with SingleTickerProviderStateMixin {
  final MusicRecognitionService _recognitionService = MusicRecognitionService.instance;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _lyricsController = TextEditingController();
  List<Track> _lyricsResults = [];
  bool _showLyricsSearch = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _recognitionService.addListener(_onRecognitionStateChanged);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lyricsController.dispose();
    _recognitionService.removeListener(_onRecognitionStateChanged);
    super.dispose();
  }

  void _onRecognitionStateChanged() {
    if (mounted) {
      setState(() {});
      
      if (_recognitionService.state == RecognitionState.listening ||
          _recognitionService.state == RecognitionState.processing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  Future<void> _startRecognition() async {
    final result = await _recognitionService.startRecognition();
    
    if (mounted) {
      if (result.success && result.track != null) {
        _showFoundDialog(result.track!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            action: SnackBarAction(
              label: 'Try Lyrics',
              onPressed: () {
                setState(() => _showLyricsSearch = true);
              },
            ),
          ),
        );
      }
    }
  }

  void _showFoundDialog(Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoundTrackSheet(
        track: track,
        onPlay: () {
          Navigator.pop(context);
          final audioService = ref.read(audioPlayerServiceProvider);
          audioService.play(track, source: PlaySource.musicRecognition);
        },
      ),
    );
  }

  Future<void> _searchByLyrics() async {
    if (_lyricsController.text.trim().isEmpty) return;
    
    final results = await _recognitionService.searchByLyrics(_lyricsController.text);
    setState(() {
      _lyricsResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _recognitionService.state;
    final isListening = state == RecognitionState.listening ||
        state == RecognitionState.processing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identify Music'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showLyricsSearch = !_showLyricsSearch;
                _lyricsResults.clear();
              });
            },
            icon: Icon(
              _showLyricsSearch ? Iconsax.microphone : Iconsax.document_text,
            ),
            tooltip: _showLyricsSearch ? 'Audio Recognition' : 'Search by Lyrics',
          ),
        ],
      ),
      body: _showLyricsSearch ? _buildLyricsSearch() : _buildAudioRecognition(isListening),
    );
  }

  Widget _buildAudioRecognition(bool isListening) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated recognition button
          GestureDetector(
            onTap: isListening ? _recognitionService.cancelRecognition : _startRecognition,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isListening
                            ? [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)]
                            : [const Color(0xFF2E2E2E), const Color(0xFF1E1E1E)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isListening
                              ? AppTheme.primaryColor.withOpacity(0.4)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: isListening ? 30 : 20,
                          spreadRadius: isListening ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Iconsax.sound : Iconsax.microphone_2,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Gap(32),
          
          // Status text
          Text(
            _recognitionService.statusMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Gap(8),
          
          // Subtitle
          Text(
            isListening
                ? 'Make sure the music is playing clearly'
                : 'Tap to identify what\'s playing',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          
          const Gap(48),
          
          // Alternative options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AlternativeOption(
                icon: Iconsax.document_text,
                label: 'Search by Lyrics',
                onTap: () {
                  setState(() => _showLyricsSearch = true);
                },
              ),
              const Gap(32),
              _AlternativeOption(
                icon: Iconsax.microphone,
                label: 'Hum to Search',
                onTap: () async {
                  final result = await _recognitionService.recognizeHumming();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message)),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsSearch() {
    return Column(
      children: [
        // Search input
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search by Lyrics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Text(
                'Type some lyrics you remember and we\'ll find the song',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const Gap(16),
              TextField(
                controller: _lyricsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter lyrics here...',
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _searchByLyrics,
                    icon: const Icon(Iconsax.search_normal),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByLyrics(),
              ),
            ],
          ),
        ),
        
        // Results
        Expanded(
          child: _recognitionService.state == RecognitionState.processing
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : _lyricsResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.music_filter,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const Gap(16),
                          Text(
                            'Enter lyrics to search',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _lyricsResults.length,
                      itemBuilder: (context, index) {
                        final track = _lyricsResults[index];
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
                            icon: const Icon(Iconsax.play5),
                            onPressed: () {
                              final audioService = ref.read(audioPlayerServiceProvider);
                              audioService.play(track, source: PlaySource.lyricsSearch);
                            },
                          ),
                          onTap: () {
                            final audioService = ref.read(audioPlayerServiceProvider);
                            audioService.play(track, source: PlaySource.lyricsSearch);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _AlternativeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AlternativeOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundTrackSheet extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;

  const _FoundTrackSheet({
    required this.track,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),
          
          // Found indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.tick_circle5, color: AppTheme.primaryColor, size: 20),
                Gap(8),
                Text(
                  'Found!',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: track.thumbnailUrl ?? '',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 150,
                height: 150,
                color: AppTheme.darkBg,
                child: const Icon(Iconsax.music, size: 48, color: Colors.grey),
              ),
            ),
          ),
          const Gap(16),
          
          // Track info
          Text(
            track.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          Text(
            track.artist,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          
          // Play button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              icon: const Icon(Iconsax.play5),
              label: const Text('Play Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}
