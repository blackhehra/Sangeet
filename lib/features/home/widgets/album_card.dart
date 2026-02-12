import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sangeet/core/theme/app_theme.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isCircular;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;

  const AlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.isCircular = false,
    this.onTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with play button overlay
            Stack(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isCircular ? 75 : 8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isCircular ? 75 : 8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      memCacheHeight: 300,
                      placeholder: (context, url) => Container(
                        color: AppTheme.darkCard,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.darkCard,
                        child: const Icon(
                          Iconsax.music,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                // Play button on hover (always visible on mobile)
                if (!isCircular)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: onPlayTap,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          ),
                        child: const Icon(
                          Iconsax.play5,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
