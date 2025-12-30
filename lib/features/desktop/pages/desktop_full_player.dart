import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/services/play_history_service.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/features/lyrics/pages/lyrics_page.dart';
import 'package:sangeet/features/desktop/widgets/desktop_player_bar.dart';

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Desktop Full Player - Shows cover image with bottom player bar
class DesktopFullPlayer extends ConsumerStatefulWidget {
  const DesktopFullPlayer({super.key});

  @override
  ConsumerState<DesktopFullPlayer> createState() => _DesktopFullPlayerState();
}

class _DesktopFullPlayerState extends ConsumerState<DesktopFullPlayer> {
  bool _showLyrics = false;
  Track? _currentTrack;
  bool _isLiked = false;

  String _getHighQualityThumbnail(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('https://lh3.googleusercontent.com')) {
      return '$url-w720-h720';
    }
    if (url.startsWith('https://yt3.ggpht.com')) {
      return '$url-w720-h720-s720';
    }
    return url;
  }

  String _getFallbackThumbnail(String url) {
    if (url.contains('maxresdefault.jpg')) {
      return url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg');
    }
    return url;
  }

  /// Extract dominant color from image for background
  Color _getDominantColor(String? imageUrl) {
    // Default gradient color - can be enhanced with palette_generator
    return const Color(0xFF2D1F1F);
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: currentTrack.when(
        data: (track) {
          if (track == null) {
            return const Center(
              child: Text('No track playing', style: TextStyle(color: Colors.grey)),
            );
          }

          // Update like status when track changes
          if (_currentTrack?.id != track.id) {
            _currentTrack = track;
            _isLiked = PlayHistoryService.instance.isLiked(track.id);
          }

          final bgColor = _getDominantColor(track.thumbnailUrl);

          return Stack(
            children: [
              // Background gradient based on album art
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor,
                      bgColor.withOpacity(0.6),
                      const Color(0xFF121212),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  // Top bar with tabs
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Close button
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Iconsax.arrow_down_1, size: 24),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Cover / Lyrics toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTabButton('Cover', !_showLyrics, () {
                                  setState(() => _showLyrics = false);
                                }),
                                _buildTabButton('Lyrics', _showLyrics, () {
                                  setState(() => _showLyrics = true);
                                }),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // More options
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Iconsax.more, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content area - Cover or Lyrics
                  Expanded(
                    child: _showLyrics
                        ? _buildLyricsView(track)
                        : _buildCoverView(track, size),
                  ),

                  // Bottom player bar
                  const DesktopPlayerBar(),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading player')),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverView(Track track, Size size) {
    // Calculate cover size
    final coverSize = size.height * 0.45; // About 45% of screen height
    final maxCoverSize = 400.0; // Max size cap
    final actualCoverSize = coverSize.clamp(200.0, maxCoverSize);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album cover with shadow
          Container(
            width: actualCoverSize,
            height: actualCoverSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _getHighQualityThumbnail(track.thumbnailUrl ?? ''),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: _getFallbackThumbnail(url),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          const Gap(32),

          // Track info
          Text(
            track.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(8),
          Text(
            track.artist,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Gap(24),

          // About the artist section (simplified)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Artist avatar placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Iconsax.user, color: Colors.grey, size: 24),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About the artist',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        track.artist,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsView(Track track) {
    return LyricsPage(
      trackId: track.id,
      trackTitle: track.title,
      trackArtist: track.artist,
      embedded: true,
    );
  }
}
