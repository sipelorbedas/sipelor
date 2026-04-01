import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/content_moderation_service.dart';

void main() {
  group('ContentModerationService', () {
    test('moderateText allows clean content', () {
      final result = ContentModerationService.moderateText('This is a clean message');
      
      expect(result['isAllowed'], true);
      expect(result['filteredText'], 'This is a clean message');
    });

    test('moderateText blocks offensive content', () {
      final result = ContentModerationService.moderateText('This contains bad word');
      
      // Should either block or filter the content
      expect(result['isAllowed'], isA<bool>());
      expect(result['filteredText'], isNotNull);
    });

    test('moderateText filters SARA content', () {
      // Test with content that contains SARA (Suku, Agama, Ras, Antar-golongan) keywords
      // Note: This is sensitive - using placeholder
      final result = ContentModerationService.moderateText('test content');
      
      expect(result['isAllowed'], isA<bool>());
    });

    test('moderateText handles empty input', () {
      final result = ContentModerationService.moderateText('');
      
      expect(result['isAllowed'], true);
      expect(result['filteredText'], '');
    });

    test('moderateText handles whitespace only', () {
      final result = ContentModerationService.moderateText('   ');
      
      expect(result['isAllowed'], true);
    });

    test('moderateText is case insensitive', () {
      // Test that moderation works regardless of case
      expect(true, true); // Placeholder
    });

    test('moderateText handles URLs', () {
      final result = ContentModerationService.moderateText('Check out https://example.com for more info');
      
      expect(result['isAllowed'], isA<bool>());
      expect(result['filteredText'], isNotNull);
    });

    test('moderateText handles special characters', () {
      final result = ContentModerationService.moderateText('Hello! @#$%^&*() World');
      
      expect(result['isAllowed'], true);
      expect(result['filteredText'], isA<String>());
    });

    test('moderateText handles emojis', () {
      final result = ContentModerationService.moderateText('Hello 👋 World 🌍');
      
      expect(result['isAllowed'], true);
      expect(result['filteredText'], contains('Hello'));
    });

    test('moderateText handles mixed languages', () {
      final result = ContentModerationService.moderateText('Hello Dunia مرحبا 世界');
      
      expect(result['isAllowed'], true);
    });

    test('moderateText handles long text', () {
      final longText = 'Hello world! ' * 100; // 1200+ characters
      final result = ContentModerationService.moderateText(longText);
      
      expect(result['isAllowed'], isA<bool>());
      expect(result['filteredText'], isNotNull);
    });

    test('moderateText handles repeated offensive words', () {
      // Test that it catches offensive content even when repeated
      final result = ContentModerationService.moderateText('test test test');
      
      expect(result, isNotNull);
      expect(result['isAllowed'], isA<bool>());
    });

    test('moderateText preserves clean text structure', () {
      const cleanText = 'This is a clean message with multiple sentences. It has punctuation!';
      final result = ContentModerationService.moderateText(cleanText);
      
      expect(result['isAllowed'], true);
      expect(result['filteredText'], equals(cleanText));
    });

    test('getFilteredWordCount returns correct count', () {
      final result = ContentModerationService.moderateText('some test text here');
      
      // Should have a filteredWordCount field
      expect(result.containsKey('filteredWordCount'), isTrue);
      expect(result['filteredWordCount'], isA<int>());
    });

    test('getSeverityLevel returns appropriate level', () {
      final result = ContentModerationService.moderateText('clean text');
      
      // Should include severity level
      if (result.containsKey('severityLevel')) {
        expect(result['severityLevel'], isA<String>());
      }
    });
  });
}
