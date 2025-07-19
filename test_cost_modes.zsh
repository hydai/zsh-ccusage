#!/usr/bin/env zsh

# Test script for cost mode configuration

echo "Testing CCUSAGE_COST_MODE configuration..."
echo "==========================================="

# Test 1: Default mode should be 'active'
echo -n "Test 1 - Default mode: "
unset CCUSAGE_COST_MODE
source ./zsh-ccusage.plugin.zsh
if [[ "$CCUSAGE_COST_MODE" == "active" ]]; then
    echo "✅ PASS (active)"
else
    echo "❌ FAIL (expected: active, got: $CCUSAGE_COST_MODE)"
fi

# Test 2: Valid mode 'daily' should be kept
echo -n "Test 2 - Valid mode 'daily': "
CCUSAGE_COST_MODE="daily"
source ./zsh-ccusage.plugin.zsh
if [[ "$CCUSAGE_COST_MODE" == "daily" ]]; then
    echo "✅ PASS (daily)"
else
    echo "❌ FAIL (expected: daily, got: $CCUSAGE_COST_MODE)"
fi

# Test 3: Valid mode 'monthly' should be kept
echo -n "Test 3 - Valid mode 'monthly': "
CCUSAGE_COST_MODE="monthly"
source ./zsh-ccusage.plugin.zsh
if [[ "$CCUSAGE_COST_MODE" == "monthly" ]]; then
    echo "✅ PASS (monthly)"
else
    echo "❌ FAIL (expected: monthly, got: $CCUSAGE_COST_MODE)"
fi

# Test 4: Invalid mode should fall back to 'active'
echo -n "Test 4 - Invalid mode 'invalid': "
CCUSAGE_COST_MODE="invalid"
source ./zsh-ccusage.plugin.zsh
if [[ "$CCUSAGE_COST_MODE" == "active" ]]; then
    echo "✅ PASS (fallback to active)"
else
    echo "❌ FAIL (expected: active, got: $CCUSAGE_COST_MODE)"
fi

# Test 5: Empty string should fall back to 'active'
echo -n "Test 5 - Empty string mode: "
CCUSAGE_COST_MODE=""
source ./zsh-ccusage.plugin.zsh
if [[ "$CCUSAGE_COST_MODE" == "active" ]]; then
    echo "✅ PASS (fallback to active)"
else
    echo "❌ FAIL (expected: active, got: $CCUSAGE_COST_MODE)"
fi

echo ""
echo "Cost mode configuration tests complete!"