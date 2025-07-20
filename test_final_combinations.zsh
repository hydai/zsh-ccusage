#!/usr/bin/env zsh

# Final test script for cost and percentage mode combinations
# This version tests the formatting function directly

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"
source "${0:A:h}/functions/ccusage-format"

echo "=== Testing Cost and Percentage Mode Combinations ==="
echo "Testing format function with sample data"
echo

# Test data
local test_cost="45.23"
local test_percentage="85"

# Track results
local passed=0
local failed=0

# Test all 9 combinations
echo "All 9 combinations (3 cost modes × 3 percentage modes):"
echo "------------------------------------------------------------"

local cost_modes=("active" "daily" "monthly")
local percentage_modes=("daily_avg" "daily_plan" "monthly")

# Map mode to suffix
typeset -A cost_suffixes=(
    "active" "A"
    "daily" "D"
    "monthly" "M"
)

typeset -A percentage_suffixes=(
    "daily_avg" "D"
    "daily_plan" "P"
    "monthly" "M"
)

# Test with normal width
export COLUMNS=120

for cost_mode in $cost_modes; do
    for percentage_mode in $percentage_modes; do
        # Set environment variables
        export CCUSAGE_COST_MODE="$cost_mode"
        export CCUSAGE_PERCENTAGE_MODE="$percentage_mode"
        
        # Get the expected suffixes
        local cost_suffix="${cost_suffixes[$cost_mode]}"
        local percentage_suffix="${percentage_suffixes[$percentage_mode]}"
        
        # Format the display
        local display=$(ccusage_format_display "$test_cost" "$test_percentage" "false" "$cost_suffix")
        
        # Clean for checking
        local clean="$display"
        clean="${clean//\%F\{[a-zA-Z]*\}/}"
        clean="${clean//\%f/}"
        clean="${clean//\%B/}"
        clean="${clean//\%b/}"
        clean="${clean//$'\e'\[[0-9;]*m/}"
        
        # Check format
        printf "%-20s + %-12s = " "$cost_mode" "$percentage_mode"
        
        # Expected format: [$45.23X | 85%%Y] where X is cost suffix, Y is percentage suffix
        if [[ "$clean" =~ "\[\$${test_cost}${cost_suffix} \| ${test_percentage}%%${percentage_suffix}\]" ]]; then
            echo "✓ $display"
            ((passed++))
        else
            echo "✗ $display (expected [\$${test_cost}${cost_suffix} | ${test_percentage}%${percentage_suffix}])"
            ((failed++))
        fi
    done
done

echo
echo "Compact mode test (terminal width < 80):"
echo "------------------------------------------------------------"

# Test with narrow terminal
export COLUMNS=60

for cost_mode in ("daily" "monthly"); do
    for percentage_mode in ("daily_avg" "monthly"); do
        # Set environment variables
        export CCUSAGE_COST_MODE="$cost_mode"
        export CCUSAGE_PERCENTAGE_MODE="$percentage_mode"
        
        # Get the expected suffixes
        local cost_suffix="${cost_suffixes[$cost_mode]}"
        local percentage_suffix="${percentage_suffixes[$percentage_mode]}"
        
        # Format the display
        local display=$(ccusage_format_display "$test_cost" "$test_percentage" "false" "$cost_suffix")
        
        # Clean for checking
        local clean="$display"
        clean="${clean//\%F\{[a-zA-Z]*\}/}"
        clean="${clean//\%f/}"
        clean="${clean//\%B/}"
        clean="${clean//\%b/}"
        clean="${clean//$'\e'\[[0-9;]*m/}"
        
        # Check format
        printf "%-20s + %-12s = " "$cost_mode" "$percentage_mode"
        
        # Expected compact format: $45.23X|85%%Y
        if [[ "$clean" =~ "^\$${test_cost}${cost_suffix}\|${test_percentage}%%${percentage_suffix}" ]]; then
            echo "✓ $display (compact)"
            ((passed++))
        else
            echo "✗ $display (expected \$${test_cost}${cost_suffix}|${test_percentage}%${percentage_suffix})"
            ((failed++))
        fi
    done
done

# Summary
echo
echo "============================================================"
echo "Test Summary:"
echo "  Passed: $passed"
echo "  Failed: $failed"
echo "  Total:  $((passed + failed))"
echo

if (( failed == 0 )); then
    echo "✅ All cost and percentage combinations work correctly!"
    exit 0
else
    echo "❌ Some combinations failed. Please check the implementation."
    exit 1
fi