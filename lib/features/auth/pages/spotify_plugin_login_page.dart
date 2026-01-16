import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/services/spotify_plugin/spotify_plugin.dart';
import 'package:sangeet/shared/providers/spotify_plugin_provider.dart';

/// Spotify login page using the plugin system
class SpotifyPluginLoginPage extends ConsumerStatefulWidget {
  const SpotifyPluginLoginPage({super.key});

  @override
  ConsumerState<SpotifyPluginLoginPage> createState() => _SpotifyPluginLoginPageState();
}

class _SpotifyPluginLoginPageState extends ConsumerState<SpotifyPluginLoginPage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleLogin() async {
    final plugin = SpotifyPluginService.instance;
    if (plugin == null) {
      setState(() {
        _error = 'Plugin not initialized. Please restart the app.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // This will open the WebView login flow
      await plugin.auth.authenticate();
      
      // Small delay to ensure WebView is closed
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Check if authentication was successful
      // Note: The plugin may throw async errors (like _Timer undefined) but auth still works
      bool isAuth = false;
      try {
        isAuth = plugin.auth.isAuthenticated();
      } catch (e) {
        print('SpotifyPluginLogin: Error checking auth state: $e');
        // Try again after a small delay - plugin might still be initializing
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          try {
            isAuth = plugin.auth.isAuthenticated();
          } catch (_) {
            // Still failing, assume not authenticated
          }
        }
      }
      
      if (isAuth) {
        if (mounted) {
          // Reset API failure flag after successful login
          plugin.auth.resetApiFailure();
          
          // Invalidate all Spotify providers to refresh state after login
          ref.invalidate(isSpotifyPluginAuthenticatedProvider);
          ref.invalidate(spotifyPluginUserProvider);
          ref.invalidate(spotifyPluginPlaylistsProvider);
          ref.invalidate(spotifyPluginLikedTracksProvider);
          ref.invalidate(spotifyPluginSavedAlbumsProvider);
          ref.invalidate(spotifyPluginFollowedArtistsProvider);
          ref.invalidate(spotifyPluginRecentlyPlayedProvider);
          ref.invalidate(spotifyPluginTopTracksProvider);
          ref.invalidate(spotifyPluginTopArtistsProvider);
          
          // Small delay to let providers refresh
          await Future.delayed(const Duration(milliseconds: 200));
          
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Authentication was cancelled or failed. Please try again.';
          });
        }
      }
    } catch (e) {
      print('SpotifyPluginLogin: Error during authentication: $e');
      if (mounted) {
        setState(() {
          _error = 'Authentication failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isSpotifyPluginAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Spotify'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spotify Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                isAuthenticated ? 'Connected!' : 'Connect to Spotify',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                isAuthenticated
                    ? 'Your Spotify account is connected. You can access your playlists, liked songs, and more.'
                    : 'Connect your Spotify account to access your playlists, liked songs, and personalized recommendations.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Login/Logout Button
              if (isAuthenticated) ...[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final plugin = SpotifyPluginService.instance;
                          if (plugin != null) {
                            await plugin.auth.logout();
                            ref.invalidate(isSpotifyPluginAuthenticatedProvider);
                            setState(() {});
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Connect with Spotify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Info text
              Text(
                'This uses the same authentication method as Spotify.\nYour credentials are stored securely on your device.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
