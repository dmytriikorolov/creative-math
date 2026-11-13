#!/bin/zsh
set -eu
cd "$(dirname "$0")"

# Use the same build location from Finder and Terminal.
export TMPDIR=/private/tmp/
if ./scripts/build-app.sh release; then
    open "$TMPDIR/creative-math-build/Creative Math.app"
else
    printf '\nBuild failed. Press Return to close this window.'
    read -r
    exit 1
fi
