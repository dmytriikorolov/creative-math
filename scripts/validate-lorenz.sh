#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/creative-math-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/creative-math-swift-cache"
swift run --disable-sandbox --cache-path "${TMPDIR:-/tmp}/creative-math-package-cache" \
    --scratch-path "${TMPDIR:-/tmp}/creative-math-build" -c release LorenzValidation "$@"
