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
    local limit=${2:-${CCUSAGE_PLAN_LIMIT:-${CCUSAGE_DAILY_LIMIT:-200}}}  # Use PLAN_LIMIT, fallback to DAILY_LIMIT, then 200
    
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

# Get number of days in the current month
# Output: Number of days (28-31)
function ccusage_get_days_in_month() {
    local year=$(date +%Y)
    local month=$(date +%m)
    
    # Use date command to get last day of current month
    local days=$(date -d "${year}-${month}-01 +1 month -1 day" +%d 2>/dev/null)
    
    # Fallback for systems without GNU date (e.g., macOS)
    if [[ -z "$days" ]]; then
        case $month in
            01|03|05|07|08|10|12) days=31 ;;
            04|06|09|11) days=30 ;;
            02)
                # Check for leap year
                if (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) )); then
                    days=29
                else
                    days=28
                fi
                ;;
            *) days=30 ;;  # Fallback
        esac
    fi
    
    echo "$days"
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
    
    # Validate mode, fall back to daily_avg if invalid
    case "$mode" in
        daily_avg|daily_plan|monthly) ;;
        *) mode="daily_avg" ;;
    esac
    
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
    
    # Extract total cost from monthly response
    # Monthly response typically has structure: {"usage": [...], "totals": {"totalCost": X}}
    local total_cost=""
    
    # First try to find in totals section
    if [[ "$json_input" =~ '"totals"[^}]*"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
        total_cost="${match[1]}"
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
# Input: JSON string from ccusage -s YYYYMMDD command
# Output: Numeric cost value or 0.00
function ccusage_parse_daily_cost() {
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
    
    # Extract total cost from daily response
    # Daily response structure: [{"model": "...", "totalCost": X, ...}]
    local total_cost=""
    
    # Try to find totalCost in the response
    if [[ "$json_input" =~ '"totalCost"[[:space:]]*:[[:space:]]*([0-9]+\.?[0-9]*)' ]]; then
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
            
            # Try cache first
            json_data=$(ccusage_cache_get "$cache_key")
            
            # If no cached data, try stale cache
            if [[ -z "$json_data" ]]; then
                json_data=$(ccusage_cache_get_stale "$cache_key")
                if [[ -n "$json_data" ]]; then
                    is_stale="true"
                else
                    # No cache available at all
                    has_error="true"
                fi
            fi
            
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
            local today=$(date '+%Y%m%d')
            cache_key="cost_daily_${today}"
            
            # Try cache first
            json_data=$(ccusage_cache_get "$cache_key")
            
            # If no cached data, try stale cache
            if [[ -z "$json_data" ]]; then
                json_data=$(ccusage_cache_get_stale "$cache_key")
                if [[ -n "$json_data" ]]; then
                    is_stale="true"
                else
                    # No cache available at all
                    has_error="true"
                fi
            fi
            
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
            local current_month=$(date '+%Y%m')
            cache_key="cost_monthly_${current_month}"
            
            # Try cache first
            json_data=$(ccusage_cache_get "$cache_key")
            
            # If no cached data, try stale cache
            if [[ -z "$json_data" ]]; then
                json_data=$(ccusage_cache_get_stale "$cache_key")
                if [[ -n "$json_data" ]]; then
                    is_stale="true"
                else
                    # No cache available at all
                    has_error="true"
                fi
            fi
            
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
