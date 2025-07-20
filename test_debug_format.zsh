#!/usr/bin/env zsh

# Debug format test

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"
source "${0:A:h}/functions/ccusage-format"

# Test case 1
export COLUMNS=120
export CCUSAGE_COST_MODE="daily"
export CCUSAGE_PERCENTAGE_MODE="monthly"

echo "=== Debug Format Test ==="
echo

local result=$(ccusage_format_display "45.23" "85" "false" "D")
echo "Raw result: '$result'"

# Clean it
local clean="$result"
clean="${clean//$'\e'\[[0-9;]*m/}"
clean="${clean//\%F\{[a-zA-Z]*\}/}"
clean="${clean//\%f/}"
clean="${clean//\%B/}"
clean="${clean//\%b/}"
echo "Clean result: '$clean'"

# Debug regex matching
echo
echo "Testing regex patterns:"

# Test 1: Basic pattern
if [[ "$clean" =~ '\$45.23D' ]]; then
    echo "✓ Matches cost part: \$45.23D"
else
    echo "✗ Does not match cost part"
fi

# Test 2: Percentage pattern
if [[ "$clean" =~ '85%%M' ]]; then
    echo "✓ Matches percentage part: 85%%M"
else
    echo "✗ Does not match percentage part"
fi

# Test 3: Full pattern
if [[ "$clean" =~ '\$45.23D.*85%%M' ]]; then
    echo "✓ Matches full pattern"
else
    echo "✗ Does not match full pattern"
fi

# Test escaped version
echo
echo "Testing escaped patterns:"
if [[ "$clean" =~ "\\$45.23D.*85%%M" ]]; then
    echo "✓ Matches with escaped dollar"
else
    echo "✗ Does not match with escaped dollar"
fi