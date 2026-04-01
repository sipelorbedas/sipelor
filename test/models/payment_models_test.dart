import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/payment_confirmation_data.dart';
import 'package:sipelor/models/payment_success_data.dart';
import 'package:sipelor/models/e_ticket_data.dart';

void main() {
  group('PaymentStatus Enum', () {
    test('should have all payment statuses', () {
      expect(PaymentStatus.pending, PaymentStatus.pending);
      expect(PaymentStatus.uploaded, PaymentStatus.uploaded);
      expect(PaymentStatus.verified, PaymentStatus.verified);
      expect(PaymentStatus.failed, PaymentStatus.failed);
    });

    test('should have exactly four statuses', () {
      expect(PaymentStatus.values.length, 4);
    });
  });

  group('PaymentMethod Enum', () {
    test('should have all payment methods', () {
      expect(PaymentMethod.bjb, PaymentMethod.bjb);
      expect(PaymentMethod.mandiri, PaymentMethod.mandiri);
      expect(PaymentMethod.bri, PaymentMethod.bri);
      expect(PaymentMethod.gopay, PaymentMethod.gopay);
      expect(PaymentMethod.ovo, PaymentMethod.ovo);
      expect(PaymentMethod.dana, PaymentMethod.dana);
      expect(PaymentMethod.linkaja, PaymentMethod.linkaja);
      expect(PaymentMethod.qris, PaymentMethod.qris);
    });

    test('should have exactly eight payment methods', () {
      expect(PaymentMethod.values.length, 8);
    });
  });

  group('PaymentConfirmationData Model', () {
    final testDeadline = DateTime(2024, 1, 10);
    
    final testData = PaymentConfirmationData(
      venueName: 'Best Futsal Arena',
      fieldName: 'Field A',
      bookingDateTime: '2024-01-15 14:00 - 16:00',
      paymentMethod: PaymentMethod.mandiri,
      accountNumber: '1234567890',
      accountName: 'PT Arena Sports',
      totalPrice: 150000,
      paymentDeadline: testDeadline,
      userName: 'John Doe',
      venueType: 'Futsal',
    );

    test('should create PaymentConfirmationData with all fields', () {
      expect(testData.venueName, 'Best Futsal Arena');
      expect(testData.fieldName, 'Field A');
      expect(testData.bookingDateTime, '2024-01-15 14:00 - 16:00');
      expect(testData.paymentMethod, PaymentMethod.mandiri);
      expect(testData.accountNumber, '1234567890');
      expect(testData.accountName, 'PT Arena Sports');
      expect(testData.totalPrice, 150000);
      expect(testData.paymentDeadline, testDeadline);
      expect(testData.userName, 'John Doe');
      expect(testData.venueType, 'Futsal');
    });

    test('should create PaymentConfirmationData with null optional fields', () {
      final minimalData = PaymentConfirmationData(
        venueName: 'Arena',
        fieldName: 'Field',
        bookingDateTime: '2024-01-15 14:00',
        paymentMethod: PaymentMethod.bri,
        accountNumber: '123456',
        accountName: 'Arena',
        totalPrice: 100000,
        paymentDeadline: testDeadline,
        userName: 'User',
      );

      expect(minimalData.venueType, isNull);
    });

    test('should support all payment methods', () {
      for (final method in PaymentMethod.values) {
        final data = PaymentConfirmationData(
          venueName: 'Arena',
          fieldName: 'Field',
          bookingDateTime: '2024-01-15',
          paymentMethod: method,
          accountNumber: '123',
          accountName: 'Account',
          totalPrice: 100000,
          paymentDeadline: testDeadline,
          userName: 'User',
        );

        expect(data.paymentMethod, method);
      }
    });
  });

  group('PaymentProof Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);

    test('should create PaymentProof with all fields', () {
      final proof = PaymentProof(
        filePath: '/path/to/proof.jpg',
        fileName: 'proof.jpg',
        uploadedAt: testDateTime,
        status: PaymentStatus.uploaded,
      );

      expect(proof.filePath, '/path/to/proof.jpg');
      expect(proof.fileName, 'proof.jpg');
      expect(proof.uploadedAt, testDateTime);
      expect(proof.status, PaymentStatus.uploaded);
    });

    test('should create PaymentProof with default status', () {
      final proof = PaymentProof();

      expect(proof.filePath, isNull);
      expect(proof.fileName, isNull);
      expect(proof.uploadedAt, isNull);
      expect(proof.status, PaymentStatus.pending);
    });

    test('should support all payment statuses', () {
      for (final status in PaymentStatus.values) {
        final proof = PaymentProof(status: status);
        expect(proof.status, status);
      }
    });
  });

  group('PaymentSuccessData Model', () {
    final testData = PaymentSuccessData(
      bookingCode: 'BK123456',
      bookingDate: '2024-01-15',
      bookingTime: '14:00 - 16:00',
      venueName: 'Best Futsal Arena',
      fieldName: 'Field A',
      paymentMethod: 'Bank Mandiri',
      totalAmount: 150000,
    );

    test('should create PaymentSuccessData with all fields', () {
      expect(testData.bookingCode, 'BK123456');
      expect(testData.bookingDate, '2024-01-15');
      expect(testData.bookingTime, '14:00 - 16:00');
      expect(testData.venueName, 'Best Futsal Arena');
      expect(testData.fieldName, 'Field A');
      expect(testData.paymentMethod, 'Bank Mandiri');
      expect(testData.totalAmount, 150000);
    });

    test('should handle different total amounts', () {
      final amounts = [50000.0, 100000.0, 150000.0, 200000.0];
      
      for (final amount in amounts) {
        final data = PaymentSuccessData(
          bookingCode: 'BK123',
          bookingDate: '2024-01-15',
          bookingTime: '14:00',
          venueName: 'Arena',
          fieldName: 'Field',
          paymentMethod: 'Bank',
          totalAmount: amount,
        );

        expect(data.totalAmount, amount);
      }
    });
  });

  group('ETicketData Model', () {
    final testTicket = ETicketData(
      venueName: 'Best Futsal Arena',
      fieldName: 'Field A',
      bookingDateTime: '2024-01-15 14:00 - 16:00',
      bookingCode: 'BK123456',
    );

    test('should create ETicketData with all fields', () {
      expect(testTicket.venueName, 'Best Futsal Arena');
      expect(testTicket.fieldName, 'Field A');
      expect(testTicket.bookingDateTime, '2024-01-15 14:00 - 16:00');
      expect(testTicket.bookingCode, 'BK123456');
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'venueName': 'Best Futsal Arena',
        'fieldName': 'Field A',
        'bookingDateTime': '2024-01-15 14:00 - 16:00',
        'bookingCode': 'BK123456',
      };

      final ticket = ETicketData.fromJson(json);

      expect(ticket.venueName, 'Best Futsal Arena');
      expect(ticket.fieldName, 'Field A');
      expect(ticket.bookingDateTime, '2024-01-15 14:00 - 16:00');
      expect(ticket.bookingCode, 'BK123456');
    });

    test('toJson should convert to JSON correctly', () {
      final json = testTicket.toJson();

      expect(json['venueName'], 'Best Futsal Arena');
      expect(json['fieldName'], 'Field A');
      expect(json['bookingDateTime'], '2024-01-15 14:00 - 16:00');
      expect(json['bookingCode'], 'BK123456');
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testTicket.toJson();
      final reconstructed = ETicketData.fromJson(json);

      expect(reconstructed.venueName, testTicket.venueName);
      expect(reconstructed.fieldName, testTicket.fieldName);
      expect(reconstructed.bookingDateTime, testTicket.bookingDateTime);
      expect(reconstructed.bookingCode, testTicket.bookingCode);
    });
  });
}
