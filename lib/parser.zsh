#!/usr/bin/env zsh

# Optimized JSON parsing utilities for zsh-ccusage plugin
# Uses zsh built-in string manipulation to avoid spawning processes

# Parse active block cost from JSON response
# Input: JSON string from ccusage blocks command
# Output: Numeric cost value or 0.00
function ccusage_parse_block_cost() {
    local json_input=$1
    
    # Check if input is empty or null
    if [[ -z "$json_input" ]]; then
        echo "0.00"
        return 0
    fi
    
    # Check if it's an error response
    if [[ "$json_input" == *'"error"'* ]]; then
        echo "0.00"
        return 0
    fi
    
    # Check for empty blocks array
    if [[ "$json_input" == *'"blocks"'*':'*'[]'* ]]; then
        echo "0.00"
        return 0
    fi
    
    # Extract cost using zsh pattern matching
    # Look for pattern: "costUSD": <number>
    local cost=""
    if [[ "$json_input" =~ '"costUSD"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
        cost="${match[1]}"
    fi
    
    # If no cost found, return 0.00
    if [[ -z "$cost" ]]; then
        echo "0.00"
        return 0
    fi
    
    # Format to 2 decimal places using zsh arithmetic
    printf "%.2f" "$cost" 2>/dev/null || echo "0.00"
}

# Parse daily usage and calculate percentage
# Input: JSON string from ccusage daily command
# Output: Percentage (0-100) based on limit
function ccusage_parse_daily_percentage() {
    local json_input=$1
    local limit=${2:-200}  # Default to $200 if not specified
    
    # Check if input is empty or null
    if [[ -z "$json_input" ]]; then
        echo "0"
        return 0
    fi
    
    # Check if it's an error response
    if [[ "$json_input" == *'"error"'* ]]; then
        echo "0"
        return 0
    fi
    
    # Extract total cost using zsh pattern matching
    local total_cost=""
    
    # First try to find in totals section
    if [[ "$json_input" =~ '"totals"[^}]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
        total_cost="${match[1]}"
    elif [[ "$json_input" =~ '"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
        # Fallback to any totalCost in the response
        total_cost="${match[1]}"
    fi
    
    # If no cost found, return 0
    if [[ -z "$total_cost" ]]; then
        echo "0"
        return 0
    fi
    
    # Validate limit is numeric and positive using zsh arithmetic
    if ! [[ "$limit" =~ ^[0-9]+\.?[0-9]*$ ]] || (( limit <= 0 )); then
        limit=200
    fi
    
    # Calculate percentage using zsh floating point arithmetic
    local percentage
    (( percentage = (total_cost * 100.0) / limit ))
    percentage=${percentage%.*}  # Truncate to integer
    
    # Cap at 100% for display purposes
    if (( percentage > 100 )); then
        echo "100"
    elif (( percentage < 0 )); then
        echo "0"
    else
        echo "$percentage"
    fi
}

# Helper function to check if JSON is valid
# Input: JSON string
# Output: 0 if valid, 1 if invalid
function ccusage_is_valid_json() {
    local json_input=$1
    
    # Basic validation - check for required JSON structure
    if [[ "$json_input" == \{*\} ]] || [[ "$json_input" == \[*\] ]]; then
        return 0
    else
        return 1
    fi
}