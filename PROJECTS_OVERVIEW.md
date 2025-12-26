# Music Streaming Apps - Comprehensive Overview

This document provides a detailed analysis of three open-source music streaming projects:
1. **BlackHole** - Indian music streaming app (JioSaavn + YouTube) - ⚠️ **DISCONTINUED (2023)**
2. **Spotube** - Cross-platform extensible music streaming platform - ✅ **ACTIVELY MAINTAINED**
3. **Spotube Plugin Spotify** - Metadata plugin for Spotube

> **Recommendation:** Follow Spotube's architecture for new projects. BlackHole uses outdated  
> patterns and dependencies that may not receive security updates or bug fixes.

---

## 1. BlackHole

### Overview
- **Author:** Ankit Sangwan
- **License:** GPL v3.0 (LGPL)
- **Version:** 1.15.10+41
- **Platforms:** Android, iOS, Windows, Linux, macOS
- **Primary Music Source:** JioSaavn API + YouTube

### Architecture

```
lib/
├── APIs/                    # API integrations
│   ├── api.dart            # JioSaavn API (primary source)
│   └── spotify_api.dart    # Spotify playlist import
├── Services/               # Core services
│   ├── audio_service.dart  # Audio playback handler (just_audio + audio_service)
│   ├── download.dart       # Download manager
│   ├── youtube_services.dart # YouTube integration
│   ├── yt_music.dart       # YouTube Music API
│   └── player_service.dart # Player controls
├── Screens/                # UI screens
│   ├── Home/               # Home page with recommendations
│   ├── Player/             # Audio player UI (101KB - very comprehensive)
│   ├── Search/             # Search functionality
│   ├── Library/            # User library
│   ├── Settings/           # App settings
│   └── YouTube/            # YouTube browsing
├── CustomWidgets/          # Reusable UI components
│   ├── miniplayer.dart     # Mini player widget
│   ├── seek_bar.dart       # Seek bar with progress
│   ├── equalizer.dart      # Audio equalizer
│   └── download_button.dart # Download functionality
├── Helpers/                # Utility functions
│   ├── lyrics.dart         # Lyrics fetching
│   ├── mediaitem_converter.dart # Media item conversion
│   ├── backup_restore.dart # Backup/restore functionality
│   └── import_export_playlist.dart # Playlist import/export
├── Models/                 # Data models
├── providers/              # State management (GetIt)
├── theme/                  # App theming
├── constants/              # App constants
└── localization/           # i18n support (15+ languages)
```

### Key Technologies
- **State Management:** GetIt (dependency injection)
- **Audio Playback:** `just_audio` + `audio_service`
- **Local Storage:** Hive (NoSQL database)
- **YouTube:** `youtube_explode_dart`
- **Networking:** HTTP package
- **UI:** Custom widgets, Sizer for responsive design

### Music Sources
1. **JioSaavn API** (Primary)
   - Home page data, search, playlists, albums, artists
   - Radio stations (featured, artist, entity)
   - High quality streaming (320kbps AAC)
   - Language-specific content (15+ languages)

2. **YouTube/YouTube Music** (Secondary)
   - Video search and playback
   - YouTube Music integration
   - Playlist import

### Key Features
- Streaming quality selection (96kbps - 320kbps)
- Offline downloads with ID3 tags
- Built-in equalizer
- Sleep timer
- Lyrics support
- Queue management
- Listening history
- Playlist import from Spotify/YouTube
- Backup & restore

### Audio Service Implementation
```dart
class AudioPlayerHandlerImpl extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  // Uses just_audio for playback
  // Handles background playback via audio_service
  // Quality switching based on network (WiFi vs Mobile)
  // Caching support
  // Equalizer integration
}
```

---

## 2. Spotube

### Overview
- **Author:** Kingkor Roy Tirtho (KRTirtho)
- **License:** BSD-4-Clause
- **Version:** 5.1.0+43
- **Platforms:** Android, iOS, Windows, Linux, macOS, Web
- **Concept:** BYOMM (Bring Your Own Music Metadata) - Plugin-based architecture

### Architecture

```
lib/
├── services/               # Core services
│   ├── audio_player/       # Audio playback (media_kit)
│   │   ├── audio_player.dart
│   │   ├── custom_player.dart
│   │   └── playback_state.dart
│   ├── sourced_track/      # Track source resolution
│   ├── youtube_engine/     # YouTube audio extraction
│   ├── metadata/           # Metadata services
│   ├── kv_store/           # Key-value storage
│   └── logger/             # Logging service
├── provider/               # State management (Riverpod)
│   ├── audio_player/       # Audio player state
│   ├── metadata_plugin/    # Plugin management
│   ├── download_manager/   # Download handling
│   ├── lyrics/             # Lyrics provider
│   ├── scrobbler/          # Last.fm scrobbling
│   └── user_preferences/   # User settings
├── modules/                # Feature modules
│   ├── player/             # Player UI components
│   ├── home/               # Home screen
│   ├── search/             # Search functionality
│   ├── library/            # User library
│   ├── playlist/           # Playlist management
│   ├── settings/           # Settings UI
│   └── metadata_plugins/   # Plugin UI
├── pages/                  # Screen pages (auto_route)
├── components/             # Reusable UI components
├── hooks/                  # Flutter hooks
├── models/                 # Data models (freezed)
│   ├── database/           # Drift database models
│   ├── metadata/           # Metadata models
│   └── playback/           # Playback models
├── collections/            # Generated assets (flutter_gen)
├── extensions/             # Dart extensions
└── utils/                  # Utility functions
```

### Key Technologies
- **State Management:** Riverpod + Flutter Hooks
- **Audio Playback:** `media_kit` (MPV-based)
- **Database:** Drift (SQLite)
- **Routing:** auto_route
- **Code Generation:** freezed, json_serializable
- **UI Framework:** shadcn_flutter
- **Plugin System:** Hetu Script (custom scripting language)

### Plugin Architecture
Spotube uses a unique plugin system based on **Hetu Script**:
- Plugins provide metadata (track info, albums, artists, playlists)
- Plugins provide audio sources (YouTube, etc.)
- Plugins are compiled to bytecode (.out files)
- Packaged as .smplug archives

```dart
// Plugin capabilities
"apis": ["webview", "localstorage", "timezone"],
"abilities": ["authentication", "metadata"]
```

### Audio Sources
1. **YouTube** (via plugins)
   - youtube_explode_dart
   - yt_dlp_dart
   - flutter_new_pipe_extractor

2. **Plugin-based** (extensible)
   - Any service can be added via plugins
   - Community-driven plugin ecosystem

### Key Features
- Cross-platform (all major platforms)
- Plugin-based extensibility
- Discord Rich Presence integration
- Last.fm scrobbling
- System tray support (desktop)
- Keyboard shortcuts
- Home widget support
- Time-synced lyrics
- Track source swapping (siblings)
- Quality presets (lossy/lossless)

### Audio Player Implementation
```dart
class AudioPlayerInterface {
  final CustomPlayer _mkPlayer; // media_kit based
  
  // Supports:
  // - Playlist management
  // - Shuffle/repeat modes
  // - Volume control
  // - Device selection
  // - Buffering state
}

class SourcedTrack {
  // Resolves track metadata to actual audio streams
  // Caches source matches in database
  // Supports sibling tracks (alternative sources)
  // Quality-based stream selection
}
```

### State Management Pattern
```dart
// Riverpod Notifier pattern
class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  // Syncs state with database
  // Handles track management
  // Persists playback state
}
```

---

## 3. Spotube Plugin Spotify

### Overview
- **Purpose:** Spotify metadata provider plugin for Spotube
- **Language:** Hetu Script (.ht files)
- **Version:** 0.2.0
- **Plugin API Version:** 2.0.0

### Architecture

```
src/
├── plugin.ht              # Main plugin entry point
├── converter/
│   └── converter.ht       # Data converters (Spotify -> Spotube format)
└── segments/              # API endpoint implementations
    ├── auth.ht            # Authentication (OAuth via webview)
    ├── album.ht           # Album endpoints
    ├── artist.ht          # Artist endpoints
    ├── browse.ht          # Browse/discover endpoints
    ├── playlist.ht        # Playlist endpoints
    ├── search.ht          # Search endpoints
    ├── track.ht           # Track endpoints
    ├── user.ht            # User profile endpoints
    └── core.ht            # Core plugin functionality

dependencies/
├── hetu_otp_util/         # OTP generation for auth
└── hetu_spotify_gql_client/ # Spotify GraphQL API client
```

### Plugin Structure
```javascript
// plugin.json
{
  "version": "0.2.0",
  "name": "Spotify",
  "entryPoint": "SpotifyMetadataProviderPlugin",
  "apis": ["webview", "localstorage", "timezone"],
  "abilities": ["authentication", "metadata"]
}
```

### Authentication Flow
1. Opens Spotify login via webview
2. Captures cookies after successful login
3. Generates TOTP using secret from remote config
4. Exchanges cookies + TOTP for access token
5. Stores credentials in local storage
6. Auto-refreshes tokens before expiration

### Data Converters
Converts Spotify API responses to Spotube's internal format:
- `fullTracks()` - Complete track info with ISRC
- `simpleAlbums()` / `fullAlbums()` - Album data
- `simpleArtists()` / `fullArtists()` - Artist data
- `fullPlaylists()` - Playlist with owner info
- `paginated()` - Handles pagination

### Key Implementation Details
```hetu
class SpotifyMetadataProviderPlugin {
  var auth: SpotifyAuthEndpoint
  var api: SpotifyGqlApi  // GraphQL client
  
  var album: AlbumEndpoint
  var artist: ArtistEndpoint
  var browse: BrowseEndpoint
  var playlist: PlaylistEndpoint
  var search: SearchEndpoint
  var track: TrackEndpoint
  var user: UserEndpoint
}
```

---

## Comparison Summary

| Feature | BlackHole | Spotube |
|---------|-----------|---------|
| **Primary Source** | JioSaavn | Plugin-based (any) |
| **State Management** | GetIt | Riverpod |
| **Audio Engine** | just_audio | media_kit (MPV) |
| **Database** | Hive | Drift (SQLite) |
| **Extensibility** | Limited | Plugin system |
| **Target Region** | India (primarily) | Global |
| **UI Framework** | Material | shadcn_flutter |
| **Code Generation** | Minimal | Heavy (freezed, etc.) |
| **Complexity** | Moderate | High |

---

## Technical Insights

### Audio Streaming Approach

**BlackHole:**
- Direct API calls to JioSaavn
- Decrypts encrypted audio URLs
- Quality selection per network type
- Simple URL-based streaming

**Spotube:**
- Plugin resolves metadata to track info
- Separate audio source plugin finds streams
- Ranks results by relevance (artist match, title match, official flag)
- Caches source matches in database
- Supports multiple quality presets

### Offline Support

**BlackHole:**
- Downloads with ID3 tag embedding
- Uses metadata_god for tagging
- Stores in device storage

**Spotube:**
- Similar download approach
- Tagged metadata support
- Integrated download manager

### UI/UX Patterns

**BlackHole:**
- Traditional Flutter Material Design
- Custom gradient containers
- Sliding up panel for player
- Bouncy scroll physics

**Spotube:**
- Modern shadcn_flutter components
- Adaptive layouts
- Desktop-first with mobile support
- System tray integration

---

## Learning Points for Building Your Own

1. **Audio Service Integration**
   - Use `audio_service` for background playback
   - Implement proper media controls
   - Handle audio focus

2. **API Integration**
   - Reverse engineer music service APIs
   - Handle authentication properly
   - Cache responses for performance

3. **Plugin Architecture** (Spotube approach)
   - Define clear plugin interfaces
   - Use scripting language for flexibility
   - Separate metadata from audio sources

4. **State Management**
   - Persist playback state
   - Sync with database
   - Handle offline scenarios

5. **Quality Selection**
   - Offer multiple quality options
   - Adapt to network conditions
   - Support both lossy and lossless

6. **Cross-Platform**
   - Use platform-specific audio engines
   - Handle permissions properly
   - Adapt UI for different form factors
