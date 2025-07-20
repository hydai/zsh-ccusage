#!/usr/bin/env zsh

# Error handler module for zsh-ccusage plugin
# Provides centralized error handling for all fetch operations

# Check for npx availability
# Returns:
#   0 if npx found, 1 if not found
# Output:
#   JSON error message if npx not found
function ccusage_check_npx() {
    if ! command -v npx &> /dev/null; then
        echo '{"error": "npx not found"}'
        return 1
    fi
    return 0
}

# Main error handling function
# Parameters:
#   $1 - exit_code: Command exit code
#   $2 - output: Command output/error message
# Returns:
#   0 on success, 1 on error
# Output:
#   Original output on success, JSON error on failure
function ccusage_handle_fetch_error() {
    local exit_code=$1
    local output=$2
    
    case $exit_code in
        0)
            # Success - return output unchanged
            echo "$output"
            return 0
            ;;
        124)
            # Timeout error
            echo '{"error": "Command timed out", "error_type": "timeout"}'
            return 1
            ;;
        *)
            # Other errors - analyze output for specific error types
            if [[ "$output" =~ "command not found" ]] || [[ "$output" =~ "not found ccusage" ]]; then
                echo '{"error": "ccusage not installed", "error_type": "not_installed"}'
            elif [[ "$output" =~ "ENOTFOUND" ]] || [[ "$output" =~ "ETIMEDOUT" ]] || [[ "$output" =~ "ECONNREFUSED" ]]; then
                echo '{"error": "Network error", "error_type": "network"}'
            elif [[ -n "$output" ]]; then
                # Escape quotes in output for valid JSON
                local escaped_output="${output//\"/\\\"}"
                echo "{\"error\": \"Command failed: ${escaped_output}\", \"error_type\": \"unknown\"}"
            else
                echo '{"error": "Command failed with no output", "error_type": "unknown"}'
            fi
            return 1
            ;;
    esac
}

# Execute command with timeout handling
# Parameters:
#   $1 - timeout_seconds: Timeout in seconds
#   $@ - command and arguments
# Returns:
#   Command exit code
# Output:
#   Command output via stdout
function ccusage_run_with_timeout() {
    local timeout_seconds=$1
    shift
    local cmd=("$@")
    
    # Check if timeout command is available
    if command -v timeout &> /dev/null; then
        timeout $timeout_seconds "${cmd[@]}" 2>&1
        return $?
    else
        # Fallback for systems without timeout (e.g., macOS)
        # Use perl if available (more reliable than shell-based timeout)
        if command -v perl &> /dev/null; then
            perl -e '
                alarm($ARGV[0]);
                $SIG{ALRM} = sub { die "timeout\n" };
                $output = `$ARGV[1]`;
                $exit_code = $? >> 8;
                print $output;
                exit($exit_code);
            ' $timeout_seconds "${cmd[*]}" 2>&1
            local exit_code=$?
            # Convert perl timeout (255) to standard timeout code (124)
            [[ $exit_code -eq 255 ]] && return 124
            return $exit_code
        else
            # Last resort: run without timeout
            "${cmd[@]}" 2>&1
            return $?
        fi
    fi
}