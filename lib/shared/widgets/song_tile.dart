import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/audio_provider.dart';
import 'package:sangeet/shared/widgets/playing_indicator.dart';

/// Reusable song tile widget with playing indicator (like Spotify)
/// Shows animated equalizer bars when the song is currently playing
class SongTile extends ConsumerWidget {
  final Track track;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool showDuration;
  final bool showThumbnail;
  final int? index; // Optional track number to show instead of thumbnail

  const SongTile({
    super.key,
    required this.track,
    required this.onTap,
    this.leading,
    this.trailing,
    this.showDuration = true,
    this.showThumbnail = true,
    this.index,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final isCurrentTrack = currentTrack?.id == track.id;
    final audioService = ref.read(audioPlayerServiceProvider);

    return ListTile(
      onTap: isCurrentTrack 
          ? () {
              // Toggle play/pause for current track
              if (isPlaying) {
                audioService.pause();
              } else {
                audioService.resume();
              }
            }
          : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading ?? _buildLeading(isCurrentTrack, isPlaying),
      title: Row(
        children: [
          // Show playing indicator for current track
          if (isCurrentTrack) ...[
            PlayingIndicator(
              isPlaying: isPlaying,
              size: 14,
              color: AppTheme.primaryColor,
            ),
            const Gap(8),
          ],
          Expanded(
            child: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCurrentTrack ? AppTheme.primaryColor : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
      trailing: trailing ?? _buildTrailing(ref, isCurrentTrack, isPlaying),
    );
  }

  Widget _buildLeading(bool isCurrentTrack, bool isPlaying) {
    // Show track number if provided
    if (index != null) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: isCurrentTrack
            ? PlayingIndicator(
                isPlaying: isPlaying,
                size: 16,
                color: AppTheme.primaryColor,
              )
            : Text(
                '${index! + 1}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
      );
    }

    // Show thumbnail
    if (showThumbnail) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 48,
          height: 48,
          child: track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: track.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.darkCard),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, color: Colors.grey),
                  ),
                )
              : Container(
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.music, color: Colors.grey),
                ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrailing(WidgetRef ref, bool isCurrentTrack, bool isPlaying) {
    final audioService = ref.read(audioPlayerServiceProvider);
    
    if (isCurrentTrack) {
      return IconButton(
        onPressed: () {
          if (isPlaying) {
            audioService.pause();
          } else {
            audioService.resume();
          }
        },
        icon: Icon(
          isPlaying ? Iconsax.pause5 : Iconsax.play5,
          size: 20,
          color: AppTheme.primaryColor,
        ),
      );
    }
    
    return IconButton(
      onPressed: () {
        // TODO: Show track options menu
      },
      icon: const Icon(Iconsax.more, size: 20),
    );
  }
}

/// Song tile for Spotify tracks (uses SpotifyTrack model)
class SpotifySongTile extends ConsumerWidget {
  final String trackId;
  final String trackName;
  final String artistName;
  final String? imageUrl;
  final VoidCallback onTap;
  final Widget? trailing;

  const SpotifySongTile({
    super.key,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    this.imageUrl,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    // Match by title since Spotify track IDs differ from YouTube IDs
    final isCurrentTrack = currentTrack?.title.toLowerCase() == trackName.toLowerCase();

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 48,
          height: 48,
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.darkCard),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, color: Colors.grey),
                  ),
                )
              : Container(
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.music, color: Colors.grey),
                ),
        ),
      ),
      title: Row(
        children: [
          if (isCurrentTrack) ...[
            PlayingIndicator(
              isPlaying: isPlaying,
              size: 14,
              color: AppTheme.primaryColor,
            ),
            const Gap(8),
          ],
          Expanded(
            child: Text(
              trackName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCurrentTrack ? AppTheme.primaryColor : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
      trailing: trailing ?? Icon(
        isCurrentTrack ? (isPlaying ? Iconsax.pause5 : Iconsax.play5) : Iconsax.more,
        size: 20,
        color: isCurrentTrack ? AppTheme.primaryColor : null,
      ),
    );
  }
}
