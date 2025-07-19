# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a ZSH plugin that displays real-time AI usage costs from the `ccusage` CLI tool in the terminal prompt. The plugin provides visual feedback with color-coded indicators to help developers monitor their AI usage and prevent exceeding block limits.

## Core Architecture

The plugin follows a modular architecture with these key components:

1. **Main Entry Point** (`zsh-ccusage.plugin.zsh`): Orchestrates plugin loading, framework detection, and lazy initialization
2. **Async Data Pipeline**: Non-blocking background jobs fetch data from ccusage CLI without freezing the terminal
3. **Cache Layer**: Two-tier caching system - in-memory (zsh associative arrays) and persistent disk cache
4. **Display Engine**: Formats cost/percentage data with color coding and terminal width adaptation

### Data Flow
```
Terminal Command → Precmd Hook → Async Fetcher → ccusage CLI → JSON Parser → Cache → Formatter → RPROMPT
```

## Development Commands

```bash
# Validate plugin syntax and structure
./validate.sh

# Test percentage mode switching
zsh test_percentage_modes.zsh

# Install for Oh My Zsh users
./install-omz.sh

# Manual testing - source and refresh
source zsh-ccusage.plugin.zsh
ccusage-refresh
```

## Key Implementation Details

### Percentage Calculation Modes
The plugin supports three modes controlled by `CCUSAGE_PERCENTAGE_MODE`:
- `daily_avg`: Compares today's usage against daily average (plan_limit / days_in_month)
- `daily_plan`: Compares today's usage against full monthly plan
- `monthly`: Compares total monthly usage against plan limit

### Async Updates
The plugin uses ZSH's background job system (`&!`) to fetch data without blocking. Results are captured via temporary files and integrated into the prompt on completion.

### Cache Strategy
- In-memory cache: 5-minute TTL for active block and daily usage
- Persistent cache: Survives shell restarts, stored in `~/.cache/zsh-ccusage/`
- Cache invalidation: Manual via `ccusage-refresh` or automatic on TTL expiry

### Color Thresholds
- Green: 0-79% usage
- Yellow: 80-99% usage  
- Red: ≥100% usage (with optional bold)

## Testing Approach

No formal test framework is used. Testing is done via:
1. `validate.sh` - Checks syntax, required files, and load performance
2. `test_percentage_modes.zsh` - Validates mode switching behavior
3. Manual testing with different scenarios (no data, high usage, network errors)

## Environment Variables

Critical configuration variables:
- `CCUSAGE_PLAN_LIMIT`: Monthly plan limit in USD (default: 200)
- `CCUSAGE_PERCENTAGE_MODE`: Calculation mode (daily_avg|daily_plan|monthly)
- `CCUSAGE_AUTO_UPDATE`: Enable/disable automatic updates
- `CCUSAGE_UPDATE_INTERVAL`: Cache duration in seconds

Note: `CCUSAGE_DAILY_LIMIT` is deprecated - use `CCUSAGE_PLAN_LIMIT`

## Function Autoloading

The plugin uses ZSH's autoload mechanism for lazy loading. Functions in the `functions/` directory are only loaded when called:
- `ccusage-fetch`: Fetches data from ccusage CLI
- `ccusage-format`: Formats display output
- `ccusage-refresh`: Manual refresh command

## Plugin Manager Compatibility

The plugin auto-detects and adapts to:
- Oh My Zsh: Standard plugin structure
- Prezto: Module compatibility
- Zinit: Light mode support
- Manual: Direct sourcing

## Performance Considerations

- Plugin load time target: <100ms
- Lazy initialization delays heavy operations until first use
- Async updates prevent blocking the terminal
- Efficient JSON parsing without external dependencies (uses zsh built-ins)

## Common Development Tasks

When modifying display logic:
1. Edit `functions/ccusage-format` for formatting changes
2. Update `lib/colors.zsh` for color threshold adjustments
3. Test with `ccusage-refresh` to see immediate changes

When adding new percentage modes:
1. Update `ccusage_calculate_percentage` in main plugin file
2. Add fetching logic if needed in `functions/ccusage-fetch`
3. Update validation in `ccusage_validate_percentage_mode`
4. Test mode switching with `test_percentage_modes.zsh`