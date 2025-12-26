@echo off
REM Build script for Sangeet Windows Executable
REM This script builds the Flutter app and creates an installer using Inno Setup

echo ========================================
echo Building Sangeet for Windows
echo ========================================

REM Step 1: Clean previous build
echo.
echo [1/4] Cleaning previous build...
call flutter clean

REM Step 2: Get dependencies
echo.
echo [2/4] Getting dependencies...
call flutter pub get

REM Step 3: Build Windows release
echo.
echo [3/4] Building Windows release...
call flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)

echo.
echo [4/4] Build complete!
echo.
echo ========================================
echo Build Output Location:
echo   build\windows\x64\runner\Release\
echo.
echo To create installer:
echo   1. Install Inno Setup from https://jrsoftware.org/isinfo.php
echo   2. Open windows\packaging\exe\inno_setup.iss in Inno Setup
echo   3. Click Build ^> Compile
echo   4. Installer will be created in dist\ folder
echo ========================================
echo.

REM Check if Inno Setup is installed and offer to compile
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo Inno Setup detected! Creating installer...
    mkdir dist 2>nul
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\packaging\exe\inno_setup.iss
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo SUCCESS: Installer created at dist\Sangeet-windows-x86_64-setup.exe
    )
) else (
    echo Inno Setup not found. Install it to create the installer automatically.
)

pause
