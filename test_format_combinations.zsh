#!/usr/bin/env zsh

# Test script for cost and percentage mode combinations formatting
# Tests formatting logic without requiring actual ccusage data

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"

# Source formatting functions
source "${0:A:h}/functions/ccusage-format"

echo "=== Testing Cost and Percentage Mode Format Combinations ==="
echo

# Define test data
local test_cost="45.23"
local test_percentage="85"
local is_stale="false"

# Define the modes to test
local cost_modes=("active" "daily" "monthly")
local percentage_modes=("daily_avg" "daily_plan" "monthly")

# Track test results
local total_tests=0
local passed_tests=0
local failed_tests=0

# Function to check display format
function check_format() {
    local display=$1
    local expected_cost_suffix=$2
    local expected_percentage_suffix=$3
    
    # Remove color codes
    local clean_display="$display"
    clean_display="${clean_display//$'\e'\[[0-9;]*m/}"
    clean_display="${clean_display//\%F\{[a-zA-Z]*\}/}"
    clean_display="${clean_display//\%f/}"
    clean_display="${clean_display//\%B/}"
    clean_display="${clean_display//\%b/}"
    
    # Check if format matches expected pattern (note: %% is used for literal % in ZSH prompts)
    if [[ "$clean_display" =~ "\$${test_cost}${expected_cost_suffix}.*${test_percentage}%%${expected_percentage_suffix}" ]]; then
        return 0
    else
        return 1
    fi
}

echo "Testing all 9 combinations of cost and percentage modes:"
echo "Using test data: cost=$test_cost, percentage=$test_percentage"
echo "Format: [Cost Mode] + [Percentage Mode] = Display Format"
printf '%60s\n' | tr ' ' '-'
echo

# Test normal width format
echo "Normal terminal width (≥80 chars):"
echo

# Ensure we have a wide terminal
export COLUMNS=120

for cost_mode in $cost_modes; do
    for percentage_mode in $percentage_modes; do
        ((total_tests++))
        
        # Set the modes
        export CCUSAGE_COST_MODE="$cost_mode"
        export CCUSAGE_PERCENTAGE_MODE="$percentage_mode"
        
        # Determine expected suffixes
        local cost_suffix
        case "$cost_mode" in
            active) cost_suffix="A" ;;
            daily) cost_suffix="D" ;;
            monthly) cost_suffix="M" ;;
        esac
        
        local percentage_suffix
        case "$percentage_mode" in
            daily_avg) percentage_suffix="D" ;;
            daily_plan) percentage_suffix="P" ;;
            monthly) percentage_suffix="M" ;;
        esac
        
        # Get formatted display
        local display=$(ccusage_format_display "$test_cost" "$test_percentage" "$is_stale" "$cost_suffix")
        
        # Check the format
        local test_label="${cost_mode} + ${percentage_mode}"
        printf "%-25s → " "$test_label"
        
        if check_format "$display" "$cost_suffix" "$percentage_suffix"; then
            echo "✓ $display"
            ((passed_tests++))
        else
            echo "✗ $display (expected \$${test_cost}${cost_suffix} and ${test_percentage}%${percentage_suffix})"
            ((failed_tests++))
        fi
    done
    echo
done

# Test compact format
echo "Compact format (terminal width < 80):"
printf '%60s\n' | tr ' ' '-'
echo

# Set narrow terminal
export COLUMNS=60

for cost_mode in $cost_modes; do
    for percentage_mode in $percentage_modes; do
        ((total_tests++))
        
        # Set the modes
        export CCUSAGE_COST_MODE="$cost_mode"
        export CCUSAGE_PERCENTAGE_MODE="$percentage_mode"
        
        # Determine expected suffixes
        local cost_suffix
        case "$cost_mode" in
            active) cost_suffix="A" ;;
            daily) cost_suffix="D" ;;
            monthly) cost_suffix="M" ;;
        esac
        
        local percentage_suffix
        case "$percentage_mode" in
            daily_avg) percentage_suffix="D" ;;
            daily_plan) percentage_suffix="P" ;;
            monthly) percentage_suffix="M" ;;
        esac
        
        # Get formatted display
        local display=$(ccusage_format_display "$test_cost" "$test_percentage" "$is_stale" "$cost_suffix")
        
        # Check the format (should be compact without brackets)
        local test_label="${cost_mode} + ${percentage_mode}"
        printf "%-25s → " "$test_label"
        
        # Remove color codes
        local clean_display="$display"
        clean_display="${clean_display//$'\e'\[[0-9;]*m/}"
        clean_display="${clean_display//\%F\{[a-zA-Z]*\}/}"
        clean_display="${clean_display//\%f/}"
        clean_display="${clean_display//\%B/}"
        clean_display="${clean_display//\%b/}"
        
        if [[ "$clean_display" =~ "^\$${test_cost}${cost_suffix}\|" ]]; then
            echo "✓ $display (compact)"
            ((passed_tests++))
        else
            echo "✗ $display (expected compact format)"
            ((failed_tests++))
        fi
    done
done

# Reset terminal width
unset COLUMNS

echo
printf '%60s\n' | tr ' ' '-'
echo "Test Summary:"
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"

if (( failed_tests == 0 )); then
    echo
    echo "✅ All format combination tests passed!"
    exit 0
else
    echo
    echo "❌ Some tests failed!"
    exit 1
fi