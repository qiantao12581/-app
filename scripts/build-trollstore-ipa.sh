#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
PROJECT_PATH="$REPOSITORY_ROOT/NutritionTracker.xcodeproj"
SCHEME="NutritionTracker"
OUTPUT_ROOT="$REPOSITORY_ROOT/artifacts"
DERIVED_DATA="$OUTPUT_ROOT/DerivedData"
PACKAGE_ROOT="$OUTPUT_ROOT/package"
APP_PATH="$DERIVED_DATA/Build/Products/Release-iphoneos/NutritionTracker.app"
IPA_PATH="$OUTPUT_ROOT/NutritionTracker-TrollStore.ipa"
BUILD_INFO_PATH="$OUTPUT_ROOT/build-info.txt"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "错误：找不到 $PROJECT_PATH" >&2
  exit 1
fi

rm -rf "$OUTPUT_ROOT"
mkdir -p "$OUTPUT_ROOT" "$PACKAGE_ROOT/Payload"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "错误：Xcode 构建完成，但没有找到 NutritionTracker.app" >&2
  exit 1
fi

/usr/bin/ditto "$APP_PATH" "$PACKAGE_ROOT/Payload/NutritionTracker.app"
(
  cd "$PACKAGE_ROOT"
  /usr/bin/zip -qry "$IPA_PATH" Payload
)

/usr/bin/unzip -t "$IPA_PATH"

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
MINIMUM_IOS=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$APP_PATH/Info.plist")
XCODE_VERSION=$(xcodebuild -version | tr '\n' ' ')
SHA256=$(shasum -a 256 "$IPA_PATH" | awk '{print $1}')

cat > "$BUILD_INFO_PATH" <<INFO
文件: NutritionTracker-TrollStore.ipa
Bundle ID: $BUNDLE_ID
最低 iOS: $MINIMUM_IOS
Xcode: $XCODE_VERSION
SHA-256: $SHA256
INFO

cat "$BUILD_INFO_PATH"
echo "IPA 已生成：$IPA_PATH"

