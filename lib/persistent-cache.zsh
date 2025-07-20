#!/usr/bin/env zsh

# Persistent cache functionality for zsh-ccusage plugin
# Stores cache data in filesystem for persistence across sessions

# Cache directory
CCUSAGE_CACHE_DIR="${CCUSAGE_CACHE_DIR:-$HOME/.cache/zsh-ccusage}"

# Ensure cache directory exists
function ccusage_ensure_cache_dir() {
    [[ -d "$CCUSAGE_CACHE_DIR" ]] || mkdir -p "$CCUSAGE_CACHE_DIR"
}

# Write data to persistent cache file
# Input: key, value
function ccusage_persistent_set() {
    local key=$1
    local value=$2
    
    ccusage_ensure_cache_dir
    
    # Sanitize key for filesystem (replace / with _)
    local safe_key="${key//\//_}"
    
    # Write value to file
    echo "$value" > "$CCUSAGE_CACHE_DIR/${safe_key}.json"
    
    # Write timestamp to separate file
    echo "$EPOCHSECONDS" > "$CCUSAGE_CACHE_DIR/${safe_key}.time"
}

# Read data from persistent cache if still valid
# Input: key, max_age (optional)
# Output: Cached value or empty string
function ccusage_persistent_get() {
    local key=$1
    local max_age=${2:-$CCUSAGE_CACHE_DURATION}
    
    # Sanitize key for filesystem (replace / with _)
    local safe_key="${key//\//_}"
    
    local value_file="$CCUSAGE_CACHE_DIR/${safe_key}.json"
    local time_file="$CCUSAGE_CACHE_DIR/${safe_key}.time"
    
    # Check if files exist
    if [[ ! -f "$value_file" || ! -f "$time_file" ]]; then
        return 1
    fi
    
    # Read timestamp
    local cache_time=$(<"$time_file")
    local current_time=$EPOCHSECONDS
    local age=$((current_time - cache_time))
    
    # Check if cache is still fresh
    if (( age <= max_age )); then
        cat "$value_file"
        return 0
    else
        return 1
    fi
}

# Get persistent cache regardless of age
# Input: key
# Output: Cached value or empty string
function ccusage_persistent_get_stale() {
    local key=$1
    
    # Sanitize key for filesystem (replace / with _)
    local safe_key="${key//\//_}"
    
    local value_file="$CCUSAGE_CACHE_DIR/${safe_key}.json"
    
    if [[ -f "$value_file" ]]; then
        cat "$value_file"
        return 0
    fi
    
    return 1
}

# Clear persistent cache entry
# Input: key
function ccusage_persistent_clear() {
    local key=$1
    
    # Sanitize key for filesystem (replace / with _)
    local safe_key="${key//\//_}"
    
    rm -f "$CCUSAGE_CACHE_DIR/${safe_key}.json" "$CCUSAGE_CACHE_DIR/${safe_key}.time" 2>/dev/null
}

# Clear all persistent cache
function ccusage_persistent_clear_all() {
    if [[ -d "$CCUSAGE_CACHE_DIR" ]]; then
        rm -f "$CCUSAGE_CACHE_DIR"/*.json "$CCUSAGE_CACHE_DIR"/*.time 2>/dev/null || true
    fi
}