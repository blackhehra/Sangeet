@echo off
echo ========================================
echo Building Sangeet APK (Release)
echo ========================================
echo.

echo Cleaning previous build...
call flutter clean
echo.

echo Getting dependencies...
call flutter pub get
echo.

echo Building APK...
call flutter build apk --release
echo.

echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo To install on your device:
echo 1. Connect your device via USB
echo 2. Enable USB debugging
echo 3. Run: adb install -r build\app\outputs\flutter-apk\app-release.apk
echo.
pause
