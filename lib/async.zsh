#!/usr/bin/env zsh

# Async functionality for zsh-ccusage plugin
# Provides non-blocking data fetching to maintain terminal responsiveness

# Global variables for async job management
typeset -g CCUSAGE_ASYNC_PID=""
typeset -g CCUSAGE_ASYNC_TMPDIR=""

# Initialize async system
function ccusage_async_init() {
    # Create temp directory for async results
    CCUSAGE_ASYNC_TMPDIR="${TMPDIR:-/tmp}/zsh-ccusage-$$"
    mkdir -p "$CCUSAGE_ASYNC_TMPDIR"
    
    # Clean up on exit
    trap "rm -rf '$CCUSAGE_ASYNC_TMPDIR'" EXIT
}

# Start async update process
function ccusage_async_update() {
    # Cancel any existing async job
    ccusage_async_cancel
    
    # Ensure temp directory exists
    if [[ ! -d "$CCUSAGE_ASYNC_TMPDIR" ]]; then
        mkdir -p "$CCUSAGE_ASYNC_TMPDIR"
    fi
    
    # Export necessary variables for background job
    export CCUSAGE_ASYNC_TMPDIR
    export CCUSAGE_PLUGIN_DIR
    
    # Start background job
    (
        # Source required functions in subshell
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-fetch"
        source "${CCUSAGE_PLUGIN_DIR}/lib/cache.zsh"
        
        # Create result files
        local block_file="$CCUSAGE_ASYNC_TMPDIR/block.json"
        local daily_file="$CCUSAGE_ASYNC_TMPDIR/daily.json"
        local status_file="$CCUSAGE_ASYNC_TMPDIR/status"
        
        # Clear previous results
        rm -f "$block_file" "$daily_file" "$status_file"
        
        # Fetch active block data
        local block_json=$(ccusage_fetch_active_block 2>/dev/null)
        local block_success=$?
        
        # Fetch daily usage data  
        local daily_json=$(ccusage_fetch_daily 2>/dev/null)
        local daily_success=$?
        
        # Write results to files
        if [[ $block_success -eq 0 && -n "$block_json" ]]; then
            echo "$block_json" > "$block_file"
        fi
        
        if [[ $daily_success -eq 0 && -n "$daily_json" ]]; then
            echo "$daily_json" > "$daily_file"
        fi
        
        # Signal completion
        echo "done" > "$status_file"
    ) &
    
    # Store background job PID
    CCUSAGE_ASYNC_PID=$!
}

# Cancel any running async job
function ccusage_async_cancel() {
    if [[ -n "$CCUSAGE_ASYNC_PID" ]] && kill -0 "$CCUSAGE_ASYNC_PID" 2>/dev/null; then
        kill "$CCUSAGE_ASYNC_PID" 2>/dev/null || true
        wait "$CCUSAGE_ASYNC_PID" 2>/dev/null || true
    fi
    CCUSAGE_ASYNC_PID=""
}

# Check if async update is needed based on cache age
function ccusage_async_check_needed() {
    # Don't start new job if one is already running
    if [[ -n "$CCUSAGE_ASYNC_PID" ]] && kill -0 "$CCUSAGE_ASYNC_PID" 2>/dev/null; then
        return 1
    fi
    
    local block_valid=$(ccusage_cache_valid "active_block" && echo 1 || echo 0)
    local daily_valid=$(ccusage_cache_valid "daily_usage" && echo 1 || echo 0)
    
    # Return 0 if update needed, 1 if cache is still fresh
    if [[ $block_valid -eq 0 || $daily_valid -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Process async results if available
function ccusage_async_process_results() {
    # Check if async job completed
    local status_file="$CCUSAGE_ASYNC_TMPDIR/status"
    if [[ ! -f "$status_file" ]] || [[ "$(<$status_file)" != "done" ]]; then
        return 1
    fi
    
    # Read results from files
    local block_file="$CCUSAGE_ASYNC_TMPDIR/block.json"
    local daily_file="$CCUSAGE_ASYNC_TMPDIR/daily.json"
    
    # Update cache with results
    if [[ -f "$block_file" ]]; then
        local cached_block=$(<"$block_file")
        if [[ -n "$cached_block" && ! "$cached_block" =~ '"error"' ]]; then
            ccusage_cache_set "active_block" "$cached_block"
        fi
    fi
    
    if [[ -f "$daily_file" ]]; then
        local cached_daily=$(<"$daily_file")
        if [[ -n "$cached_daily" && ! "$cached_daily" =~ '"error"' ]]; then
            ccusage_cache_set "daily_usage" "$cached_daily"
        fi
    fi
    
    # Clean up temp files
    rm -f "$block_file" "$daily_file" "$status_file"
    
    # Clear async PID
    CCUSAGE_ASYNC_PID=""
    
    return 0
}