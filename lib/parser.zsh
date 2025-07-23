#!/usr/bin/env zsh

# Optimized JSON parsing utilities for zsh-ccusage plugin
# Uses zsh built-in string manipulation to avoid spawning processes

# Parse active block cost from JSON response
# Input: JSON string from ccusage blocks command
# Output: Numeric cost value or 0.00
function ccusage_parse_block_cost() {
    local json_input=$1
    
    # Use JSON validation utility
    local validation_result=$(ccusage_validate_json_input "$json_input")
    if [[ $? -eq 1 ]]; then
        echo "$validation_result"
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
    local limit=${2:-${CCUSAGE_PLAN_LIMIT:-${CCUSAGE_DAILY_LIMIT:-200}}}  # Use PLAN_LIMIT, fallback to DAILY_LIMIT, then 200
    
    # Use JSON validation utility with custom default value for percentage
    local validation_result=$(ccusage_validate_json_input "$json_input" "0")
    if [[ $? -eq 1 ]]; then
        echo "$validation_result"
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
    
    # Ensure non-negative value
    if (( percentage < 0 )); then
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


# Calculate percentage based on configured mode
# Input: daily_cost, monthly_cost (optional for monthly mode)
# Output: Percentage value
function ccusage_calculate_percentage() {
    local daily_cost=$1
    local monthly_cost=${2:-0}
    
    # Get configuration
    local mode="${CCUSAGE_PERCENTAGE_MODE:-daily_avg}"
    local plan_limit="${CCUSAGE_PLAN_LIMIT:-${CCUSAGE_DAILY_LIMIT:-200}}"
    
    # Ensure mode is valid using unified validation
    if ! ccusage_validate_mode "percentage" "$mode" >/dev/null 2>&1; then
        mode="$(ccusage_validate_mode "percentage" "$mode")"
    fi
    
    # Validate numeric inputs
    if ! [[ "$daily_cost" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        daily_cost=0
    fi
    if ! [[ "$monthly_cost" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        monthly_cost=0
    fi
    if ! [[ "$plan_limit" =~ ^[0-9]+\.?[0-9]*$ ]] || (( plan_limit <= 0 )); then
        plan_limit=200
    fi
    
    local percentage=0
    
    case "$mode" in
        daily_avg)
            # Calculate daily average: daily_cost / (plan_limit / days_in_month)
            local days_in_month=$(ccusage_get_days_in_month)
            local daily_limit
            (( daily_limit = plan_limit * 1.0 / days_in_month ))
            if (( daily_limit > 0 )); then
                (( percentage = (daily_cost * 100.0) / daily_limit ))
            fi
            ;;
        
        daily_plan)
            # Calculate against full plan limit: daily_cost / plan_limit
            if (( plan_limit > 0 )); then
                (( percentage = (daily_cost * 100.0) / plan_limit ))
            fi
            ;;
        
        monthly)
            # Calculate monthly percentage: monthly_cost / plan_limit
            if (( plan_limit > 0 )); then
                (( percentage = (monthly_cost * 100.0) / plan_limit ))
            fi
            ;;
    esac
    
    # Return integer percentage
    percentage=${percentage%.*}
    
    # Ensure non-negative value
    if (( percentage < 0 )); then
        echo "0"
    else
        echo "$percentage"
    fi
}

# Parse monthly usage total cost from JSON response
# Input: JSON string from ccusage monthly command
# Output: Numeric cost value or 0.00
function ccusage_parse_monthly_cost() {
    local json_input=$1
    
    # Use JSON validation utility
    local validation_result=$(ccusage_validate_json_input "$json_input")
    if [[ $? -eq 1 ]]; then
        echo "$validation_result"
        return 0
    fi
    
    # Extract total cost from monthly response
    # New format: {"monthly": [...], "totals": {"totalCost": X}}
    local total_cost=""
    
    # First try to find in totals section (preferred)
    if [[ "$json_input" =~ '"totals"[^}]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
        total_cost="${match[1]}"
    elif [[ "$json_input" =~ '"monthly"[[:space:]]*:[[:space:]]*\[' ]]; then
        # If no totals, try to sum all months or get current month
        # Get current month in YYYY-MM format
        local current_month=$(date +%Y-%m)
        # Look for current month's totalCost
        if [[ "$json_input" =~ "\"month\"[[:space:]]*:[[:space:]]*\"$current_month\"[^}]*\"totalCost\"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)" ]]; then
            total_cost="${match[1]}"
        fi
    elif [[ "$json_input" =~ '"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
        # Fallback to any totalCost in the response
        total_cost="${match[1]}"
    fi
    
    # If no cost found, return 0.00
    if [[ -z "$total_cost" ]]; then
        echo "0.00"
        return 0
    fi
    
    # Format to 2 decimal places using zsh arithmetic
    printf "%.2f" "$total_cost" 2>/dev/null || echo "0.00"
}

# Parse daily cost from JSON response
# Input: JSON string from ccusage daily command
# Output: Numeric cost value or 0.00
function ccusage_parse_daily_cost() {
    local json_input=$1
    local use_latest=${2:-false}  # If true, use latest daily entry
    
    # Use JSON validation utility
    local validation_result=$(ccusage_validate_json_input "$json_input")
    if [[ $? -eq 1 ]]; then
        echo "$validation_result"
        return 0
    fi
    
    # Handle empty array response (no data)
    if [[ "$json_input" == "[]" ]]; then
        echo "0.00"
        return 0
    fi
    
    # Extract total cost from daily response
    # New format: {"daily": [...], "totals": {"totalCost": X}}
    local total_cost=""
    
    if [[ "$use_latest" == "true" ]] && [[ "$json_input" =~ '"daily"[[:space:]]*:[[:space:]]*\[' ]]; then
        # For latest daily data, find the last totalCost in the daily array
        # Use a reverse search approach - find all totalCost occurrences
        # Since we want the latest (last) entry, we'll use a different strategy
        
        # First check if there's data in the daily array
        if [[ "$json_input" =~ '"daily"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]' ]]; then
            # Empty daily array
            echo "0.00"
            return 0
        fi
        
        # Find the position of the last date entry and extract totalCost after it
        # Look for pattern: "date":"YYYY-MM-DD"..."totalCost":X
        # Get all text after the last "date" occurrence
        local last_date_pos=${json_input%"date"*}
        local from_last_date=${json_input:${#last_date_pos}}
        
        # Now find the first totalCost after this position
        if [[ "$from_last_date" =~ '"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
            total_cost="${match[1]}"
        fi
    else
        # Original logic for single day or totals
        # First try to find in totals section (preferred)
        if [[ "$json_input" =~ '"totals"[^}]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
            total_cost="${match[1]}"
        elif [[ "$json_input" =~ '"daily"[[:space:]]*:[[:space:]]*\[' ]]; then
            # If no totals section, extract first day's totalCost from daily array
            if [[ "$json_input" =~ '"daily"[[:space:]]*:[[:space:]]*\[[^]]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
                total_cost="${match[1]}"
            fi
        elif [[ "$json_input" =~ '^[[:space:]]*\[' ]]; then
            # Direct array format - extract first item's totalCost
            if [[ "$json_input" =~ '\[[^]]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
                total_cost="${match[1]}"
            fi
        fi
    fi
    
    # If no cost found, return 0.00
    if [[ -z "$total_cost" ]]; then
        echo "0.00"
        return 0
    fi
    
    # Format to 2 decimal places using zsh arithmetic
    printf "%.2f" "$total_cost" 2>/dev/null || echo "0.00"
}

# Get cost based on configured cost mode
# Input: none (uses CCUSAGE_COST_MODE environment variable)
# Output: Array with three elements: cost_value mode_indicator is_stale
# Example: ("45.23" "A" "false") for active mode with fresh data
#          ("20.45" "D" "true") for daily mode with stale data
#          ("-.--" "M" "false") for monthly mode with no data
function ccusage_get_cost_by_mode() {
    # Get configuration
    local mode="${CCUSAGE_COST_MODE:-active}"
    
    # Validate mode, fall back to active if invalid
    case "$mode" in
        active|daily|monthly) ;;
        *) mode="active" ;;
    esac
    
    local cost="0.00"
    local mode_indicator=""
    local json_data=""
    local cache_key=""
    local is_stale="false"
    local has_error="false"
    
    # Route to appropriate fetcher based on mode
    case "$mode" in
        active)
            mode_indicator="A"
            cache_key="cost_active"
            
            # Use unified cache retrieval helper
            ccusage_cache_get_with_fallback "$cache_key" json_data is_stale has_error
            
            # Parse the cost
            if [[ -n "$json_data" ]] && [[ "$json_data" != *'"error"'* ]]; then
                cost=$(ccusage_parse_block_cost "$json_data")
            elif [[ "$has_error" == "true" ]] && [[ -z "$json_data" ]]; then
                # No cache available, show placeholder
                cost="-.--"
            fi
            ;;
            
        daily)
            mode_indicator="D"
            # Include today's date in cache key for daily mode
            local today=$(ccusage_get_today)
            cache_key="cost_daily_${today}"
            
            # Use unified cache retrieval helper
            ccusage_cache_get_with_fallback "$cache_key" json_data is_stale has_error
            
            # Parse the cost
            if [[ -n "$json_data" ]] && [[ "$json_data" != *'"error"'* ]]; then
                cost=$(ccusage_parse_daily_cost "$json_data")
            elif [[ "$has_error" == "true" ]] && [[ -z "$json_data" ]]; then
                # No cache available, show placeholder
                cost="-.--"
            fi
            ;;
            
        monthly)
            mode_indicator="M"
            # Include current month in cache key for monthly mode
            local current_month=$(ccusage_get_current_month)
            cache_key="cost_monthly_${current_month}"
            
            # Use unified cache retrieval helper
            ccusage_cache_get_with_fallback "$cache_key" json_data is_stale has_error
            
            # Parse the cost
            if [[ -n "$json_data" ]] && [[ "$json_data" != *'"error"'* ]]; then
                cost=$(ccusage_parse_monthly_cost "$json_data")
            elif [[ "$has_error" == "true" ]] && [[ -z "$json_data" ]]; then
                # No cache available, show placeholder
                cost="-.--"
            fi
            ;;
    esac
    
    # Return array with cost, mode indicator, and stale flag
    echo "$cost" "$mode_indicator" "$is_stale"
}
