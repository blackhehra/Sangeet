import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/spotify_plugin_provider.dart';
import 'package:sangeet/models/spotify_models.dart';
import 'package:sangeet/features/playlist/widgets/create_playlist_dialog.dart';

class DesktopSidebar extends ConsumerWidget {
  final int selectedNavIndex;
  final Function(int) onNavSelected;
  final String? selectedPlaylistId;
  final bool isLikedSongsSelected;
  final Function(SpotifySimplePlaylist) onPlaylistSelected;
  final VoidCallback onLikedSongsSelected;
  final VoidCallback onHomeSelected;

  const DesktopSidebar({
    super.key,
    required this.selectedNavIndex,
    required this.onNavSelected,
    this.selectedPlaylistId,
    this.isLikedSongsSelected = false,
    required this.onPlaylistSelected,
    required this.onLikedSongsSelected,
    required this.onHomeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(spotifyPluginPlaylistsProvider);
    final likedTracks = ref.watch(spotifyPluginLikedTracksProvider);
    final isAuthenticated = ref.watch(isSpotifyPluginAuthenticatedProvider);

    return Container(
      width: 72,
      color: Colors.black,
      child: Column(
        children: [
          const Gap(8),
          // Navigation Icons
          _NavIconButton(
            icon: Iconsax.home_2,
            selectedIcon: Iconsax.home_15,
            isSelected: selectedNavIndex == 0,
            onTap: () {
              onNavSelected(0);
              onHomeSelected();
            },
            tooltip: 'Home',
          ),
          _NavIconButton(
            icon: Iconsax.search_normal,
            selectedIcon: Iconsax.search_normal_1,
            isSelected: selectedNavIndex == 1,
            onTap: () => onNavSelected(1),
            tooltip: 'Search',
          ),
          
          const Gap(8),
          Divider(color: Colors.grey.shade800, height: 1, indent: 16, endIndent: 16),
          const Gap(8),
          
          // Library icon
          _NavIconButton(
            icon: Iconsax.music_library_2,
            selectedIcon: Iconsax.music_library_25,
            isSelected: selectedNavIndex == 2,
            onTap: () => onNavSelected(2),
            tooltip: 'Library',
          ),
          
          // Add playlist button
          Builder(
            builder: (context) => _NavIconButton(
              icon: Iconsax.add,
              selectedIcon: Iconsax.add,
              isSelected: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreatePlaylistDialog(),
                );
              },
              tooltip: 'Create Playlist',
            ),
          ),
          
          const Gap(8),
          Divider(color: Colors.grey.shade800, height: 1, indent: 16, endIndent: 16),
          const Gap(8),
          
          // Playlist thumbnails
          Expanded(
            child: isAuthenticated
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      // Liked Songs
                      likedTracks.when(
                        data: (tracks) => _PlaylistThumbnail(
                          isLikedSongs: true,
                          isSelected: isLikedSongsSelected,
                          trackCount: tracks.length,
                          onTap: onLikedSongsSelected,
                        ),
                        loading: () => const _PlaylistThumbnailShimmer(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      
                      const Gap(8),
                      
                      // User playlists
                      ...playlists.when(
                        data: (items) => items.map((playlist) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PlaylistThumbnail(
                            imageUrl: playlist.images.isNotEmpty 
                                ? playlist.images.first.url 
                                : null,
                            isSelected: selectedPlaylistId == playlist.id,
                            onTap: () => onPlaylistSelected(playlist),
                            tooltip: playlist.name,
                          ),
                        )).toList(),
                        loading: () => [
                          const _PlaylistThumbnailShimmer(),
                          const Gap(8),
                          const _PlaylistThumbnailShimmer(),
                        ],
                        error: (_, __) => [],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _NavIconButton({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: widget.isSelected 
                  ? AppTheme.darkCard 
                  : _isHovered 
                      ? AppTheme.darkCard.withOpacity(0.5) 
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.isSelected ? widget.selectedIcon : widget.icon,
              color: widget.isSelected || _isHovered ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistThumbnail extends StatefulWidget {
  final String? imageUrl;
  final bool isLikedSongs;
  final bool isSelected;
  final int? trackCount;
  final VoidCallback onTap;
  final String? tooltip;

  const _PlaylistThumbnail({
    this.imageUrl,
    this.isLikedSongs = false,
    required this.isSelected,
    this.trackCount,
    required this.onTap,
    this.tooltip,
  });

  @override
  State<_PlaylistThumbnail> createState() => _PlaylistThumbnailState();
}

class _PlaylistThumbnailState extends State<_PlaylistThumbnail> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (widget.isLikedSongs) {
      content = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4B01D0), Color(0xFF9DBAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
          border: widget.isSelected 
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: const Center(
          child: Icon(Iconsax.heart5, color: Colors.white, size: 20),
        ),
      );
    } else {
      content = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: widget.isSelected 
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.isSelected ? 2 : 4),
          child: widget.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, color: Colors.grey, size: 20),
                  ),
                )
              : Container(
                  color: AppTheme.darkCard,
                  child: const Icon(Iconsax.music, color: Colors.grey, size: 20),
                ),
        ),
      );
    }

    return Tooltip(
      message: widget.tooltip ?? (widget.isLikedSongs ? 'Liked Songs' : ''),
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _PlaylistThumbnailShimmer extends StatelessWidget {
  const _PlaylistThumbnailShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
