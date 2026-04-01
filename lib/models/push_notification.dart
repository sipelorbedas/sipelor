/// Model for push notifications stored in Supabase
class PushNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  PushNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    required this.createdAt,
    this.readAt,
  });

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: null, // read_at column doesn't exist in database schema
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PushNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return PushNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Notification types enum
class NotificationType {
  static const String bookingApproved = 'booking_approved';
  static const String bookingRejected = 'booking_rejected';
  static const String bookingCompleted = 'booking_completed';
  static const String paymentVerified = 'payment_verified';
  static const String paymentReminder = 'payment_reminder';
  static const String promoAvailable = 'promo_available';
  static const String reviewReminder = 'review_reminder';
  static const String maintenanceSchedule = 'maintenance_schedule';
  static const String bookingExpired = 'booking_expired';
  static const String chatMessage = 'chat_message';
  static const String general = 'general';

  /// Get all notification types
  static List<String> get all => [
    bookingApproved,
    bookingRejected,
    bookingCompleted,
    paymentVerified,
    paymentReminder,
    promoAvailable,
    reviewReminder,
    maintenanceSchedule,
    bookingExpired,
    chatMessage,
    general,
  ];

  /// Get display name for notification type
  static String getDisplayName(String type) {
    switch (type) {
      case bookingApproved:
        return 'Booking Disetujui';
      case bookingRejected:
        return 'Booking Ditolak';
      case bookingCompleted:
        return 'Booking Selesai';
      case paymentVerified:
        return 'Pembayaran Terverifikasi';
      case paymentReminder:
        return 'Pengingat Pembayaran';
      case promoAvailable:
        return 'Promo Tersedia';
      case reviewReminder:
        return 'Pengingat Review';
      case maintenanceSchedule:
        return 'Jadwal Maintenance';
      case bookingExpired:
        return 'Booking Expired';
      case chatMessage:
        return 'Pesan Chat';
      case general:
        return 'Umum';
      default:
        return 'Notifikasi';
    }
  }

  /// Get icon for notification type
  static String getIcon(String type) {
    switch (type) {
      case bookingApproved:
        return '✅';
      case bookingRejected:
        return '❌';
      case bookingCompleted:
        return '✅';
      case paymentVerified:
        return '✅';
      case paymentReminder:
        return '⏰';
      case promoAvailable:
        return '🎉';
      case reviewReminder:
        return '⭐';
      case maintenanceSchedule:
        return '🔧';
      case bookingExpired:
        return '⌛';
      case chatMessage:
        return '💬';
      case general:
        return '📢';
      default:
        return '🔔';
    }
  }
}
