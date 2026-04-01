# 🧪 Testing Guide - SIPELOR BEDAS

Comprehensive testing infrastructure for the SIPELOR BEDAS application.

---

## 📋 Test Structure

```
test/
├── services/              # Unit tests for 32 services
│   ├── booking_expiration_service_test.dart
│   ├── email_verification_service_test.dart
│   ├── chat_service_test.dart
│   └── ... (29 more)
│
├── widgets/               # Widget tests for 42+ screens
│   ├── home_screen_test.dart
│   ├── sign_in_screen_test.dart
│   ├── booking_confirmation_screen_test.dart
│   └── ... (39 more)
│
├── integration/           # Integration tests for main flows
│   ├── user_booking_flow_test.dart
│   ├── admin_management_flow_test.dart
│   ├── chat_flow_test.dart
│   └── authentication_flow_test.dart
│
├── utils/                 # Utility function tests
│   └── input_sanitizer_test.dart
│
├── test_helper.dart      # Common mocks and fixtures
├── widget_test.dart      # Main test file (legacy)
│
├── manual_testing_checklist.md       # Manual QA checklist
├── security_penetration_testing_checklist.md  # Security audit
│
├── run_all_tests.bat     # Windows test runner
├── run_all_tests.sh      # Unix/Linux/Mac test runner
└── README_TESTING.md     # This file
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Mock Classes

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run All Tests

**Windows:**
```cmd
test\run_all_tests.bat
```

**Unix/Linux/Mac:**
```bash
chmod +x test/run_all_tests.sh
./test/run_all_tests.sh
```

### 4. Run Specific Test Types

**Unit Tests Only:**
```bash
flutter test test/services/
flutter test test/utils/
```

**Widget Tests Only:**
```bash
flutter test test/widgets/
```

**Integration Tests Only:**
```bash
flutter test test/integration/
```

**Single Test File:**
```bash
flutter test test/services/booking_expiration_service_test.dart
```

---

## 📊 Code Coverage

### Generate Coverage Report

```bash
flutter test --coverage
```

### View Coverage in Browser

**Windows (requires lcov via chocolatey):**
```cmd
choco install lcov
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml -o coverage\html coverage\lcov.info
start coverage\html\index.html
```

**Mac:**
```bash
brew install lcov
genhtml -o coverage/html coverage/lcov.info
open coverage/html/index.html
```

**Ubuntu/Linux:**
```bash
sudo apt-get install lcov
genhtml -o coverage/html coverage/lcov.info
xdg-open coverage/html/index.html
```

### Coverage Goals

- **Unit Tests**: 70%+ coverage for all services
- **Widget Tests**: 60%+ coverage for critical screens
- **Integration Tests**: 100% coverage of main user flows

---

## 🧪 Writing Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sipelor/services/your_service.dart';
import '../test_helper.dart';

void main() {
  group('YourService', () {
    late YourService service;

    setUp(() {
      service = YourService();
    });

    test('method name should do something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = service.method(input);

      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/screens/your_screen.dart';
import '../test_helper.dart';

void main() {
  group('YourScreen Widget Tests', () {
    testWidgets('displays expected widgets', (tester) async {
      // Arrange & Act
      await pumpWidgetWithMaterial(tester, const YourScreen());

      // Assert
      expect(find.text('Expected Text'), findsOneWidget);
      expect(find.byType(ExpectedWidget), findsOneWidget);
    });
  });
}
```

### Integration Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sipelor/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Flow', () {
    testWidgets('completes full flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Interact with app
      await tester.tap(find.text('Button'));
      await tester.pumpAndSettle();

      // Verify result
      expect(find.text('Success'), findsOneWidget);
    });
  });
}
```

---

## 🔧 Testing Tools

### Mockito (Mocking)
Used for mocking dependencies like Supabase, HTTP clients, etc.

```dart
@GenerateMocks([SupabaseClient, GoTrueClient])
void main() {
  final mockClient = MockSupabaseClient();
  when(mockClient.from('table')).thenReturn(mockQuery);
}
```

### Faker (Test Data)
Generate realistic fake data for tests.

```dart
import 'package:faker/faker.dart';

final faker = Faker();
final email = faker.internet.email();
final name = faker.person.name();
```

### Integration Test Package
Run tests on real devices/emulators.

```bash
flutter test integration_test/
```

---

## ✅ Manual Testing

For comprehensive manual testing, follow:
- **[manual_testing_checklist.md](./manual_testing_checklist.md)** - Complete QA checklist

### Key Areas to Test Manually

1. **Authentication flows** (sign up, login, password reset)
2. **Booking complete flow** (browse → book → pay → ticket)
3. **Admin dashboard** (field management, booking approval)
4. **Real-time chat** (user-admin messaging)
5. **Payment proof upload** (image upload and approval)
6. **E-ticket generation** (QR code, save, share)
7. **Responsive design** (mobile, tablet, desktop)
8. **Offline behavior** (no internet handling)

---

## 🔐 Security Testing

For penetration testing and security audit, follow:
- **[security_penetration_testing_checklist.md](./security_penetration_testing_checklist.md)** - Security audit checklist

### Critical Security Tests

1. **Authentication security** (brute force protection, session management)
2. **Authorization** (access control, role-based permissions)
3. **Injection attacks** (SQL injection, XSS, command injection)
4. **File upload security** (type validation, size limits, malware)
5. **Encryption** (data at rest, data in transit, SSL pinning)
6. **Business logic** (price manipulation, double booking)
7. **Rate limiting** (API abuse prevention)

### Security Testing Tools

- **OWASP ZAP**: Automated vulnerability scanning
- **Burp Suite**: Manual penetration testing
- **Charles Proxy / mitmproxy**: SSL pinning verification
- **Postman**: API security testing

---

## 📈 Continuous Integration

### GitHub Actions (Example)

```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

---

## 🐛 Debugging Tests

### Run Tests in Debug Mode

```bash
flutter test --debug test/services/your_test.dart
```

### Print Debug Output

```dart
test('something', () {
  debugPrint('Debug info: $variable');
  print('Standard output: $variable');
  expect(result, expectedValue);
});
```

### Run Single Test

```dart
test('my test', () { ... }, skip: false);  // Run this one
test('other test', () { ... }, skip: true);  // Skip this one
```

---

## 📝 Test Checklist

### Before Production Deployment

- [ ] All unit tests pass (70%+ coverage)
- [ ] All widget tests pass (60%+ coverage)
- [ ] All integration tests pass (100% of main flows)
- [ ] Manual testing checklist completed
- [ ] Security penetration testing completed
- [ ] No critical or high-severity findings
- [ ] Performance testing completed (load times, memory usage)
- [ ] Cross-platform testing (Android, iOS, Web)
- [ ] Different screen sizes tested (phone, tablet, desktop)
- [ ] Error tracking verified (Sentry captures errors)
- [ ] Analytics verified (user events tracked)

---

## 🎯 Testing Goals

### Current Status (Initial Setup)

| Test Type | Target | Current | Status |
|-----------|--------|---------|--------|
| Unit Tests (Services) | 70% | 0% | 🔴 Not Started |
| Unit Tests (Utils) | 80% | 30% | 🟡 In Progress |
| Widget Tests | 60% | 0% | 🔴 Not Started |
| Integration Tests | 100% flows | 0% | 🔴 Not Started |
| Manual Testing | 100% | 0% | 🔴 Not Started |
| Security Testing | 100% | 0% | 🔴 Not Started |

### Target Status (Production Ready)

| Test Type | Target | Goal | Status |
|-----------|--------|------|--------|
| Unit Tests (Services) | 70% | ✅ | 🟢 Ready |
| Unit Tests (Utils) | 80% | ✅ | 🟢 Ready |
| Widget Tests | 60% | ✅ | 🟢 Ready |
| Integration Tests | 100% flows | ✅ | 🟢 Ready |
| Manual Testing | 100% | ✅ | 🟢 Ready |
| Security Testing | 100% | ✅ | 🟢 Ready |

---

## 📚 Resources

### Flutter Testing Documentation
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

### Testing Best Practices
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Flutter Testing Anti-patterns](https://docs.flutter.dev/cookbook/testing/widget/finders)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)

---

## 🤝 Contributing

When adding new features:

1. Write tests **before** implementing the feature (TDD)
2. Ensure all tests pass before committing
3. Maintain or improve code coverage
4. Update this documentation if test structure changes
5. Add manual testing steps for new user-facing features

---

## 📞 Support

For questions about testing:
- Check existing tests in `test/` directory
- Review `test_helper.dart` for common utilities
- Refer to Flutter testing documentation
- Ask the development team

---

**Last Updated**: 28 Januari 2026  
**Version**: 1.0.0  
**Maintained by**: SIPELOR BEDAS Development Team
