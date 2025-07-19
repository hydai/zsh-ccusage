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

  Scenario: Display format for costs under $100
    Given the active block cost is $45.23
    And the daily usage is 35%
    When the prompt is rendered
    Then it should display "[$45.23 | 35%]" in the right prompt
    And use appropriate colors (green for low, yellow for medium, red for high)

  Scenario: Display format for high usage
    Given the daily usage is above 80%
    When the prompt is rendered
    Then the percentage should be displayed in red
    And optionally blink or use bold formatting

  Scenario: Compact display for small terminals
    Given the terminal width is less than 80 columns
    When the prompt is rendered
    Then it should use a compact format like "$45.23|35%"
```

## Technical Requirements

- Use `npx ccusage@latest blocks --active --json` for active block cost
- Use `npx ccusage@latest daily -s YYYYMMDD --json` for daily totals
- Cache results to avoid excessive API calls
- Support standard zsh theming variables
- Provide configuration through environment variables:
  - `CCUSAGE_AUTO_UPDATE` (true/false)
  - `CCUSAGE_UPDATE_INTERVAL` (seconds)
  - `CCUSAGE_DISPLAY_FORMAT` (custom format string)
  - `CCUSAGE_DAILY_LIMIT` (default: 200)

## Success Metrics

- Plugin loads without impacting terminal startup time (<100ms)
- Cost information updates within 1 second of command execution
- No disruption to normal terminal usage when ccusage is unavailable
- Clear visual indicators for different usage levels