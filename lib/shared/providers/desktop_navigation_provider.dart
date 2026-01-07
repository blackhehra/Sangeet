import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source page for navigation (to know where to go back)
enum NavigationSource {
  home,
  library,
}

/// Navigation state for desktop shell
class DesktopNavigationState {
  final Widget? contentOverride;
  final String? playlistId;
  final String? playlistName;
  final String? imageUrl;
  final bool isLikedSongs;
  final bool isAlbum;
  final String? albumSubtitle;
  final String? artistId;
  final String? artistName;
  final String? artistSubscribersText;
  final bool isMusicAlbum; // True for music albums, false for other albums
  final NavigationSource source; // Where the user navigated from

  const DesktopNavigationState({
    this.contentOverride,
    this.playlistId,
    this.playlistName,
    this.imageUrl,
    this.isLikedSongs = false,
    this.isAlbum = false,
    this.albumSubtitle,
    this.artistId,
    this.artistName,
    this.artistSubscribersText,
    this.isMusicAlbum = false,
    this.source = NavigationSource.home,
  });

  DesktopNavigationState copyWith({
    Widget? contentOverride,
    String? playlistId,
    String? playlistName,
    String? imageUrl,
    bool? isLikedSongs,
    bool? isAlbum,
    String? albumSubtitle,
    String? artistId,
    String? artistName,
    String? artistSubscribersText,
    bool? isMusicAlbum,
    NavigationSource? source,
  }) {
    return DesktopNavigationState(
      contentOverride: contentOverride ?? this.contentOverride,
      playlistId: playlistId ?? this.playlistId,
      playlistName: playlistName ?? this.playlistName,
      imageUrl: imageUrl ?? this.imageUrl,
      isLikedSongs: isLikedSongs ?? this.isLikedSongs,
      isAlbum: isAlbum ?? this.isAlbum,
      albumSubtitle: albumSubtitle ?? this.albumSubtitle,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      artistSubscribersText: artistSubscribersText ?? this.artistSubscribersText,
      isMusicAlbum: isMusicAlbum ?? this.isMusicAlbum,
      source: source ?? this.source,
    );
  }

  bool get isArtist => artistId != null;
}

/// Provider for desktop navigation state
final desktopNavigationProvider = StateNotifierProvider<DesktopNavigationNotifier, DesktopNavigationState>((ref) {
  return DesktopNavigationNotifier();
});

class DesktopNavigationNotifier extends StateNotifier<DesktopNavigationState> {
  DesktopNavigationNotifier() : super(const DesktopNavigationState());

  void openPlaylist({
    required String playlistId,
    required String playlistName,
    String? imageUrl,
    NavigationSource source = NavigationSource.home,
  }) {
    state = DesktopNavigationState(
      playlistId: playlistId,
      playlistName: playlistName,
      imageUrl: imageUrl,
      isLikedSongs: false,
      isAlbum: false,
      source: source,
    );
  }

  void openLikedSongs({NavigationSource source = NavigationSource.home}) {
    state = DesktopNavigationState(
      isLikedSongs: true,
      isAlbum: false,
      source: source,
    );
  }

  void openAlbum({
    required String albumId,
    required String albumName,
    String? imageUrl,
    String? subtitle,
    bool isMusicAlbum = false, // True for music albums, false for other albums
    NavigationSource source = NavigationSource.home,
  }) {
    state = DesktopNavigationState(
      playlistId: albumId,
      playlistName: albumName,
      imageUrl: imageUrl,
      isLikedSongs: false,
      isAlbum: true,
      albumSubtitle: subtitle,
      isMusicAlbum: isMusicAlbum,
      source: source,
    );
  }

  void openArtist({
    required String artistId,
    required String artistName,
    String? imageUrl,
    String? subscribersText,
    NavigationSource source = NavigationSource.home,
  }) {
    state = DesktopNavigationState(
      artistId: artistId,
      artistName: artistName,
      imageUrl: imageUrl,
      artistSubscribersText: subscribersText,
      source: source,
    );
  }

  void setContent(Widget content, {NavigationSource source = NavigationSource.home}) {
    state = DesktopNavigationState(contentOverride: content, source: source);
  }

  void clear() {
    state = const DesktopNavigationState();
  }

  /// Go back based on the source - returns the source so caller can handle navigation
  NavigationSource goBack() {
    final source = state.source;
    state = const DesktopNavigationState();
    return source;
  }
}
