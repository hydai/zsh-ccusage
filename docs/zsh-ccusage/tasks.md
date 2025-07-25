# ZSH CCUsage Plugin - Task Breakdown

- [x] 1. Create basic plugin structure with visible prompt display
  - Create zsh-ccusage.plugin.zsh as main entry point
  - Add plugin to RPROMPT with hardcoded "[$0.00 | 0%]" display
  - Verify plugin loads and displays in terminal
  - _Requirements: R1, R5

- [x] 2. Implement cost display formatting with color support
  - Create lib/colors.zsh with color utility functions
  - Implement ccusage_format_display function in functions/ccusage-format
  - Add color coding: green (0-50%), yellow (50-80%), red (80%+)
  - Test with different percentage values
  - _Requirements: R5

- [x] 3. Add fetching for active block cost
  - Create functions/ccusage-fetch with ccusage_fetch_active_block
  - Execute npx ccusage@latest blocks --active --json
  - Return raw JSON response or error
  - Handle command not found gracefully
  - _Requirements: R1

- [x] 4. Parse active block cost from JSON response
  - Create lib/parser.zsh with JSON parsing utilities
  - Implement ccusage_parse_block_cost function
  - Extract cost field and handle malformed JSON
  - Return 0.00 for empty/no active blocks
  - _Requirements: R1

- [x] 5. Add daily usage fetching and percentage calculation
  - Implement ccusage_fetch_daily in functions/ccusage-fetch
  - Auto-calculate today's date in YYYYMMDD format
  - Parse response and calculate percentage against $200 limit
  - Handle edge cases (negative, over 100%)
  - _Requirements: R2

- [x] 6. Integrate real data into prompt display
  - Connect fetcher → parser → formatter pipeline
  - Update RPROMPT with live cost and percentage data
  - Test end-to-end data flow
  - Verify prompt updates after commands
  - _Requirements: R1, R2

- [x] 7. Implement basic caching mechanism
  - Create lib/cache.zsh with cache management functions
  - Use zsh associative arrays for in-memory storage
  - Cache both active block and daily usage data
  - Set 5-minute default cache duration
  - _Requirements: R4

- [x] 8. Add precmd hook for automatic updates
  - Implement ccusage_precmd function
  - Check CCUSAGE_AUTO_UPDATE environment variable
  - Trigger data fetch on each command if enabled
  - Skip updates when disabled
  - _Requirements: R3

- [x] 9. Create manual refresh command
  - Implement functions/ccusage-refresh command
  - Clear cache and force data refresh
  - Update prompt immediately with new data
  - Make available as 'ccusage-refresh' command
  - _Requirements: R3

- [x] 10. Add async data fetching
  - Implement ccusage_async_update using background jobs
  - Prevent blocking during data fetch
  - Update prompt when fetch completes
  - Maintain responsiveness during updates
  - _Requirements: R1, R3

- [x] 11. Implement comprehensive error handling
  - Handle ccusage not installed (silent failure)
  - Use cached values during network failures
  - Add visual indicator for stale data
  - Gracefully handle invalid JSON responses
  - _Requirements: R4

- [x] 12. Add environment variable configuration
  - Support CCUSAGE_AUTO_UPDATE (true/false)
  - Support CCUSAGE_UPDATE_INTERVAL (seconds)
  - Support CCUSAGE_DISPLAY_FORMAT (custom format)
  - Support CCUSAGE_DAILY_LIMIT (default: 200)
  - _Requirements: R3, R5

- [x] 13. Optimize for terminal width
  - Detect terminal width for compact mode
  - Use "$45.23|35%" format for width < 80
  - Maintain readability in small terminals
  - Test with various terminal sizes
  - _Requirements: R5

- [x] 14. Add performance optimizations
  - Ensure plugin loads in <100ms
  - Profile and optimize slow operations
  - Minimize impact on shell startup
  - Test with different shell configurations
  - _Requirements: Success Metrics

- [x] 15. Create README with installation instructions
  - Document plugin installation for oh-my-zsh, prezto, zinit
  - List all configuration options with examples
  - Include troubleshooting section
  - Add screenshots of different display states
  - _Requirements: Documentation

- [x] 16. Add plugin manager compatibility
  - Test with oh-my-zsh framework
  - Test with prezto framework
  - Test with zinit plugin manager
  - Ensure proper loading in all environments
  - _Requirements: Deployment

- [x] 17. Add percentage mode configuration support
  - Add CCUSAGE_PERCENTAGE_MODE environment variable handling
  - Support values: daily_avg (default), daily_plan, monthly
  - Validate mode and fall back to daily_avg for invalid values
  - Update configuration loading in plugin initialization
  - _Requirements: R7

- [x] 18. Implement monthly usage fetching
  - Add ccusage_fetch_monthly function in functions/ccusage-fetch
  - Execute npx ccusage@latest monthly --json
  - Cache monthly data separately with 5-minute TTL
  - Handle errors and return cached data when available
  - _Requirements: R6

- [x] 19. Create percentage calculation engine
  - Implement ccusage_calculate_percentage function
  - Support three calculation modes based on CCUSAGE_PERCENTAGE_MODE
  - Add ccusage_get_days_in_month helper function
  - Handle CCUSAGE_PLAN_LIMIT configuration (default: 200)
  - _Requirements: R6, R7

- [x] 20. Update display formatter for percentage modes
  - Modify ccusage_format_display to include mode indicator
  - Display as XXX%D for daily_avg, XXX%P for daily_plan, XXX%M for monthly
  - Maintain existing color coding based on percentage value
  - Ensure backward compatibility with existing format
  - _Requirements: R6, R8

- [x] 21. Enhance color coding for percentage thresholds
  - Update color logic: <80% green, ≥80% yellow, ≥100% red
  - Apply colors consistently across all percentage modes
  - Add bold formatting for values ≥100%
  - Test with terminals that don't support colors
  - _Requirements: R8

- [x] 22. Update parser for new data requirements
  - Modify ccusage_parse_daily_percentage to use configurable limit
  - Add parsing for monthly usage JSON response
  - Extract total cost from monthly data
  - Handle missing or malformed monthly data
  - _Requirements: R6

- [x] 23. Integrate percentage modes into async update flow
  - Update ccusage_async_update to fetch monthly data when needed
  - Only fetch monthly data for monthly mode to optimize performance
  - Ensure all modes work with existing cache and async infrastructure
  - Test mode switching without restart
  - _Requirements: R6, R7

- [x] 24. Add CCUSAGE_PLAN_LIMIT configuration
  - Replace CCUSAGE_DAILY_LIMIT with CCUSAGE_PLAN_LIMIT
  - Maintain backward compatibility (DAILY_LIMIT falls back to PLAN_LIMIT)
  - Update all percentage calculations to use PLAN_LIMIT
  - Document migration in README
  - _Requirements: R7

- [x] 25. Test percentage display with real data
  - Verify daily_avg calculation: $20 usage, 31-day month = 310%D
  - Verify daily_plan calculation: $100 usage, $200 limit = 50%P
  - Verify monthly calculation: $1800 usage, $200 limit = 900%M
  - Test edge cases: 0% usage, >999% usage
  - _Requirements: R6

- [x] 26. Update documentation for percentage features
  - Document new environment variables in README
  - Add examples for each percentage mode
  - Include screenshots showing different modes and colors
  - Create migration guide from DAILY_LIMIT to PLAN_LIMIT
  - _Requirements: R6, R7, R8

- [x] 27. Add CCUSAGE_COST_MODE environment variable
  - Add cost mode configuration with values: active (default), daily, monthly
  - Implement ccusage_validate_cost_mode function
  - Fall back to 'active' for invalid values
  - Store validated mode in global variable
  - _Requirements: R9, R11

- [x] 28. Update cost display to show mode suffix
  - Modify ccusage_format_display to append cost mode suffix
  - Show 'A' for active, 'D' for daily, 'M' for monthly
  - Format as "$45.23A", "$20.45D", "$1800.00M"
  - Ensure suffix appears before percentage separator
  - _Requirements: R11

- [x] 29. Implement daily cost fetching for cost mode
  - Add ccusage_fetch_daily_cost function
  - Use npx ccusage@latest -s YYYYMMDD --json
  - Auto-generate today's date in YYYYMMDD format
  - Parse total cost from response
  - _Requirements: R9

- [x] 30. Implement monthly cost fetching for cost mode
  - Add ccusage_fetch_monthly_cost function
  - Use npx ccusage@latest monthly -s YYYYMM01 --json
  - Auto-generate current month's first day
  - Parse total cost from response
  - _Requirements: R9

- [x] 31. Create cost mode data router
  - Implement ccusage_get_cost_by_mode function
  - Route to appropriate fetcher based on CCUSAGE_COST_MODE
  - Return cost value and mode indicator
  - Handle errors per mode independently
  - _Requirements: R9

- [x] 32. Add separate cache keys for cost modes
  - Use mode-specific cache keys: cost_active, cost_daily, cost_monthly
  - Cache each mode's data independently
  - Maintain 5-minute TTL for all cost caches
  - Prevent cache collision between modes
  - _Requirements: R13

- [x] 33. Update async fetcher for parallel cost updates
  - Modify ccusage_async_update to fetch all cost modes
  - Run fetches in parallel using background jobs
  - Update only expired caches
  - Show current mode immediately while others update
  - _Requirements: R13

- [x] 34. Implement ccusage-set-cost-mode command
  - Create runtime mode switcher function
  - Validate input mode (active, daily, monthly)
  - Update CCUSAGE_COST_MODE for current session
  - Show available modes when called without arguments
  - _Requirements: R12

- [x] 35. Add cost mode error handling
  - Show cached value with asterisk on API failure
  - Display "$-.--MODE" when no cache available
  - Continue showing other modes if one fails
  - Log errors without disrupting prompt
  - _Requirements: R14

- [x] 36. Test independent cost and percentage combinations
  - Verify daily cost + monthly percentage shows "[$20.45D | 900%M]"
  - Verify monthly cost + daily average shows "[$1800.00M | 310%D]"
  - Test all 9 possible combinations (3 cost × 3 percentage)
  - Ensure display format consistency
  - _Requirements: R10

- [x] 37. Add persistent cache for cost modes
  - Extend disk cache to store cost mode data
  - Use mode-specific cache files
  - Load from disk cache on shell startup
  - Update disk cache alongside memory cache
  - _Requirements: R13

- [x] 38. Update refresh command for all cost modes
  - Modify ccusage-refresh to clear all cost caches
  - Trigger parallel refresh of all modes
  - Show progress indicator during refresh
  - Update prompt with fresh data
  - _Requirements: R13

- [x] 39. Optimize cost mode performance
  - Only fetch current mode on regular updates
  - Batch API calls when multiple modes expired
  - Profile and ensure <100ms impact
  - Test with slow network conditions
  - _Requirements: Success Metrics

- [x] 40. Create test script for cost modes
  - Write test_cost_modes.zsh similar to test_percentage_modes.zsh
  - Test mode switching and validation
  - Verify cache independence
  - Check error handling scenarios
  - _Requirements: R9, R12, R14

- [x] 41. Update documentation for cost display modes
  - Document CCUSAGE_COST_MODE in README
  - Add examples for each cost mode
  - Show screenshots of different mode combinations
  - Include ccusage-set-cost-mode usage
  - _Requirements: R9, R10, R11, R12