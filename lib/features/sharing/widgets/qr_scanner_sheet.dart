import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sangeet/core/theme/app_theme.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';
import 'package:sangeet/services/sharing/qr_share_service.dart';

/// Sheet for scanning QR codes to import shared content
class QrScannerSheet extends ConsumerStatefulWidget {
  const QrScannerSheet({super.key});

  /// Show the QR scanner sheet
  static Future<ShareData?> show(BuildContext context) {
    return showModalBottomSheet<ShareData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QrScannerSheet(),
    );
  }

  @override
  ConsumerState<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends ConsumerState<QrScannerSheet> {
  final _shareService = ShareService.instance;
  final _scanSession = MultiQrScanSession();
  MobileScannerController? _controller;
  
  bool _isProcessing = false;
  String? _lastScannedData;
  String _statusMessage = 'Point camera at QR code';

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue == _lastScannedData) return;
    
    _lastScannedData = rawValue;
    _processQrData(rawValue);
  }

  void _processQrData(String qrData) {
    setState(() => _isProcessing = true);

    try {
      final shareData = _shareService.parseQrData(qrData);
      
      if (shareData == null) {
        setState(() {
          _statusMessage = 'Invalid QR code. Try again.';
          _isProcessing = false;
        });
        _lastScannedData = null; // Allow re-scan
        return;
      }

      // Single QR code (not chunked)
      if (!shareData.isChunked) {
        _completeImport(shareData);
        return;
      }

      // Multi-QR: add to session
      final isNew = _scanSession.addChunk(shareData);
      
      if (!isNew) {
        setState(() {
          _statusMessage = 'Already scanned this QR. Scan the next one.';
          _isProcessing = false;
        });
        return;
      }

      // Check if complete
      if (_scanSession.isComplete) {
        final combined = _scanSession.combine();
        if (combined != null) {
          _completeImport(combined);
        } else {
          setState(() {
            _statusMessage = 'Error combining QR codes. Try again.';
            _isProcessing = false;
          });
          _scanSession.reset();
        }
      } else {
        // Need more QR codes
        final missing = _scanSession.missingParts;
        setState(() {
          _statusMessage = 'Scanned ${_scanSession.scannedCount}/${_scanSession.totalCount}. '
              'Scan QR ${missing.first} next.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  void _completeImport(ShareData data) {
    Navigator.pop(context, data);
  }

  void _resetSession() {
    setState(() {
      _scanSession.reset();
      _lastScannedData = null;
      _statusMessage = 'Point camera at QR code';
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: _resetSession,
                    icon: const Icon(Iconsax.refresh),
                    tooltip: 'Reset',
                  ),
                ],
              ),
            ),

            // Scanner
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    // Scan overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Processing indicator
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Status and progress
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress indicator for multi-QR
                  if (_scanSession.totalCount > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _scanSession.totalCount,
                        (index) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _scanSession.scannedCount > index
                                ? AppTheme.primaryColor
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                  ],
                  
                  // Status message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _scanSession.scannedCount > 0
                              ? Iconsax.tick_circle
                              : Iconsax.scan,
                          color: _scanSession.scannedCount > 0
                              ? AppTheme.primaryColor
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info about what's being scanned
                  if (_scanSession.name != null) ...[
                    const Gap(12),
                    Text(
                      'Importing: ${_scanSession.name}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
