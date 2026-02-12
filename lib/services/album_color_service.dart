import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Album Color Service
/// Extracts dominant colors from album art for dynamic theming
class AlbumColorService {
  static AlbumColorService? _instance;
  static AlbumColorService get instance => _instance ??= AlbumColorService._();
  
  AlbumColorService._();

  final Map<String, AlbumColors> _colorCache = {};
  static const int _maxCacheSize = 50;

  /// Get colors for an album art URL
  /// Returns cached result if available, otherwise extracts colors
  Future<AlbumColors> getColorsForImage(String imageUrl) async {
    if (imageUrl.isEmpty) {
      return AlbumColors.defaultColors;
    }

    // Check cache first
    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl]!;
    }

    try {
      // Run palette extraction off the main isolate to avoid UI jank
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(50, 50), // Smaller size for faster processing
        maximumColorCount: 8,
        timeout: const Duration(seconds: 5),
      );

      final colors = AlbumColors(
        dominant: paletteGenerator.dominantColor?.color ?? const Color(0xFF1E1E1E),
        vibrant: paletteGenerator.vibrantColor?.color,
        darkVibrant: paletteGenerator.darkVibrantColor?.color,
        lightVibrant: paletteGenerator.lightVibrantColor?.color,
        muted: paletteGenerator.mutedColor?.color,
        darkMuted: paletteGenerator.darkMutedColor?.color ?? const Color(0xFF121212),
        lightMuted: paletteGenerator.lightMutedColor?.color,
      );

      // Cache the result
      _addToCache(imageUrl, colors);

      return colors;
    } catch (e) {
      debugPrint('AlbumColorService: Error extracting colors: $e');
      return AlbumColors.defaultColors;
    }
  }

  /// Get a gradient for the mini player based on album colors
  List<Color> getMiniPlayerGradient(AlbumColors colors) {
    final baseColor = colors.darkVibrant ?? colors.darkMuted ?? colors.dominant;
    
    return [
      baseColor.withValues(alpha: 0.95),
      _darken(baseColor, 0.3).withValues(alpha: 0.98),
    ];
  }

  /// Get a gradient for the full player page
  List<Color> getPlayerGradient(AlbumColors colors) {
    final topColor = colors.darkVibrant ?? colors.muted ?? colors.dominant;
    final bottomColor = const Color(0xFF121212);
    
    return [
      _adjustBrightness(topColor, 0.4),
      bottomColor,
    ];
  }

  /// Get text color that contrasts well with the background
  Color getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Get secondary text color
  Color getSecondaryTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 
        ? Colors.black.withValues(alpha: 0.7) 
        : Colors.white.withValues(alpha: 0.7);
  }

  /// Get accent color for controls
  Color getAccentColor(AlbumColors colors) {
    return colors.vibrant ?? colors.lightVibrant ?? colors.dominant;
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Color _adjustBrightness(Color color, double targetBrightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(targetBrightness.clamp(0.0, 1.0)).toColor();
  }

  void _addToCache(String key, AlbumColors colors) {
    if (_colorCache.length >= _maxCacheSize) {
      // Remove oldest entry
      _colorCache.remove(_colorCache.keys.first);
    }
    _colorCache[key] = colors;
  }

  /// Clear the color cache
  void clearCache() {
    _colorCache.clear();
  }

  /// Preload colors for a list of image URLs
  Future<void> preloadColors(List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (!_colorCache.containsKey(url)) {
        await getColorsForImage(url);
      }
    }
  }
}

class AlbumColors {
  final Color dominant;
  final Color? vibrant;
  final Color? darkVibrant;
  final Color? lightVibrant;
  final Color? muted;
  final Color? darkMuted;
  final Color? lightMuted;

  const AlbumColors({
    required this.dominant,
    this.vibrant,
    this.darkVibrant,
    this.lightVibrant,
    this.muted,
    this.darkMuted,
    this.lightMuted,
  });

  static const AlbumColors defaultColors = AlbumColors(
    dominant: Color(0xFF1E1E1E),
    darkMuted: Color(0xFF121212),
  );

  /// Get the best background color for the mini player
  Color get miniPlayerBackground {
    return darkVibrant ?? darkMuted ?? dominant;
  }

  /// Get the best accent color
  Color get accent {
    return vibrant ?? lightVibrant ?? dominant;
  }

  /// Check if colors are dark enough for white text
  bool get isDark {
    return dominant.computeLuminance() < 0.5;
  }
}
