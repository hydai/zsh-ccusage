# Code Refactoring Tasks

- [x] 1. Create error handler module with npx check function
  - Create `lib/error-handler.zsh` file
  - Implement `ccusage_check_npx()` function that returns JSON error if npx not found
  - Test function manually by temporarily renaming npx
  - Verify JSON output format matches existing error patterns
  - _Requirements: R1

- [x] 2. Implement main error handling function
  - Add `ccusage_handle_fetch_error()` to `lib/error-handler.zsh`
  - Handle exit code 0 (success) - return output unchanged
  - Handle exit code 124 (timeout) - return timeout JSON error
  - Pattern match for "command not found", network errors (ENOTFOUND, ETIMEDOUT, ECONNREFUSED)
  - _Requirements: R1

- [x] 3. Add timeout execution helper to error handler
  - Implement `ccusage_run_with_timeout()` in error handler module
  - Support both bash and zsh timeout syntax
  - Capture output and exit code properly
  - Test with short and long-running commands
  - _Requirements: R1

- [x] 4. Update plugin loader to source error handler module
  - Modify `zsh-ccusage.plugin.zsh` to source `lib/error-handler.zsh`
  - Ensure module loads before functions directory
  - Run `./validate.sh` to verify no syntax errors
  - Test plugin reload with `source zsh-ccusage.plugin.zsh`
  - _Requirements: R1

- [x] 5. Refactor first fetch function to use error handler
  - Update `ccusage_fetch_active_block()` in `functions/ccusage-fetch`
  - Replace npx check with `ccusage_check_npx()` call
  - Replace error handling with `ccusage_handle_fetch_error()` call
  - Test all error scenarios (success, timeout, network error)
  - _Requirements: R1

- [x] 6. Create date utilities module with caching
  - Create `lib/date-utils.zsh` file
  - Define global cache variables (CCUSAGE_CACHED_TODAY, etc.)
  - Implement `ccusage_get_today()` with 60-second cache
  - Test cache hit/miss behavior
  - _Requirements: R2

- [x] 7. Add month and day calculations to date utilities
  - Implement `ccusage_get_current_month()` with caching
  - Implement `ccusage_get_days_in_month()` with leap year support
  - Test date rollover scenarios
  - Verify performance improvement with time measurements
  - _Requirements: R2

- [x] 8. Update plugin to use date utilities
  - Replace direct date calls in `zsh-ccusage.plugin.zsh` with utility functions
  - Update `lib/async.zsh` to use cached dates
  - Update `lib/parser.zsh` date generation
  - Verify dates remain consistent across components
  - _Requirements: R2

- [x] 9. Refactor remaining fetch functions
  - Update `ccusage_fetch_block_history()` to use error handler
  - Update `ccusage_fetch_daily_cost()` to use error handler
  - Update `ccusage_fetch_monthly_cost()` to use error handler  
  - Update `ccusage_fetch_blocks()` to use error handler
  - _Requirements: R1

- [x] 10. Create JSON validation utilities module
  - Create `lib/json-utils.zsh` file
  - Implement `ccusage_validate_json_input()` function
  - Implement `ccusage_extract_error_message()` function
  - Test with various JSON inputs (empty, error, valid)
  - _Requirements: R4

- [x] 11. Update parser functions to use JSON utilities
  - Replace validation logic in `ccusage_parse_block_cost()`
  - Replace validation logic in `ccusage_parse_daily_cost()`
  - Replace validation logic in `ccusage_parse_monthly_cost()`
  - Ensure backward compatibility maintained
  - _Requirements: R4

- [x] 12. Add cache retrieval helper function
  - Add `ccusage_cache_get_with_fallback()` to `lib/cache.zsh`
  - Implement fresh cache lookup with stale fallback
  - Set appropriate flags (is_stale, has_error)
  - Test all cache scenarios
  - _Requirements: R3

- [x] 13. Refactor parser cache retrieval logic
  - Update `ccusage_get_cost_by_mode()` to use cache helper
  - Remove duplicate cache retrieval code
  - Test all three modes (active_block, daily, monthly)
  - Verify stale data handling still works
  - _Requirements: R3

- [ ] 14. Clean up obsolete code and test
  - Remove duplicate error handling code from all fetch functions
  - Remove duplicate date generation code
  - Run full test suite (`./validate.sh`, `test_percentage_modes.zsh`)
  - Measure load time to ensure <100ms target maintained
  - _Requirements: R1, R2, R3, R4

- [ ] 15. Create unit tests for new modules
  - Create `test/test-error-handler.zsh` with all error scenarios
  - Create `test/test-date-utils.zsh` with cache behavior tests
  - Create `test/test-json-utils.zsh` with validation tests
  - Document how to run tests in README
  - _Requirements: R1, R2, R4

- [ ] 16. Update documentation and tag release
  - Update CLAUDE.md with new module descriptions
  - Document refactoring changes in CHANGELOG
  - Create git tag for pre-refactoring version
  - Update any affected user documentation
  - _Requirements: R1, R2, R3, R4