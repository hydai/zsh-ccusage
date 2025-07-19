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
source "${CCUSAGE_PLUGIN_DIR}/lib/parser.zsh"

# Initialize plugin
function ccusage_init() {
    # Set default display if not already in RPROMPT
    if [[ ! "$RPROMPT" =~ "ccusage_display" ]]; then
        # Add ccusage display to the left of existing RPROMPT content
        RPROMPT='$(ccusage_display)'${RPROMPT:+" $RPROMPT"}
    fi
}

# Display function - returns formatted cost information
function ccusage_display() {
    # Fetch active block data
    local block_json=$(ccusage_fetch_active_block)
    local cost=$(ccusage_parse_block_cost "$block_json")
    
    # Fetch daily usage data
    local daily_json=$(ccusage_fetch_daily)
    local daily_limit=${CCUSAGE_DAILY_LIMIT:-200}
    local percentage=$(ccusage_parse_daily_percentage "$daily_json" "$daily_limit")
    
    # Format and display the data
    ccusage_format_display "$cost" "$percentage"
}

# Initialize the plugin
ccusage_init