#!/bin/bash

# Track F Integration & QA Test Runner
# This script should be run in Xcode 15+ environment

set -euo pipefail

SCHEME="${IOS_SCHEME:-AliangIOS}"

pick_destination() {
    if [[ -n "${IOS_TEST_DESTINATION:-}" ]]; then
        echo "${IOS_TEST_DESTINATION}"
        return
    fi

    local simulator_id
    simulator_id="$( (xcodebuild -showdestinations -scheme "$SCHEME" 2>/dev/null) | awk '
        /platform:iOS Simulator/ && /name:iPhone/ && /id:/ {
            if (match($0, /id:[^,}]+/)) {
                id = substr($0, RSTART + 3, RLENGTH - 3)
                if (id !~ /^dvtdevice-/) {
                    print id
                    exit
                }
            }
        }
    ')"

    if [[ -n "$simulator_id" ]]; then
        echo "id=$simulator_id"
        return
    fi

    echo "generic/platform=iOS Simulator"
}

run_xcodebuild() {
    if command -v xcpretty >/dev/null 2>&1; then
        xcodebuild "$@" | xcpretty
    else
        xcodebuild "$@"
    fi
}

DESTINATION="$(pick_destination)"

echo "========================================="
echo "Track F Integration & QA Test Runner"
echo "========================================="
echo "Using scheme: $SCHEME"
echo "Using destination: $DESTINATION"

echo ""
echo "Step 1: Building iOS project..."
run_xcodebuild build \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug

echo ""
echo "Step 2: Running Track F regression tests..."
run_xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:AliangIOSTests/TrackFRegressionRunnerTests

echo ""
echo "Step 3: Running all Track tests..."
for test_class in \
    AuthViewModelTests \
    FeedViewModelTests \
    ComposerViewModelTests \
    InteractionViewModelTests
do
    run_xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"AliangIOSTests/$test_class"
done

echo ""
echo "========================================="
echo "All Track F test gates passed!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Run E2E simulator testing (login -> feed -> publish -> like/comment)"
echo "2. Generate PR summary"
echo "3. Merge feat/ios-05-integration-qa to main"
