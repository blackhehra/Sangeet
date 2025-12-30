import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';

/// Page shown when importing shared content
/// Handles deep links, files, and QR code imports
class ImportHandlerPage extends ConsumerStatefulWidget {
  final ShareData shareData;

  const ImportHandlerPage({
    super.key,
    required this.shareData,
  });

  @override
  ConsumerState<ImportHandlerPage> createState() => _ImportHandlerPageState();
}

class _ImportHandlerPageState extends ConsumerState<ImportHandlerPage> {
  final _shareService = ShareService.instance;
  bool _isImporting = false;
  ImportResult? _result;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _import() async {
    setState(() => _isImporting = true);

    try {
      final result = await _shareService.importToLibrary(widget.shareData);
      setState(() {
        _result = result;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _result = ImportResult(
          success: false,
          type: widget.shareData.type,
          name: widget.shareData.name ?? 'Unknown',
          trackCount: widget.shareData.tracks.length,
          message: 'Import failed',
          error: e.toString(),
        );
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _result != null ? _buildResultView() : _buildPreviewView(),
    );
  }

  Widget _buildPreviewView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTypeIcon(),
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const Gap(20),

          // Title
          Text(
            _getTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(8),

          // Subtitle
          Text(
            _getSubtitle(),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),

          // Track list preview
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Iconsax.music, size: 20),
                      const Gap(8),
                      Text(
                        '${widget.shareData.tracks.length} songs',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Show first few tracks
                ...widget.shareData.tracks.take(5).map((track) => ListTile(
                      dense: true,
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )),
                if (widget.shareData.tracks.length > 5)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '+ ${widget.shareData.tracks.length - 5} more songs',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Gap(32),

          // Import button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isImporting ? null : _import,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Iconsax.import_1),
              label: Text(_isImporting ? 'Importing...' : 'Import to Library'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: result.success
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.success ? Iconsax.tick_circle : Iconsax.close_circle,
                size: 48,
                color: result.success ? Colors.green : Colors.red,
              ),
            ),
            const Gap(24),

            // Result message
            Text(
              result.success ? 'Import Successful!' : 'Import Failed',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              result.message,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (result.error != null) ...[
              const Gap(8),
              Text(
                result.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Gap(32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                if (result.success && result.playlistId != null) ...[
                  const Gap(16),
                  FilledButton(
                    onPressed: () {
                      // Navigate to the imported playlist
                      Navigator.pop(context, result.playlistId);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('View Playlist'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.shareData.type) {
      case ShareType.song:
        return Iconsax.music;
      case ShareType.playlist:
        return Iconsax.music_playlist;
      case ShareType.album:
        return Iconsax.music_square;
    }
  }

  String _getTitle() {
    switch (widget.shareData.type) {
      case ShareType.song:
        return widget.shareData.tracks.first.title;
      case ShareType.playlist:
        return widget.shareData.name ?? 'Shared Playlist';
      case ShareType.album:
        return widget.shareData.name ?? 'Shared Album';
    }
  }

  String _getSubtitle() {
    switch (widget.shareData.type) {
      case ShareType.song:
        return 'by ${widget.shareData.tracks.first.artist}';
      case ShareType.playlist:
        return widget.shareData.description ?? 'Shared with you';
      case ShareType.album:
        return widget.shareData.description != null
            ? 'by ${widget.shareData.description}'
            : 'Shared with you';
    }
  }
}

/// Dialog to show when receiving shared content
class ImportConfirmDialog extends StatelessWidget {
  final ShareData shareData;

  const ImportConfirmDialog({
    super.key,
    required this.shareData,
  });

  static Future<bool?> show(BuildContext context, ShareData shareData) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ImportConfirmDialog(shareData: shareData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getTypeIcon(),
            color: AppTheme.primaryColor,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              'Import ${_getTypeLabel()}?',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getName(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Gap(4),
          Text(
            '${shareData.tracks.length} songs',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
          ),
          child: const Text('Import'),
        ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (shareData.type) {
      case ShareType.song:
        return Iconsax.music;
      case ShareType.playlist:
        return Iconsax.music_playlist;
      case ShareType.album:
        return Iconsax.music_square;
    }
  }

  String _getTypeLabel() {
    switch (shareData.type) {
      case ShareType.song:
        return 'Song';
      case ShareType.playlist:
        return 'Playlist';
      case ShareType.album:
        return 'Album';
    }
  }

  String _getName() {
    switch (shareData.type) {
      case ShareType.song:
        return '${shareData.tracks.first.title} - ${shareData.tracks.first.artist}';
      case ShareType.playlist:
        return shareData.name ?? 'Shared Playlist';
      case ShareType.album:
        return shareData.name ?? 'Shared Album';
    }
  }
}
