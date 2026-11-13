#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/creative-math-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/creative-math-swift-cache"
developer_path=$(xcode-select -p)
test_flags=()
if [[ "$developer_path" == */CommandLineTools ]]; then
    # This CLT distribution includes Swift Testing but SwiftPM omits its search paths.
    test_flags=(
        -Xswiftc "-F$developer_path/Library/Developer/Frameworks"
        -Xlinker -rpath -Xlinker "$developer_path/Library/Developer/Frameworks"
        -Xlinker -rpath -Xlinker "$developer_path/Library/Developer/usr/lib"
    )
fi
swift test --disable-sandbox --disable-xctest --enable-swift-testing \
    --cache-path "${TMPDIR:-/tmp}/creative-math-package-cache" \
    --scratch-path "${TMPDIR:-/tmp}/creative-math-build" "${test_flags[@]}"
