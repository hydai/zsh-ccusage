#!/usr/bin/env zsh

# ZSH CCUsage Plugin - Optimized Version
# Displays real-time ccusage cost information in terminal prompt

# Plugin version
CCUSAGE_VERSION="0.1.0"

# Get plugin directory
CCUSAGE_PLUGIN_DIR="${0:A:h}"

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
    local cache_key_daily="daily_usage"
    local is_stale=false
    
    # Try to get cached active block data (never fetch synchronously)
    local block_json=$(ccusage_cache_get "$cache_key_block")
    if [[ -z "$block_json" ]]; then
        # No cached data - try stale cache
        block_json=$(ccusage_cache_get_stale "$cache_key_block")
        if [[ -n "$block_json" ]]; then
            is_stale=true
        else
            # No data at all - use default
            block_json='{"blocks":[]}'
        fi
    fi
    cost=$(ccusage_parse_block_cost "$block_json")
    
    # Try to get cached daily usage data (never fetch synchronously)
    local daily_json=$(ccusage_cache_get "$cache_key_daily")
    if [[ -z "$daily_json" ]]; then
        # No cached data - try stale cache
        daily_json=$(ccusage_cache_get_stale "$cache_key_daily")
        if [[ -n "$daily_json" ]]; then
            is_stale=true
        else
            # No data at all - use default
            daily_json='{"totals":{"totalCost":0}}'
        fi
    fi
    local daily_limit=${CCUSAGE_DAILY_LIMIT:-200}
    percentage=$(ccusage_parse_daily_percentage "$daily_json" "$daily_limit")
    
    # Format and display the data
    ccusage_format_display "$cost" "$percentage" "$is_stale"
}

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
    
    # Set initial default values in cache to avoid empty display
    if ! ccusage_cache_valid "active_block"; then
        ccusage_cache_set "active_block" '{"blocks":[]}'
    fi
    if ! ccusage_cache_valid "daily_usage"; then
        ccusage_cache_set "daily_usage" '{"totals":{"totalCost":0}}'
    fi
    
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