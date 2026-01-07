import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/shared/providers/lyrics_provider.dart';
import 'package:sangeet/shared/providers/palette_provider.dart';
import 'package:sangeet/features/lyrics/pages/lyrics_page.dart';

/// Mini lyrics card that shows current lyric line - can be embedded in player page
/// Similar to Spotify's lyrics preview card
class LyricsMiniCard extends ConsumerWidget {
  final Color? backgroundColor;
  final Color? textColor;

  const LyricsMiniCard({
    super.key,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsAsync = ref.watch(currentLyricsProvider);
    final activeIndex = ref.watch(activeLyricIndexProvider);
    
    // Get colors from album art palette
    final bgColor = ref.watch(dominantColorDarkProvider);
    final txtColor = ref.watch(lyricsTextColorProvider);
    final secondaryTxtColor = ref.watch(lyricsSecondaryTextColorProvider);

    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.lyrics.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get current and next few lyrics
        final currentLyrics = <String>[];
        if (activeIndex >= 0 && activeIndex < lyrics.lyrics.length) {
          // Add current line
          currentLyrics.add(lyrics.lyrics[activeIndex].text);
          
          // Add next 2 lines if available
          for (int i = 1; i <= 2; i++) {
            if (activeIndex + i < lyrics.lyrics.length) {
              final nextText = lyrics.lyrics[activeIndex + i].text;
              if (nextText.isNotEmpty) {
                currentLyrics.add(nextText);
              }
            }
          }
        } else if (lyrics.lyrics.isNotEmpty) {
          // Show first few lines if not started yet
          for (int i = 0; i < 3 && i < lyrics.lyrics.length; i++) {
            if (lyrics.lyrics[i].text.isNotEmpty) {
              currentLyrics.add(lyrics.lyrics[i].text);
            }
          }
        }

        if (currentLyrics.isEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LyricsPage(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Lyrics',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? txtColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Iconsax.arrow_up_2,
                      size: 16,
                      color: textColor ?? txtColor,
                    ),
                    Icon(
                      Iconsax.maximize_4,
                      size: 16,
                      color: textColor ?? txtColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Lyrics preview
                ...currentLyrics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  final isFirst = index == 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: isFirst ? 18 : 16,
                        fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                        color: isFirst 
                            ? (textColor ?? txtColor)
                            : (textColor ?? secondaryTxtColor),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              'Lyrics',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor ?? txtColor,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? txtColor,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
