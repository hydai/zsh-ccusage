#!/usr/bin/env zsh

# ZSH CCUsage Plugin
# Displays real-time ccusage cost information in terminal prompt

# Plugin version
CCUSAGE_VERSION="0.1.0"

# Get plugin directory
CCUSAGE_PLUGIN_DIR="${0:A:h}"

# Source all required components
source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-format"
source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-fetch"
source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-refresh"
source "${CCUSAGE_PLUGIN_DIR}/lib/parser.zsh"
source "${CCUSAGE_PLUGIN_DIR}/lib/cache.zsh"

# Initialize plugin
function ccusage_init() {
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
}

# Display function - returns formatted cost information
function ccusage_display() {
    local cost percentage
    local cache_key_block="active_block"
    local cache_key_daily="daily_usage"
    
    # Try to get cached active block data
    local block_json=$(ccusage_cache_get "$cache_key_block")
    if [[ -z "$block_json" ]]; then
        # Cache miss - fetch fresh data
        block_json=$(ccusage_fetch_active_block)
        # Cache the result if it's not an error
        if [[ ! "$block_json" =~ '"error"' ]]; then
            ccusage_cache_set "$cache_key_block" "$block_json"
        fi
    fi
    cost=$(ccusage_parse_block_cost "$block_json")
    
    # Try to get cached daily usage data
    local daily_json=$(ccusage_cache_get "$cache_key_daily")
    if [[ -z "$daily_json" ]]; then
        # Cache miss - fetch fresh data
        daily_json=$(ccusage_fetch_daily)
        # Cache the result if it's not an error
        if [[ ! "$daily_json" =~ '"error"' ]]; then
            ccusage_cache_set "$cache_key_daily" "$daily_json"
        fi
    fi
    local daily_limit=${CCUSAGE_DAILY_LIMIT:-200}
    percentage=$(ccusage_parse_daily_percentage "$daily_json" "$daily_limit")
    
    # Format and display the data
    ccusage_format_display "$cost" "$percentage"
}

# Precmd hook for automatic updates
function ccusage_precmd() {
    # Check if auto-update is enabled (default: true)
    local auto_update=${CCUSAGE_AUTO_UPDATE:-true}
    
    # Only trigger update if auto-update is enabled
    if [[ "$auto_update" == "true" ]]; then
        # Force cache refresh by clearing cache entries
        ccusage_cache_clear
    fi
}

# Initialize the plugin
ccusage_init