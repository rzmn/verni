#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RESULT_FILE="${SCRIPT_DIR}/result.report"

# Initialize variables for totals
TOTAL_LINES=0
WEIGHTED_COVERAGE=0

# Print header
echo "📊 Test Coverage Report"
echo "----------------------------------------"

# Read the file line by line
while IFS= read -r LINE; do
    # Split the line into components
    IFS='-' read -r TARGET COVERAGE LINES <<< "$LINE"
    
    # Calculate weighted coverage for this target
    TARGET_WEIGHTED_COVERAGE=$((COVERAGE * LINES))
    
    # Add to totals
    TOTAL_LINES=$((TOTAL_LINES + LINES))
    WEIGHTED_COVERAGE=$((WEIGHTED_COVERAGE + TARGET_WEIGHTED_COVERAGE))
    
    # Print target details
    printf "📱 %-25s %3d%% (%4d lines)\n" "${TARGET}" "${COVERAGE}" "${LINES}"
done < "${RESULT_FILE}"

# Calculate total coverage percentage
TOTAL_COVERAGE=$((WEIGHTED_COVERAGE / TOTAL_LINES))

PACKAGES_COUNT=$(cd "${SCRIPT_DIR}/../Packages" && git ls-files "./**/Implementations/**/Package.swift" | wc -l)
PACKAGES_COVERED_COUNT=$(cat "${RESULT_FILE}" | wc -l)

echo "----------------------------------------"
printf "📈 Packages covered: %d of %d\n" "${PACKAGES_COVERED_COUNT}" "${PACKAGES_COUNT}" 
printf "📈 Coverage for covered packages: %d%% (%d total lines)\n" "${TOTAL_COVERAGE}" "${TOTAL_LINES}" 

curl --location --request PUT 'https://api.jsonbin.io/v3/b/66e66909acd3cb34a884adb5' \
    --header "X-Master-Key: ${JSONBINS_KEY}" \
    --header "Content-Type: application/json" \
    --data "{\"coverage\":\"${TOTAL_COVERAGE}%\"}"