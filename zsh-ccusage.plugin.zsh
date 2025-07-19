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

# Validate percentage mode configuration
function ccusage_validate_percentage_mode() {
    local mode="${CCUSAGE_PERCENTAGE_MODE}"
    case "$mode" in
        daily_avg|daily_plan|monthly)
            # Valid mode, keep it
            ;;
        *)
            # Invalid mode, fall back to default
            CCUSAGE_PERCENTAGE_MODE="daily_avg"
            ;;
    esac
}

# Validate cost mode configuration
function ccusage_validate_cost_mode() {
    local mode="${CCUSAGE_COST_MODE}"
    case "$mode" in
        active|daily|monthly)
            # Valid mode, keep it
            ;;
        *)
            # Invalid mode, fall back to default
            CCUSAGE_COST_MODE="active"
            ;;
    esac
}

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
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-format"
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-fetch"
        source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-refresh"
        source "${CCUSAGE_PLUGIN_DIR}/lib/parser.zsh"
        source "${CCUSAGE_PLUGIN_DIR}/lib/cache.zsh"
        source "${CCUSAGE_PLUGIN_DIR}/lib/async.zsh"
        
        # Initialize async system
        ccusage_async_init
        
        CCUSAGE_COMPONENTS_LOADED=true
    fi
}

# Display function - returns formatted cost information
function ccusage_display() {
    # Ensure components are loaded
    ccusage_load_components
    
    local cost percentage
    local cache_key_block="active_block"
    local today=$(date '+%Y%m%d')
    local current_month=$(date '+%Y%m')
    local cache_key_daily="daily_usage_${today}"
    local cache_key_monthly="monthly_usage_${current_month}"
    local is_stale=false
    
    # Try to get cached active block data (never fetch synchronously)
    local block_json=$(ccusage_cache_get "$cache_key_block")
    local has_data=false
    
    if [[ -z "$block_json" ]]; then
        # No cached data - try stale cache
        block_json=$(ccusage_cache_get_stale "$cache_key_block")
        if [[ -n "$block_json" ]]; then
            is_stale=true
            has_data=true
        fi
    else
        has_data=true
    fi
    
    # Try to get cached daily usage data (never fetch synchronously)
    local daily_json=$(ccusage_cache_get "$cache_key_daily")
    if [[ -z "$daily_json" ]]; then
        # No cached data - try stale cache
        daily_json=$(ccusage_cache_get_stale "$cache_key_daily")
        if [[ -n "$daily_json" ]]; then
            is_stale=true
            has_data=true
        fi
    else
        has_data=true
    fi
    
    # Try to get cached monthly usage data if in monthly mode
    local monthly_json=""
    if [[ "${CCUSAGE_PERCENTAGE_MODE:-daily_avg}" == "monthly" ]]; then
        monthly_json=$(ccusage_cache_get "$cache_key_monthly")
        if [[ -z "$monthly_json" ]]; then
            # No cached data - try stale cache
            monthly_json=$(ccusage_cache_get_stale "$cache_key_monthly")
            if [[ -n "$monthly_json" ]]; then
                is_stale=true
            fi
        fi
    fi
    
    # If no data at all, return loading indicator
    if [[ "$has_data" == "false" ]]; then
        echo -n "[Loading...]"
        return
    fi
    
    # Parse the data
    cost=$(ccusage_parse_block_cost "$block_json")
    
    # Calculate percentage based on mode
    local mode="${CCUSAGE_PERCENTAGE_MODE:-daily_avg}"
    local daily_cost monthly_cost
    
    # Parse daily cost from JSON
    daily_cost=$(ccusage_parse_daily_percentage "$daily_json" "1")  # Get raw cost by using limit=1
    if [[ -z "$daily_cost" ]] || [[ "$daily_cost" == "0" ]]; then
        # Fallback: extract total cost directly
        if [[ "$daily_json" =~ '"totals"[^}]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
            daily_cost="${match[1]}"
        elif [[ "$daily_json" =~ '"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
            daily_cost="${match[1]}"
        else
            daily_cost="0"
        fi
    else
        # Convert percentage back to cost (daily_cost was percentage with limit=1)
        daily_cost=$((daily_cost / 100.0))
    fi
    
    # Parse monthly cost if needed
    if [[ "$mode" == "monthly" && -n "$monthly_json" ]]; then
        monthly_cost=$(ccusage_parse_monthly_cost "$monthly_json")
    fi
    
    # Calculate percentage using the new function
    percentage=$(ccusage_calculate_percentage "$daily_cost" "$monthly_cost")
    
    # Format and display the data
    ccusage_format_display "$cost" "$percentage" "$is_stale"
}

# Track last displayed value for change detection
typeset -g CCUSAGE_LAST_DISPLAY=""

# Precmd hook for automatic updates
function ccusage_precmd() {
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
    # Validate configuration
    ccusage_validate_percentage_mode
    ccusage_validate_cost_mode
    
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