<div align="center">
  <h1>🎵 Sangeet</h1>

A cross-platform music streaming application built with Flutter.<br>
Stream your favorite music with a beautiful, modern interface and powerful features.

[![GitHub Release](https://img.shields.io/github/v/release/blackhehra/Sangeet)](https://github.com/blackhehra/Sangeet/releases)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/blackhehra/Sangeet/android-build.yml?label=Android%20Build)](https://github.com/blackhehra/Sangeet/actions)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/blackhehra/Sangeet/ios-build.yml?label=iOS%20Build)](https://github.com/blackhehra/Sangeet/actions)
[![License](https://img.shields.io/github/license/blackhehra/Sangeet)](LICENSE)

</div>

---

## 🌟 Features

- 🎵 **Stream Music** - High-quality audio streaming with adaptive quality
- 🔍 **Smart Search** - Find your favorite songs, artists, and albums instantly
- 📱 **Cross-Platform** - Available on Android and iOS
- 🎨 **Beautiful UI** - Modern, intuitive interface with smooth animations
- 🎧 **Background Playback** - Listen while using other apps
- 📻 **Lock Screen Controls** - Full media controls on lock screen
- 💾 **Smart Caching** - Intelligent caching for faster playback and offline listening
- 🔄 **Auto-Retry** - Automatic retry mechanism for failed tracks
- ⚡ **Fast Loading** - Optimized track matching and streaming
- 🎼 **Synced Lyrics** - Time-synchronized lyrics display
- 📊 **Equalizer** - Built-in audio equalizer for customized sound
- 🔊 **Bluetooth Support** - Seamless Bluetooth audio device integration
- 🌙 **Dark Mode** - Eye-friendly dark theme
- 🚀 **Native Performance** - Built with Flutter for smooth 60fps experience

## 📥 Installation

### Android

<a href="https://github.com/blackhehra/Sangeet/releases/latest">
  <img width="220" alt="Download APK" src="https://user-images.githubusercontent.com/114044633/223920025-83687de0-e463-4c5d-8122-e06e4bb7d40c.png">
</a>

**Latest Release:** Download the APK from [GitHub Releases](https://github.com/blackhehra/Sangeet/releases/latest)

**Installation Steps:**
1. Download `Sangeet-Android-1.0.0-beta.1.apk`
2. Enable "Install from Unknown Sources" in your device settings
3. Open the APK file and install

### iOS

<a href="https://github.com/blackhehra/Sangeet/releases/latest">
  <img width="220" alt="Download iOS IPA" src="https://github.com/user-attachments/assets/3e50d93d-fb39-435c-be6b-337745f7c423">
</a>

**Note:** iOS installation requires sideloading with [AltStore](https://altstore.io/) or similar tools.

**Installation Steps:**
1. Download `Sangeet-iOS.ipa` from [GitHub Releases](https://github.com/blackhehra/Sangeet/releases/latest)
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
- **YouTube Explode Dart** - YouTube data extraction
- **Drift** - SQLite database
- **Dio** - HTTP client
- **SharedPreferences** - Local storage

## 📱 Screenshots

*Coming soon...*

## 📄 License

This project is licensed under the BSD-4-Clause License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

### Services

- **YouTube** - Music streaming source
- **YouTube Music** - Music metadata and discovery
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
