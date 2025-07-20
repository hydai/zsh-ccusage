#!/usr/bin/env zsh

# Test script for percentage mode switching without restart

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"

echo "Testing percentage mode switching..."
echo

# Test 1: Default mode (daily_avg)
echo "Test 1: Default mode (should be daily_avg)"
echo "Current mode: ${CCUSAGE_PERCENTAGE_MODE:-daily_avg}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 2: Switch to daily_plan mode
echo "Test 2: Switching to daily_plan mode"
export CCUSAGE_PERCENTAGE_MODE="daily_plan"
ccusage_ensure_valid_percentage_mode
echo "Current mode: ${CCUSAGE_PERCENTAGE_MODE}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 3: Switch to monthly mode
echo "Test 3: Switching to monthly mode"
export CCUSAGE_PERCENTAGE_MODE="monthly"
ccusage_ensure_valid_percentage_mode
echo "Current mode: ${CCUSAGE_PERCENTAGE_MODE}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 4: Invalid mode (should fall back to daily_avg)
echo "Test 4: Setting invalid mode (should fall back to daily_avg)"
export CCUSAGE_PERCENTAGE_MODE="invalid_mode"
ccusage_ensure_valid_percentage_mode
echo "Current mode: ${CCUSAGE_PERCENTAGE_MODE}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 5: Check cache behavior
echo "Test 5: Checking cache behavior"
echo "Active block cache valid: $(ccusage_cache_valid 'active_block' && echo 'yes' || echo 'no')"
echo "Daily usage cache valid: $(ccusage_cache_valid 'daily_usage' && echo 'yes' || echo 'no')"
echo "Monthly usage cache valid: $(ccusage_cache_valid 'monthly_usage' && echo 'yes' || echo 'no')"

echo
echo "Test complete!"