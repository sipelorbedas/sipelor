import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/payment_formatters.dart';
import 'package:sipelor/models/payment_confirmation_data.dart';

void main() {
  group('PaymentFormatters.formatCurrency', () {
    test('formats thousand separators correctly', () {
      expect(PaymentFormatters.formatCurrency(150000), 'Rp. 150.000');
      expect(PaymentFormatters.formatCurrency(1000000), 'Rp. 1.000.000');
    });

    test('handles zero', () {
      expect(PaymentFormatters.formatCurrency(0), 'Rp. 0');
    });

    test('handles decimal (truncated)', () {
      expect(PaymentFormatters.formatCurrency(150000.99), 'Rp. 150.001');
    });
  });

  group('PaymentFormatters.formatCurrencyShort', () {
    test('millions formatted as Jt', () {
      expect(PaymentFormatters.formatCurrencyShort(1500000), contains('Jt'));
    });

    test('thousands formatted as Rb', () {
      expect(PaymentFormatters.formatCurrencyShort(50000), contains('Rb'));
    });

    test('small amounts formatted plain', () {
      expect(PaymentFormatters.formatCurrencyShort(500), 'Rp 500');
    });
  });

  group('PaymentFormatters.formatCurrencyCompact', () {
    test('billions → B', () {
      expect(PaymentFormatters.formatCurrencyCompact(2500000000), contains('B'));
    });

    test('millions → M', () {
      expect(PaymentFormatters.formatCurrencyCompact(1500000), contains('M'));
    });

    test('thousands → K', () {
      expect(PaymentFormatters.formatCurrencyCompact(1500), contains('K'));
    });

    test('small → plain', () {
      expect(PaymentFormatters.formatCurrencyCompact(500), 'Rp 500');
    });
  });

  group('PaymentFormatters.formatAmountOnly', () {
    test('formats without currency symbol', () {
      final result = PaymentFormatters.formatAmountOnly(150000);
      expect(result, '150.000');
      expect(result, isNot(contains('Rp')));
    });
  });

  group('PaymentFormatters.formatToRupiah', () {
    test('alias for formatCurrency', () {
      expect(
        PaymentFormatters.formatToRupiah(75000),
        PaymentFormatters.formatCurrency(75000),
      );
    });
  });

  group('PaymentFormatters.formatBookingDateTime', () {
    test('returns Indonesian day and month names', () {
      final dt = DateTime(2026, 3, 3, 14, 30);
      final result = PaymentFormatters.formatBookingDateTime(dt);
      expect(result, contains('Maret'));
      expect(result, contains('2026'));
      expect(result, contains('14.30'));
    });

    test('contains pipe separator', () {
      final dt = DateTime(2026, 1, 1, 10, 0);
      expect(PaymentFormatters.formatBookingDateTime(dt), contains('|'));
    });
  });

  group('PaymentFormatters.getPaymentMethodName', () {
    test('all PaymentMethod values return non-empty name', () {
      for (final method in PaymentMethod.values) {
        final name = PaymentFormatters.getPaymentMethodName(method);
        expect(name, isNotEmpty);
      }
    });

    test('BJB returns transfer name', () {
      expect(PaymentFormatters.getPaymentMethodName(PaymentMethod.bjb), contains('BJB'));
    });
  });

  group('PaymentFormatters.extractDate', () {
    test('extracts date part before pipe', () {
      expect(
        PaymentFormatters.extractDate('Sabtu, 3 Januari 2023 | 18.00'),
        'Sabtu, 3 Januari 2023',
      );
    });

    test('returns original if no pipe', () {
      expect(PaymentFormatters.extractDate('NoSeparator'), 'NoSeparator');
    });
  });

  group('PaymentFormatters.extractTime', () {
    test('extracts time part after pipe', () {
      expect(
        PaymentFormatters.extractTime('Sabtu, 3 Januari 2023 | 18.00'),
        '18.00',
      );
    });

    test('returns empty if no pipe', () {
      expect(PaymentFormatters.extractTime('NoSeparator'), '');
    });
  });

  group('PaymentFormatters.extractFieldNumber', () {
    test('extracts number from field name', () {
      expect(PaymentFormatters.extractFieldNumber('Lapangan 2'), '2');
      expect(PaymentFormatters.extractFieldNumber('Field 3'), '3');
    });

    test('returns original if no number found', () {
      expect(PaymentFormatters.extractFieldNumber('Main'), 'Main');
    });
  });

  group('PaymentFormatters.formatBookingStatus', () {
    test('all known statuses translated to Indonesian', () {
      expect(PaymentFormatters.formatBookingStatus('pending'), 'Menunggu');
      expect(PaymentFormatters.formatBookingStatus('confirmed'), 'Dikonfirmasi');
      expect(PaymentFormatters.formatBookingStatus('completed'), 'Selesai');
      expect(PaymentFormatters.formatBookingStatus('cancelled'), 'Dibatalkan');
    });

    test('unknown status returned as-is', () {
      expect(PaymentFormatters.formatBookingStatus('unknown'), 'unknown');
    });
  });

  group('PaymentFormatters.formatPaymentStatus', () {
    test('all known statuses translated', () {
      expect(PaymentFormatters.formatPaymentStatus('pending'), 'Menunggu Verifikasi');
      expect(PaymentFormatters.formatPaymentStatus('verified'), 'Terverifikasi');
      expect(PaymentFormatters.formatPaymentStatus('rejected'), 'Ditolak');
    });

    test('unknown returned as-is', () {
      expect(PaymentFormatters.formatPaymentStatus('other'), 'other');
    });
  });
}
