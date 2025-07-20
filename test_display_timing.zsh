#!/usr/bin/env zsh

# Detailed timing test for display function
source ./zsh-ccusage.plugin.zsh

echo "=== Display Function Timing Analysis ==="
echo ""

# Ensure components are loaded
ccusage_load_components

# Pre-populate cache to test cached performance
echo "Pre-populating cache..."
ccusage-refresh >/dev/null 2>&1
sleep 2

echo "Testing individual operations..."
echo ""

# Test 1: Cache retrieval
echo "1. Cache retrieval timing:"
start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    ccusage_cache_get "cost_active" >/dev/null
done
end=$(($(date +%s%N)/1000000))
echo "   Average cache get: $(( (end - start) / 10 ))ms"

# Test 2: Cost parsing
echo "2. Cost parsing timing:"
test_json='{"blocks":[{"cost":45.23}]}'
start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    ccusage_parse_block_cost "$test_json" >/dev/null
done
end=$(($(date +%s%N)/1000000))
echo "   Average parse cost: $(( (end - start) / 10 ))ms"

# Test 3: Percentage calculation
echo "3. Percentage calculation timing:"
start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    ccusage_calculate_percentage "20" "100" >/dev/null
done
end=$(($(date +%s%N)/1000000))
echo "   Average percentage calc: $(( (end - start) / 10 ))ms"

# Test 4: Format display
echo "4. Format display timing:"
start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    ccusage_format_display "45.23" "85" "false" "A" >/dev/null
done
end=$(($(date +%s%N)/1000000))
echo "   Average format: $(( (end - start) / 10 ))ms"

# Test 5: Full display function
echo "5. Full display timing:"
start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    ccusage_display >/dev/null
done
end=$(($(date +%s%N)/1000000))
echo "   Average full display: $(( (end - start) / 10 ))ms"

echo ""
echo "=== Function call counts ==="
# Count how many function calls happen in display
(
    set -x
    ccusage_display 2>&1 >/dev/null | grep -c "+"
) 2>&1 | tail -1 | sed 's/^/Total function calls: /'