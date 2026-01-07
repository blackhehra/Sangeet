import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/lyrics.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/providers/lyrics_provider.dart';

/// Widget that displays synced lyrics with auto-scroll
class SyncedLyricsView extends ConsumerStatefulWidget {
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? fontSize;
  final bool showControls;

  const SyncedLyricsView({
    super.key,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.fontSize,
    this.showControls = true,
  });

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView> {
  late AutoScrollController _scrollController;
  int _lastActiveIndex = -1;
  double _textZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentLyricsProvider);
    final activeIndex = ref.watch(activeLyricIndexProvider);
    final delay = ref.watch(lyricsDelayProvider);

    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.lyrics.isEmpty) {
          return _buildNoLyrics(context);
        }

        // Check if lyrics are synced
        if (!lyrics.isSynced) {
          return _buildPlainLyrics(context, lyrics);
        }

        // Auto-scroll to active lyric
        if (activeIndex != _lastActiveIndex && activeIndex >= 0) {
          _lastActiveIndex = activeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.scrollToIndex(
                activeIndex,
                preferPosition: AutoScrollPosition.middle,
                duration: const Duration(milliseconds: 300),
              );
            }
          });
        }

        return Stack(
          children: [
            // Lyrics list
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              itemCount: lyrics.lyrics.length,
              itemBuilder: (context, index) {
                final lyric = lyrics.lyrics[index];
                final isActive = index == activeIndex;

                return AutoScrollTag(
                  key: ValueKey(index),
                  controller: _scrollController,
                  index: index,
                  child: _buildLyricLine(
                    context,
                    lyric,
                    isActive,
                    delay,
                    index == lyrics.lyrics.length - 1,
                  ),
                );
              },
            ),

            // Controls
            if (widget.showControls)
              Positioned(
                right: 16,
                bottom: 16,
                child: _buildControls(context, delay),
              ),

          ],
        );
      },
      loading: () => _buildLoading(context),
      error: (error, _) => _buildNoLyrics(context),
    );
  }

  Widget _buildLyricLine(
    BuildContext context,
    LyricSlice lyric,
    bool isActive,
    int delay,
    bool isLast,
  ) {
    if (lyric.text.isEmpty) {
      return const SizedBox(height: 32);
    }

    final activeColor = widget.activeColor ?? Colors.white;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade500;
    final baseFontSize = widget.fontSize ?? 24.0;

    return GestureDetector(
      onTap: () {
        // Seek to this lyric's timestamp
        final audioService = ref.read(audioPlayerServiceProvider);
        final seekTime = Duration(seconds: lyric.time.inSeconds - delay);
        if (!seekTime.isNegative) {
          audioService.seek(seekTime);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isActive ? 16 : 12,
        ).copyWith(bottom: isLast ? 100 : null),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: (isActive ? baseFontSize + 4 : baseFontSize) * _textZoom,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : inactiveColor,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          child: Text(lyric.text),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, int delay) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delay controls
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  ref.read(lyricsDelayProvider.notifier).state = delay - 1;
                },
                icon: const Icon(Iconsax.minus, size: 16),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Text(
                '${delay}s',
                style: const TextStyle(fontSize: 12),
              ),
              IconButton(
                onPressed: () {
                  ref.read(lyricsDelayProvider.notifier).state = delay + 1;
                },
                icon: const Icon(Iconsax.add, size: 16),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Zoom controls
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _textZoom > 0.6 ? () {
                  setState(() => _textZoom -= 0.1);
                } : null,
                icon: const Icon(Iconsax.text, size: 14),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: _textZoom < 1.5 ? () {
                  setState(() => _textZoom += 0.1);
                } : null,
                icon: const Icon(Iconsax.text_bold, size: 18),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlainLyrics(BuildContext context, SubtitleSimple lyrics) {
    final textColor = widget.inactiveColor ?? Colors.grey.shade300;
    final baseFontSize = widget.fontSize ?? 20.0;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Plain Lyrics (not synced)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                lyrics.lyrics.map((l) => l.text).join('\n'),
                style: TextStyle(
                  fontSize: baseFontSize * _textZoom,
                  color: textColor,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoLyrics(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.music,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'No lyrics available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lyrics will appear here when available',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading lyrics...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
