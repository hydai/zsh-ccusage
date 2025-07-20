#!/usr/bin/env zsh

# Async functionality for zsh-ccusage plugin
# Provides non-blocking data fetching to maintain terminal responsiveness

# Global variables for async job management
typeset -g CCUSAGE_ASYNC_PID=""
typeset -g CCUSAGE_ASYNC_TMPDIR=""

# Initialize async system
function ccusage_async_init() {
    # Create temp directory for async results
    # Use a more stable identifier that persists across subshells
    CCUSAGE_ASYNC_TMPDIR="${TMPDIR:-/tmp}/zsh-ccusage-${UID:-$(id -u)}-$$"
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
    export CCUSAGE_PERCENTAGE_MODE
    export CCUSAGE_COST_MODE
    export CCUSAGE_FETCH_ALL_MODES
    
    # Disable job control notifications for this subshell
    setopt local_options no_notify no_monitor
    
    # Start background job
    (
        # Source required functions in subshell
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-fetch" 2>/dev/null
        source "${CCUSAGE_PLUGIN_DIR}/lib/cache.zsh" 2>/dev/null
        source "${CCUSAGE_PLUGIN_DIR}/lib/date-utils.zsh" 2>/dev/null
        
        # Create result files
        local block_file="$CCUSAGE_ASYNC_TMPDIR/block.json"
        local daily_file="$CCUSAGE_ASYNC_TMPDIR/daily.json"
        local monthly_file="$CCUSAGE_ASYNC_TMPDIR/monthly.json"
        local cost_active_file="$CCUSAGE_ASYNC_TMPDIR/cost_active.json"
        local cost_daily_file="$CCUSAGE_ASYNC_TMPDIR/cost_daily.json"
        local cost_monthly_file="$CCUSAGE_ASYNC_TMPDIR/cost_monthly.json"
        local status_file="$CCUSAGE_ASYNC_TMPDIR/status"
        
        # Clear previous results
        rm -f "$block_file" "$daily_file" "$monthly_file" "$cost_active_file" "$cost_daily_file" "$cost_monthly_file" "$status_file" 2>/dev/null
        
        # Fetch active block data
        local block_json=$(ccusage_fetch_active_block 2>/dev/null)
        local block_success=$?
        
        # Fetch daily usage data  
        local daily_json=$(ccusage_fetch_daily 2>/dev/null)
        local daily_success=$?
        
        # Fetch monthly usage data only if percentage mode is monthly
        local monthly_json=""
        local monthly_success=1
        if [[ "${CCUSAGE_PERCENTAGE_MODE:-daily_avg}" == "monthly" ]]; then
            monthly_json=$(ccusage_fetch_monthly 2>/dev/null)
            monthly_success=$?
        fi
        
        # Fetch cost data for all modes (only expired caches)
        local today=$(ccusage_get_today)
        local current_month=$(ccusage_get_current_month)
        
        # Check which cost mode caches need updating
        local fetch_cost_active=false
        local fetch_cost_daily=false
        local fetch_cost_monthly=false
        
        # Performance optimization: Only fetch current cost mode on regular updates
        # Unless all_modes is set (e.g., from refresh command)
        local all_modes="${CCUSAGE_FETCH_ALL_MODES:-false}"
        
        if [[ "$all_modes" == "true" ]]; then
            # Batch mode: check all caches
            if ! ccusage_cache_valid "cost_active"; then
                fetch_cost_active=true
            fi
            
            if ! ccusage_cache_valid "cost_daily_${today}"; then
                fetch_cost_daily=true
            fi
            
            if ! ccusage_cache_valid "cost_monthly_${current_month}"; then
                fetch_cost_monthly=true
            fi
        else
            # Regular mode: only fetch current cost mode
            case "${CCUSAGE_COST_MODE:-active}" in
                active)
                    if ! ccusage_cache_valid "cost_active"; then
                        fetch_cost_active=true
                    fi
                    ;;
                daily)
                    if ! ccusage_cache_valid "cost_daily_${today}"; then
                        fetch_cost_daily=true
                    fi
                    ;;
                monthly)
                    if ! ccusage_cache_valid "cost_monthly_${current_month}"; then
                        fetch_cost_monthly=true
                    fi
                    ;;
            esac
        fi
        
        # Count how many cost mode fetches are needed
        local fetch_count=0
        [[ "$fetch_cost_active" == "true" ]] && (( fetch_count++ ))
        [[ "$fetch_cost_daily" == "true" ]] && (( fetch_count++ ))
        [[ "$fetch_cost_monthly" == "true" ]] && (( fetch_count++ ))
        
        # Batch API calls when multiple modes need updating
        if (( fetch_count > 1 )); then
            # Multiple modes need updating - fetch in parallel for efficiency
            if [[ "$fetch_cost_active" == "true" ]]; then
                (
                    local cost_active_json=$(ccusage_fetch_active_block 2>/dev/null)
                    if [[ $? -eq 0 && -n "$cost_active_json" ]]; then
                        echo "$cost_active_json" > "$cost_active_file" 2>/dev/null
                    fi
                ) &
            fi
            
            if [[ "$fetch_cost_daily" == "true" ]]; then
                (
                    local cost_daily_json=$(ccusage_fetch_daily_cost 2>/dev/null)
                    if [[ $? -eq 0 && -n "$cost_daily_json" ]]; then
                        echo "$cost_daily_json" > "$cost_daily_file" 2>/dev/null
                    fi
                ) &
            fi
            
            if [[ "$fetch_cost_monthly" == "true" ]]; then
                (
                    local cost_monthly_json=$(ccusage_fetch_monthly_cost 2>/dev/null)
                    if [[ $? -eq 0 && -n "$cost_monthly_json" ]]; then
                        echo "$cost_monthly_json" > "$cost_monthly_file" 2>/dev/null
                    fi
                ) &
            fi
            
            # Wait for all parallel fetches to complete
            wait
        else
            # Single mode needs updating - fetch directly without subshell overhead
            if [[ "$fetch_cost_active" == "true" ]]; then
                local cost_active_json=$(ccusage_fetch_active_block 2>/dev/null)
                if [[ $? -eq 0 && -n "$cost_active_json" ]]; then
                    echo "$cost_active_json" > "$cost_active_file" 2>/dev/null
                fi
            elif [[ "$fetch_cost_daily" == "true" ]]; then
                local cost_daily_json=$(ccusage_fetch_daily_cost 2>/dev/null)
                if [[ $? -eq 0 && -n "$cost_daily_json" ]]; then
                    echo "$cost_daily_json" > "$cost_daily_file" 2>/dev/null
                fi
            elif [[ "$fetch_cost_monthly" == "true" ]]; then
                local cost_monthly_json=$(ccusage_fetch_monthly_cost 2>/dev/null)
                if [[ $? -eq 0 && -n "$cost_monthly_json" ]]; then
                    echo "$cost_monthly_json" > "$cost_monthly_file" 2>/dev/null
                fi
            fi
        fi
        
        # Write results to files
        if [[ $block_success -eq 0 && -n "$block_json" ]]; then
            echo "$block_json" > "$block_file" 2>/dev/null
        fi
        
        if [[ $daily_success -eq 0 && -n "$daily_json" ]]; then
            echo "$daily_json" > "$daily_file" 2>/dev/null
        fi
        
        if [[ $monthly_success -eq 0 && -n "$monthly_json" ]]; then
            echo "$monthly_json" > "$monthly_file" 2>/dev/null
        fi
        
        # Signal completion
        echo "done" > "$status_file" 2>/dev/null
    ) 2>&1 >/dev/null &!
    
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
    
    # Generate date-based cache keys
    local today=$(date '+%Y%m%d')
    local current_month=$(date '+%Y%m')
    
    local block_valid=$(ccusage_cache_valid "active_block" && echo 1 || echo 0)
    local daily_valid=$(ccusage_cache_valid "daily_usage_${today}" && echo 1 || echo 0)
    local monthly_valid=1  # Default to valid unless in monthly mode
    
    # Check monthly cache only if in monthly mode
    if [[ "${CCUSAGE_PERCENTAGE_MODE:-daily_avg}" == "monthly" ]]; then
        monthly_valid=$(ccusage_cache_valid "monthly_usage_${current_month}" && echo 1 || echo 0)
    fi
    
    # Check cost mode caches
    local cost_active_valid=$(ccusage_cache_valid "cost_active" && echo 1 || echo 0)
    local cost_daily_valid=$(ccusage_cache_valid "cost_daily_${today}" && echo 1 || echo 0)
    local cost_monthly_valid=$(ccusage_cache_valid "cost_monthly_${current_month}" && echo 1 || echo 0)
    
    # Return 0 if update needed, 1 if cache is still fresh
    if [[ $block_valid -eq 0 || $daily_valid -eq 0 || $monthly_valid -eq 0 || 
          $cost_active_valid -eq 0 || $cost_daily_valid -eq 0 || $cost_monthly_valid -eq 0 ]]; then
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
    local monthly_file="$CCUSAGE_ASYNC_TMPDIR/monthly.json"
    local cost_active_file="$CCUSAGE_ASYNC_TMPDIR/cost_active.json"
    local cost_daily_file="$CCUSAGE_ASYNC_TMPDIR/cost_daily.json"
    local cost_monthly_file="$CCUSAGE_ASYNC_TMPDIR/cost_monthly.json"
    
    # Generate date-based cache keys
    local today=$(date '+%Y%m%d')
    local current_month=$(date '+%Y%m')
    
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
            ccusage_cache_set "daily_usage_${today}" "$cached_daily"
        fi
    fi
    
    if [[ -f "$monthly_file" ]]; then
        local cached_monthly=$(<"$monthly_file")
        if [[ -n "$cached_monthly" && ! "$cached_monthly" =~ '"error"' ]]; then
            ccusage_cache_set "monthly_usage_${current_month}" "$cached_monthly"
        fi
    fi
    
    # Update cost mode caches
    if [[ -f "$cost_active_file" ]]; then
        local cached_cost_active=$(<"$cost_active_file")
        if [[ -n "$cached_cost_active" && ! "$cached_cost_active" =~ '"error"' ]]; then
            ccusage_cache_set "cost_active" "$cached_cost_active"
        fi
    fi
    
    if [[ -f "$cost_daily_file" ]]; then
        local cached_cost_daily=$(<"$cost_daily_file")
        if [[ -n "$cached_cost_daily" && ! "$cached_cost_daily" =~ '"error"' ]]; then
            ccusage_cache_set "cost_daily_${today}" "$cached_cost_daily"
        fi
    fi
    
    if [[ -f "$cost_monthly_file" ]]; then
        local cached_cost_monthly=$(<"$cost_monthly_file")
        if [[ -n "$cached_cost_monthly" && ! "$cached_cost_monthly" =~ '"error"' ]]; then
            ccusage_cache_set "cost_monthly_${current_month}" "$cached_cost_monthly"
        fi
    fi
    
    # Clean up temp files
    rm -f "$block_file" "$daily_file" "$monthly_file" "$cost_active_file" "$cost_daily_file" "$cost_monthly_file" "$status_file"
    
    # Clear async PID
    CCUSAGE_ASYNC_PID=""
    
    return 0
}