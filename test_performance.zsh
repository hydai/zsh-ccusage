#!/usr/bin/env zsh

# Performance test script for zsh-ccusage plugin
# Tests plugin load time and various operations

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== ZSH CCUsage Plugin Performance Test ==="
echo ""

# Test 1: Plugin load time
echo "Test 1: Plugin Load Time"
echo "------------------------"

# Measure plugin load time
start_time=$(($(date +%s%N)/1000000))
source ./zsh-ccusage.plugin.zsh
end_time=$(($(date +%s%N)/1000000))
load_time=$((end_time - start_time))

echo "Plugin load time: ${load_time}ms"
if (( load_time < 100 )); then
    echo -e "${GREEN}✓ PASS${NC}: Load time is under 100ms target"
else
    echo -e "${RED}✗ FAIL${NC}: Load time exceeds 100ms target"
fi
echo ""

# Test 2: First display call (lazy loading components)
echo "Test 2: First Display Call (Lazy Loading)"
echo "-----------------------------------------"

start_time=$(($(date +%s%N)/1000000))
result=$(ccusage_display 2>/dev/null)
end_time=$(($(date +%s%N)/1000000))
first_display_time=$((end_time - start_time))

echo "First display call time: ${first_display_time}ms"
if (( first_display_time < 200 )); then
    echo -e "${GREEN}✓ PASS${NC}: First display is reasonably fast"
else
    echo -e "${YELLOW}⚠ WARN${NC}: First display is slow (expected due to component loading)"
fi
echo ""

# Test 3: Subsequent display calls (cached)
echo "Test 3: Cached Display Performance"
echo "---------------------------------"

total_time=0
iterations=10

for i in {1..$iterations}; do
    start_time=$(($(date +%s%N)/1000000))
    result=$(ccusage_display 2>/dev/null)
    end_time=$(($(date +%s%N)/1000000))
    iter_time=$((end_time - start_time))
    total_time=$((total_time + iter_time))
done

avg_time=$((total_time / iterations))
echo "Average cached display time (${iterations} calls): ${avg_time}ms"
if (( avg_time < 10 )); then
    echo -e "${GREEN}✓ PASS${NC}: Cached display is very fast"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Cached display could be faster"
fi
echo ""

# Test 4: Cost mode switching performance
echo "Test 4: Cost Mode Switching"
echo "---------------------------"

modes=("active" "daily" "monthly")
for mode in $modes; do
    start_time=$(($(date +%s%N)/1000000))
    CCUSAGE_COST_MODE=$mode
    ccusage_validate_cost_mode
    result=$(ccusage_display 2>/dev/null)
    end_time=$(($(date +%s%N)/1000000))
    switch_time=$((end_time - start_time))
    
    echo "Mode '$mode' switch time: ${switch_time}ms"
done
echo ""

# Test 5: Async update check performance
echo "Test 5: Async Update Check"
echo "-------------------------"

start_time=$(($(date +%s%N)/1000000))
ccusage_async_check_needed
check_result=$?
end_time=$(($(date +%s%N)/1000000))
check_time=$((end_time - start_time))

echo "Async check time: ${check_time}ms"
if (( check_time < 5 )); then
    echo -e "${GREEN}✓ PASS${NC}: Async check is very fast"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Async check could be optimized"
fi
echo ""

# Test 6: Memory usage check (rough estimate)
echo "Test 6: Memory Usage"
echo "-------------------"

# Check number of global variables
global_vars=$(set | grep -c "^CCUSAGE_" || true)
echo "Global variables created: $global_vars"

# Check function count
function_count=$(functions | grep -c "ccusage" || true)
echo "Functions loaded: $function_count"

if (( global_vars < 20 && function_count < 30 )); then
    echo -e "${GREEN}✓ PASS${NC}: Reasonable memory footprint"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Consider reducing memory usage"
fi
echo ""

# Summary
echo "=== Performance Summary ==="
echo "Plugin load time: ${load_time}ms (target: <100ms)"
echo "First display time: ${first_display_time}ms"
echo "Avg cached display: ${avg_time}ms"
echo ""

# Overall assessment
if (( load_time < 100 && avg_time < 10 )); then
    echo -e "${GREEN}✓ Overall: EXCELLENT PERFORMANCE${NC}"
elif (( load_time < 150 && avg_time < 20 )); then
    echo -e "${YELLOW}⚠ Overall: ACCEPTABLE PERFORMANCE${NC}"
else
    echo -e "${RED}✗ Overall: PERFORMANCE NEEDS IMPROVEMENT${NC}"
fi