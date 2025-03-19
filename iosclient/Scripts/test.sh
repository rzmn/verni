#!/usr/bin/env bash
set -e -x

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

RESULT_FILE="${SCRIPT_DIR}/result.report"
rm -f "${RESULT_FILE}"

function run_test() {
    SCHEME=$1
    PACKAGE_PATH=$2
    TARGET_NAME="${SCHEME}"
    
    echo "----------------------------------------"
    echo "Testing: ${TARGET_NAME}"

    BUILD_DIR="${PACKAGE_PATH}/_build"
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"

    cd "${PACKAGE_PATH}"
    swift package resolve

    xcodebuild \
        -scheme "${SCHEME}" test \
        -derivedDataPath "${BUILD_DIR}" \
        -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
        | xcbeautify
    
    REPORT=$(find "${BUILD_DIR}" -name "*.xcresult" -print | head -n 1)

    COVERAGE_DATA=$(xcrun xccov view --report --json "${REPORT}" | \
        jq --arg target "${TARGET_NAME}" '
        .targets[] | 
        select(.name == $target) | 
        {
            coverage: .lineCoverage,
            totalLines: (.files | map(.executableLines) | add)
        }')
    
    COVERAGE=$(echo "${COVERAGE_DATA}" | jq '.coverage')
    TOTAL_LINES=$(echo "${COVERAGE_DATA}" | jq '.totalLines')
    
    PERCENTAGE=$(echo "$COVERAGE * 100" | bc)
    PERCENTAGE_INT=${PERCENTAGE%.*}
    
    echo "${TARGET_NAME}-${PERCENTAGE_INT}-${TOTAL_LINES}" >> "${RESULT_FILE}"
}

INFRASTRUCTURE_DIR="${SCRIPT_DIR}/../Packages/Infrastructure"
DATA_DIR="${SCRIPT_DIR}/../Packages/Data"

TARGET_NAMES=(
    "FoundationFilesystem"
    "DefaultApiImplementation"
)

TARGET_PATHS=(
    "${INFRASTRUCTURE_DIR}/Filesystem/Implementations/FoundationFilesystem"
    "${DATA_DIR}/Api/Implementations/DefaultApiImplementation"
)

echo "Running tests for all targets..."
for i in "${!TARGET_NAMES[@]}"; do
    run_test "${TARGET_NAMES[$i]}" "${TARGET_PATHS[$i]}"
done

sh "${SCRIPT_DIR}/coverage_report.sh"

