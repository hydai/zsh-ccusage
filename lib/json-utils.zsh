#!/usr/bin/env zsh

# JSON validation utilities for zsh-ccusage plugin

# Validate JSON input for errors or empty data
# Parameters:
#   $1 - json_input: JSON string to validate
#   $2 - default_value: Value to return on invalid input (optional, default: "0.00")
# Returns:
#   0 if valid, 1 if invalid
# Output:
#   Default value on invalid input (via echo, not return value)
function ccusage_validate_json_input() {
    local json_input=$1
    local default_value=${2:-"0.00"}
    
    # Check for empty input
    if [[ -z "$json_input" ]]; then
        echo "$default_value"
        return 1
    fi
    
    # Check for error field in JSON
    # Using grep for pattern matching to avoid dependencies
    if echo "$json_input" | grep -q '"error"'; then
        echo "$default_value"
        return 1
    fi
    
    # Input is valid
    return 0
}

# Extract error message from JSON
# Parameters:
#   $1 - json_input: JSON string
# Returns:
#   Error message or empty string
function ccusage_extract_error_message() {
    local json_input=$1
    
    # Return empty if no input
    if [[ -z "$json_input" ]]; then
        echo ""
        return
    fi
    
    # Extract error message using parameter expansion
    # Look for pattern: "error": "message"
    local error_msg=""
    if [[ "$json_input" =~ '"error"[[:space:]]*:[[:space:]]*"([^"]*)"' ]]; then
        error_msg="${match[1]}"
    fi
    
    echo "$error_msg"
}