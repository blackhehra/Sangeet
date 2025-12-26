# flutter_app

# Flutter + Kotlin Android App

A Flutter project with native Kotlin integration via Method Channels.

## Build APK

### Option 1: Using batch script
```cmd
build_apk.bat
```

### Option 2: Using Flutter command
```cmd
flutter build apk --debug
```

**APK Output:** `build\app\outputs\flutter-apk\app-debug.apk`

### Release APK
```cmd
flutter build apk --release
```

## Project Structure

```
Project/
├── lib/
│   └── main.dart                 # Flutter UI (Dart)
├── android/
│   └── app/src/main/kotlin/
│       └── MainActivity.kt       # Native Kotlin code
├── pubspec.yaml                  # Flutter dependencies
└── build_apk.bat                 # Build script
```

## Flutter ↔ Kotlin Communication

This app demonstrates calling native Kotlin code from Flutter using Method Channels:

- **Channel:** `com.example.flutter_app/native`
- **Methods:**
  - `greetFromKotlin(name)` - Returns greeting from Kotlin
  - `getDeviceInfo()` - Returns device info from Android APIs

### Adding More Kotlin Functions

1. Add method in `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
private fun myNewFunction(): String {
    return "Result from Kotlin"
}
```

2. Register in `configureFlutterEngine`:
```kotlin
"myNewMethod" -> result.success(myNewFunction())
```

3. Call from Flutter:
```dart
final result = await platform.invokeMethod('myNewMethod');
```
