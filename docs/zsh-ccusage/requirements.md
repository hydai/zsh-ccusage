# ZSH CCUsage Plugin Requirements

## Overview
A zsh plugin that displays real-time ccusage cost information in the terminal prompt to help developers monitor AI usage costs and prevent exceeding block limits.

## User Stories

## 1. Real-time Cost Display

As a developer using AI tools
I want to see current block usage cost in my terminal prompt
So that I can monitor my spending and avoid exceeding block limits

```gherkin
Feature: Display active block cost in prompt

  Scenario: Show cost for active block
    Given I have ccusage installed
    And I have the zsh plugin enabled
    When I execute any command in terminal
    Then the right prompt should display the current active block cost
    And the cost should appear to the left of the time display

  Scenario: Handle no active blocks
    Given I have ccusage installed
    And I have the zsh plugin enabled
    When there are no active blocks
    Then the right prompt should display "$0.00" or hide the cost display
```

## 2. Daily Usage Percentage Display

As a developer with daily spending limits
I want to see my daily usage percentage relative to $200 limit
So that I can track my daily spending progress

```gherkin
Feature: Display daily usage percentage

  Scenario: Show daily usage percentage
    Given I have used some AI services today
    When I execute any command in terminal
    Then the right prompt should display daily usage percentage
    And the percentage should be calculated as (daily total / $200) * 100

  Scenario: Handle start of new day
    Given it's a new day (after midnight)
    When I execute any command in terminal
    Then the plugin should fetch today's date automatically
    And display the correct daily usage for the current date
```

## 3. Toggle Automatic Updates

As a developer
I want to control when the cost information updates
So that I can balance between real-time monitoring and performance

```gherkin
Feature: Toggle automatic updates

  Scenario: Enable automatic updates (default)
    Given the plugin is installed
    When I execute any command
    Then the cost display should update automatically
    And fetch the latest data from ccusage

  Scenario: Disable automatic updates
    Given I have set CCUSAGE_AUTO_UPDATE=false
    When I execute commands
    Then the cost display should not update automatically
    And should only update when manually triggered

  Scenario: Manual refresh
    Given automatic updates are disabled
    When I run a manual refresh command
    Then the cost display should update with latest data
```

## 4. Error Handling

As a developer
I want the plugin to handle errors gracefully
So that my terminal experience isn't disrupted

```gherkin
Feature: Handle ccusage errors

  Scenario: ccusage command not found
    Given ccusage is not installed
    When the plugin tries to fetch cost data
    Then the prompt should not display cost information
    And should not show error messages in the prompt

  Scenario: Network or API errors
    Given ccusage is installed
    When the API request fails
    Then the plugin should use cached values if available
    And indicate stale data with a visual cue

  Scenario: Invalid JSON response
    Given ccusage returns invalid JSON
    When the plugin parses the response
    Then it should handle the error gracefully
    And display last known good values or hide the display
```

## 5. Prompt Formatting

As a developer
I want the cost information to be clearly visible and well-formatted
So that I can quickly glance at my usage

```gherkin
Feature: Format cost display in prompt

  Scenario: Display format with percentage
    Given the active block cost is $45.23
    And today's usage is $20 with daily average mode
    And the calculated percentage is 310%
    When the prompt is rendered
    Then it should display "[$45.23 | 310%D]" in the right prompt
    And the percentage should be colored red (>100%)

  Scenario: Display format for high usage
    Given the daily usage is above 80%
    When the prompt is rendered
    Then the percentage should be displayed in red
    And optionally blink or use bold formatting

  Scenario: Compact display for small terminals
    Given the terminal width is less than 80 columns
    And the percentage mode is daily_avg showing 85%
    When the prompt is rendered
    Then it should use a compact format like "$45.23|85%D"
    And maintain color coding for the percentage
```

## 6. Configurable Usage Percentage Display

As a developer with a usage plan
I want to see my usage as a percentage of my plan limit
So that I can better understand my spending relative to my budget

```gherkin
Feature: Display usage percentage with multiple calculation modes

  Scenario: Show daily average usage percentage (default)
    Given I have set my plan limit to $200
    And today's usage is $20
    And current month has 31 days
    When the prompt is rendered
    Then it should calculate percentage as: $20 / ($200/31) = 310%
    And display it as "310%D" after the cost

  Scenario: Show daily plan percentage
    Given I have set CCUSAGE_PERCENTAGE_MODE=daily_plan
    And today's usage is $100
    And my plan limit is $200
    When the prompt is rendered
    Then it should calculate percentage as: $100 / $200 = 50%
    And display it as "50%P"

  Scenario: Show monthly usage percentage
    Given I have set CCUSAGE_PERCENTAGE_MODE=monthly
    And monthly usage is $1800
    And my plan limit is $200
    When the prompt is rendered
    Then it should calculate percentage as: $1800 / $200 = 900%
    And display it as "900%M"
```

## 7. Percentage Mode Configuration

As a developer
I want to configure which percentage calculation mode to use
So that I can monitor usage in the way that's most relevant to me

```gherkin
Feature: Configure percentage calculation mode

  Scenario: Use environment variable to set mode
    Given I set CCUSAGE_PERCENTAGE_MODE=daily_avg
    When the plugin loads
    Then it should use daily average calculation

  Scenario: Invalid mode falls back to default
    Given I set CCUSAGE_PERCENTAGE_MODE=invalid_mode
    When the plugin loads
    Then it should use daily average calculation (default)
    And not show error messages

  Scenario: Configure custom plan limit
    Given I set CCUSAGE_PLAN_LIMIT=500
    When calculating any percentage
    Then it should use $500 as the plan limit
    And default to $200 if not set
```

## 8. Color-Coded Usage Warnings

As a developer
I want visual warnings based on my usage percentage
So that I can quickly identify when I'm approaching or exceeding limits

```gherkin
Feature: Color-code percentage based on thresholds

  Scenario: Low usage shows green
    Given the calculated percentage is 50%
    When the prompt is rendered
    Then the percentage should be displayed in green color

  Scenario: Medium usage shows yellow
    Given the calculated percentage is 85%
    When the prompt is rendered
    Then the percentage should be displayed in yellow color

  Scenario: High usage shows red
    Given the calculated percentage is 150%
    When the prompt is rendered
    Then the percentage should be displayed in red color
    And optionally use bold formatting for emphasis

  Scenario: Maintain readability in different terminals
    Given the terminal doesn't support colors
    When the prompt is rendered
    Then the percentage should still be readable
    And use alternative indicators like brackets or asterisks
```

## 9. Multiple Cost Display Modes

As a developer
I want to choose between different cost display modes
So that I can monitor the cost metric most relevant to my workflow

```gherkin
Feature: Configure cost display modes

  Scenario: Display active block cost (default)
    Given CCUSAGE_COST_MODE is not set or set to "active"
    When the prompt is rendered
    Then it should fetch cost using "ccstat --quiet blocks --active --json"
    And display the cost with no suffix indicator
    And cache the result separately from other modes

  Scenario: Display daily total cost
    Given I have set CCUSAGE_COST_MODE=daily
    When the prompt is rendered
    Then it should fetch cost using "ccstat --quiet -s YYYYMMDD --json"
    And display the cost with "D" suffix like "$20.45D"
    And use today's date in YYYYMMDD format

  Scenario: Display monthly total cost
    Given I have set CCUSAGE_COST_MODE=monthly
    When the prompt is rendered
    Then it should fetch cost using "ccstat --quiet monthly -s YYYYMM01 --json"
    And display the cost with "M" suffix like "$1800.00M"
    And use current month's first day in YYYYMM01 format
```

## 10. Independent Cost and Percentage Modes

As a developer
I want to combine any cost mode with any percentage mode
So that I can create the monitoring view that best fits my needs

```gherkin
Feature: Combine cost and percentage modes independently

  Scenario: Mix daily cost with monthly percentage
    Given I have set CCUSAGE_COST_MODE=daily
    And I have set CCUSAGE_PERCENTAGE_MODE=monthly
    When the prompt is rendered
    Then it should display daily cost with "D" suffix
    And display monthly percentage with "M" suffix
    And the display should show "[$20.45D | 900%M]"

  Scenario: Mix monthly cost with daily average percentage
    Given I have set CCUSAGE_COST_MODE=monthly
    And I have set CCUSAGE_PERCENTAGE_MODE=daily_avg
    When the prompt is rendered
    Then it should display monthly cost with "M" suffix
    And display daily average percentage with "D" suffix
    And the display should show "[$1800.00M | 310%D]"
```

## 11. Cost Mode Suffix Display

As a developer
I want to always see which cost mode is active
So that I can quickly understand what the displayed cost represents

```gherkin
Feature: Always show cost mode suffix

  Scenario: Show suffix for active block mode
    Given CCUSAGE_COST_MODE=active
    When the prompt is rendered
    Then the cost should be displayed with "A" suffix like "$45.23A"

  Scenario: Show suffix for daily mode
    Given CCUSAGE_COST_MODE=daily
    When the prompt is rendered
    Then the cost should be displayed with "D" suffix like "$20.45D"

  Scenario: Show suffix for monthly mode
    Given CCUSAGE_COST_MODE=monthly
    When the prompt is rendered
    Then the cost should be displayed with "M" suffix like "$1800.00M"
```

## 12. Runtime Cost Mode Switching

As a developer
I want to switch cost display modes without restarting my shell
So that I can quickly check different cost metrics during my work session

```gherkin
Feature: Switch cost modes at runtime

  Scenario: Switch mode using command
    Given the plugin is loaded with default settings
    When I run "ccusage-set-cost-mode daily"
    Then CCUSAGE_COST_MODE should be updated to "daily"
    And the next prompt refresh should show daily cost
    And the change should persist for the current shell session

  Scenario: Invalid mode reverts to default
    Given the plugin is loaded
    When I run "ccusage-set-cost-mode invalid"
    Then it should display an error message
    And keep the current mode unchanged

  Scenario: List available modes
    Given the plugin is loaded
    When I run "ccusage-set-cost-mode" without arguments
    Then it should display available modes: active, daily, monthly
    And show the currently active mode
```

## 13. Separate Cache Management for Cost Modes

As a developer
I want each cost mode to have its own cache
So that switching modes gives me fresh data without unnecessary API calls

```gherkin
Feature: Independent cache for each cost mode

  Scenario: Cache different modes separately
    Given I switch from active to daily mode
    When the prompt refreshes
    Then it should check the daily mode cache first
    And only call the API if daily cache is expired
    And not affect the active mode cache

  Scenario: Parallel cache updates
    Given all three cost mode caches are expired
    When I manually refresh with ccusage-refresh
    Then it should update all three caches in parallel
    And show the current mode's value immediately
    And have fresh data ready for mode switching

  Scenario: Show stale cache indicator
    Given the daily cost API call fails
    And there is a cached daily value from 10 minutes ago
    When the prompt is rendered in daily mode
    Then it should display the cached value
    And add an asterisk to indicate stale data like "$20.45D*"
```

## 14. Cost Mode Error Handling

As a developer
I want the plugin to handle mode-specific errors gracefully
So that one failing API doesn't break my entire prompt

```gherkin
Feature: Handle cost mode API failures

  Scenario: Fallback to cache on API failure
    Given the monthly cost API call fails
    And I'm in monthly cost mode
    And there's a cached value
    When the prompt is rendered
    Then it should display the cached value with "*" suffix
    And not show error messages in the prompt

  Scenario: Show placeholder when no cache available
    Given the daily cost API call fails
    And I'm in daily cost mode
    And there's no cached value
    When the prompt is rendered
    Then it should display "$-.--D" as placeholder
    And retry on next prompt refresh

  Scenario: Independent mode failures
    Given the monthly API fails but daily API succeeds
    When I switch from monthly to daily mode
    Then daily mode should show fresh data
    And switching back to monthly should show cached data with "*"
```

## Technical Requirements

- Use `ccstat --quiet blocks --active --json` for active block cost
- Use `ccstat --quiet daily -s YYYYMMDD --json` for daily totals
- Use `ccstat --quiet monthly --json` for monthly totals
- Cache results to avoid excessive API calls
- Support standard zsh theming variables
- Provide configuration through environment variables:
  - `CCUSAGE_AUTO_UPDATE` (true/false)
  - `CCUSAGE_UPDATE_INTERVAL` (seconds)
  - `CCUSAGE_DISPLAY_FORMAT` (custom format string)
  - `CCUSAGE_DAILY_LIMIT` (default: 200) - deprecated, use CCUSAGE_PLAN_LIMIT
  - `CCUSAGE_PLAN_LIMIT` (default: 200) - monthly plan limit in USD
  - `CCUSAGE_PERCENTAGE_MODE` (daily_avg|daily_plan|monthly, default: daily_avg)
  - `CCUSAGE_COST_MODE` (active|daily|monthly, default: active)

## Success Metrics

- Plugin loads without impacting terminal startup time (<100ms)
- Cost information updates within 1 second of command execution
- No disruption to normal terminal usage when ccusage is unavailable
- Clear visual indicators for different usage levels
- Percentage calculations update synchronously with cost display
- Support for different percentage calculation modes
- Independent cost and percentage mode selection
- Separate cache management for each cost mode
- Runtime mode switching without shell restart
- Clear visual indicators for cost mode (A/D/M suffixes)