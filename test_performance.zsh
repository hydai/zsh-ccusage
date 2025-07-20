#!/usr/bin/env zsh

# Performance test for zsh-ccusage plugin
# Tests that the prompt doesn't block for 3-5 seconds

echo "Testing zsh-ccusage performance..."
echo "This will measure the time taken by key functions"
echo

# Source the plugin
source ./zsh-ccusage.plugin.zsh

# Measure display function performance
echo "1. Testing ccusage_display() performance:"
time_start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    output=$(ccusage_display)
done
time_end=$(($(date +%s%N)/1000000))
time_diff=$((time_end - time_start))
avg_time=$((time_diff / 10))
echo "   Average time for ccusage_display(): ${avg_time}ms"
echo "   Last output: $output"
echo

# Measure precmd hook performance
echo "2. Testing ccusage_precmd() performance:"
time_start=$(($(date +%s%N)/1000000))
for i in {1..10}; do
    ccusage_precmd
done
time_end=$(($(date +%s%N)/1000000))
time_diff=$((time_end - time_start))
avg_time=$((time_diff / 10))
echo "   Average time for ccusage_precmd(): ${avg_time}ms"
echo

# Test rapid consecutive calls (simulating fast command entry)
echo "3. Testing rapid consecutive calls:"
time_start=$(($(date +%s%N)/1000000))
for i in {1..20}; do
    ccusage_display > /dev/null
    ccusage_precmd
done
time_end=$(($(date +%s%N)/1000000))
time_diff=$((time_end - time_start))
echo "   Total time for 20 rapid calls: ${time_diff}ms"
echo "   Average time per iteration: $((time_diff / 20))ms"
echo

# Check cache status
echo "4. Cache status:"
echo "   Memory cache entries: ${#CCUSAGE_CACHE[@]}"
echo "   Cache duration: ${CCUSAGE_CACHE_DURATION}s"
echo

# Performance summary
echo "Performance Summary:"
echo "==================="
if (( avg_time < 50 )); then
    echo "✓ Display function is fast (<50ms)"
else
    echo "✗ Display function is slow (>50ms)"
fi

if (( time_diff < 1000 )); then
    echo "✓ No blocking detected"
else
    echo "✗ Potential blocking detected"
fi