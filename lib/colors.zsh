#!/usr/bin/env zsh

# Color utility functions for zsh-ccusage plugin

# Check if terminal supports colors
function ccusage_has_colors() {
    # Check if terminal supports colors
    if [[ -z "$TERM" ]] || [[ "$TERM" == "dumb" ]]; then
        echo "false"
        return
    fi
    
    # Check if colors are disabled via NO_COLOR env var
    if [[ -n "$NO_COLOR" ]]; then
        echo "false"
        return
    fi
    
    # Check tput if available
    if command -v tput >/dev/null 2>&1; then
        if (( $(tput colors 2>/dev/null || echo 0) >= 8 )); then
            echo "true"
        else
            echo "false"
        fi
    else
        # Assume color support if we can't detect
        echo "true"
    fi
}

# Define color codes for different usage levels
CCUSAGE_COLOR_LOW="%F{green}"      # <80%
CCUSAGE_COLOR_MEDIUM="%F{yellow}"  # ≥80%
CCUSAGE_COLOR_HIGH="%F{red}"       # ≥100%
CCUSAGE_COLOR_RESET="%f"           # Reset color
CCUSAGE_BOLD="%B"                  # Bold formatting
CCUSAGE_BOLD_RESET="%b"            # Reset bold

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
    if (( percentage < 80 )); then
        echo "$CCUSAGE_COLOR_LOW"
    elif (( percentage < 100 )); then
        echo "$CCUSAGE_COLOR_MEDIUM"
    else
        echo "$CCUSAGE_COLOR_HIGH"
    fi
}

# Check if percentage should be bold
# Input: percentage
# Output: true/false
function ccusage_should_bold() {
    local percentage=$1
    
    # Validate input
    if [[ ! "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "false"
        return
    fi
    
    # Bold for values >= 100%
    if (( percentage >= 100 )); then
        echo "true"
    else
        echo "false"
    fi
}

# Get text indicator for percentage (for non-color terminals)
# Input: percentage
# Output: text indicator
function ccusage_get_indicator() {
    local percentage=$1
    
    # Validate input
    if [[ ! "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo ""
        return
    fi
    
    # Return indicator based on percentage
    if (( percentage < 80 )); then
        echo ""  # No indicator for low usage
    elif (( percentage < 100 )); then
        echo "!"  # Warning indicator
    else
        echo "!!"  # Critical indicator
    fi
}

# Apply color to text
# Input: text, percentage
# Output: colored text or text with indicators
function ccusage_colorize() {
    local text=$1
    local percentage=$2
    
    if [[ $(ccusage_has_colors) == "true" ]]; then
        # Use colors if supported
        local color=$(ccusage_get_color $percentage)
        local should_bold=$(ccusage_should_bold $percentage)
        
        if [[ "$should_bold" == "true" ]]; then
            echo "${CCUSAGE_BOLD}${color}${text}${CCUSAGE_COLOR_RESET}${CCUSAGE_BOLD_RESET}"
        else
            echo "${color}${text}${CCUSAGE_COLOR_RESET}"
        fi
    else
        # Use text indicators for non-color terminals
        local indicator=$(ccusage_get_indicator $percentage)
        echo "${text}${indicator}"
    fi
}