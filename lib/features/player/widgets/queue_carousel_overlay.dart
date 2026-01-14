import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/audio_player_service.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';

/// An inline carousel that replaces the album art section
/// Shows queue items as a horizontal scrollable list with cascade effect
/// The main album art shrinks into this carousel on long press
class InlineQueueCarousel extends ConsumerStatefulWidget {
  final double animationValue; // 0.0 = normal view, 1.0 = carousel view
  final VoidCallback onClose;
  final VoidCallback onSongSelected;
  final double normalArtSize; // Size of the normal album art
  final bool isBuffering;

  const InlineQueueCarousel({
    super.key,
    required this.animationValue,
    required this.onClose,
    required this.onSongSelected,
    required this.normalArtSize,
    this.isBuffering = false,
  });

  @override
  ConsumerState<InlineQueueCarousel> createState() => _InlineQueueCarouselState();
}

class _InlineQueueCarouselState extends ConsumerState<InlineQueueCarousel> {
  PageController? _pageController;
  double _currentPage = 0;
  int _selectedIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initPageController();
      _initialized = true;
    }
  }

  void _initPageController() {
    final audioService = ref.read(audioPlayerServiceProvider);
    _selectedIndex = audioService.currentIndex;
    _currentPage = _selectedIndex.toDouble();
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.38, // Increased for larger photos
    );
    _pageController!.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (_pageController?.hasClients ?? false) {
      setState(() {
        _currentPage = _pageController!.page ?? _currentPage;
        _selectedIndex = _currentPage.round();
      });
    }
  }

  @override
  void dispose() {
    _pageController?.removeListener(_onPageChanged);
    _pageController?.dispose();
    super.dispose();
  }

  String _getHighQualityThumbnail(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('https://lh3.googleusercontent.com')) {
      return '$url-w480-h480';
    }
    if (url.startsWith('https://yt3.ggpht.com')) {
      return '$url-w480-h480-s480';
    }
    return url;
  }

  void _onItemTap(int index, AudioPlayerService audioService) {
    if (index == _selectedIndex) {
      // Tap on center item - play and close
      audioService.skipToIndex(index);
      widget.onSongSelected();
    } else {
      // Tap on side item - animate to center
      _pageController?.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final queue = audioService.queue;
    final currentTrack = queue.isNotEmpty && audioService.currentIndex < queue.length
        ? queue[audioService.currentIndex]
        : null;

    if (queue.isEmpty || currentTrack == null) {
      return SizedBox(
        width: widget.normalArtSize,
        height: widget.normalArtSize,
      );
    }

    final animValue = widget.animationValue;
    
    // Sizes interpolation
    final carouselItemSize = widget.normalArtSize * 0.42;
    final currentSize = widget.normalArtSize * (1.0 - animValue * 0.62); // Shrinks to ~38%
    final centerElevation = 25.0 * animValue;
    
    // When not in carousel mode, show normal album art
    if (animValue < 0.01) {
      return _buildNormalAlbumArt(currentTrack, audioService);
    }

    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: widget.normalArtSize + 80,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Carousel (fades in as animation progresses)
            Opacity(
              opacity: animValue,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: widget.normalArtSize + 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Spacer for elevation room at top + shift downward
                    SizedBox(height: centerElevation + 80),
                    
                    // Carousel
                    SizedBox(
                      height: carouselItemSize + 50,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: queue.length,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        pageSnapping: false,
                        itemBuilder: (context, index) {
                          return _buildCarouselItem(
                            track: queue[index],
                            index: index,
                            itemSize: carouselItemSize,
                            centerElevation: centerElevation,
                            audioService: audioService,
                          );
                        },
                      ),
                    ),
                    
                    // Queue position
                    Text(
                      '${_selectedIndex + 1} / ${queue.length}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main album art (shrinks and fades out)
            if (animValue < 0.99)
              Opacity(
                opacity: 1.0 - animValue,
                child: Transform.scale(
                  scale: 1.0 - (animValue * 0.6),
                  child: _buildNormalAlbumArt(currentTrack, audioService),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalAlbumArt(Track track, AudioPlayerService audioService) {
    return Container(
      width: widget.normalArtSize,
      height: widget.normalArtSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: _getHighQualityThumbnail(track.thumbnailUrl ?? ''),
              width: widget.normalArtSize,
              height: widget.normalArtSize,
              fit: BoxFit.cover,
              memCacheWidth: 1080,
              memCacheHeight: 1080,
              errorWidget: (context, url, error) => Container(
                color: AppTheme.darkCard,
                child: const Icon(Iconsax.music, size: 80, color: Colors.grey),
              ),
            ),
            if (widget.isBuffering)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem({
    required Track track,
    required int index,
    required double itemSize,
    required double centerElevation,
    required AudioPlayerService audioService,
  }) {
    final distance = (index - _currentPage).abs();
    final isCenter = distance < 0.5;
    final isCurrent = index == audioService.currentIndex;
    
    final scale = 1.0 - (distance * 0.2).clamp(0.0, 0.2);
    final elevation = centerElevation * (1.0 - distance.clamp(0.0, 1.0));
    final opacity = 1.0 - (distance * 0.35).clamp(0.0, 0.5);

    return GestureDetector(
      onTap: () => _onItemTap(index, audioService),
      child: Transform.translate(
        offset: Offset(0, -elevation),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: isCenter ? 15 : 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: isCurrent
                        ? Border.all(color: AppTheme.primaryColor, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _getHighQualityThumbnail(track.thumbnailUrl ?? ''),
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          memCacheHeight: 400,
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.darkCard,
                            child: const Icon(Iconsax.music, size: 30, color: Colors.grey),
                          ),
                        ),
                        if (isCurrent)
                          Positioned(
                            bottom: 3,
                            right: 3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(Iconsax.music_play5, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isCenter ? 1.0 : 0.0,
                  child: SizedBox(
                    width: itemSize + 16,
                    child: Column(
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          track.artist,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
