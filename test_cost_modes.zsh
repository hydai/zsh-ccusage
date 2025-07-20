#!/usr/bin/env zsh

# Test script for cost mode functionality

# Source the plugin
source "${0:A:h}/zsh-ccusage.plugin.zsh"

echo "Testing cost mode functionality..."
echo

# Test 1: Default mode (active)
echo "Test 1: Default mode (should be active)"
echo "Current mode: ${CCUSAGE_COST_MODE:-active}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 2: Switch to daily mode
echo "Test 2: Switching to daily mode"
export CCUSAGE_COST_MODE="daily"
ccusage_validate_cost_mode
echo "Current mode: ${CCUSAGE_COST_MODE}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 3: Switch to monthly mode
echo "Test 3: Switching to monthly mode"
export CCUSAGE_COST_MODE="monthly"
ccusage_validate_cost_mode
echo "Current mode: ${CCUSAGE_COST_MODE}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 4: Invalid mode (should fall back to active)
echo "Test 4: Setting invalid mode (should fall back to active)"
export CCUSAGE_COST_MODE="invalid_mode"
ccusage_validate_cost_mode
echo "Current mode: ${CCUSAGE_COST_MODE}"
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 5: Test ccusage-set-cost-mode command
echo "Test 5: Testing ccusage-set-cost-mode command"
echo "5a: Show available modes (no arguments)"
ccusage-set-cost-mode
echo

echo "5b: Set to daily mode using command"
ccusage-set-cost-mode daily
echo "Current mode after command: ${CCUSAGE_COST_MODE}"
echo "Display: $(ccusage_display)"
echo

echo "5c: Try invalid mode with command"
ccusage-set-cost-mode invalid
echo "Current mode after invalid: ${CCUSAGE_COST_MODE}"
echo

# Test 6: Cache independence
echo "Test 6: Testing cache independence"
echo "Setting mode to active and refreshing..."
ccusage-set-cost-mode active
ccusage-refresh
sleep 2
echo "Active mode cache entries:"
echo "  cost_active: ${CCUSAGE_CACHE[cost_active]:-<empty>}"
echo "  cost_daily: ${CCUSAGE_CACHE[cost_daily]:-<empty>}"
echo "  cost_monthly: ${CCUSAGE_CACHE[cost_monthly]:-<empty>}"
echo

echo "Switching to daily mode..."
ccusage-set-cost-mode daily
echo "Daily mode cache entries (should still have active cached):"
echo "  cost_active: ${CCUSAGE_CACHE[cost_active]:-<empty>}"
echo "  cost_daily: ${CCUSAGE_CACHE[cost_daily]:-<empty>}"
echo "  cost_monthly: ${CCUSAGE_CACHE[cost_monthly]:-<empty>}"
echo

# Test 7: Error handling scenarios
echo "Test 7: Testing error handling"
echo "7a: Simulating API failure (disabling network would be needed for real test)"
echo "Current display (should show cached value or placeholder): $(ccusage_display)"
echo

# Test 8: Cost and percentage mode combinations
echo "Test 8: Testing cost and percentage mode combinations"
echo "8a: Daily cost + Monthly percentage"
export CCUSAGE_COST_MODE="daily"
export CCUSAGE_PERCENTAGE_MODE="monthly"
ccusage_validate_cost_mode
ccusage_validate_percentage_mode
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

echo "8b: Monthly cost + Daily average percentage"
export CCUSAGE_COST_MODE="monthly"
export CCUSAGE_PERCENTAGE_MODE="daily_avg"
ccusage_validate_cost_mode
ccusage_validate_percentage_mode
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

echo "8c: Active cost + Daily plan percentage"
export CCUSAGE_COST_MODE="active"
export CCUSAGE_PERCENTAGE_MODE="daily_plan"
ccusage_validate_cost_mode
ccusage_validate_percentage_mode
ccusage-refresh
sleep 2
echo "Display: $(ccusage_display)"
echo

# Test 9: Mode suffix display
echo "Test 9: Verifying mode suffix display"
echo "Each cost should show its mode suffix (A/D/M):"
echo "Active mode:"
ccusage-set-cost-mode active
ccusage-refresh
sleep 1
echo "  $(ccusage_display) - should show 'A' suffix"

echo "Daily mode:"
ccusage-set-cost-mode daily
ccusage-refresh
sleep 1
echo "  $(ccusage_display) - should show 'D' suffix"

echo "Monthly mode:"
ccusage-set-cost-mode monthly
ccusage-refresh
sleep 1
echo "  $(ccusage_display) - should show 'M' suffix"
echo

# Test 10: Performance test
echo "Test 10: Performance test (multiple mode switches)"
local start_time=$SECONDS
for mode in active daily monthly active daily monthly; do
    ccusage-set-cost-mode $mode > /dev/null 2>&1
done
local elapsed=$((SECONDS - start_time))
echo "Time for 6 mode switches: ${elapsed}s"
echo

echo "Test complete!"
echo "Final state:"
echo "  CCUSAGE_COST_MODE: ${CCUSAGE_COST_MODE}"
echo "  CCUSAGE_PERCENTAGE_MODE: ${CCUSAGE_PERCENTAGE_MODE}"
echo "  Display: $(ccusage_display)"