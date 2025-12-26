# Music Streaming App - Project TODO

A comprehensive TODO list for building our own music streaming application.

> **Note:** We follow **Spotube's architecture** as it's actively maintained (2024+).  
> BlackHole development stopped in 2023 - we only reference it for simpler patterns.

## Architecture Decision: Spotube-Style (Modern)
- **State Management:** Riverpod (not GetIt)
- **Audio Engine:** media_kit (not just_audio)
- **Database:** Drift/SQLite (not Hive)
- **UI Framework:** Modern Material 3 / shadcn_flutter
- **Code Generation:** freezed, json_serializable, auto_route

---

## Phase 1: Project Setup & Foundation

### 1.1 Project Initialization
- [ ] Create new Flutter project with proper package name
- [ ] Set up folder structure following clean architecture
- [ ] Configure `pubspec.yaml` with required dependencies
- [ ] Set up multi-platform support (Android, iOS, Windows, Linux, macOS)
- [ ] Configure app icons and splash screens
- [ ] Set up Git repository with proper `.gitignore`

### 1.2 Core Dependencies (Spotube-Style Modern Stack)
```yaml
dependencies:
  # State Management (Riverpod - industry standard)
  flutter_riverpod: ^2.5.1
  hooks_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5
  riverpod_annotation: ^2.3.5
  
  # Audio (media_kit - MPV based, actively maintained)
  media_kit: ^1.1.10
  media_kit_libs_audio: ^1.0.4          # Audio-only libs (smaller)
  audio_service: ^0.18.13               # Background playback
  audio_session: ^0.1.19
  
  # Database (Drift - type-safe SQLite)
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.23
  
  # Networking
  dio: ^5.4.3
  
  # YouTube (actively maintained)
  youtube_explode_dart: ^2.2.0
  
  # UI (Modern)
  cached_network_image: ^3.3.1
  skeletonizer: ^1.1.2                  # Loading skeletons
  sliding_up_panel: ^2.0.0+1
  auto_size_text: ^3.0.0
  
  # Utils
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
  connectivity_plus: ^6.1.2
  share_plus: ^7.2.2
  url_launcher: ^6.2.6
  collection: ^1.18.0
  
  # Metadata & Lyrics
  metadata_god: ^1.1.0
  lrc: ^1.0.2
  
  # Code Generation Support
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # Routing
  auto_route: ^9.3.0

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.2
  json_serializable: ^6.6.2
  drift_dev: ^2.21.0
  riverpod_generator: ^2.4.3
  auto_route_generator: ^9.0.0
  flutter_lints: ^3.0.1
```

### 1.3 Folder Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── extensions/
├── data/
│   ├── models/
│   ├── repositories/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   └── database/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── providers/
│   └── controllers/
└── services/
    ├── audio/
    ├── download/
    ├── api/
    └── storage/
```

---

## Phase 2: Data Layer

### 2.1 Models
- [ ] Create `Track` model (id, name, artists, album, duration, imageUrl, streamUrl, isrc)
- [ ] Create `Album` model (id, name, artists, tracks, images, releaseDate, type)
- [ ] Create `Artist` model (id, name, images, genres, followers)
- [ ] Create `Playlist` model (id, name, description, owner, tracks, images)
- [ ] Create `SearchResult` model (tracks, albums, artists, playlists)
- [ ] Create `StreamInfo` model (url, quality, codec, bitrate, expireAt)
- [ ] Generate freezed classes for immutability

### 2.2 Database Setup
- [ ] Set up Drift/Hive database
- [ ] Create tables/boxes for:
  - [ ] Cached tracks
  - [ ] Downloaded tracks
  - [ ] Playlists (user created)
  - [ ] Favorites
  - [ ] Listening history
  - [ ] Search history
  - [ ] Player state (current queue, position, etc.)
  - [ ] App settings/preferences

### 2.3 API Services
- [ ] Create base API client with interceptors
- [ ] Implement YouTube service:
  - [ ] Search videos/music
  - [ ] Get video details
  - [ ] Get stream URLs
  - [ ] Get playlists
  - [ ] Get channel info
- [ ] Implement additional music API (JioSaavn/Spotify/etc.):
  - [ ] Search (songs, albums, artists, playlists)
  - [ ] Get home page data
  - [ ] Get album details
  - [ ] Get artist details
  - [ ] Get playlist details
  - [ ] Get recommendations
- [ ] Implement lyrics service (multiple sources)

### 2.4 Repositories
- [ ] Create `TrackRepository` (fetch, cache, download)
- [ ] Create `PlaylistRepository` (CRUD operations)
- [ ] Create `SearchRepository` (search across sources)
- [ ] Create `UserRepository` (favorites, history)
- [ ] Create `SettingsRepository` (preferences)

---

## Phase 3: Audio Service

### 3.1 Audio Player Setup
- [ ] Initialize audio player (media_kit or just_audio)
- [ ] Implement `AudioPlayerService`:
  - [ ] Play/Pause/Stop
  - [ ] Next/Previous
  - [ ] Seek
  - [ ] Volume control
  - [ ] Speed control
  - [ ] Loop modes (none, one, all)
  - [ ] Shuffle mode
  - [ ] Queue management

### 3.2 Background Playback
- [ ] Set up `audio_service` for background playback
- [ ] Implement media notification controls
- [ ] Handle audio focus
- [ ] Implement lock screen controls

### 3.3 Stream Resolution
- [ ] Create `SourcedTrack` service:
  - [ ] Resolve track metadata to stream URL
  - [ ] Cache resolved sources
  - [ ] Handle expired URLs (refresh)
  - [ ] Support multiple quality levels
  - [ ] Implement source ranking algorithm

### 3.4 Audio State Management
- [ ] Create `AudioPlayerProvider`:
  - [ ] Current track
  - [ ] Queue (upcoming tracks)
  - [ ] Playback state (playing, paused, buffering)
  - [ ] Position/Duration
  - [ ] Loop/Shuffle state
  - [ ] Volume
- [ ] Persist player state to database
- [ ] Restore state on app launch

---

## Phase 4: Core Features

### 4.1 Home Screen
- [ ] Design home page layout
- [ ] Implement sections:
  - [ ] Recently played
  - [ ] Recommended for you
  - [ ] Trending songs
  - [ ] New releases
  - [ ] Featured playlists
  - [ ] Top charts
- [ ] Add pull-to-refresh
- [ ] Implement lazy loading

### 4.2 Search
- [ ] Create search UI with suggestions
- [ ] Implement search across:
  - [ ] Songs
  - [ ] Albums
  - [ ] Artists
  - [ ] Playlists
- [ ] Add search history
- [ ] Implement filters (type, duration, etc.)

### 4.3 Player Screen
- [ ] Design full-screen player:
  - [ ] Album art (with blur background)
  - [ ] Track info (title, artist, album)
  - [ ] Progress bar with seek
  - [ ] Play/Pause button
  - [ ] Next/Previous buttons
  - [ ] Shuffle/Repeat buttons
  - [ ] Volume slider
  - [ ] Queue button
  - [ ] Like button
  - [ ] More options menu
- [ ] Implement mini player (bottom bar)
- [ ] Add swipe gestures
- [ ] Implement lyrics display

### 4.4 Library
- [ ] Create library tabs:
  - [ ] Playlists
  - [ ] Albums
  - [ ] Artists
  - [ ] Downloaded
  - [ ] Favorites
- [ ] Implement playlist CRUD
- [ ] Add sorting options
- [ ] Implement local music scanning

### 4.5 Queue Management
- [ ] Display current queue
- [ ] Drag to reorder
- [ ] Remove from queue
- [ ] Clear queue
- [ ] Save queue as playlist
- [ ] Add to queue (play next, add to end)

---

## Phase 5: Downloads & Offline

### 5.1 Download Manager
- [ ] Create download service
- [ ] Implement download queue
- [ ] Show download progress
- [ ] Handle download errors/retry
- [ ] Support background downloads
- [ ] Implement download quality selection

### 5.2 Metadata Tagging
- [ ] Embed ID3 tags on download:
  - [ ] Title
  - [ ] Artist
  - [ ] Album
  - [ ] Album art
  - [ ] Year
  - [ ] Genre
  - [ ] Track number
- [ ] Use `metadata_god` package

### 5.3 Offline Mode
- [ ] Detect offline state
- [ ] Show only downloaded content when offline
- [ ] Cache album art for offline
- [ ] Handle stream URL expiration

---

## Phase 6: Settings & Preferences

### 6.1 Audio Settings
- [ ] Streaming quality (Low/Medium/High)
- [ ] Download quality
- [ ] WiFi-only streaming option
- [ ] WiFi-only download option
- [ ] Equalizer (if supported)
- [ ] Crossfade duration
- [ ] Gapless playback

### 6.2 App Settings
- [ ] Theme (Light/Dark/System)
- [ ] Accent color picker
- [ ] Language selection
- [ ] Download location
- [ ] Cache size limit
- [ ] Clear cache option

### 6.3 Playback Settings
- [ ] Auto-play recommendations
- [ ] Skip silence
- [ ] Normalize volume
- [ ] Sleep timer

### 6.4 Data & Privacy
- [ ] Clear listening history
- [ ] Clear search history
- [ ] Export/Import playlists
- [ ] Backup & restore

---

## Phase 7: Advanced Features

### 7.1 Lyrics
- [ ] Fetch lyrics from multiple sources
- [ ] Display synced lyrics (if available)
- [ ] Fallback to static lyrics
- [ ] Auto-scroll with playback
- [ ] Allow manual search/edit

### 7.2 Recommendations
- [ ] Implement "Similar tracks" feature
- [ ] Create personalized mixes
- [ ] "Because you listened to..." sections
- [ ] Artist/Genre radio

### 7.3 Social Features
- [ ] Share track/playlist links
- [ ] Share to social media
- [ ] Collaborative playlists (if API supports)

### 7.4 Import/Export
- [ ] Import playlists from Spotify
- [ ] Import playlists from YouTube
- [ ] Export playlists as JSON
- [ ] Import playlists from JSON

---

## Phase 8: Platform-Specific

### 8.1 Android
- [ ] Configure permissions (storage, internet, foreground service)
- [ ] Set up notification channel
- [ ] Handle audio focus properly
- [ ] Support Android Auto (optional)
- [ ] Home screen widget

### 8.2 iOS
- [ ] Configure capabilities (background audio)
- [ ] Set up audio session
- [ ] Control Center integration
- [ ] Lock screen controls
- [ ] Home screen widget

### 8.3 Desktop (Windows/Linux/macOS)
- [ ] Window management
- [ ] System tray integration
- [ ] Keyboard shortcuts
- [ ] Media key support
- [ ] Discord Rich Presence (optional)

---

## Phase 9: Polish & Optimization

### 9.1 Performance
- [ ] Implement image caching
- [ ] Optimize list rendering (lazy loading)
- [ ] Minimize rebuilds (proper state management)
- [ ] Profile and fix memory leaks
- [ ] Optimize database queries

### 9.2 UX Improvements
- [ ] Add loading skeletons
- [ ] Implement error states with retry
- [ ] Add haptic feedback
- [ ] Smooth animations/transitions
- [ ] Accessibility support

### 9.3 Testing
- [ ] Unit tests for services
- [ ] Widget tests for UI
- [ ] Integration tests for flows
- [ ] Test on multiple devices

### 9.4 Documentation
- [ ] Code documentation
- [ ] README with setup instructions
- [ ] Contributing guidelines
- [ ] API documentation

---

## Phase 10: Release

### 10.1 Pre-release
- [ ] Update version number
- [ ] Generate release notes
- [ ] Test on all target platforms
- [ ] Fix critical bugs

### 10.2 Build & Deploy
- [ ] Generate signed APK/AAB for Android
- [ ] Build for iOS (if applicable)
- [ ] Build for desktop platforms
- [ ] Create GitHub release
- [ ] Submit to F-Droid (optional)

### 10.3 Post-release
- [ ] Monitor crash reports
- [ ] Gather user feedback
- [ ] Plan next version features

---

## Quick Start Commands

```bash
# Create project
flutter create --org com.yourname music_app

# Add dependencies
flutter pub add flutter_riverpod hooks_riverpod flutter_hooks
flutter pub add audio_service just_audio
flutter pub add dio http youtube_explode_dart
flutter pub add hive_flutter path_provider
flutter pub add cached_network_image
flutter pub add freezed_annotation json_annotation --dev
flutter pub add build_runner freezed json_serializable --dev

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Build APK
flutter build apk --release
```

---

## Priority Order (MVP)

1. **Week 1-2:** Project setup, models, basic API integration
2. **Week 3-4:** Audio player service, background playback
3. **Week 5-6:** Home screen, search, basic player UI
4. **Week 7-8:** Library, playlists, favorites
5. **Week 9-10:** Downloads, offline mode
6. **Week 11-12:** Settings, polish, testing
7. **Week 13+:** Advanced features, platform-specific, release

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [audio_service Package](https://pub.dev/packages/audio_service)
- [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart)
- [BlackHole Source](https://github.com/Sangwan5688/BlackHole)
- [Spotube Source](https://github.com/KRTirtho/spotube)
