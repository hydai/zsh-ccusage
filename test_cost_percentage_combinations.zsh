#!/usr/bin/env zsh

# Test script for independent cost and percentage mode combinations
# Tests all 9 possible combinations (3 cost modes × 3 percentage modes)

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"

echo "=== Testing Cost and Percentage Mode Combinations ==="
echo

# Define the modes to test
local cost_modes=("active" "daily" "monthly")
local percentage_modes=("daily_avg" "daily_plan" "monthly")

# Expected combinations with their display formats
# Format: cost_mode:percentage_mode -> expected_display_format
typeset -A expected_formats=(
    "active:daily_avg"     "[\$X.XXA | XXX%D]"
    "active:daily_plan"    "[\$X.XXA | XXX%P]"
    "active:monthly"       "[\$X.XXA | XXX%M]"
    "daily:daily_avg"      "[\$X.XXD | XXX%D]"
    "daily:daily_plan"     "[\$X.XXD | XXX%P]"
    "daily:monthly"        "[\$X.XXD | XXX%M]"
    "monthly:daily_avg"    "[\$X.XXM | XXX%D]"
    "monthly:daily_plan"   "[\$X.XXM | XXX%P]"
    "monthly:monthly"      "[\$X.XXM | XXX%M]"
)

# Track test results
local total_tests=0
local passed_tests=0
local failed_tests=0

# Function to wait for data to load
function wait_for_data() {
    local max_attempts=10
    local attempt=0
    local display
    
    while (( attempt < max_attempts )); do
        display=$(ccusage_display)
        if [[ "$display" != "[Loading...]" ]]; then
            echo "$display"
            return 0
        fi
        ((attempt++))
        sleep 1
    done
    
    echo "$display"
    return 1
}

# Function to check if display matches expected pattern
function check_display_format() {
    local display=$1
    local cost_mode=$2
    local percentage_mode=$3
    
    # Extract cost suffix and percentage suffix from display
    # Expected format: [$XX.XXC | XX%P] where C is cost suffix and P is percentage suffix
    local cost_suffix_found=""
    local percentage_suffix_found=""
    
    # Parse the display string
    # Remove color codes first (handle ANSI and ZSH prompt color codes)
    local clean_display="$display"
    # Remove ANSI escape codes
    clean_display="${clean_display//$'\e'\[[0-9;]*m/}"
    # Remove ZSH prompt color codes like %F{green} and %f
    clean_display="${clean_display//\%F\{[a-zA-Z]*\}/}"
    clean_display="${clean_display//\%f/}"
    
    # Now parse the clean display
    if [[ "$clean_display" =~ '\$[0-9.-]+([ADM]).*\|.*[0-9]+%([DPM])' ]]; then
        cost_suffix_found=$match[1]
        percentage_suffix_found=$match[2]
    fi
    
    # Determine expected suffixes
    local expected_cost_suffix
    case "$cost_mode" in
        active) expected_cost_suffix="A" ;;
        daily) expected_cost_suffix="D" ;;
        monthly) expected_cost_suffix="M" ;;
    esac
    
    local expected_percentage_suffix
    case "$percentage_mode" in
        daily_avg) expected_percentage_suffix="D" ;;
        daily_plan) expected_percentage_suffix="P" ;;
        monthly) expected_percentage_suffix="M" ;;
    esac
    
    # Check if both suffixes match
    if [[ "$cost_suffix_found" == "$expected_cost_suffix" ]] && \
       [[ "$percentage_suffix_found" == "$expected_percentage_suffix" ]]; then
        return 0
    else
        return 1
    fi
}

# Test each combination
echo "Testing all 9 combinations of cost and percentage modes:"
echo "Format: [Cost Mode] + [Percentage Mode] = Display Format"
printf '%60s\n' | tr ' ' '-'
echo

# Initial refresh to ensure some data is loaded
echo "Initial data loading..."
ccusage-refresh >/dev/null 2>&1
sleep 3
echo

for cost_mode in $cost_modes; do
    for percentage_mode in $percentage_modes; do
        ((total_tests++))
        
        # Set the modes
        export CCUSAGE_COST_MODE="$cost_mode"
        export CCUSAGE_PERCENTAGE_MODE="$percentage_mode"
        
        # Validate modes
        ccusage_validate_cost_mode
        ccusage_validate_percentage_mode
        
        # Clear caches to ensure fresh data
        unset 'CCUSAGE_CACHE[cost_active]'
        unset 'CCUSAGE_CACHE[cost_daily]'
        unset 'CCUSAGE_CACHE[cost_monthly]'
        unset 'CCUSAGE_CACHE[daily_usage]'
        unset 'CCUSAGE_CACHE[monthly_usage]'
        
        # Trigger a refresh
        ccusage-refresh >/dev/null 2>&1
        
        # Wait for async updates to complete
        sleep 2
        
        # Get the display (wait for data to load)
        local display=$(wait_for_data)
        
        # Check the format
        local test_label="${cost_mode} + ${percentage_mode}"
        printf "%-25s → " "$test_label"
        
        if check_display_format "$display" "$cost_mode" "$percentage_mode"; then
            echo "✓ $display"
            ((passed_tests++))
        else
            echo "✗ $display (expected ${expected_formats[${cost_mode}:${percentage_mode}]})"
            ((failed_tests++))
        fi
    done
    echo
done

# Test compact format for narrow terminals
echo "Testing compact format (terminal width < 80):"
printf '%60s\n' | tr ' ' '-'
echo

# Simulate narrow terminal
export COLUMNS=60

for cost_mode in $cost_modes; do
    for percentage_mode in $percentage_modes; do
        ((total_tests++))
        
        # Set the modes
        export CCUSAGE_COST_MODE="$cost_mode"
        export CCUSAGE_PERCENTAGE_MODE="$percentage_mode"
        
        # Validate modes
        ccusage_validate_cost_mode
        ccusage_validate_percentage_mode
        
        # Get the display (should be compact)
        local display=$(wait_for_data)
        
        # Check if it's in compact format (no brackets, no spaces around |)
        local test_label="${cost_mode} + ${percentage_mode}"
        printf "%-25s → " "$test_label"
        
        # Remove color codes for checking
        local clean_display="$display"
        # Remove ANSI escape codes
        clean_display="${clean_display//$'\e'\[[0-9;]*m/}"
        # Remove ZSH prompt color codes like %F{green} and %f
        clean_display="${clean_display//\%F\{[a-zA-Z]*\}/}"
        clean_display="${clean_display//\%f/}"
        
        if [[ "$clean_display" =~ '^\$[0-9.-]+[ADM]\|[0-9]+%[DPM]' ]]; then
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
    echo "✅ All tests passed!"
    exit 0
else
    echo
    echo "❌ Some tests failed!"
    exit 1
fi