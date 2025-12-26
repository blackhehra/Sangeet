import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/shared/providers/custom_playlist_provider.dart';
import 'package:sangeet/features/playlist/widgets/create_playlist_dialog.dart';

class AddToPlaylistDialog extends ConsumerWidget {
  final Track track;

  const AddToPlaylistDialog({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(customPlaylistsProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Create New Playlist button
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              title: const Text(
                'Create New Playlist',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const CreatePlaylistDialog(),
                );
                
                // After creating, show this dialog again to add the track
                if (result == true && context.mounted) {
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AddToPlaylistDialog(track: track),
                    );
                  }
                }
              },
            ),
            
            const Divider(height: 1),
            
            // Existing playlists
            if (playlists.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.music_playlist,
                          size: 64,
                          color: Colors.grey.shade700,
                        ),
                        const Gap(16),
                        Text(
                          'No playlists yet',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Create your first playlist above',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final isAdded = playlist.tracks.any((t) => t.id == track.id);
                    
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.music_playlist,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${playlist.tracks.length} songs',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isAdded
                          ? Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                      onTap: isAdded
                          ? null
                          : () async {
                              final success = await ref
                                  .read(customPlaylistsProvider.notifier)
                                  .addTrackToPlaylist(playlist.id, track);
                              
                              if (context.mounted) {
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added to "${playlist.name}"',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Song already in playlist'),
                                    ),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
