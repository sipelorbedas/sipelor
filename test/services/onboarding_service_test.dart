import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('hasSeenOnboarding returns false by default', () async {
      final hasSeen = await OnboardingService.hasSeenOnboarding();
      expect(hasSeen, isFalse);
    });

    test('markOnboardingAsSeen should set flag to true', () async {
      // Initially false
      bool hasSeen = await OnboardingService.hasSeenOnboarding();
      expect(hasSeen, isFalse);

      // Mark as seen
      await OnboardingService.markOnboardingAsSeen();

      // Should now be true
      hasSeen = await OnboardingService.hasSeenOnboarding();
      expect(hasSeen, isTrue);
    });

    test('hasSeenBookingTutorial returns false by default', () async {
      final hasSeen = await OnboardingService.hasSeenBookingTutorial();
      expect(hasSeen, isFalse);
    });

    test('markBookingTutorialAsSeen should set flag to true', () async {
      // Initially false
      bool hasSeen = await OnboardingService.hasSeenBookingTutorial();
      expect(hasSeen, isFalse);

      // Mark as seen
      await OnboardingService.markBookingTutorialAsSeen();

      // Should now be true
      hasSeen = await OnboardingService.hasSeenBookingTutorial();
      expect(hasSeen, isTrue);
    });

    test('resetOnboarding should clear all onboarding flags', () async {
      // Mark both as seen
      await OnboardingService.markOnboardingAsSeen();
      await OnboardingService.markBookingTutorialAsSeen();

      // Verify both are true
      bool hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      bool hasSeenTutorial = await OnboardingService.hasSeenBookingTutorial();
      expect(hasSeenOnboarding, isTrue);
      expect(hasSeenTutorial, isTrue);

      // Reset
      await OnboardingService.resetOnboarding();

      // Verify both are false
      hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      hasSeenTutorial = await OnboardingService.hasSeenBookingTutorial();
      expect(hasSeenOnboarding, isFalse);
      expect(hasSeenTutorial, isFalse);
    });

    test('onboarding and booking tutorial are independent', () async {
      // Mark only onboarding as seen
      await OnboardingService.markOnboardingAsSeen();

      // Verify states
      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      final hasSeenTutorial = await OnboardingService.hasSeenBookingTutorial();

      expect(hasSeenOnboarding, isTrue);
      expect(hasSeenTutorial, isFalse);
    });

    test('persistent state survives multiple checks', () async {
      // Mark as seen
      await OnboardingService.markOnboardingAsSeen();

      // Check multiple times
      for (int i = 0; i < 3; i++) {
        final hasSeen = await OnboardingService.hasSeenOnboarding();
        expect(hasSeen, isTrue);
      }
    });
  });
}
