#!/usr/bin/env zsh

# ZSH CCUsage Plugin - Optimized Version
# Displays real-time ccusage cost information in terminal prompt

# Plugin version
CCUSAGE_VERSION="0.1.0"

# Get plugin directory
CCUSAGE_PLUGIN_DIR="${0:A:h}"

# Configuration variables with defaults
: ${CCUSAGE_PERCENTAGE_MODE:="daily_avg"}  # daily_avg, daily_plan, or monthly
: ${CCUSAGE_COST_MODE:="active"}           # active, daily, or monthly

# Load validation functions (will be loaded with other components)
# The validation functions are now in lib/validation.zsh

# Detect plugin manager / framework
function ccusage_detect_framework() {
    if [[ -n "$ZSH_VERSION" ]]; then
        # Check for oh-my-zsh
        if [[ -n "$ZSH" && -f "$ZSH/oh-my-zsh.sh" ]]; then
            echo "oh-my-zsh"
        # Check for prezto
        elif [[ -n "$ZPREZTODIR" || -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
            echo "prezto"
        # Check for zinit
        elif (( $+functions[zinit] )); then
            echo "zinit"
        # Check for zplug
        elif (( $+functions[zplug] )); then
            echo "zplug"
        # Check for antigen
        elif (( $+functions[antigen] )); then
            echo "antigen"
        else
            echo "none"
        fi
    fi
}

# Framework compatibility
CCUSAGE_FRAMEWORK=$(ccusage_detect_framework)

# Lazy loading flags
typeset -g CCUSAGE_LOADED=false
typeset -g CCUSAGE_COMPONENTS_LOADED=false

# Function to load components on demand
function ccusage_load_components() {
    if [[ "$CCUSAGE_COMPONENTS_LOADED" == "false" ]]; then
        # Add functions directory to fpath for autoloading
        fpath=("${CCUSAGE_PLUGIN_DIR}/functions" $fpath)
        
        # Source all required components
        source "${CCUSAGE_PLUGIN_DIR}/lib/validation.zsh"
        source "${CCUSAGE_PLUGIN_DIR}/lib/error-handler.zsh"
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-format"
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-fetch"
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-refresh"
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-set-cost-mode"
        source "${CCUSAGE_PLUGIN_DIR}/lib/parser.zsh"
        source "${CCUSAGE_PLUGIN_DIR}/lib/cache.zsh"
        source "${CCUSAGE_PLUGIN_DIR}/lib/async.zsh"
        
        # Initialize async system
        ccusage_async_init
        
        CCUSAGE_COMPONENTS_LOADED=true
    fi
}

# Cache the last display result to avoid recalculation
typeset -g CCUSAGE_LAST_DISPLAY_CACHE=""
typeset -g CCUSAGE_LAST_DISPLAY_TIME=0

# Display function - returns formatted cost information
function ccusage_display() {
    # Quick cache check - return last result if very recent (within 1 second)
    local current_time=$EPOCHSECONDS
    if [[ -n "$CCUSAGE_LAST_DISPLAY_CACHE" ]] && (( current_time - CCUSAGE_LAST_DISPLAY_TIME < 1 )); then
        echo -n "$CCUSAGE_LAST_DISPLAY_CACHE"
        return
    fi
    
    # Ensure components are loaded
    ccusage_load_components
    
    # Pre-generate cache keys once
    local today=$(date '+%Y%m%d')
    local current_month=$(date '+%Y%m')
    local cache_key_block="active_block"
    local cache_key_daily="daily_usage_${today}"
    local cache_key_monthly="monthly_usage_${current_month}"
    
    # Combined cache check for better performance
    local block_json daily_json monthly_json
    local has_data=false
    local is_stale=false
    
    # Try memory cache first (fastest)
    if [[ -n "${CCUSAGE_CACHE[$cache_key_block]}" ]]; then
        block_json="${CCUSAGE_CACHE[$cache_key_block]}"
        has_data=true
    fi
    
    if [[ -n "${CCUSAGE_CACHE[$cache_key_daily]}" ]]; then
        daily_json="${CCUSAGE_CACHE[$cache_key_daily]}"
        has_data=true
    fi
    
    # If no memory cache, check persistent cache
    if [[ "$has_data" == "false" ]]; then
        # Try stale cache as fallback
        block_json=$(ccusage_cache_get_stale "$cache_key_block")
        daily_json=$(ccusage_cache_get_stale "$cache_key_daily")
        
        if [[ -n "$block_json" ]] || [[ -n "$daily_json" ]]; then
            has_data=true
            is_stale=true
        fi
    fi
    
    # Only check monthly if needed
    if [[ "${CCUSAGE_PERCENTAGE_MODE:-daily_avg}" == "monthly" ]]; then
        if [[ -n "${CCUSAGE_CACHE[$cache_key_monthly]}" ]]; then
            monthly_json="${CCUSAGE_CACHE[$cache_key_monthly]}"
        elif [[ "$is_stale" == "true" ]]; then
            monthly_json=$(ccusage_cache_get_stale "$cache_key_monthly")
        fi
    fi
    
    # If no data at all, return loading indicator
    if [[ "$has_data" == "false" ]]; then
        CCUSAGE_LAST_DISPLAY_CACHE="[Loading...]"
        CCUSAGE_LAST_DISPLAY_TIME=$current_time
        echo -n "$CCUSAGE_LAST_DISPLAY_CACHE"
        return
    fi
    
    # Get cost based on configured cost mode
    local cost_info=($(ccusage_get_cost_by_mode))
    local cost="${cost_info[1]}"
    local cost_mode_suffix="${cost_info[2]}"
    local cost_is_stale="${cost_info[3]:-false}"
    
    # Calculate percentage
    local daily_cost=0
    local monthly_cost=0
    
    if [[ -n "$daily_json" ]]; then
        daily_cost=$(ccusage_parse_daily_cost "$daily_json")
    fi
    
    if [[ "${CCUSAGE_PERCENTAGE_MODE:-daily_avg}" == "monthly" && -n "$monthly_json" ]]; then
        monthly_cost=$(ccusage_parse_monthly_cost "$monthly_json")
    fi
    
    local percentage=$(ccusage_calculate_percentage "$daily_cost" "$monthly_cost")
    
    # Determine overall stale status
    local display_is_stale="false"
    if [[ "$cost_is_stale" == "true" ]] || [[ "$is_stale" == "true" ]]; then
        display_is_stale="true"
    fi
    
    # Format and cache the result
    local display_result=$(ccusage_format_display "$cost" "$percentage" "$display_is_stale" "$cost_mode_suffix")
    CCUSAGE_LAST_DISPLAY_CACHE="$display_result"
    CCUSAGE_LAST_DISPLAY_TIME=$current_time
    
    echo -n "$display_result"
}

# Track last update time to throttle precmd executions
typeset -g CCUSAGE_LAST_UPDATE_CHECK=0

# Precmd hook for automatic updates
function ccusage_precmd() {
    # Throttle precmd execution - only check every 5 seconds
    local current_time=$EPOCHSECONDS
    if (( current_time - CCUSAGE_LAST_UPDATE_CHECK < 5 )); then
        return
    fi
    CCUSAGE_LAST_UPDATE_CHECK=$current_time
    
    # Ensure components are loaded
    ccusage_load_components
    
    # Check if auto-update is enabled (default: true)
    local auto_update=${CCUSAGE_AUTO_UPDATE:-true}
    
    # Only trigger update if auto-update is enabled
    if [[ "$auto_update" == "true" ]]; then
        # First, check if there are async results to process
        ccusage_async_process_results
        
        # Then check if async update is needed based on cache age
        if ccusage_async_check_needed; then
            # Trigger async update in background
            ccusage_async_update
        fi
    fi
}

# Initialize plugin
function ccusage_init() {
    # Load components first if not already loaded
    ccusage_load_components
    
    # Validate configuration
    ccusage_ensure_valid_percentage_mode
    ccusage_ensure_valid_cost_mode
    
    # Framework-specific initialization
    case "$CCUSAGE_FRAMEWORK" in
        "oh-my-zsh")
            # Oh-my-zsh handles plugin loading automatically
            ;;
        "prezto")
            # Prezto modules may need special handling
            # Define module metadata if running under prezto
            if (( $+functions[pmodload] )); then
                zstyle ':prezto:module:ccusage' loaded 'yes'
            fi
            ;;
        "zinit")
            # Zinit may benefit from ice modifiers
            # These are typically set by the user, but we ensure compatibility
            ;;
        "zplug"|"antigen")
            # These plugin managers handle loading automatically
            ;;
    esac
    
    # Set default display if not already in RPROMPT
    if [[ ! "$RPROMPT" =~ "ccusage_display" ]]; then
        # Add ccusage display to the left of existing RPROMPT content
        RPROMPT='$(ccusage_display)'${RPROMPT:+" $RPROMPT"}
    fi
    
    # Register precmd hook for automatic updates
    # Remove any existing ccusage_precmd from precmd_functions to avoid duplicates
    precmd_functions=(${precmd_functions[@]:#ccusage_precmd})
    # Add our precmd function
    precmd_functions+=(ccusage_precmd)
    
    # Load components and trigger initial async update
    ccusage_load_components
    
    # Trigger first async update immediately
    if [[ "${CCUSAGE_AUTO_UPDATE:-true}" == "true" ]]; then
        ccusage_async_update
    fi
    
    CCUSAGE_LOADED=true
}

# Initialize the plugin only if not already loaded
if [[ "$CCUSAGE_LOADED" != "true" ]]; then
    ccusage_init
fi