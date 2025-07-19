#!/usr/bin/env zsh

# Cache management for zsh-ccusage plugin

# Global associative arrays for cache storage
typeset -gA CCUSAGE_CACHE
typeset -gA CCUSAGE_CACHE_TIME

# Default cache duration (5 minutes = 300 seconds)
CCUSAGE_CACHE_DURATION=${CCUSAGE_UPDATE_INTERVAL:-300}

# Use zsh's built-in $EPOCHSECONDS for performance
# This avoids spawning external date processes
zmodload zsh/datetime 2>/dev/null || true

# Store data in cache with timestamp
# Input: key, value
function ccusage_cache_set() {
    local key=$1
    local value=$2
    
    # Store the value
    CCUSAGE_CACHE[$key]=$value
    
    # Store current timestamp using built-in EPOCHSECONDS
    CCUSAGE_CACHE_TIME[$key]=$EPOCHSECONDS
}

# Retrieve cached data if still valid
# Input: key, max_age (seconds, optional - defaults to CCUSAGE_CACHE_DURATION)
# Output: Cached value or empty string
function ccusage_cache_get() {
    local key=$1
    local max_age=${2:-$CCUSAGE_CACHE_DURATION}
    
    # Check if key exists
    if [[ -z "${CCUSAGE_CACHE[$key]}" ]]; then
        return 1
    fi
    
    # Get cache timestamp
    local cache_time=${CCUSAGE_CACHE_TIME[$key]:-0}
    local current_time=$EPOCHSECONDS
    local age=$((current_time - cache_time))
    
    # Check if cache is still fresh
    if (( age <= max_age )); then
        echo "${CCUSAGE_CACHE[$key]}"
        return 0
    else
        # Cache is stale, remove it
        unset "CCUSAGE_CACHE[$key]"
        unset "CCUSAGE_CACHE_TIME[$key]"
        return 1
    fi
}

# Clear all cache entries
function ccusage_cache_clear_all() {
    CCUSAGE_CACHE=()
    CCUSAGE_CACHE_TIME=()
}

# Clear specific cache entry
# Input: key
function ccusage_cache_clear() {
    local key=$1
    if [[ -n "$key" ]]; then
        unset "CCUSAGE_CACHE[$key]"
        unset "CCUSAGE_CACHE_TIME[$key]"
    else
        # No key provided, clear all
        ccusage_cache_clear_all
    fi
}

# Alias for backward compatibility
function ccusage_cache_remove() {
    ccusage_cache_clear "$1"
}

# Check if cache entry exists and is valid
# Input: key, max_age (optional)
# Return: 0 if valid, 1 if invalid or missing
function ccusage_cache_valid() {
    local key=$1
    local max_age=${2:-$CCUSAGE_CACHE_DURATION}
    
    ccusage_cache_get "$key" "$max_age" > /dev/null
    return $?
}

# Get cache age in seconds
# Input: key
# Output: Age in seconds or -1 if not found
function ccusage_cache_age() {
    local key=$1
    
    if [[ -z "${CCUSAGE_CACHE_TIME[$key]}" ]]; then
        echo "-1"
        return 1
    fi
    
    local cache_time=${CCUSAGE_CACHE_TIME[$key]}
    local current_time=$EPOCHSECONDS
    echo $((current_time - cache_time))
}

# Get cached data regardless of age (for fallback during errors)
# Input: key
# Output: Cached value or empty string
function ccusage_cache_get_stale() {
    local key=$1
    
    # Return cached value if it exists, regardless of age
    if [[ -n "${CCUSAGE_CACHE[$key]}" ]]; then
        echo "${CCUSAGE_CACHE[$key]}"
        return 0
    fi
    
    return 1
}