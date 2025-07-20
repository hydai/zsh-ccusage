#!/usr/bin/env zsh

# Test script for JSON utilities

# Source the JSON utilities
source "$(dirname $0)/lib/json-utils.zsh"

echo "Testing JSON Utilities..."
echo "========================"

# Test 1: Empty input validation
echo "\nTest 1: Empty input validation"
result=$(ccusage_validate_json_input "")
exit_code=$?
echo "Result: '$result' (exit code: $exit_code)"
echo "Expected: '0.00' (exit code: 1)"

# Test 2: JSON with error field
echo "\nTest 2: JSON with error field"
error_json='{"error": "Network timeout", "code": "ETIMEDOUT"}'
result=$(ccusage_validate_json_input "$error_json")
exit_code=$?
echo "Result: '$result' (exit code: $exit_code)"
echo "Expected: '0.00' (exit code: 1)"

# Test 3: Valid JSON
echo "\nTest 3: Valid JSON"
valid_json='{"cost": "42.50", "usage": "high"}'
result=$(ccusage_validate_json_input "$valid_json")
exit_code=$?
echo "Result: '$result' (exit code: $exit_code)"
echo "Expected: '' (exit code: 0)"

# Test 4: Custom default value
echo "\nTest 4: Custom default value"
result=$(ccusage_validate_json_input "" "N/A")
exit_code=$?
echo "Result: '$result' (exit code: $exit_code)"
echo "Expected: 'N/A' (exit code: 1)"

# Test 5: Extract error message
echo "\nTest 5: Extract error message"
error_json='{"error": "Network timeout", "code": "ETIMEDOUT"}'
result=$(ccusage_extract_error_message "$error_json")
echo "Result: '$result'"
echo "Expected: 'Network timeout'"

# Test 6: Extract error from empty input
echo "\nTest 6: Extract error from empty input"
result=$(ccusage_extract_error_message "")
echo "Result: '$result'"
echo "Expected: ''"

# Test 7: Extract error from JSON without error
echo "\nTest 7: Extract error from JSON without error"
valid_json='{"cost": "42.50", "usage": "high"}'
result=$(ccusage_extract_error_message "$valid_json")
echo "Result: '$result'"
echo "Expected: ''"

echo "\nAll tests completed!"