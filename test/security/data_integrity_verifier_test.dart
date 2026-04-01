import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/security/data_integrity_verifier.dart';

// Helper to compute HMAC for test verification

String _computeHmacForTest(String payload, String secret) {
  final key = utf8.encode(secret);
  final data = utf8.encode(payload);
  return Hmac(sha256, key).convert(data).toString();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('DataIntegrityVerifier.signPayload & verifyPayload', () {
    final testPayload = {
      'booking_id': 'SJH-20260303-A1B2',
      'user_id': 'user-123',
      'amount': '150000.00',
      'status': 'pending',
    };

    test('sign then verify succeeds', () async {
      final signature = await DataIntegrityVerifier.signPayload(testPayload);
      expect(signature, isNotEmpty);

      final result = await DataIntegrityVerifier.verifyPayload(
        payload: testPayload,
        signature: signature,
      );
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('tampered payload fails verification', () async {
      final signature = await DataIntegrityVerifier.signPayload(testPayload);
      final tamperedPayload = {...testPayload, 'amount': '999999.00'};
      final result = await DataIntegrityVerifier.verifyPayload(
        payload: tamperedPayload,
        signature: signature,
      );
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('wrong signature fails verification', () async {
      final result = await DataIntegrityVerifier.verifyPayload(
        payload: testPayload,
        signature: 'invalid-signature',
      );
      expect(result.isValid, isFalse);
    });

    test('map key order does not affect signature (normalized)', () async {
      final p1 = {'a': '1', 'b': '2'};
      final p2 = {'b': '2', 'a': '1'};
      final sig1 = await DataIntegrityVerifier.signPayload(p1);
      final sig2 = await DataIntegrityVerifier.signPayload(p2);
      expect(sig1, equals(sig2));
    });
  });

  group('DataIntegrityVerifier.signString & verifyString', () {
    test('sign then verify string succeeds', () async {
      const data = 'booking:SJH-20260303-A1B2';
      final sig = await DataIntegrityVerifier.signString(data);

      final result = await DataIntegrityVerifier.verifyString(
        data: data,
        signature: sig,
      );
      expect(result.isValid, isTrue);
    });

    test('tampered string fails', () async {
      const data = 'original-string';
      final sig = await DataIntegrityVerifier.signString(data);

      final result = await DataIntegrityVerifier.verifyString(
        data: 'tampered-string',
        signature: sig,
      );
      expect(result.isValid, isFalse);
    });

    test('empty string signs and verifies correctly', () async {
      const data = '';
      final sig = await DataIntegrityVerifier.signString(data);
      final result = await DataIntegrityVerifier.verifyString(
        data: data,
        signature: sig,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('DataIntegrityVerifier.signBooking & verifyBooking', () {
    const bookingId = 'SJH-20260303-ABCD';
    const userId = 'user-999';
    const amount = 150000.0;
    const status = 'confirmed';

    test('sign then verify booking succeeds', () async {
      final token = await DataIntegrityVerifier.signBooking(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        status: status,
      );

      final result = await DataIntegrityVerifier.verifyBooking(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        status: status,
        token: token,
      );
      expect(result.isValid, isTrue);
    });

    test('tampered amount fails verification', () async {
      final token = await DataIntegrityVerifier.signBooking(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        status: status,
      );

      final result = await DataIntegrityVerifier.verifyBooking(
        bookingId: bookingId,
        userId: userId,
        amount: 999999.0,
        status: status,
        token: token,
      );
      expect(result.isValid, isFalse);
    });

    test('tampered status fails verification', () async {
      final token = await DataIntegrityVerifier.signBooking(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        status: status,
      );

      final result = await DataIntegrityVerifier.verifyBooking(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        status: 'cancelled',
        token: token,
      );
      expect(result.isValid, isFalse);
    });

    test('tampered userId fails verification', () async {
      final token = await DataIntegrityVerifier.signBooking(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        status: status,
      );

      final result = await DataIntegrityVerifier.verifyBooking(
        bookingId: bookingId,
        userId: 'attacker-user-id',
        amount: amount,
        status: status,
        token: token,
      );
      expect(result.isValid, isFalse);
    });
  });

  group('DataIntegrityVerifier.verifyServerHmac', () {
    test('correct hmac returns true', () {
      const payload = 'test-payload';
      const secret = 'shared-webhook-secret';
      final sig = _computeHmacForTest(payload, secret);

      expect(
        DataIntegrityVerifier.verifyServerHmac(
          payload: payload,
          signature: sig,
          sharedSecret: secret,
        ),
        isTrue,
      );
    });

    test('wrong signature returns false', () {
      expect(
        DataIntegrityVerifier.verifyServerHmac(
          payload: 'data',
          signature: 'wrong-sig',
          sharedSecret: 'secret',
        ),
        isFalse,
      );
    });

    test('wrong secret returns false', () {
      const payload = 'data';
      const secret = 'correct-secret';
      final sig = _computeHmacForTest(payload, secret);

      expect(
        DataIntegrityVerifier.verifyServerHmac(
          payload: payload,
          signature: sig,
          sharedSecret: 'wrong-secret',
        ),
        isFalse,
      );
    });
  });

  group('DataIntegrityVerifier.algorithm', () {
    test('returns HMAC-SHA256', () {
      expect(DataIntegrityVerifier.algorithm, 'HMAC-SHA256');
    });
  });

  group('IntegrityResult', () {
    test('valid constructor creates correct result', () {
      const r = IntegrityResult.valid();
      expect(r.isValid, isTrue);
      expect(r.error, isNull);
    });

    test('invalid constructor with message', () {
      const r = IntegrityResult.invalid('data tampered');
      expect(r.isValid, isFalse);
      expect(r.error, 'data tampered');
    });
  });
}
