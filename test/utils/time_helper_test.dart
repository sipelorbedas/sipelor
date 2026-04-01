import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/time_helper.dart';

void main() {
  final baseUtc = DateTime.utc(2026, 3, 3, 8, 0, 0); // 08:00 UTC

  group('TimeHelper.toIndonesiaTime', () {
    test('default offset is UTC+7', () {
      final result = TimeHelper.toIndonesiaTime(baseUtc);
      expect(result.hour, 15); // 08:00 + 7 = 15:00
    });

    test('custom offset applied correctly', () {
      final result = TimeHelper.toIndonesiaTime(baseUtc, offsetHours: 8);
      expect(result.hour, 16); // 08:00 + 8 = 16:00
    });
  });

  group('TimeHelper.toWIB / toWITA / toWIT', () {
    test('toWIB = UTC+7', () {
      final r = TimeHelper.toWIB(baseUtc);
      expect(r.hour, 15);
    });

    test('toWITA = UTC+8', () {
      final r = TimeHelper.toWITA(baseUtc);
      expect(r.hour, 16);
    });

    test('toWIT = UTC+9', () {
      final r = TimeHelper.toWIT(baseUtc);
      expect(r.hour, 17);
    });
  });

  group('TimeHelper.formatChatTime', () {
    test('returns HH:mm format', () {
      final result = TimeHelper.formatChatTime(baseUtc);
      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(result, '15:00');
    });
  });

  group('TimeHelper.formatChatDate', () {
    test('today returns "Hari ini"', () {
      final now = DateTime.now().toUtc();
      final result = TimeHelper.formatChatDate(now);
      expect(result, 'Hari ini');
    });

    test('yesterday returns "Kemarin"', () {
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final result = TimeHelper.formatChatDate(yesterday);
      expect(result, 'Kemarin');
    });

    test('older date returns formatted date', () {
      final old = DateTime.utc(2025, 1, 15);
      final result = TimeHelper.formatChatDate(old);
      // Should not be "Hari ini" or "Kemarin"
      expect(result, isNot('Hari ini'));
      expect(result, isNot('Kemarin'));
      expect(result.length, greaterThan(4));
    });
  });

  group('TimeHelper.formatConversationTime', () {
    test('today shows HH:mm', () {
      final now = DateTime.now().toUtc();
      final result = TimeHelper.formatConversationTime(now);
      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('yesterday shows "Kemarin"', () {
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final result = TimeHelper.formatConversationTime(yesterday);
      expect(result, 'Kemarin');
    });

    test('older than a week shows date', () {
      final old = DateTime.utc(2025, 1, 1);
      final result = TimeHelper.formatConversationTime(old);
      expect(result, isNot('Kemarin'));
      expect(result.contains('/'), isTrue);
    });
  });

  group('TimeHelper.formatFullDateTime', () {
    test('returns WIB timezone label by default', () {
      final result = TimeHelper.formatFullDateTime(baseUtc);
      expect(result, contains('WIB'));
    });

    test('custom timezone label', () {
      final result = TimeHelper.formatFullDateTime(
        baseUtc,
        offsetHours: 8,
        timezone: 'WITA',
      );
      expect(result, contains('WITA'));
    });
  });

  group('TimeHelper.getTimezoneName', () {
    test('7 → WIB', () => expect(TimeHelper.getTimezoneName(7), 'WIB'));
    test('8 → WITA', () => expect(TimeHelper.getTimezoneName(8), 'WITA'));
    test('9 → WIT', () => expect(TimeHelper.getTimezoneName(9), 'WIT'));
    test('other → UTC+n', () => expect(TimeHelper.getTimezoneName(5), 'UTC+5'));
  });
}
