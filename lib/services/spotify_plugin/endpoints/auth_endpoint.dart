import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:hetu_script/hetu_script.dart';

/// Check if running on desktop platform
bool get _kIsDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Spotify authentication endpoint wrapper
/// Wraps the Hetu plugin's auth functionality
/// Uses desktop_webview_window for desktop (Windows/macOS/Linux) to avoid reCAPTCHA issues
/// Uses flutter_inappwebview for mobile (Android/iOS)
class SpotifyAuthEndpoint {
  final Hetu _hetu;
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  StreamSubscription? _pluginAuthSubscription;
  
  /// Cached auth state - survives plugin errors
  /// Once authenticated, we trust this until explicit logout
  bool? _cachedAuthState;
  
  /// Track if we've had API failures (401 errors)
  bool _hasApiFailure = false;
  
  SpotifyAuthEndpoint(this._hetu) {
    // Listen to plugin's auth state stream for reactive updates
    _initPluginAuthStream();
  }
  
  /// Initialize listening to the plugin's auth state stream
  void _initPluginAuthStream() {
    try {
      final pluginStream = _hetu.eval("metadataPlugin.auth.authStateStream");
      if (pluginStream is Stream) {
        _pluginAuthSubscription = pluginStream.listen((event) {
          print('SpotifyAuth: Plugin auth state changed');
          // Update cached state from plugin stream
          final newAuthState = isAuthenticated();
          _authStateController.add(newAuthState);
        });
      }
    } catch (e) {
      print('SpotifyAuth: Could not subscribe to plugin auth stream: $e');
    }
  }
  
  /// Mark that an API call failed with 401 - tokens are invalid
  /// This should be called by other endpoints when they get 401 errors
  void markAuthFailed() {
    print('SpotifyAuth: Marking auth as failed due to 401 error');
    _hasApiFailure = true;
    _cachedAuthState = false;
    _notifyAuthStateChange();
  }
  
  /// Check if we've had API failures
  bool get hasApiFailure => _hasApiFailure;
  
  /// Reset API failure flag (after successful re-auth)
  void resetApiFailure() {
    _hasApiFailure = false;
  }
  
  /// Get the auth state stream
  /// Emits true when authenticated, false when not
  Stream<bool> get authStateStream => _authStateController.stream;
  
  /// Notify auth state change
  void _notifyAuthStateChange() {
    final isAuth = isAuthenticated();
    _authStateController.add(isAuth);
  }
  
  /// Authenticate with Spotify
  /// This opens the WebView login flow
  /// Uses desktop_webview_window for desktop platforms (handles reCAPTCHA properly)
  Future<void> authenticate() async {
    print('SpotifyAuth: Starting authentication...');
    await _hetu.eval("metadataPlugin.auth.authenticate()");
    print('SpotifyAuth: Authentication completed');
    
    // Cache the auth state as true after successful authentication
    // This survives async plugin errors like _Timer
    _cachedAuthState = true;
    
    _notifyAuthStateChange();
  }
  
  /// Check if user is authenticated
  /// Uses cached state if available to survive plugin errors
  bool isAuthenticated() {
    // If we have a cached auth state (set after successful login or logout),
    // trust it over the plugin's potentially error-prone check
    if (_cachedAuthState != null) {
      print('SpotifyAuth: Using cached auth state: $_cachedAuthState');
      return _cachedAuthState!;
    }
    
    try {
      print('SpotifyAuth: Checking auth state from plugin...');
      final result = _hetu.eval("metadataPlugin.auth.isAuthenticated()");
      print('SpotifyAuth: Plugin returned: $result (type: ${result.runtimeType})');
      final isAuth = result as bool? ?? false;
      // Cache the initial state from plugin
      _cachedAuthState = isAuth;
      print('SpotifyAuth: Cached auth state: $isAuth');
      return isAuth;
    } catch (e) {
      print('SpotifyAuth: Error checking authentication: $e');
      // If we get an error and have no cached state, assume not authenticated
      return _cachedAuthState ?? false;
    }
  }
  
  /// Logout from Spotify
  Future<void> logout() async {
    print('SpotifyAuth: Logging out...');
    
    // Clear cached auth state first
    _cachedAuthState = false;
    
    await _hetu.eval("metadataPlugin.auth.logout()");
    
    // Clear WebView data based on platform
    try {
      if (_kIsDesktop) {
        // Use desktop_webview_window to clear data
        await WebviewWindow.clearAll();
      } else {
        // Use flutter_inappwebview for mobile
        await WebStorageManager.instance().deleteAllData();
        await CookieManager.instance().deleteAllCookies();
      }
    } catch (e) {
      print('SpotifyAuth: Error clearing WebView data: $e');
    }
    
    _notifyAuthStateChange();
    print('SpotifyAuth: Logged out');
  }
  
  /// Dispose resources
  void dispose() {
    _pluginAuthSubscription?.cancel();
    _authStateController.close();
  }
}
