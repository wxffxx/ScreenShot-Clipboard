#!/bin/bash
set -e

APP_NAME="ScreenShot&Clipboard"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"

echo "Cleaning up old build..."
rm -rf "${APP_DIR}"

echo "Creating app bundle structure..."
mkdir -p "${MACOS_DIR}"

echo "Compiling main.swift..."
swiftc main.swift -o "${MACOS_DIR}/${APP_NAME}"

echo "Moving Info.plist into the app bundle..."
cp Info.plist "${CONTENTS_DIR}/"

LOGO_FILE=""
if [ -f "logo.png" ]; then LOGO_FILE="logo.png"; fi
if [ -f "logo.jpg" ]; then LOGO_FILE="logo.jpg"; fi
if [ -f "logo.jpeg" ]; then LOGO_FILE="logo.jpeg"; fi

if [ -n "$LOGO_FILE" ]; then
    echo "Found $LOGO_FILE! Converting to macOS AppIcon.icns..."
    mkdir -p AppIcon.iconset
    sips -s format png -z 16 16     "$LOGO_FILE" --out AppIcon.iconset/icon_16x16.png > /dev/null
    sips -s format png -z 32 32     "$LOGO_FILE" --out AppIcon.iconset/icon_16x16@2x.png > /dev/null
    sips -s format png -z 32 32     "$LOGO_FILE" --out AppIcon.iconset/icon_32x32.png > /dev/null
    sips -s format png -z 64 64     "$LOGO_FILE" --out AppIcon.iconset/icon_32x32@2x.png > /dev/null
    sips -s format png -z 128 128   "$LOGO_FILE" --out AppIcon.iconset/icon_128x128.png > /dev/null
    sips -s format png -z 256 256   "$LOGO_FILE" --out AppIcon.iconset/icon_128x128@2x.png > /dev/null
    sips -s format png -z 256 256   "$LOGO_FILE" --out AppIcon.iconset/icon_256x256.png > /dev/null
    sips -s format png -z 512 512   "$LOGO_FILE" --out AppIcon.iconset/icon_256x256@2x.png > /dev/null
    sips -s format png -z 512 512   "$LOGO_FILE" --out AppIcon.iconset/icon_512x512.png > /dev/null
    sips -s format png -z 1024 1024 "$LOGO_FILE" --out AppIcon.iconset/icon_512x512@2x.png > /dev/null
    iconutil -c icns AppIcon.iconset
    rm -R AppIcon.iconset
    
    mkdir -p "${CONTENTS_DIR}/Resources"
    mv AppIcon.icns "${CONTENTS_DIR}/Resources/"
fi

echo "Build complete. App is ready at ${APP_DIR}."
