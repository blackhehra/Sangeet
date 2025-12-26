@echo off
echo ============================================
echo   Flutter + Kotlin APK Builder
echo ============================================
echo.

echo [INFO] Building APK...
flutter build apk --debug

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================
    echo   Build Successful!
    echo ============================================
    echo.
    echo APK Location:
    echo   build\app\outputs\flutter-apk\app-debug.apk
    echo.
) else (
    echo.
    echo [ERROR] Build failed!
)
pause
