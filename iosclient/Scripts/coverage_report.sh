#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RESULT_FILE="${SCRIPT_DIR}/result.report"

# Initialize variables for totals
total_lines=0
weighted_coverage=0

# Print header
echo "📊 Test Coverage Report"
echo "----------------------------------------"

# Read the file line by line
while IFS= read -r line; do
    # Split the line into components
    IFS='-' read -r target coverage lines <<< "$line"
    
    # Calculate weighted coverage for this target
    target_weighted_coverage=$((coverage * lines))
    
    # Add to totals
    total_lines=$((total_lines + lines))
    weighted_coverage=$((weighted_coverage + target_weighted_coverage))
    
    # Print target details
    printf "📱 %-25s %3d%% (%4d lines)\n" "${target}" "${coverage}" "${lines}"
done < "${RESULT_FILE}"

# Calculate total coverage percentage
total_coverage=$((weighted_coverage / total_lines))

echo "----------------------------------------"
printf "📈 Total Coverage: %d%% (%d total lines)\n" "${total_coverage}" "${total_lines}" 
