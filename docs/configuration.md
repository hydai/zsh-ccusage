# ZSH CCUsage Plugin Configuration

## Environment Variables

The following environment variables can be used to configure the plugin:

### Display Configuration

- `CCUSAGE_AUTO_UPDATE` (default: `true`)
  - Enable/disable automatic updates on each command

- `CCUSAGE_UPDATE_INTERVAL` (default: `30`)
  - Cache duration in seconds

- `CCUSAGE_DISPLAY_FORMAT` (default: `"[$cost | $percentage%]"`)
  - Custom display format string

- `CCUSAGE_DAILY_LIMIT` (default: `200`)
  - Daily spending limit in USD (deprecated, use CCUSAGE_PLAN_LIMIT)

### Percentage Mode Configuration

- `CCUSAGE_PERCENTAGE_MODE` (default: `daily_avg`)
  - Controls how the usage percentage is calculated
  - Valid values:
    - `daily_avg`: Today's usage / (Plan limit / Days in month)
    - `daily_plan`: Today's usage / Plan limit
    - `monthly`: Monthly usage / Plan limit
  - Invalid values automatically fall back to `daily_avg`

### Cache Configuration

- `CCUSAGE_CACHE_DIR` (default: `$HOME/.cache/zsh-ccusage`)
  - Directory for persistent cache storage