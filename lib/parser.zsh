#!/usr/bin/env zsh

# JSON parsing utilities for zsh-ccusage plugin

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
    if [[ "$json_input" =~ '"error"' ]]; then
        echo "0.00"
        return 0
    fi
    
    # Basic JSON validation
    if ! ccusage_is_valid_json "$json_input"; then
        echo "0.00"
        return 0
    fi
    
    # Extract cost from the first active block
    # Look for pattern: "costUSD": <number>
    local cost=$(echo "$json_input" | grep -o '"costUSD"[[:space:]]*:[[:space:]]*[0-9.]*' | head -1 | grep -o '[0-9.]*$')
    
    # If no cost found or empty blocks array, return 0.00
    if [[ -z "$cost" ]] || [[ "$json_input" =~ '"blocks"[[:space:]]*:[[:space:]]*\[\]' ]]; then
        echo "0.00"
        return 0
    fi
    
    # Validate numeric value
    if ! [[ "$cost" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "0.00"
        return 0
    fi
    
    # Format to 2 decimal places
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
    if [[ "$json_input" =~ '"error"' ]]; then
        echo "0"
        return 0
    fi
    
    # Basic JSON validation
    if ! ccusage_is_valid_json "$json_input"; then
        echo "0"
        return 0
    fi
    
    # Extract total cost from daily totals
    # Look for pattern in totals section: "totalCost": <number>
    local total_cost=$(echo "$json_input" | grep -A10 '"totals"' | grep -o '"totalCost"[[:space:]]*:[[:space:]]*[0-9.]*' | head -1 | grep -o '[0-9.]*$')
    
    # If no cost found, try to get from first daily entry
    if [[ -z "$total_cost" ]]; then
        total_cost=$(echo "$json_input" | grep -o '"totalCost"[[:space:]]*:[[:space:]]*[0-9.]*' | head -1 | grep -o '[0-9.]*$')
    fi
    
    # If still no cost found, return 0
    if [[ -z "$total_cost" ]]; then
        echo "0"
        return 0
    fi
    
    # Validate numeric value
    if ! [[ "$total_cost" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "0"
        return 0
    fi
    
    # Validate limit is numeric and positive
    if ! [[ "$limit" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$limit <= 0" | bc -l) )); then
        limit=200
    fi
    
    # Calculate percentage
    local percentage=$(awk -v cost="$total_cost" -v limit="$limit" 'BEGIN { printf "%.0f", (cost / limit) * 100 }' 2>/dev/null || echo "0")
    
    # Cap at 100% for display purposes (actual usage can exceed limit)
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
    if [[ "$json_input" =~ ^\{.*\}$ ]] || [[ "$json_input" =~ ^\[.*\]$ ]]; then
        return 0
    else
        return 1
    fi
}