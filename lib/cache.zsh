#!/usr/bin/env zsh

# Cache management for zsh-ccusage plugin

# Global associative arrays for cache storage
typeset -gA CCUSAGE_CACHE
typeset -gA CCUSAGE_CACHE_TIME

# Default cache duration (30 seconds)
CCUSAGE_CACHE_DURATION=${CCUSAGE_UPDATE_INTERVAL:-30}

# Use zsh's built-in $EPOCHSECONDS for performance
# This avoids spawning external date processes
zmodload zsh/datetime 2>/dev/null || true

# Source persistent cache functionality
source "${0:A:h}/persistent-cache.zsh"

# Store data in cache with timestamp
# Input: key, value
function ccusage_cache_set() {
    local key=$1
    local value=$2
    
    # Store in memory cache
    CCUSAGE_CACHE[$key]=$value
    CCUSAGE_CACHE_TIME[$key]=${EPOCHSECONDS:-$(date +%s)}
    
    # Also store in persistent cache
    ccusage_persistent_set "$key" "$value"
}

# Retrieve cached data if still valid
# Input: key, max_age (seconds, optional - defaults to CCUSAGE_CACHE_DURATION)
# Output: Cached value or empty string
function ccusage_cache_get() {
    local key=$1
    local max_age=${2:-$CCUSAGE_CACHE_DURATION}
    
    # First check memory cache
    if [[ -n "${CCUSAGE_CACHE[$key]}" ]]; then
        local cache_time=${CCUSAGE_CACHE_TIME[$key]:-0}
        local current_time=${EPOCHSECONDS:-$(date +%s)}
        local age=$((current_time - cache_time))
        
        if (( age <= max_age )); then
            echo "${CCUSAGE_CACHE[$key]}"
            return 0
        else
            # Memory cache is stale, remove it
            unset "CCUSAGE_CACHE[$key]"
            unset "CCUSAGE_CACHE_TIME[$key]"
        fi
    fi
    
    # Try persistent cache
    local persistent_value=$(ccusage_persistent_get "$key" "$max_age")
    if [[ -n "$persistent_value" ]]; then
        # Load into memory cache for faster access
        CCUSAGE_CACHE[$key]=$persistent_value
        CCUSAGE_CACHE_TIME[$key]=${EPOCHSECONDS:-$(date +%s)}
        echo "$persistent_value"
        return 0
    fi
    
    return 1
}

# Clear all cache entries
function ccusage_cache_clear_all() {
    CCUSAGE_CACHE=()
    CCUSAGE_CACHE_TIME=()
    ccusage_persistent_clear_all
}

# Clear specific cache entry
# Input: key
function ccusage_cache_clear() {
    local key=$1
    if [[ -n "$key" ]]; then
        unset "CCUSAGE_CACHE[$key]"
        unset "CCUSAGE_CACHE_TIME[$key]"
        ccusage_persistent_clear "$key"
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
    
    # First check memory cache
    if [[ -n "${CCUSAGE_CACHE[$key]}" ]]; then
        echo "${CCUSAGE_CACHE[$key]}"
        return 0
    fi
    
    # Try persistent cache (stale)
    local persistent_value=$(ccusage_persistent_get_stale "$key")
    if [[ -n "$persistent_value" ]]; then
        echo "$persistent_value"
        return 0
    fi
    
    return 1
}