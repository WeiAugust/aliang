#!/usr/bin/env bash

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
    else
        echo "generic/platform=iOS Simulator"
    fi
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
echo "Aliang iOS Xcode 测试"
echo "========================================="
echo "Scheme: $SCHEME"
echo "Destination: $DESTINATION"

echo ""
echo "[1/3] Build"
run_xcodebuild build \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug

echo ""
echo "[2/3] 集成回归测试"
run_xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:AliangIOSTests/TrackFRegressionRunnerTests

echo ""
echo "[3/3] 核心模块测试"
for test_class in \
    AuthViewModelTests \
    FeedViewModelTests \
    ComposerViewModelTests \
    InteractionViewModelTests \
    ProfileViewModelTests \
    SearchViewModelTests

do
    run_xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"AliangIOSTests/$test_class"
done

echo ""
echo "✅ iOS 测试执行完成"
