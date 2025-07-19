# ZSH CCUsage Plugin

A lightweight ZSH plugin that displays real-time AI usage costs from the `ccusage` CLI tool directly in your terminal prompt.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![ZSH](https://img.shields.io/badge/zsh-5.0%2B-green.svg)

## Overview

The zsh-ccusage plugin helps developers monitor their AI usage costs in real-time by displaying the current active block cost and daily usage percentage in the terminal prompt. It prevents exceeding block limits by providing visual feedback with color-coded indicators.

**Example display**: `[$45.23 | 35%]`

## Features

- 🚀 **Real-time cost display** - Shows current active block cost
- 📊 **Daily usage tracking** - Displays usage as percentage of daily limit
- 🎨 **Color-coded indicators** - Green (0-50%), Yellow (50-80%), Red (80%+)
- ⚡ **Async updates** - Non-blocking data fetching
- 💾 **Smart caching** - Reduces API calls with intelligent cache management
- 🔧 **Highly configurable** - Customize display format, update intervals, and limits
- 📱 **Responsive design** - Adapts to terminal width automatically
- 🛡️ **Robust error handling** - Gracefully handles network issues and missing dependencies

## Requirements

- ZSH 5.0 or higher
- Node.js and npm/npx (for running ccusage CLI)
- [ccusage CLI](https://github.com/yourusername/ccusage) installed or accessible via npx

## Installation

### Oh My Zsh

1. Clone the repository into your custom plugins directory:
   ```bash
   git clone https://github.com/yourusername/zsh-ccusage ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ccusage
   ```

2. Add the plugin to your `.zshrc`:
   ```bash
   plugins=(... zsh-ccusage)
   ```

3. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

### Prezto

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/zsh-ccusage ~/zsh-ccusage
   ```

2. Add to your `.zpreztorc`:
   ```bash
   zstyle ':prezto:load' pmodule \
     ... \
     'zsh-ccusage'
   ```

3. Create a symlink:
   ```bash
   ln -s ~/zsh-ccusage ~/.zprezto/modules/zsh-ccusage
   ```

### Zinit

Add to your `.zshrc`:
```bash
zinit light yourusername/zsh-ccusage
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/zsh-ccusage.git ~/zsh-ccusage
   ```

2. Source the plugin in your `.zshrc`:
   ```bash
   source ~/zsh-ccusage/zsh-ccusage.plugin.zsh
   ```

3. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

## Configuration

The plugin can be configured using environment variables. Add these to your `.zshrc` before sourcing the plugin:

| Variable | Default | Description |
|----------|---------|-------------|
| `CCUSAGE_AUTO_UPDATE` | `true` | Enable/disable automatic updates on each command |
| `CCUSAGE_UPDATE_INTERVAL` | `30` | Cache duration in seconds (30 seconds) |
| `CCUSAGE_PLAN_LIMIT` | `200` | Monthly plan limit in USD for percentage calculations |
| `CCUSAGE_PERCENTAGE_MODE` | `daily_avg` | Percentage calculation mode (see below) |
| `CCUSAGE_DISPLAY_FORMAT` | `[$%.2f \| %d%%]` | Custom display format (printf-style) |
| `CCUSAGE_CACHE_DIR` | `$HOME/.cache/zsh-ccusage` | Directory for cache files |

### Percentage Modes

The `CCUSAGE_PERCENTAGE_MODE` variable controls how the usage percentage is calculated:

- **`daily_avg`** (default): Compares today's usage against the daily average of your monthly plan
  - Formula: `today's usage / (plan limit / days in month) * 100`
  - Example: $20 today with $200 plan in 31-day month = 310%D
  
- **`daily_plan`**: Compares today's usage against your full monthly plan limit
  - Formula: `today's usage / plan limit * 100`
  - Example: $100 today with $200 plan = 50%P
  
- **`monthly`**: Compares total monthly usage against your plan limit
  - Formula: `monthly usage / plan limit * 100`
  - Example: $1800 this month with $200 plan = 900%M

The mode indicator (D/P/M) is displayed after the percentage to show which calculation is being used.

### Example Configuration

```bash
# Disable automatic updates
export CCUSAGE_AUTO_UPDATE=false

# Update every 2 minutes (default is 30 seconds)
export CCUSAGE_UPDATE_INTERVAL=120

# Set monthly plan limit to $100
export CCUSAGE_PLAN_LIMIT=100

# Use daily plan percentage mode
export CCUSAGE_PERCENTAGE_MODE=daily_plan

# Custom display format
export CCUSAGE_DISPLAY_FORMAT="AI: $%.2f (%d%%)"

# Source the plugin
source ~/zsh-ccusage/zsh-ccusage.plugin.zsh
```

## Usage

### Automatic Updates

By default, the plugin automatically updates cost information in the background. The display appears in your right prompt (RPROMPT).

### Manual Refresh

Force a refresh of the cost data:
```bash
ccusage-refresh
```

### Display Format

The plugin shows information in the format: `[cost | percentage]`

- **Cost**: Current active block cost (e.g., $45.23)
- **Percentage**: Usage percentage based on configured mode (e.g., 35%D, 50%P, 900%M)

#### Display States

- `[$45.23 | 35%]` - Normal display with current data
- `[$45.23* | 35%*]` - Asterisk indicates stale/cached data
- `[$0.00 | 0%]` - No active blocks or usage
- `$45.23|35%` - Compact format for narrow terminals (<80 chars)

#### Color Coding

- 🟢 **Green**: <80% of limit
- 🟡 **Yellow**: ≥80% of limit
- 🔴 **Red**: ≥100% of limit (may use bold formatting)

## Troubleshooting

### Plugin not displaying

1. Verify ZSH version: `echo $ZSH_VERSION` (should be 5.0+)
2. Check if plugin is loaded: `echo $plugins` (for Oh My Zsh)
3. Ensure ccusage CLI is accessible: `npx ccusage@latest --version`

### No cost data showing

1. Check if ccusage is working: `npx ccusage@latest blocks --active`
2. Force refresh: `ccusage-refresh`
3. Check cache directory permissions: `ls -la $HOME/.cache/zsh-ccusage`

### Slow shell startup

1. Disable automatic updates: `export CCUSAGE_AUTO_UPDATE=false`
2. Increase cache interval: `export CCUSAGE_UPDATE_INTERVAL=1800`
3. The plugin uses async loading and should have <100ms impact on startup

### Stale data indicator (*)

The asterisk indicates cached data is being used due to:
- Network connectivity issues
- ccusage API errors
- Cache still valid (within update interval)

Run `ccusage-refresh` to force an update.

## Performance

The plugin is optimized for minimal impact on shell performance:

- **Lazy loading**: Components load only when needed
- **Async updates**: Non-blocking background data fetching
- **Smart caching**: Reduces API calls and network overhead
- **Efficient parsing**: Optimized JSON parsing without external dependencies
- **Startup impact**: <100ms on average systems

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork and clone the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test with different ZSH configurations
5. Submit a pull request

### Testing

Test the plugin with different scenarios:
```bash
# Test with no active blocks
# Test with high usage (>80%)
# Test with network disconnected
# Test with narrow terminal
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Created for developers who want to keep track of their AI usage costs without leaving the terminal.