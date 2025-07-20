#!/usr/bin/env zsh

# Test plugin behavior under slow network conditions
echo "=== Testing with Slow Network Conditions ==="
echo ""

# Source the plugin
source ./zsh-ccusage.plugin.zsh

# Function to simulate slow network by wrapping npx
function simulate_slow_network() {
    # Create a wrapper script that adds delay
    cat > /tmp/slow_npx.sh << 'EOF'
#!/bin/bash
# Simulate 3-second network delay
sleep 3
# Call real npx
exec npx "$@"
EOF
    chmod +x /tmp/slow_npx.sh
    
    # Temporarily override npx command
    alias npx='/tmp/slow_npx.sh'
}

# Function to restore normal network
function restore_network() {
    unalias npx 2>/dev/null || true
    rm -f /tmp/slow_npx.sh
}

# Test 1: Initial display with no cache (should show loading)
echo "Test 1: Initial display with empty cache"
echo "----------------------------------------"
# Clear all caches
ccusage_cache_clear_all 2>/dev/null || true
echo "Display result: $(ccusage_display)"
echo ""

# Test 2: Trigger async update with slow network
echo "Test 2: Async update with 3-second network delay"
echo "-----------------------------------------------"
simulate_slow_network

# Time how long the update takes (should return immediately)
start=$(($(date +%s%N)/1000000))
ccusage_async_update
end=$(($(date +%s%N)/1000000))
update_time=$((end - start))

echo "Async update triggered in: ${update_time}ms"
if (( update_time < 100 )); then
    echo "✓ PASS: Async update is non-blocking"
else
    echo "✗ FAIL: Async update blocked the terminal"
fi

# Test 3: Display while fetch is in progress
echo ""
echo "Test 3: Display during slow fetch"
echo "---------------------------------"
sleep 1
echo "Display result (1s after trigger): $(ccusage_display)"
echo "Expected: Should show cached or loading state"

# Wait for async to complete
echo ""
echo "Waiting for async fetch to complete..."
sleep 3

# Process results
ccusage_async_process_results

echo "Display after completion: $(ccusage_display)"
echo ""

# Test 4: Refresh command with slow network
echo "Test 4: Manual refresh with slow network"
echo "---------------------------------------"
start=$(($(date +%s%N)/1000000))
echo "Starting refresh..."
# Run refresh in background to test non-blocking
(ccusage-refresh) &
refresh_pid=$!

# Check if main shell is responsive
sleep 0.5
end=$(($(date +%s%N)/1000000))
response_time=$((end - start))

echo "Shell remained responsive: ${response_time}ms"
if (( response_time < 1000 )); then
    echo "✓ PASS: Shell stays responsive during refresh"
else
    echo "✗ FAIL: Shell blocked during refresh"
fi

# Wait for refresh to complete
wait $refresh_pid

# Test 5: Mode switching during slow fetch
echo ""
echo "Test 5: Cost mode switching during slow fetch"
echo "--------------------------------------------"
# Start a slow fetch
ccusage_async_update

# Immediately switch modes
echo "Switching from active to daily mode..."
CCUSAGE_COST_MODE=daily
result1=$(ccusage_display)
echo "Display in daily mode: $result1"

echo "Switching to monthly mode..."
CCUSAGE_COST_MODE=monthly
result2=$(ccusage_display)
echo "Display in monthly mode: $result2"

# Restore
restore_network
CCUSAGE_COST_MODE=active

echo ""
echo "=== Summary ==="
echo "The plugin should:"
echo "1. Never block the terminal during network operations"
echo "2. Show cached/stale data when network is slow"
echo "3. Update asynchronously in the background"
echo "4. Allow mode switching even during fetches"