#!/usr/bin/env zsh

# ZSH CCUsage Plugin
# Displays real-time ccusage cost information in terminal prompt

# Plugin version
CCUSAGE_VERSION="0.1.0"

# Get plugin directory
CCUSAGE_PLUGIN_DIR="${0:A:h}"

# Source formatting function
source "${CCUSAGE_PLUGIN_DIR}/functions/ccusage-format"

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
    # For now, use hardcoded values with formatting
    local cost="0.00"
    local percentage="0"
    
    # Use the formatting function with color support
    ccusage_format_display "$cost" "$percentage"
}

# Initialize the plugin
ccusage_init