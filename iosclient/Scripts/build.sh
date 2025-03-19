#!/usr/bin/env bash
set -ex

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${SCRIPT_DIR}/../Packages/Assembly"

xcodebuild \
    -scheme Assembly clean build analyze \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=latest" \
    | xcbeautify && exit ${PIPESTATUS[0]}