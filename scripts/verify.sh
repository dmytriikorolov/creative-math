#!/bin/zsh
# Reproducible local checks. UI inspection is a separate, explicit gate.
set -eu
set -o pipefail
cd "$(dirname "$0")/.."
mode="${1:-check}"
if [[ "$mode" != check && "$mode" != launch && "$mode" != xcode ]]; then
    print -u2 'Usage: scripts/verify.sh [check|launch|xcode]'
    exit 2
fi
export TMPDIR="${TMPDIR:-/private/tmp/}"
artifacts="${CREATIVE_MATH_ARTIFACTS:-$PWD/docs/evidence/verification-$(date -u +%Y%m%dT%H%M%SZ)-$$}"
mkdir -p "$artifacts/screenshots"
print "Artifacts: $artifacts"
run_check() {
    local label="$1"
    shift
    print "Running $label"
    if "$@" > "$artifacts/$label.log" 2>&1; then
        print "$label: PASS" | tee -a "$artifacts/results.txt"
    else
        local result=$?
        print "$label: FAIL ($result); see $label.log" | tee -a "$artifacts/results.txt"
        return "$result"
    fi
}
if [[ "$mode" == xcode ]]; then
    run_check xcode xcodebuild -project CreativeMath.xcodeproj -scheme CreativeMath \
        -destination 'platform=macOS' -derivedDataPath "$TMPDIR/creative-math-xcode" \
        -resultBundlePath "$artifacts/CreativeMath.xcresult" build test
else
    run_check tests ./scripts/test.sh
    run_check build ./scripts/build-app.sh release
    run_check signature codesign --verify --deep --strict "$TMPDIR/creative-math-build/Creative Math.app"
    if [[ "$mode" == launch ]]; then
        run_check launch open "$TMPDIR/creative-math-build/Creative Math.app"
    fi
fi
print 'VISUAL QA: NOT RUN by this script. Inspect the live app and record screenshots separately.' | tee -a "$artifacts/results.txt"
