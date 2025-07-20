#!/usr/bin/env zsh

# Simple test for format function

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"

# Source formatting functions
source "${0:A:h}/functions/ccusage-format"

# Test with wide terminal
export COLUMNS=120
export CCUSAGE_COST_MODE="daily"
export CCUSAGE_PERCENTAGE_MODE="monthly"

echo "Testing format with:"
echo "  Terminal width: $COLUMNS"
echo "  Cost mode: $CCUSAGE_COST_MODE"
echo "  Percentage mode: $CCUSAGE_PERCENTAGE_MODE"
echo

# Call format function directly
local result=$(ccusage_format_display "20.45" "900" "false" "D")
echo "Result: '$result'"

# Show clean version without colors
local clean="${result//$'\e'\[[0-9;]*m/}"
clean="${clean//\%F\{[a-zA-Z]*\}/}"
clean="${clean//\%f/}"
clean="${clean//\%B/}"
clean="${clean//\%b/}"
echo "Clean: '$clean'"

# Check pattern
if [[ "$clean" =~ '\$20.45D.*900%%M' ]]; then
    echo "✓ Pattern matches expected format"
else
    echo "✗ Pattern does not match"
fi