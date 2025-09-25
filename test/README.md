# Trashifier App - Unit Tests

This directory contains comprehensive unit tests for the Trashifier App, covering all major business logic components.

## Test Coverage

### Models (`test/models/`)
- **`trash_date_test.dart`** - Tests for the TrashDate model
  - Constructor and factory methods
  - Date comparison methods (isToday, isFuture, isSameDate)
  - Formatted properties (formatted date, day name, days until text)
  - Equality and hash code behavior
  - String representation

- **`trash_type_test.dart`** - Tests for the TrashType enum
  - Enum values and properties
  - String representation
  - Equality and hash code consistency

### Helpers (`test/helpers/`)
- **`date_format_helper_test.dart`** - Tests for date formatting utilities
  - Date formatting (formatDate, formatDayName)
  - Date calculations (calculateDaysUntil, getDaysUntilText)
  - Date comparisons (isSameDate, isToday, isFuture)
  - Edge cases and time-dependent logic

- **`trash_type_helper_test.dart`** - Tests for trash type utilities
  - Icon and color mappings for each trash type
  - Notification title and body generation
  - Text color preferences
  - Integration with TrashColors class
  - BuildContext-dependent methods

- **`calendar_helper_test.dart`** - Tests for calendar UI helper
  - Calendar day building for single and multiple trash types
  - Date matching logic
  - Color and layout handling
  - Text color calculations

- **`notification_helper_test.dart`** - Tests for notification logic
  - Date filtering and processing logic
  - ID generation consistency
  - Integration with different trash types

### Services (`test/services/`)
- **`storage_service_test.dart`** - Tests for SharedPreferences storage
  - Singleton pattern implementation
  - Date saving and loading for all trash types
  - Data persistence across operations
  - Error handling and edge cases
  - Empty list handling and data clearing

- **`notifications_service_test.dart`** - Tests for notification system
  - Service initialization
  - Instant notification display
  - Scheduled notification management
  - Notification cancellation
  - Permission handling (mocked)
  - Integration scenarios

- **`theme_service_test.dart`** - Tests for theme management
  - Theme initialization and persistence
  - Theme toggling and setting
  - ChangeNotifier integration
  - SharedPreferences integration
  - Edge cases and error handling

### Widget Tests (`test/`)
- **`widget_test.dart`** - Tests for main app widget
  - App initialization without crashes
  - Theme configuration
  - Provider integration

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Files
```bash
flutter test test/models/trash_date_test.dart
flutter test test/helpers/
flutter test test/services/
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Test Suite
```bash
flutter test test/all_tests.dart
```

## Test Organization

Tests are organized by component type:
- **Models** - Data structures and business entities
- **Helpers** - Utility functions and formatting logic
- **Services** - Business logic and external integrations
- **Widgets** - UI components and integration tests

## Key Testing Patterns

1. **Comprehensive Coverage** - Each public method and property is tested
2. **Edge Case Handling** - Tests cover empty inputs, null values, and boundary conditions
3. **Integration Testing** - Tests verify component interactions work correctly
4. **Mock Dependencies** - External dependencies (SharedPreferences, notifications) are properly mocked
5. **Consistency Validation** - Tests ensure consistent behavior across all enum values and data types

## Test Statistics

- **Total Test Files**: 9
- **Total Test Cases**: 58+ individual tests
- **Coverage Areas**: Models, Helpers, Services, Widgets
- **Mock Integrations**: SharedPreferences, Flutter Local Notifications

## Notes for Developers

- All tests use proper setUp and tearDown methods where needed
- Time-dependent tests handle current time variations gracefully
- Mock objects are configured to simulate real-world scenarios
- Tests are designed to be deterministic and not dependent on external state
- Each test group focuses on a specific aspect of functionality

## Future Test Enhancements

Consider adding:
- Widget integration tests for complex UI interactions
- Golden file tests for visual consistency
- Performance tests for large data sets
- End-to-end tests for complete user workflows