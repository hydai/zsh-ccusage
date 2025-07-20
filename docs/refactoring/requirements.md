# Code Refactoring Requirements

## 1. Extract Common Error Handling Module

As a developer
I want to have a centralized error handling module
So that I can maintain consistent error handling across all fetch functions without code duplication

```gherkin
Feature: Common Error Handling Module
  
  Scenario: Handle successful command execution
    Given a command executes with exit code 0
    When the error handler processes the result
    Then it returns the command output unchanged
    And returns exit code 0
  
  Scenario: Handle timeout errors
    Given a command times out with exit code 124
    When the error handler processes the result
    Then it returns a JSON error with type "timeout"
    And returns exit code 1
  
  Scenario: Handle missing ccusage installation
    Given a command fails with "command not found" message
    When the error handler processes the result
    Then it returns a JSON error with type "not_installed"
    And returns exit code 1
  
  Scenario: Handle network errors
    Given a command fails with network error messages (ENOTFOUND, ETIMEDOUT, ECONNREFUSED)
    When the error handler processes the result
    Then it returns a JSON error with type "network"
    And returns exit code 1
```

## 2. Create Date Utilities with Caching

As a developer
I want to have cached date operations
So that I can reduce system calls and improve performance

```gherkin
Feature: Date Utilities Module
  
  Scenario: Get today's date with caching
    Given the date cache is empty
    When I request today's date
    Then it calls the system date command once
    And caches the result for 60 seconds
  
  Scenario: Reuse cached date within timeout
    Given today's date is already cached
    And less than 60 seconds have passed
    When I request today's date again
    Then it returns the cached value without system call
  
  Scenario: Refresh cache after timeout
    Given today's date is cached
    And more than 60 seconds have passed
    When I request today's date
    Then it calls the system date command again
    And updates the cache with new value
```

## 3. Refactor Cache Retrieval Pattern

As a developer
I want a unified cache retrieval helper
So that I can handle cache misses and stale data consistently

```gherkin
Feature: Cache Retrieval Helper
  
  Scenario: Retrieve fresh cache data
    Given valid data exists in cache
    When I retrieve data with fallback
    Then it returns the cached data
    And marks is_stale as false
    And marks has_error as false
  
  Scenario: Fall back to stale cache
    Given fresh cache is empty
    And stale cache contains data
    When I retrieve data with fallback
    Then it returns the stale data
    And marks is_stale as true
    And marks has_error as false
  
  Scenario: Handle complete cache miss
    Given both fresh and stale cache are empty
    When I retrieve data with fallback
    Then it returns empty string
    And marks is_stale as false
    And marks has_error as true
```

## 4. Extract JSON Validation Helpers

As a developer
I want consistent JSON validation
So that all parse functions handle invalid input the same way

```gherkin
Feature: JSON Validation Helpers
  
  Scenario: Validate empty JSON input
    Given an empty JSON string
    When I validate the input
    Then it returns the default value
    And indicates validation failure
  
  Scenario: Validate JSON with error
    Given a JSON string containing an error field
    When I validate the input
    Then it returns the default value
    And indicates validation failure
  
  Scenario: Validate valid JSON
    Given a valid JSON string without errors
    When I validate the input
    Then it indicates validation success
    And allows further processing
```