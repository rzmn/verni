#!/usr/bin/env bash
set -e -x

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BUILD_DIR="${SCRIPT_DIR}/_build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

RESULT_FILE="${SCRIPT_DIR}/result.report"
rm -f "${RESULT_FILE}"

function run_test() {
    SCHEME=$1
    PACKAGE_PATH=$2
    TARGET_NAME="${SCHEME}"
    
    echo "----------------------------------------"
    echo "Testing: ${TARGET_NAME}"

    cd "${PACKAGE_PATH}"

    xcodebuild \
        -scheme "${SCHEME}" test \
        -derivedDataPath "${BUILD_DIR}" \
        -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
        | xcbeautify
    
    REPORT=$(find "${BUILD_DIR}" -name "*${TARGET_NAME}*.xcresult" -print | head -n 1)

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
DOMAIN_DIR="${SCRIPT_DIR}/../Packages/Domain"

TARGET_NAMES=(
    "FoundationFilesystem"

    "PersistentStorageSQLite"
    "DefaultApiImplementation"
    "DefaultServerSideEvents"
    "SandboxSyncEngine"
    "RemoteSyncEngine"

    "DefaultAvatarsRepositoryImplementation"
    "DefaultEmailConfirmationUseCaseImplementation"
    "DefaultValidationUseCasesImplementation"
)

TARGET_PATHS=(
    "${INFRASTRUCTURE_DIR}/Filesystem/Implementations/FoundationFilesystem"

    "${DATA_DIR}/PersistentStorage/Implementations/PersistentStorageSQLite"
    "${DATA_DIR}/Api/Implementations/DefaultApiImplementation"
    "${DATA_DIR}/ServerSideEvents/Implementations/DefaultServerSideEvents"
    "${DATA_DIR}/SyncEngine/Implementations/SandboxSyncEngine"
    "${DATA_DIR}/SyncEngine/Implementations/RemoteSyncEngine"

    "${DOMAIN_DIR}/AvatarsRepository/Implementations/DefaultAvatarsRepositoryImplementation"
    "${DOMAIN_DIR}/EmailConfirmationUseCase/Implementations/DefaultEmailConfirmationUseCaseImplementation"
    "${DOMAIN_DIR}/CredentialsFormatValidationUseCase/Implementations/DefaultValidationUseCasesImplementation"
)

echo "Running tests for all targets..."
for i in "${!TARGET_NAMES[@]}"; do
    run_test "${TARGET_NAMES[$i]}" "${TARGET_PATHS[$i]}"
done

rm -rf "${BUILD_DIR}"
sh "${SCRIPT_DIR}/coverage_report.sh"
