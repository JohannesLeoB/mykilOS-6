#!/usr/bin/env bash
set -euo pipefail

# Baut die App und verpackt sie in eine DMG für die Distribution.
# Voraussetzung: build_and_run.sh muss vorher gelaufen sein (oder die App
# liegt bereits unter dist/mykilOS 6.app).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/mykilOS 6.app"
DMG_NAME="mykilOS-6"
DMG_PATH="$DIST_DIR/$DMG_NAME.dmg"
VOLUME_NAME="mykilOS 6"

# Build falls nötig
if [ ! -d "$APP_BUNDLE" ]; then
  echo "App-Bundle nicht gefunden, baue erst…" >&2
  "$ROOT_DIR/script/build_and_run.sh" &
  BUILD_PID=$!
  sleep 3
  kill "$BUILD_PID" 2>/dev/null || true
fi

if [ ! -d "$APP_BUNDLE" ]; then
  echo "Fehler: $APP_BUNDLE existiert nicht." >&2
  exit 1
fi

# Alte DMG entfernen
rm -f "$DMG_PATH"

# DMG erstellen
echo "Erstelle DMG…" >&2
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$APP_BUNDLE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG erstellt: $DMG_PATH" >&2
echo "Größe: $(du -h "$DMG_PATH" | cut -f1)" >&2
