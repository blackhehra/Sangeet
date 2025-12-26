@echo off
REM Build script for Sangeet Windows Portable Version
REM Creates a portable zip file that can run without installation

echo ========================================
echo Building Sangeet Portable for Windows
echo ========================================

REM Step 1: Clean previous build
echo.
echo [1/5] Cleaning previous build...
call flutter clean

REM Step 2: Get dependencies
echo.
echo [2/5] Getting dependencies...
call flutter pub get

REM Step 3: Build Windows release
echo.
echo [3/5] Building Windows release...
call flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)

REM Step 4: Create dist folder
echo.
echo [4/5] Preparing portable package...
mkdir dist 2>nul

REM Step 5: Create zip file using PowerShell
echo.
echo [5/5] Creating portable zip...
powershell -Command "Compress-Archive -Path 'build\windows\x64\runner\Release\*' -DestinationPath 'dist\Sangeet-windows-x86_64-portable.zip' -Force"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS!
    echo Portable version created at:
    echo   dist\Sangeet-windows-x86_64-portable.zip
    echo.
    echo Users can extract and run sangeet.exe directly
    echo ========================================
) else (
    echo.
    echo ERROR: Failed to create zip file
)

pause
