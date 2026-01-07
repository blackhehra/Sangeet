import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GenreCard extends StatelessWidget {
  final String title;
  final Color color;
  final String imageUrl;
  final VoidCallback? onTap;

  const GenreCard({
    super.key,
    required this.title,
    required this.color,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Title
            Positioned(
              top: 12,
              left: 12,
              right: 50,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Image (rotated)
            Positioned(
              right: -15,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(-2, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: color.withOpacity(0.8),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
