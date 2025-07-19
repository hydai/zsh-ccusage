#!/usr/bin/env zsh
# Test async functionality

echo "🧪 Testing zsh-ccusage async behavior..."

# Source the plugin
source ./zsh-ccusage.plugin.zsh

echo "✅ Plugin loaded: $CCUSAGE_LOADED"
echo "📊 Initial display: $(ccusage_display)"

# Check cache
echo ""
echo "🔍 Checking cache state:"
echo "   Active block cached: $(ccusage_cache_valid 'active_block' && echo 'YES' || echo 'NO')"
echo "   Daily usage cached: $(ccusage_cache_valid 'daily_usage' && echo 'YES' || echo 'NO')"

# Test async update
echo ""
echo "🚀 Triggering async update..."
ccusage_async_update

# Wait a bit and check if async is running
sleep 0.5
if [[ -n "$CCUSAGE_ASYNC_PID" ]] && kill -0 "$CCUSAGE_ASYNC_PID" 2>/dev/null; then
    echo "✅ Async job running (PID: $CCUSAGE_ASYNC_PID)"
else
    echo "❌ No async job detected"
fi

# Test display during async update
echo ""
echo "📊 Display during async update: $(ccusage_display)"
echo "   (Should show default values immediately)"

# Wait for async to complete
echo ""
echo "⏳ Waiting for async job to complete..."
wait_time=0
while [[ -n "$CCUSAGE_ASYNC_PID" ]] && kill -0 "$CCUSAGE_ASYNC_PID" 2>/dev/null && (( wait_time < 10 )); do
    sleep 1
    wait_time=$((wait_time + 1))
    echo -n "."
done
echo ""

# Process results
ccusage_async_process_results

# Final display
echo ""
echo "📊 Final display after async: $(ccusage_display)"

# Performance test
echo ""
echo "⚡ Performance test (10 calls):"
time for i in {1..10}; do
    ccusage_display > /dev/null
done

echo ""
echo "✨ Test complete!"