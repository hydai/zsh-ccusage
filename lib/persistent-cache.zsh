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
    
    # Write to persistent cache asynchronously to avoid blocking
    {
        # Write value to file
        echo "$value" > "$CCUSAGE_CACHE_DIR/${safe_key}.json"
        
        # Write timestamp to separate file
        echo "${EPOCHSECONDS:-$(date +%s)}" > "$CCUSAGE_CACHE_DIR/${safe_key}.time"
    } &!
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
    
    # Check if files exist - use test command for speed
    [[ -f "$value_file" && -f "$time_file" ]] || return 1
    
    # Read timestamp with minimal overhead
    local cache_time
    if read -r cache_time < "$time_file" 2>/dev/null; then
        local current_time=${EPOCHSECONDS:-$(date +%s)}
        local age=$((current_time - cache_time))
        
        # Check if cache is still fresh
        if (( age <= max_age )); then
            # Use read for small files to avoid cat overhead
            if [[ -s "$value_file" ]]; then
                cat "$value_file" 2>/dev/null
                return 0
            fi
        fi
    fi
    
    return 1
}

# Get persistent cache regardless of age
# Input: key
# Output: Cached value or empty string
function ccusage_persistent_get_stale() {
    local key=$1
    
    # Sanitize key for filesystem (replace / with _)
    local safe_key="${key//\//_}"
    
    local value_file="$CCUSAGE_CACHE_DIR/${safe_key}.json"
    
    # Fast existence check and read
    [[ -f "$value_file" ]] && cat "$value_file" 2>/dev/null
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