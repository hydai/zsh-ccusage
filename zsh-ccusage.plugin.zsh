#!/usr/bin/env zsh

# ZSH CCUsage Plugin
# Displays real-time ccusage cost information in terminal prompt

# Plugin version
CCUSAGE_VERSION="0.1.0"

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
    # For now, return hardcoded display
    echo '[$0.00 | 0%]'
}

# Initialize the plugin
ccusage_init