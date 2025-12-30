import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/shared/providers/custom_playlist_provider.dart';
import 'package:sangeet/features/playlist/pages/custom_playlist_detail_page.dart';
import 'package:sangeet/features/playlist/widgets/create_playlist_dialog.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/desktop_navigation_provider.dart';
import 'package:sangeet/features/sharing/widgets/qr_scanner_sheet.dart';
import 'package:sangeet/features/sharing/pages/import_handler_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get _isDesktopPlatform => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

class CustomPlaylistsPage extends ConsumerWidget {
  const CustomPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(customPlaylistsProvider);
    final isDesktop = _isDesktopPlatform;

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(desktopNavigationProvider.notifier).clear();
                },
              )
            : null,
        title: const Text('My Playlists'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Import from QR code
          IconButton(
            onPressed: () => _scanQrCode(context),
            icon: const Icon(Iconsax.scan),
            tooltip: 'Scan QR Code',
          ),
          // Import from file
          IconButton(
            onPressed: () => _importFromFile(context),
            icon: const Icon(Iconsax.document_download),
            tooltip: 'Import .sangeet file',
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.music_playlist,
                    size: 80,
                    color: Colors.grey.shade700,
                  ),
                  const Gap(16),
                  Text(
                    'No playlists yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Create your first playlist',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Gap(24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePlaylistDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Playlist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppTheme.darkCard,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: _PlaylistCoverImage(
                      tracks: playlist.tracks,
                      size: 56,
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${playlist.tracks.length} songs',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              Gap(8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDelete(context, ref, playlist.id, playlist.name);
                        }
                      },
                    ),
                    onTap: () {
                      if (isDesktop) {
                        ref.read(desktopNavigationProvider.notifier).setContent(
                          CustomPlaylistDetailPage(playlistId: playlist.id),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomPlaylistDetailPage(
                              playlistId: playlist.id,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: playlists.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreatePlaylistDialog(context, ref),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(customPlaylistsProvider.notifier).deletePlaylist(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$name"')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _scanQrCode(BuildContext context) async {
    final shareData = await QrScannerSheet.show(context);
    if (shareData != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImportHandlerPage(shareData: shareData),
        ),
      );
    }
  }

  void _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null && file.path!.endsWith('.sangeet')) {
          final shareData = await ShareService.instance.importFromFile(file.path!);
          if (shareData != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImportHandlerPage(shareData: shareData),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to read .sangeet file')),
            );
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a .sangeet file')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Auto-generated playlist cover image
/// Shows single image for 1-3 tracks, 4-image grid for 4+ tracks
class _PlaylistCoverImage extends StatelessWidget {
  final List<Track> tracks;
  final double size;

  const _PlaylistCoverImage({
    required this.tracks,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      // Empty playlist - show gradient with icon
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Iconsax.music_playlist,
          color: Colors.white,
          size: size * 0.5,
        ),
      );
    }

    if (tracks.length < 4) {
      // 1-3 tracks - show first track's image
      final imageUrl = tracks.first.thumbnailUrl;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildFallback(),
                )
              : _buildFallback(),
        ),
      );
    }

    // 4+ tracks - show 2x2 grid of first 4 track images
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
          children: tracks.take(4).map((track) {
            final imageUrl = track.thumbnailUrl;
            return imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.darkCard,
                      child: const Icon(Iconsax.music, color: Colors.grey, size: 16),
                    ),
                  )
                : Container(
                    color: AppTheme.darkCard,
                    child: const Icon(Iconsax.music, color: Colors.grey, size: 16),
                  );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppTheme.darkCard,
      child: Icon(
        Iconsax.music,
        color: Colors.grey,
        size: size * 0.5,
      ),
    );
  }
}
