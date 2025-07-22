@echo off
REM =============================================================================
REM Frontend Production Build Script (Windows)
REM =============================================================================
REM This script builds the frontend for production deployment on Windows
REM =============================================================================

setlocal enabledelayedexpansion

echo [%date% %time%] Starting Frontend Production Build
echo ==================================================

REM Check if we're in the Frontend directory
if not exist "package.json" (
    echo [ERROR] This script must be run from the Frontend directory
    exit /b 1
)

REM Clean previous builds
if exist "dist" (
    echo [%date% %time%] Cleaning previous build...
    rmdir /s /q dist
)

REM Install dependencies
echo [%date% %time%] Installing dependencies...
call npm ci --only=production
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    exit /b 1
)

REM Run build
echo [%date% %time%] Building for production...
call npm run build
if errorlevel 1 (
    echo [ERROR] Build failed
    exit /b 1
)

REM Verify build
if not exist "dist" (
    echo [ERROR] Build failed - dist directory not created
    exit /b 1
)

if not exist "dist\index.html" (
    echo [ERROR] Build failed - index.html not found in dist
    exit /b 1
)

echo [%date% %time%] Build completed successfully!
echo [INFO] Build output is in the 'dist' directory

REM Show files in build
echo [INFO] Build contents:
dir dist

echo ==================================================
echo [%date% %time%] Frontend build ready for deployment!
echo [INFO] Deploy the 'dist' directory to your web server

pause
