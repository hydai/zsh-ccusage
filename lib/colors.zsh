#!/usr/bin/env zsh

# Color utility functions for zsh-ccusage plugin

# Define color codes for different usage levels
CCUSAGE_COLOR_LOW="%F{green}"      # 0-50%
CCUSAGE_COLOR_MEDIUM="%F{yellow}"  # 50-80%
CCUSAGE_COLOR_HIGH="%F{red}"       # 80%+
CCUSAGE_COLOR_RESET="%f"           # Reset color

# Get color based on percentage
# Input: percentage (0-100)
# Output: zsh color code
function ccusage_get_color() {
    local percentage=$1
    
    # Validate input
    if [[ ! "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$CCUSAGE_COLOR_RESET"
        return
    fi
    
    # Determine color based on percentage
    if (( percentage < 50 )); then
        echo "$CCUSAGE_COLOR_LOW"
    elif (( percentage < 80 )); then
        echo "$CCUSAGE_COLOR_MEDIUM"
    else
        echo "$CCUSAGE_COLOR_HIGH"
    fi
}

# Apply color to text
# Input: text, percentage
# Output: colored text
function ccusage_colorize() {
    local text=$1
    local percentage=$2
    local color=$(ccusage_get_color $percentage)
    
    echo "${color}${text}${CCUSAGE_COLOR_RESET}"
}