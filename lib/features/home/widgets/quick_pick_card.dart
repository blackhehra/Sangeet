import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sangeet/core/theme/app_theme.dart';

class QuickPickCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback? onTap;
  final Gradient? imageGradient;
  final IconData? icon;

  const QuickPickCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.onTap,
    this.imageGradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Image or Gradient
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: imageGradient != null
                  ? Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(gradient: imageGradient),
                      child: icon != null
                          ? Icon(icon, color: Colors.white, size: 28)
                          : null,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppTheme.darkCard,
                        highlightColor: AppTheme.darkCardHover,
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppTheme.darkCard,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.darkCard,
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
