#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash Scripts/swift.sh build -c release
BIN_DIR="$(bash Scripts/swift.sh build -c release --show-bin-path)"
APP="$PWD/build/KeyShelf.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/KeyShelf" "$APP/Contents/MacOS/KeyShelf"
cp Resources/Info.plist "$APP/Contents/Info.plist"
bash Scripts/swift.sh Scripts/make-icon.swift "$PWD/build"
cp build/KeyShelf.icns "$APP/Contents/Resources/KeyShelf.icns"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
echo "Built: $APP"
