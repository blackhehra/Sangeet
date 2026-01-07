import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/palette_provider.dart';
import 'package:sangeet/features/lyrics/widgets/synced_lyrics_view.dart';

/// Full-screen lyrics page similar to Spotify's lyrics view
class LyricsPage extends ConsumerStatefulWidget {
  final String? trackId;
  final String? trackTitle;
  final String? trackArtist;
  final bool embedded; // For desktop full player - no scaffold, no controls

  const LyricsPage({
    super.key,
    this.trackId,
    this.trackTitle,
    this.trackArtist,
    this.embedded = false,
  });

  @override
  ConsumerState<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends ConsumerState<LyricsPage> {
  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final audioService = ref.watch(audioPlayerServiceProvider);
    
    // Get colors from album art palette
    final dominantColor = ref.watch(dominantColorProvider);
    final bgColor = ref.watch(dominantColorDarkProvider);
    final textColor = ref.watch(lyricsTextColorProvider);
    final secondaryTextColor = ref.watch(lyricsSecondaryTextColorProvider);

    // Embedded mode for desktop full player - just show lyrics
    if (widget.embedded) {
      return Container(
        color: Colors.transparent,
        child: SyncedLyricsView(
          activeColor: Colors.white,
          inactiveColor: Colors.grey.shade500,
          fontSize: 24,
          showControls: false,
        ),
      );
    }

    if (currentTrack == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_down_1),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.music, size: 64, color: Colors.grey.shade600),
              const Gap(16),
              Text(
                'No track playing',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dominantColor.withValues(alpha: 0.8),
              bgColor,
              AppTheme.darkBg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Iconsax.arrow_down_1),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'LYRICS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            currentTrack.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Lyrics view
              Expanded(
                child: SyncedLyricsView(
                  activeColor: textColor,
                  inactiveColor: secondaryTextColor,
                  fontSize: 22,
                  showControls: true,
                ),
              ),

              // Mini player controls at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: currentTrack.thumbnailUrl ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 48,
                          height: 48,
                          color: AppTheme.darkCard,
                          child: const Icon(Iconsax.music, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                    const Gap(12),
                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentTrack.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentTrack.artist,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    IconButton(
                      onPressed: () => audioService.skipToPrevious(),
                      icon: const Icon(Iconsax.previous, size: 24),
                    ),
                    IconButton(
                      onPressed: () => audioService.togglePlayPause(),
                      icon: Icon(
                        isPlaying ? Iconsax.pause : Iconsax.play,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: () => audioService.skipToNext(),
                      icon: const Icon(Iconsax.next, size: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
