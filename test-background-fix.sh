#!/usr/bin/env zsh
# Test background job output suppression

echo "🧪 Testing background job output suppression..."
echo ""

# Source the plugin
source ./zsh-ccusage.plugin.zsh

echo "1️⃣ Testing async update (should not show job control messages):"
ccusage_async_update

# Give it a moment to start
sleep 0.5

echo "   ✓ If you don't see '[1] 12345' or 'done' messages, the fix is working!"
echo ""

echo "2️⃣ Waiting for completion..."
wait $CCUSAGE_ASYNC_PID 2>/dev/null

echo "   ✓ Background job completed"
echo ""

echo "3️⃣ Testing display format:"
echo "   Display: $(ccusage_display)"
echo ""

echo "✨ Test complete!"
echo ""
echo "To apply the fix to your shell:"
echo "  source ~/.zshrc"