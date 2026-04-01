import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/push_notification.dart';

void main() {
  group('PushNotification Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    
    final testNotification = PushNotification(
      id: 'notif123',
      userId: 'user456',
      type: NotificationType.bookingApproved,
      title: 'Booking Approved',
      body: 'Your booking has been approved',
      data: {'booking_id': 'booking789'},
      read: false,
      createdAt: testDateTime,
    );

    test('should create PushNotification with all fields', () {
      expect(testNotification.id, 'notif123');
      expect(testNotification.userId, 'user456');
      expect(testNotification.type, NotificationType.bookingApproved);
      expect(testNotification.title, 'Booking Approved');
      expect(testNotification.body, 'Your booking has been approved');
      expect(testNotification.data, {'booking_id': 'booking789'});
      expect(testNotification.read, false);
      expect(testNotification.createdAt, testDateTime);
    });

    test('should create PushNotification with null optional fields', () {
      final minimalNotif = PushNotification(
        id: 'notif456',
        userId: 'user789',
        type: NotificationType.general,
        title: 'Test',
        body: 'Test body',
        read: false,
        createdAt: testDateTime,
      );

      expect(minimalNotif.data, isNull);
      expect(minimalNotif.readAt, isNull);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'notif123',
        'user_id': 'user456',
        'type': 'booking_approved',
        'title': 'Booking Approved',
        'body': 'Your booking has been approved',
        'data': {'booking_id': 'booking789'},
        'is_read': false,
        'created_at': '2024-01-01T12:00:00.000',
      };

      final notification = PushNotification.fromJson(json);

      expect(notification.id, 'notif123');
      expect(notification.userId, 'user456');
      expect(notification.type, 'booking_approved');
      expect(notification.read, false);
    });

    test('fromJson should handle default read value', () {
      final json = {
        'id': 'notif456',
        'user_id': 'user789',
        'type': 'general',
        'title': 'Test',
        'body': 'Test body',
        'created_at': '2024-01-01T12:00:00.000',
      };

      final notification = PushNotification.fromJson(json);

      expect(notification.read, false); // Default value
    });

    test('toJson should convert to JSON correctly', () {
      final json = testNotification.toJson();

      expect(json['id'], 'notif123');
      expect(json['user_id'], 'user456');
      expect(json['type'], NotificationType.bookingApproved);
      expect(json['title'], 'Booking Approved');
      expect(json['body'], 'Your booking has been approved');
      expect(json['data'], {'booking_id': 'booking789'});
      expect(json['is_read'], false);
      expect(json['created_at'], testDateTime.toIso8601String());
    });

    test('copyWith should update specified fields only', () {
      final updated = testNotification.copyWith(
        read: true,
        readAt: testDateTime.add(Duration(hours: 1)),
      );

      expect(updated.read, true);
      expect(updated.readAt, isNotNull);
      expect(updated.id, testNotification.id);
      expect(updated.title, testNotification.title);
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testNotification.toJson();
      final reconstructed = PushNotification.fromJson(json);

      expect(reconstructed.id, testNotification.id);
      expect(reconstructed.userId, testNotification.userId);
      expect(reconstructed.type, testNotification.type);
      expect(reconstructed.read, testNotification.read);
    });
  });

  group('NotificationType', () {
    test('should have all notification types', () {
      expect(NotificationType.bookingApproved, 'booking_approved');
      expect(NotificationType.bookingRejected, 'booking_rejected');
      expect(NotificationType.paymentReminder, 'payment_reminder');
      expect(NotificationType.promoAvailable, 'promo_available');
      expect(NotificationType.reviewReminder, 'review_reminder');
      expect(NotificationType.maintenanceSchedule, 'maintenance_schedule');
      expect(NotificationType.bookingExpired, 'booking_expired');
      expect(NotificationType.chatMessage, 'chat_message');
      expect(NotificationType.general, 'general');
    });

    test('all should contain all types', () {
      final all = NotificationType.all;
      
      expect(all, contains('booking_approved'));
      expect(all, contains('booking_rejected'));
      expect(all, contains('payment_reminder'));
      expect(all, contains('promo_available'));
      expect(all, contains('review_reminder'));
      expect(all, contains('maintenance_schedule'));
      expect(all, contains('booking_expired'));
      expect(all, contains('chat_message'));
      expect(all, contains('general'));
      expect(all.length, 9);
    });

    test('getDisplayName should return correct names', () {
      expect(NotificationType.getDisplayName('booking_approved'), 'Booking Disetujui');
      expect(NotificationType.getDisplayName('booking_rejected'), 'Booking Ditolak');
      expect(NotificationType.getDisplayName('payment_reminder'), 'Pengingat Pembayaran');
      expect(NotificationType.getDisplayName('promo_available'), 'Promo Tersedia');
      expect(NotificationType.getDisplayName('review_reminder'), 'Pengingat Review');
      expect(NotificationType.getDisplayName('maintenance_schedule'), 'Jadwal Maintenance');
      expect(NotificationType.getDisplayName('booking_expired'), 'Booking Expired');
      expect(NotificationType.getDisplayName('chat_message'), 'Pesan Chat');
      expect(NotificationType.getDisplayName('general'), 'Umum');
      expect(NotificationType.getDisplayName('unknown'), 'Notifikasi');
    });

    test('getIcon should return correct icons', () {
      expect(NotificationType.getIcon('booking_approved'), '✅');
      expect(NotificationType.getIcon('booking_rejected'), '❌');
      expect(NotificationType.getIcon('payment_reminder'), '⏰');
      expect(NotificationType.getIcon('promo_available'), '🎉');
      expect(NotificationType.getIcon('review_reminder'), '⭐');
      expect(NotificationType.getIcon('maintenance_schedule'), '🔧');
      expect(NotificationType.getIcon('booking_expired'), '⌛');
      expect(NotificationType.getIcon('chat_message'), '💬');
      expect(NotificationType.getIcon('general'), '📢');
      expect(NotificationType.getIcon('unknown'), '🔔');
    });
  });
}
