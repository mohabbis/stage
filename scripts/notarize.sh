#!/bin/zsh
set -euo pipefail

: "${APPLE_ID:?Set APPLE_ID}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID}"
: "${DEVELOPER_ID:?Set DEVELOPER_ID to the Developer ID Application identity}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build

xcodebuild -project Stage.xcodeproj -scheme Stage -configuration Release \
  -archivePath build/Stage.xcarchive archive \
  CODE_SIGN_STYLE=Manual \
  "CODE_SIGN_IDENTITY=$DEVELOPER_ID" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  ENABLE_HARDENED_RUNTIME=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO

APP="build/Stage.xcarchive/Products/Applications/Stage.app"
rm -f build/Stage.dmg
hdiutil create -volname Stage -srcfolder "$APP" -ov -format UDZO build/Stage.dmg
xcrun notarytool submit build/Stage.dmg \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait
xcrun stapler staple build/Stage.dmg
echo "Notarized disk image: $ROOT/build/Stage.dmg"
