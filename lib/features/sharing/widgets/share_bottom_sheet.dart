import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';
import 'package:sangeet/features/sharing/widgets/qr_display_sheet.dart';

/// Bottom sheet for sharing content
/// Shows options for Link, File, and QR code sharing
class ShareBottomSheet extends ConsumerStatefulWidget {
  final ShareData shareData;

  const ShareBottomSheet({
    super.key,
    required this.shareData,
  });

  /// Show the share bottom sheet
  static Future<void> show(BuildContext context, ShareData shareData) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(shareData: shareData),
    );
  }

  @override
  ConsumerState<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<ShareBottomSheet> {
  final _shareService = ShareService.instance;
  late ShareSummary _summary;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _summary = _shareService.getShareSummary(widget.shareData);
  }

  Future<void> _shareViaLink() async {
    final shareText = _shareService.generateShareText(widget.shareData);
    
    Navigator.pop(context);
    
    await Share.share(
      shareText,
      subject: _getShareSubject(),
    );
  }

  Future<void> _shareViaFile() async {
    setState(() => _isExporting = true);
    
    try {
      final filePath = await _shareService.exportToFile(widget.shareData);
      
      Navigator.pop(context);
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: _getShareSubject(),
        text: _getFileShareText(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showQrCode() {
    Navigator.pop(context);
    QrDisplaySheet.show(context, widget.shareData);
  }

  Future<void> _copyLink() async {
    final links = _shareService.generateLinks(widget.shareData);
    final text = links.length == 1 
        ? links.first 
        : links.asMap().entries.map((e) => 'Part ${e.key + 1}: ${e.value}').join('\n');
    
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(links.length == 1 
              ? 'Link copied to clipboard' 
              : '${links.length} links copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getShareSubject() {
    switch (widget.shareData.type) {
      case ShareType.song:
        final track = widget.shareData.tracks.first;
        return '${track.title} - ${track.artist}';
      case ShareType.playlist:
        return 'Playlist: ${widget.shareData.name}';
      case ShareType.album:
        return 'Album: ${widget.shareData.name}';
    }
  }

  String _getFileShareText() {
    return 'Open this file with Sangeet to import ${_summary.description}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    _getTypeIcon(),
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const Gap(12),
                  Text(
                    'Share ${_summary.typeLabel}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _getHeaderSubtitle(),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Share options
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Link sharing
                  _ShareOptionTile(
                    icon: Iconsax.link,
                    title: 'Share Link',
                    subtitle: _summary.requiresMultipleLinks
                        ? '${_summary.linkCount} links (playlist is large)'
                        : 'Send via any app',
                    onTap: _shareViaLink,
                  ),

                  // Copy link
                  _ShareOptionTile(
                    icon: Iconsax.copy,
                    title: 'Copy Link',
                    subtitle: _summary.requiresMultipleLinks
                        ? 'Copy ${_summary.linkCount} links'
                        : 'Copy to clipboard',
                    onTap: _copyLink,
                  ),

                  // File sharing
                  _ShareOptionTile(
                    icon: Iconsax.document,
                    title: 'Share as File',
                    subtitle: '.sangeet file (best for large playlists)',
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _isExporting ? null : _shareViaFile,
                  ),

                  // QR code
                  _ShareOptionTile(
                    icon: Iconsax.scan_barcode,
                    title: 'Show QR Code',
                    subtitle: _summary.requiresMultipleQr
                        ? '${_summary.qrCount} QR codes (scan all to import)'
                        : 'For nearby sharing',
                    onTap: _showQrCode,
                  ),
                ],
              ),
            ),

            const Gap(8),
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

  String _getHeaderSubtitle() {
    switch (widget.shareData.type) {
      case ShareType.song:
        final track = widget.shareData.tracks.first;
        return '${track.title}\nby ${track.artist}';
      case ShareType.playlist:
        return '"${widget.shareData.name}"\n${_summary.trackCount} songs';
      case ShareType.album:
        final artist = widget.shareData.description;
        return '"${widget.shareData.name}"${artist != null ? '\nby $artist' : ''}\n${_summary.trackCount} songs';
    }
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? const Icon(
        Iconsax.arrow_right_3,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
