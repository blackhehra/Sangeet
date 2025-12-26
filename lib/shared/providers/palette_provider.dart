import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';

/// Provider that extracts the dominant color from the current track's album art
final albumPaletteProvider = FutureProvider<PaletteGenerator?>((ref) async {
  final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
  
  if (currentTrack == null || currentTrack.thumbnailUrl == null || currentTrack.thumbnailUrl!.isEmpty) {
    return null;
  }
  
  try {
    final imageProvider = NetworkImage(currentTrack.thumbnailUrl!);
    final palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      size: const Size(100, 100), // Use smaller size for faster processing
      maximumColorCount: 16,
    );
    return palette;
  } catch (e) {
    print('PaletteProvider: Error extracting palette: $e');
    return null;
  }
});

/// Provider for the dominant color from album art
final dominantColorProvider = Provider<Color>((ref) {
  final palette = ref.watch(albumPaletteProvider).valueOrNull;
  
  if (palette == null) {
    return const Color(0xFF3D2A1F); // Default warm brown
  }
  
  // Try to get the most vibrant/dominant color
  // Priority: vibrantColor > dominantColor > mutedColor > default
  final color = palette.vibrantColor?.color ??
      palette.dominantColor?.color ??
      palette.mutedColor?.color ??
      const Color(0xFF3D2A1F);
  
  return color;
});

/// Provider for a darkened version of the dominant color (for backgrounds)
final dominantColorDarkProvider = Provider<Color>((ref) {
  final color = ref.watch(dominantColorProvider);
  
  // Darken the color for better readability
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness * 0.4).clamp(0.1, 0.3)).toColor();
});

/// Provider for text color that contrasts with the dominant color
final lyricsTextColorProvider = Provider<Color>((ref) {
  final bgColor = ref.watch(dominantColorDarkProvider);
  
  // Calculate luminance to determine if we need light or dark text
  final luminance = bgColor.computeLuminance();
  
  if (luminance > 0.5) {
    return Colors.black87;
  } else {
    return Colors.white;
  }
});

/// Provider for secondary/inactive text color
final lyricsSecondaryTextColorProvider = Provider<Color>((ref) {
  final textColor = ref.watch(lyricsTextColorProvider);
  return textColor.withValues(alpha: 0.6);
});
