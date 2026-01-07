import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';

/// Bottom sheet for displaying QR code(s) for sharing
class QrDisplaySheet extends ConsumerStatefulWidget {
  final ShareData shareData;

  const QrDisplaySheet({
    super.key,
    required this.shareData,
  });

  /// Show the QR display sheet
  static Future<void> show(BuildContext context, ShareData shareData) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrDisplaySheet(shareData: shareData),
    );
  }

  @override
  ConsumerState<QrDisplaySheet> createState() => _QrDisplaySheetState();
}

class _QrDisplaySheetState extends ConsumerState<QrDisplaySheet> {
  final _shareService = ShareService.instance;
  late List<String> _qrDataList;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _qrDataList = _shareService.generateQrData(widget.shareData);
  }

  void _nextQr() {
    if (_currentIndex < _qrDataList.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousQr() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMultiQr = _qrDataList.length > 1;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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
                    Text(
                      isMultiQr ? 'QR Codes' : 'QR Code',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // QR Code display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _qrDataList[_currentIndex],
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),

              // Multi-QR navigation
              if (isMultiQr) ...[
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0 ? _previousQr : null,
                      icon: const Icon(Iconsax.arrow_left_2),
                      style: IconButton.styleFrom(
                        backgroundColor: _currentIndex > 0
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.grey.shade800,
                      ),
                    ),
                    const Gap(20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_qrDataList.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Gap(20),
                    IconButton(
                      onPressed: _currentIndex < _qrDataList.length - 1
                          ? _nextQr
                          : null,
                      icon: const Icon(Iconsax.arrow_right_3),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _currentIndex < _qrDataList.length - 1
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Text(
                  'Show all ${_qrDataList.length} QR codes to the receiver',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],

              // Instructions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          isMultiQr
                              ? 'The receiver needs to scan all ${_qrDataList.length} QR codes to get the complete ${_getTypeLabel()}.'
                              : 'The receiver can scan this QR code with Sangeet to import the ${_getTypeLabel()}.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (widget.shareData.type) {
      case ShareType.song:
        final track = widget.shareData.tracks.first;
        return '${track.title} - ${track.artist}';
      case ShareType.playlist:
        return '"${widget.shareData.name}" (${widget.shareData.tracks.length} songs)';
      case ShareType.album:
        return '"${widget.shareData.name}" (${widget.shareData.tracks.length} songs)';
    }
  }

  String _getTypeLabel() {
    switch (widget.shareData.type) {
      case ShareType.song:
        return 'song';
      case ShareType.playlist:
        return 'playlist';
      case ShareType.album:
        return 'album';
    }
  }
}
