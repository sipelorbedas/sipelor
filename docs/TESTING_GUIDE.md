# Testing Guide - SIPELOR BEDAS

## Overview

This guide explains the testing strategy and how to run tests for the SIPELOR BEDAS project.

---

## 📋 Test Structure

```
test/
├── models/                  # Model tests
│   ├── booking_test.dart
│   └── field_test.dart
├── services/               # Service tests
│   └── file_encryption_service_test.dart
├── widgets/                # Widget tests (TODO)
└── widget_test.dart        # Basic smoke tests
```

---

## 🧪 Test Categories

### 1. Unit Tests

**Purpose:** Test individual functions and classes in isolation

**Location:** `test/models/`, `test/services/`

**Examples:**
- Model serialization/deserialization
- Business logic functions
- Data validation
- Service methods

**Coverage Target:** 70%+

### 2. Widget Tests

**Purpose:** Test UI components

**Location:** `test/widgets/`

**Examples:**
- Button interactions
- Form validation
- Navigation
- State changes

**Coverage Target:** 50%+

### 3. Integration Tests

**Purpose:** Test complete user flows

**Location:** `integration_test/` (to be created)

**Examples:**
- Login flow
- Booking process
- Payment verification
- Admin workflows

**Coverage Target:** 30%+

---

## 🚀 Running Tests

### Quick Start

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/booking_test.dart

# Run tests matching pattern
flutter test --name "Booking"
```

### Using Test Scripts

**Linux/Mac:**
```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

**Windows:**
```batch
scripts\run_tests.bat
```

### Watch Mode

```bash
# Install watcher
flutter pub global activate test_watcher

# Run in watch mode
flutter pub global run test_watcher
```

---

## 📊 Coverage Reports

### Generate Coverage

```bash
# Run tests with coverage
flutter test --coverage

# View coverage file
cat coverage/lcov.info
```

### View HTML Report

**Using genhtml (Linux/Mac):**
```bash
# Install lcov
sudo apt install lcov  # Ubuntu/Debian
brew install lcov      # macOS

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

**Using VS Code:**
1. Install extension: **Coverage Gutters**
2. Run tests with coverage
3. Click "Watch" in status bar
4. Coverage shown inline in code

---

## ✍️ Writing Tests

### Model Tests Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('should create Booking from JSON correctly', () {
      // Arrange
      final json = {
        'id': 'test-123',
        'booking_id': 'BOOK001',
        // ... more fields
      };

      // Act
      final booking = Booking.fromJson(json);

      // Assert
      expect(booking.id, 'test-123');
      expect(booking.bookingId, 'BOOK001');
    });
  });
}
```

### Service Tests Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/file_encryption_service.dart';

void main() {
  group('FileEncryptionService Tests', () {
    late FileEncryptionService service;

    setUp(() async {
      service = FileEncryptionService();
      await service.initialize();
    });

    test('should encrypt and decrypt file correctly', () async {
      // Test implementation
    });
  });
}
```

### Widget Tests Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/widgets/booking_card.dart';

void main() {
  testWidgets('BookingCard should display booking info', (tester) async {
    // Arrange
    final booking = Booking(/* ... */);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BookingCard(booking: booking),
      ),
    );

    // Assert
    expect(find.text('BOOK001'), findsOneWidget);
  });
}
```

---

## 🎯 Testing Best Practices

### 1. Follow AAA Pattern

```dart
test('description', () {
  // Arrange - Set up test data
  final input = 'test';
  
  // Act - Execute the function
  final result = functionUnderTest(input);
  
  // Assert - Verify the result
  expect(result, expectedOutput);
});
```

### 2. Use Descriptive Names

```dart
// ❌ Bad
test('test 1', () { });

// ✅ Good
test('should return empty list when no bookings exist', () { });
```

### 3. One Assertion Per Test

```dart
// ❌ Bad - Multiple unrelated assertions
test('booking validation', () {
  expect(booking.isValid(), true);
  expect(booking.amount, 100000);
  expect(booking.user, isNotNull);
});

// ✅ Good - Separate tests
test('should validate booking with all required fields', () {
  expect(booking.isValid(), true);
});

test('should have correct amount', () {
  expect(booking.amount, 100000);
});
```

### 4. Use setUp and tearDown

```dart
group('BookingService', () {
  late BookingService service;

  setUp(() {
    service = BookingService();
  });

  tearDown(() {
    service.dispose();
  });

  test('test 1', () { /* ... */ });
  test('test 2', () { /* ... */ });
});
```

### 5. Mock Dependencies

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([SupabaseClient])
void main() {
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
  });

  test('should fetch bookings', () async {
    // Arrange
    when(mockClient.from('bookings').select())
      .thenReturn(mockData);

    // Act & Assert
    final bookings = await repository.getBookings();
    expect(bookings.length, 5);
  });
}
```

---

## 🔍 Debugging Tests

### Print Debugging

```dart
test('debug test', () {
  print('Current value: $value');
  debugPrint('Debug info: $info');
  
  expect(value, expected);
});
```

### Run Single Test

```bash
# Run specific test by name
flutter test --name "should create Booking from JSON"

# Run specific file
flutter test test/models/booking_test.dart
```

### Use Debugger

In VS Code:
1. Set breakpoint in test file
2. Click "Debug" above test
3. Step through code

---

## 📈 Coverage Goals

| Component | Current | Target |
|-----------|---------|--------|
| Models | ~80% | 80%+ |
| Services | ~30% | 70%+ |
| Repositories | 0% | 70%+ |
| Widgets | 0% | 50%+ |
| **Overall** | **~15%** | **60%+** |

---

## 🚧 Current Test Status

### ✅ Implemented Tests

- [x] Booking model tests (complete)
- [x] Field model tests (complete)
- [x] FileEncryptionService tests (complete)
- [x] Basic smoke tests

### 🔨 TODO Tests (Priority Order)

1. **High Priority:**
   - [ ] BiometricAuthService tests
   - [ ] SupabaseBookingRepository tests
   - [ ] Payment validation tests
   - [ ] Security service tests

2. **Medium Priority:**
   - [ ] StaffService tests
   - [ ] RevenueAnalyticsService tests
   - [ ] NotificationService tests
   - [ ] ChatService tests

3. **Low Priority:**
   - [ ] Widget tests (screens)
   - [ ] Integration tests
   - [ ] E2E tests

---

## 🛠️ Test Utilities

### Helper Functions

Create `test/test_helpers.dart`:

```dart
import 'package:sipelor/models/booking.dart';

// Create mock booking for tests
Booking createMockBooking({
  String id = 'test-123',
  String status = 'pending',
}) {
  return Booking(
    id: id,
    bookingId: 'BOOK001',
    userId: 'user-123',
    fieldId: 'field-456',
    venueId: 'venue-789',
    bookingDate: DateTime.now(),
    startTime: '08:00',
    endTime: '10:00',
    durationHours: 2,
    totalAmount: 200000,
    status: BookingStatus.fromString(status),
    paymentStatus: PaymentStatus.pending,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
```

### Mock Data

Create `test/mock_data.dart`:

```dart
const mockBookingJson = {
  'id': 'test-123',
  'booking_id': 'BOOK001',
  // ... more fields
};

const mockFieldJson = {
  'id': 'field-123',
  'venue_name': 'Test Venue',
  // ... more fields
};
```

---

## 📚 Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Flutter Test Best Practices](https://flutter.dev/docs/cookbook/testing)
- [Test Coverage Best Practices](https://about.codecov.io/blog/getting-started-with-code-coverage/)

---

## ✅ Testing Checklist

Before committing code:

- [ ] All tests pass locally
- [ ] New features have tests
- [ ] Bug fixes have regression tests
- [ ] Coverage hasn't decreased
- [ ] No test warnings or errors

Before releasing:

- [ ] All CI tests pass
- [ ] Coverage meets targets
- [ ] Integration tests pass
- [ ] Performance tests pass

---

**Last Updated:** 2026-02-20

**Maintained by:** SIPELOR Development Team
