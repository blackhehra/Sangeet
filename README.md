<div align="center">
  <h1>🎵 Sangeet</h1>

A cross-platform music streaming application built by **blackhehra** with Flutter.<br>
Stream your favorite music with a beautiful, modern interface and powerful features.

**Keywords:** music player, flutter, streaming app, blackhehra, sangeet, cross-platform, android, ios

[![GitHub Release](https://img.shields.io/github/v/release/blackhehra/Sangeet)](https://github.com/blackhehra/Sangeet/releases)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/blackhehra/Sangeet/android-build.yml?label=Android%20Build)](https://github.com/blackhehra/Sangeet/actions)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/blackhehra/Sangeet/ios-build.yml?label=iOS%20Build)](https://github.com/blackhehra/Sangeet/actions)
[![License](https://img.shields.io/github/license/blackhehra/Sangeet)](LICENSE)
[![Stars](https://img.shields.io/github/stars/blackhehra/Sangeet?style=social)](https://github.com/blackhehra/Sangeet)
[![Forks](https://img.shields.io/github/forks/blackhehra/Sangeet?style=social)](https://github.com/blackhehra/Sangeet)

</div>

---

## 📖 About Sangeet

**Sangeet** Sangeet is a modern, open-source music streaming application developed by **blackhehra**. Built with Flutter, it provides a seamless music listening experience across Android, iOS, Windows, macOS, and Linux platforms.

### 🎯 Why Sangeet?

- **Free & Open Source** - No ads, no subscriptions, completely free
- **Music Streaming Integration** - Access millions of songs
- **Cross-Platform** - Same experience on all your devices
- **Privacy-Focused** - No data collection, no tracking
- **Beautiful UI** - Material Design 3 with smooth animations

### 🔍 Search Keywords
music player, flutter music app, blackhehra, sangeet music, cross-platform music, android music player, ios music app, music streaming, free music app

## ✨ Features

### 🎵 Playback & Streaming
- **High-Quality Audio Streaming** - Stream music with adaptive quality
- **Background Playback** - Continue listening while using other apps or when screen is off
- **Persistent Stream Cache** - Smart caching system that remembers stream URLs across app restarts for instant playback
- **Auto-Retry Logic** - Automatic retry mechanism with exponential backoff for failed tracks
- **Priority Track Matching** - Intelligent matching algorithm that prioritizes currently playing tracks
- **Offline Cache** - Download and cache songs for offline listening

### 🎨 User Interface
- **Modern Material Design 3** - Beautiful, intuitive interface following latest design guidelines
- **Smooth Animations** - 60fps performance with fluid transitions and animations
- **Dark Mode** - Eye-friendly dark theme with dynamic colors
- **Lock Screen Controls** - Full media controls on lock screen and notification shade
- **Mini Player** - Persistent mini player for quick access to playback controls

### 🔍 Discovery & Organization
- **Smart Search** - Find songs, artists, albums, and playlists instantly
- **Playlist Management** - Create, edit, and organize your playlists
- **Queue Management** - Reorder, add, or remove songs from the playback queue
- **Listening History** - Track your recently played songs
- **Quick Picks** - Personalized music recommendations

### 🎼 Advanced Features
- **Synced Lyrics** - Time-synchronized lyrics display with auto-scroll
- **Audio Equalizer** - Built-in equalizer with presets and custom settings
- **Bluetooth Support** - Seamless integration with Bluetooth audio devices
- **Sleep Timer** - Auto-stop playback after a set duration
- **Crossfade** - Smooth transitions between tracks

### 🚀 Performance
- **Native Performance** - Built with Flutter for smooth, native-like experience
- **Optimized Track Matching** - Background pre-fetching and caching for instant playback
- **Low Data Usage** - Efficient streaming with minimal data consumption
- **Fast App Startup** - Optimized initialization for quick app launch

## 📥 Installation

### Android

<a href="https://github.com/blackhehra/Sangeet/releases/latest">
  <img width="220" alt="Download APK" src="https://user-images.githubusercontent.com/114044633/223920025-83687de0-e463-4c5d-8122-e06e4bb7d40c.png">
</a>

**Latest Release:** Download the APK from [GitHub Releases](https://github.com/blackhehra/Sangeet/releases/latest)

[![Latest Release](https://img.shields.io/github/v/release/blackhehra/Sangeet?label=Latest%20Version)](https://github.com/blackhehra/Sangeet/releases/latest)

**Installation Steps:**
1. Download the latest APK from the releases page
2. Enable "Install from Unknown Sources" in your device settings
3. Open the APK file and install

### iOS

<a href="https://github.com/blackhehra/Sangeet/releases/latest">
  <img width="220" alt="Download iOS IPA" src="https://github.com/user-attachments/assets/3e50d93d-fb39-435c-be6b-337745f7c423">
</a>

**Note:** iOS installation requires sideloading with [AltStore](https://altstore.io/) or similar tools.

**Installation Steps:**
1. Download the latest IPA from [GitHub Releases](https://github.com/blackhehra/Sangeet/releases/latest)
2. Install AltStore on your iOS device
3. Use AltStore to sideload the IPA file


## 🛠️ Building from Source

### Prerequisites

- Flutter SDK (3.35.6 or later)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git

### Clone the Repository

```bash
git clone https://github.com/blackhehra/Sangeet.git
cd Sangeet
```

### Install Dependencies

```bash
flutter pub get
```

### Create Environment File

Create a `.env` file in the root directory:

```env
YTM_API_KEY=your_youtube_music_api_key_here
```

### Build for Android

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### Build for iOS

```bash
# Build iOS (requires macOS)
flutter build ios --release --no-codesign
```

**Output:** `build/ios/iphoneos/Runner.app`

## 🏗️ Architecture

Sangeet is built with a modern, scalable architecture:

- **State Management:** Riverpod for reactive state management
- **Audio Playback:** media_kit with native performance
- **Streaming:** Custom HTTP server with intelligent caching
- **Track Matching:** Advanced algorithm with priority matching and background pre-fetching
- **UI:** Flutter with custom animations and Material Design 3
- **Storage:** SQLite (Drift) for local data persistence
- **Network:** Dio for efficient HTTP requests

## 🎯 Key Technologies

- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management
- **media_kit** - High-performance audio playback
- **Music Service** - Music data extraction
- **Drift** - SQLite database
- **Dio** - HTTP client
- **SharedPreferences** - Local storage

## 📱 Screenshots

*Coming soon...*

## 📄 License

This project is licensed under the BSD-4-Clause License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This project and its contents are not affiliated with, funded, authorized, endorsed by, or in any way associated with YouTube, Google LLC, or any of its affiliates and subsidiaries.

Any trademark, service mark, trade name, or other intellectual property rights used in this project are owned by the respective owners.

Sangeet is an independent application that uses publicly available APIs and services. Users are responsible for complying with YouTube's Terms of Service.

## 🙏 Acknowledgments

### Services

- **Music Service** - Music streaming source
- **Music Service** - Music metadata and discovery
- **Flutter** - Cross-platform framework
- **GitHub Actions** - CI/CD pipeline

### Key Dependencies

- [flutter_riverpod](https://riverpod.dev) - State management
- [media_kit](https://github.com/media-kit/media-kit) - Audio playback
- [youtube_explode_dart](https://github.com/Hexer10/youtube_explode_dart) - YouTube data extraction
- [drift](https://drift.simonbinder.eu/) - SQLite database
- [dio](https://github.com/cfug/dio) - HTTP client
- [cached_network_image](https://github.com/Baseflow/flutter_cached_network_image) - Image caching
- [audio_service](https://pub.dev/packages/audio_service) - Background audio
- [shared_preferences](https://pub.dev/packages/shared_preferences) - Local storage

For a complete list of dependencies, see [pubspec.yaml](pubspec.yaml).

## 📞 Contact

**Telegram:** [https://t.me/sangeet_official](https://t.me/sangeet_official)

**Project Link:** [https://github.com/blackhehra/Sangeet](https://github.com/blackhehra/Sangeet)

---

<div align="center">
  <sub>Built with ❤️ using Flutter</sub>
</div>
