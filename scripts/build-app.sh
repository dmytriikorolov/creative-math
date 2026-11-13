#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."

# Keep all build artifacts and caches in a writable location for restricted sessions.
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/creative-math-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/creative-math-swift-cache"
build_path="${TMPDIR:-/tmp}/creative-math-build"
cache_path="${TMPDIR:-/tmp}/creative-math-package-cache"
build_configuration="${1:-debug}"
if [[ "$build_configuration" != debug && "$build_configuration" != release ]]; then
    printf '%s\n' 'Usage: build-app.sh [debug|release]' >&2
    exit 2
fi
swift build -c "$build_configuration" --disable-sandbox --cache-path "$cache_path" --scratch-path "$build_path"
bin_path=$(swift build -c "$build_configuration" --disable-sandbox --cache-path "$cache_path" --scratch-path "$build_path" --show-bin-path)
app_path="$build_path/Creative Math.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp Assets/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
cp "$bin_path/CreativeMath" "$app_path/Contents/MacOS/CreativeMath"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CreativeMath</string>
<key>CFBundleIdentifier</key><string>dev.creativemath.CreativeMath</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleName</key><string>Creative Math</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.0.1</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app_path"
printf '%s\n' "$app_path"
