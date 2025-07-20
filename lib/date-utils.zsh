#!/usr/bin/env zsh

# Date utilities module for zsh-ccusage plugin
# Provides cached date operations to reduce system calls

# Global cache variables
typeset -g CCUSAGE_CACHED_TODAY=""
typeset -g CCUSAGE_CACHED_MONTH=""
typeset -g CCUSAGE_LAST_DATE_CHECK=0

# Cache TTL in seconds
typeset -g CCUSAGE_DATE_CACHE_TTL=60

# Get today's date with caching (YYYYMMDD format)
# Cache TTL: 60 seconds
# Returns: Date string
function ccusage_get_today() {
    local current_time=${EPOCHSECONDS:-$(date +%s)}
    local time_diff=$((current_time - CCUSAGE_LAST_DATE_CHECK))
    
    # Check if cache is still valid
    if [[ -n "$CCUSAGE_CACHED_TODAY" ]] && (( time_diff < CCUSAGE_DATE_CACHE_TTL )); then
        echo "$CCUSAGE_CACHED_TODAY"
        return 0
    fi
    
    # Cache expired or empty, fetch new date
    CCUSAGE_CACHED_TODAY=$(date +%Y%m%d)
    CCUSAGE_LAST_DATE_CHECK=$current_time
    
    echo "$CCUSAGE_CACHED_TODAY"
}

# Get current month with caching (YYYYMM format)
# Cache TTL: 60 seconds
# Returns: Month string
function ccusage_get_current_month() {
    local current_time=${EPOCHSECONDS:-$(date +%s)}
    local time_diff=$((current_time - CCUSAGE_LAST_DATE_CHECK))
    
    # Check if cache is still valid
    if [[ -n "$CCUSAGE_CACHED_MONTH" ]] && (( time_diff < CCUSAGE_DATE_CACHE_TTL )); then
        echo "$CCUSAGE_CACHED_MONTH"
        return 0
    fi
    
    # Cache expired or empty, fetch new month
    CCUSAGE_CACHED_MONTH=$(date +%Y%m)
    # Update the check time if not already updated by ccusage_get_today
    if [[ -z "$CCUSAGE_CACHED_TODAY" ]] || (( time_diff >= CCUSAGE_DATE_CACHE_TTL )); then
        CCUSAGE_LAST_DATE_CHECK=$current_time
    fi
    
    echo "$CCUSAGE_CACHED_MONTH"
}

# Get days in current month
# Returns: Number of days
function ccusage_get_days_in_month() {
    local month=$(ccusage_get_current_month)
    local year=${month:0:4}
    local month_num=${month:4:2}
    
    # Remove leading zero for arithmetic
    month_num=${month_num#0}
    
    local days
    case $month_num in
        1|3|5|7|8|10|12)
            days=31
            ;;
        4|6|9|11)
            days=30
            ;;
        2)
            # Check for leap year
            if (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) )); then
                days=29
            else
                days=28
            fi
            ;;
        *)
            # Fallback
            days=30
            ;;
    esac
    
    echo "$days"
}