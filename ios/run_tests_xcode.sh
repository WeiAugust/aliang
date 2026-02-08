#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$SCRIPT_DIR/AliangHostApp.xcodeproj"
SCHEME="${IOS_SCHEME:-AliangHostApp}"

pick_destination() {
    if [[ -n "${IOS_TEST_DESTINATION:-}" ]]; then
        echo "${IOS_TEST_DESTINATION}"
        return
    fi

    local simulator_id
    simulator_id="$( (xcodebuild -showdestinations -project "$PROJECT_PATH" -scheme "$SCHEME" 2>/dev/null) | awk '
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

run_swift_test() {
    swift test --package-path "$SCRIPT_DIR" "$@"
}

DESTINATION="$(pick_destination)"

echo "========================================="
echo "Aliang iOS 测试"
echo "========================================="
echo "Xcode Scheme: $SCHEME"
echo "Simulator: $DESTINATION"

echo ""
echo "[1/3] Build Host App (Simulator)"
run_xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug

echo ""
echo "[2/3] 集成回归测试 (Swift Package)"
run_swift_test --filter TrackFRegressionRunnerTests

echo ""
echo "[3/3] 核心模块测试 (Swift Package)"
for test_class in \
    AuthViewModelTests \
    FeedViewModelTests \
    ComposerViewModelTests \
    InteractionViewModelTests \
    ProfileViewModelTests \
    SearchViewModelTests
do
    run_swift_test --filter "$test_class"
done

echo ""
echo "✅ iOS 测试执行完成"
