#!/usr/bin/env zsh
# validation.zsh - Unified validation functions for zsh-ccusage plugin

# Valid modes configuration
typeset -gA CCUSAGE_VALID_MODES=(
    percentage "daily_avg daily_plan monthly"
    cost "active daily monthly"
)

# Default modes
typeset -gA CCUSAGE_DEFAULT_MODES=(
    percentage "daily_avg"
    cost "active"
)

# Mode suffixes for display
typeset -gA CCUSAGE_MODE_SUFFIXES=(
    # Percentage mode suffixes
    daily_avg "D"
    daily_plan "P"
    monthly "M"
    # Cost mode suffixes
    active "A"
    daily "D"
    monthly "M"
)

# Unified validation function
# Usage: ccusage_validate_mode "percentage" "daily_avg"
# Returns: 0 if valid, 1 if invalid (and sets to default)
function ccusage_validate_mode() {
    local mode_type="$1"
    local mode_value="$2"
    local valid_modes="${CCUSAGE_VALID_MODES[$mode_type]}"
    local default_mode="${CCUSAGE_DEFAULT_MODES[$mode_type]}"
    
    # Check if mode type is valid
    if [[ -z "$valid_modes" ]]; then
        echo "Error: Invalid mode type '$mode_type'" >&2
        return 1
    fi
    
    # Check if mode value is valid
    if [[ " $valid_modes " == *" $mode_value "* ]]; then
        # Valid mode
        return 0
    else
        # Invalid mode - return default
        echo "$default_mode"
        return 1
    fi
}

# Get mode suffix for display
# Usage: ccusage_get_mode_suffix "daily_avg"
# Returns: The suffix character (D, P, M, A)
function ccusage_get_mode_suffix() {
    local mode="$1"
    echo "${CCUSAGE_MODE_SUFFIXES[$mode]:-?}"
}

# Validate and set percentage mode
function ccusage_ensure_valid_percentage_mode() {
    local mode="${CCUSAGE_PERCENTAGE_MODE:-daily_avg}"
    if ! ccusage_validate_mode "percentage" "$mode" >/dev/null 2>&1; then
        CCUSAGE_PERCENTAGE_MODE="$(ccusage_validate_mode "percentage" "$mode")"
    fi
}

# Validate and set cost mode
function ccusage_ensure_valid_cost_mode() {
    local mode="${CCUSAGE_COST_MODE:-active}"
    if ! ccusage_validate_mode "cost" "$mode" >/dev/null 2>&1; then
        CCUSAGE_COST_MODE="$(ccusage_validate_mode "cost" "$mode")"
    fi
}