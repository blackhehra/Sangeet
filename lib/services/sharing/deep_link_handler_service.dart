import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:sangeet/services/sharing/share_service.dart';
import 'package:sangeet/services/sharing/share_data_model.dart';
import 'package:sangeet/features/sharing/pages/import_handler_page.dart';

/// Service for handling incoming deep links and file opens
class DeepLinkHandlerService {
  static DeepLinkHandlerService? _instance;
  static DeepLinkHandlerService get instance => _instance ??= DeepLinkHandlerService._();
  
  DeepLinkHandlerService._();

  final _shareService = ShareService.instance;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  /// Callback for when a share is received
  void Function(ShareData shareData)? onShareReceived;

  /// Global navigator key for showing import UI
  GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize the deep link handler
  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    this.navigatorKey = navigatorKey;
    _appLinks = AppLinks();

    // Handle initial link (app opened via link)
    try {
      final initialUri = await _appLinks!.getInitialAppLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      print('DeepLinkHandlerService: Error getting initial link: $e');
    }

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      _handleUri,
      onError: (e) {
        print('DeepLinkHandlerService: Error in link stream: $e');
      },
    );

    print('DeepLinkHandlerService: Initialized');
  }

  /// Handle an incoming URI
  void _handleUri(Uri uri) {
    print('DeepLinkHandlerService: Received URI: $uri');

    // Check if it's a Sangeet share link
    if (uri.scheme == 'sangeet' && uri.host == 'share') {
      _handleShareLink(uri);
    } else if (uri.scheme == 'file' || uri.path.endsWith('.sangeet')) {
      _handleFileOpen(uri);
    }
  }

  /// Handle a sangeet:// share link
  void _handleShareLink(Uri uri) {
    final link = uri.toString();
    final shareData = _shareService.parseLink(link);

    if (shareData != null) {
      _processShareData(shareData);
    } else {
      print('DeepLinkHandlerService: Failed to parse share link');
    }
  }

  /// Handle opening a .sangeet file
  Future<void> _handleFileOpen(Uri uri) async {
    final filePath = uri.toFilePath();
    final shareData = await _shareService.importFromFile(filePath);

    if (shareData != null) {
      _processShareData(shareData);
    } else {
      print('DeepLinkHandlerService: Failed to parse file');
    }
  }

  /// Process received share data
  void _processShareData(ShareData shareData) {
    // Notify callback if set
    if (onShareReceived != null) {
      onShareReceived!(shareData);
      return;
    }

    // Otherwise, show import UI
    _showImportUI(shareData);
  }

  /// Show the import UI for the received share
  void _showImportUI(ShareData shareData) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      print('DeepLinkHandlerService: No context available for showing import UI');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImportHandlerPage(shareData: shareData),
      ),
    );
  }

  /// Manually handle a link string (for testing or manual input)
  void handleLinkString(String link) {
    try {
      final uri = Uri.parse(link);
      _handleUri(uri);
    } catch (e) {
      print('DeepLinkHandlerService: Invalid link: $e');
    }
  }

  /// Manually handle file bytes (for share intent)
  void handleFileBytes(List<int> bytes) {
    final shareData = _shareService.importFromBytes(bytes);
    if (shareData != null) {
      _processShareData(shareData);
    }
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
