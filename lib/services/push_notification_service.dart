import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import '../models/push_notification.dart';
import '../core/app_router.dart';
import '../screens/user/user_bookings_screen.dart';
import '../screens/user/user_chat_screen.dart';

/// Singleton instance for global access
PushNotificationService get pushNotificationService =>
    PushNotificationService();

/// Service for handling push notifications using Supabase Realtime
///
/// This service uses Supabase's realtime features to listen for new notifications
/// in the database and display them using local notifications.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static SupabaseClient get _supabase => Supabase.instance.client;

  static RealtimeChannel? _notificationChannel;
  static RealtimeChannel? _bookingsChannel; // Direct bookings subscription
  static bool _isInitialized = false;
  static StreamSubscription<AuthState>? _authSubscription;
  static Timer? _reconnectionTimer;
  static int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;

  // Key to cache last-known booking statuses (to detect real changes)
  static const String _bookingStatusCacheKey = 'push_booking_status_cache';

  // SharedPreferences keys for notification preferences
  static const String _keyBookingNotifications = 'notif_booking_enabled';
  static const String _keyPaymentReminders = 'notif_payment_enabled';
  static const String _keyPromoNotifications = 'notif_promo_enabled';
  static const String _keyReviewReminders = 'notif_review_enabled';
  static const String _keyMaintenanceNotifications =
      'notif_maintenance_enabled';
  static const String _keyChatNotifications = 'notif_chat_enabled';
  static const String _keySound = 'notif_sound_enabled';
  static const String _keyVibration = 'notif_vibration_enabled';

  /// Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [PushNotification] Already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        if (kDebugMode) print('🚀 [PushNotification] Initializing service...');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup auth state listener FIRST to catch all events
      _setupAuthListener();

      // Check if user is already logged in (from persisted session)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '👤 [PushNotification] User already logged in, subscribing to notifications...',
            );
          }
        }
        // Subscribe to Supabase Realtime for new notifications
        await _subscribeToNotifications();
      } else {
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '👤 [PushNotification] No user logged in, will subscribe when user signs in',
            );
          }
        }
      }

      _isInitialized = true;

      if (kDebugMode) {
        if (kDebugMode) print('✅ [PushNotification] Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error initializing service: $e');
        }
      }
    }
  }

  /// Setup auth state listener to handle login/logout
  void _setupAuthListener() {
    // Cancel existing subscription if any
    _authSubscription?.cancel();

    // Listen to auth state changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '🔐 [PushNotification] Auth event: $event, User: ${session?.user.id}',
          );
        }
      }

      if (event == AuthChangeEvent.signedIn) {
        // User logged in - subscribe to notifications
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '👤 [PushNotification] User signed in, subscribing to notifications...',
            );
          }
        }
        _subscribeToNotifications();
      } else if (event == AuthChangeEvent.signedOut) {
        // User logged out - unsubscribe
        if (kDebugMode) {
          if (kDebugMode) {
            print('👤 [PushNotification] User signed out, unsubscribing...');
          }
        }
        _unsubscribeFromNotifications();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // Token refreshed - ensure subscription is active
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '🔄 [PushNotification] Token refreshed, checking subscription...',
            );
          }
        }
        if (_notificationChannel == null) {
          _subscribeToNotifications();
        }
      }
    });
  }

  /// Unsubscribe from notifications and bookings channels
  Future<void> _unsubscribeFromNotifications() async {
    try {
      if (_notificationChannel != null) {
        await _notificationChannel!.unsubscribe();
        _notificationChannel = null;
        if (kDebugMode) {
          if (kDebugMode) {
            print('✅ [PushNotification] Unsubscribed from notifications');
          }
        }
      }
      if (_bookingsChannel != null) {
        await _bookingsChannel!.unsubscribe();
        _bookingsChannel = null;
        if (kDebugMode) {
          if (kDebugMode) {
            print('✅ [PushNotification] Unsubscribed from bookings channel');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [PushNotification] Error unsubscribing: $e');
      }
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    if (kDebugMode) {
      if (kDebugMode) {
        print('🔧 [PushNotification] Initializing local notifications...');
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (kDebugMode) {
      if (kDebugMode) {
        print(
          '🔧 [PushNotification] Local notifications initialized successfully',
        );
      }
    }

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final permissionGranted = await androidImplementation
            .requestNotificationsPermission();
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '🔧 [PushNotification] Android permission granted: $permissionGranted',
            );
          }
        }

        // Note: Exact alarm permission is NOT needed for push notifications
        // It's only needed if you want to schedule exact time alarms
        // Removed to prevent unnecessary "Alarm & Pengingat" dialog
      }
    }

    if (kDebugMode) {
      if (kDebugMode) {
        print('✅ [PushNotification] Local notifications fully initialized');
      }
    }
  }

  /// Subscribe to Supabase Realtime for new notifications
  Future<void> _subscribeToNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '⚠️ [PushNotification] No user logged in, skipping subscription',
          );
        }
      }
      return;
    }

    try {
      // Cancel any pending reconnection timer
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;

      // Unsubscribe from previous channel if exists
      if (_notificationChannel != null) {
        try {
          await _notificationChannel!.unsubscribe();
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) {
              print('⚠️ [PushNotification] Error unsubscribing: $e');
            }
          }
        }
        _notificationChannel = null;
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('🔌 [PushNotification] Creating channel for user: ${user.id}');
        }
      }

      // Subscribe to notifications table for current user
      _notificationChannel = _supabase
          .channel('notifications:${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '🔔 [PushNotification] New notification received: ${payload.newRecord}',
                  );
                }
              }
              _handleNewNotification(payload.newRecord);
            },
          )
          .subscribe((status, [error]) {
            if (kDebugMode) {
              if (kDebugMode) {
                print('📡 [PushNotification] Channel status: $status');
              }
              if (error != null) {
                if (kDebugMode) {
                  print('❌ [PushNotification] Channel error: $error');
                }
              }
            }

            // Handle different subscription statuses
            if (status == RealtimeSubscribeStatus.subscribed) {
              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '✅ [PushNotification] Successfully subscribed to notifications',
                  );
                }
              }
              _reconnectionAttempts = 0; // Reset reconnection counter
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '⏱️ [PushNotification] Subscription timed out, attempting reconnection...',
                  );
                }
              }
              _attemptReconnection();
            } else if (status == RealtimeSubscribeStatus.channelError) {
              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '❌ [PushNotification] Channel error, attempting reconnection...',
                  );
                }
              }
              _attemptReconnection();
            } else if (status == RealtimeSubscribeStatus.closed) {
              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '🔌 [PushNotification] Channel closed, attempting reconnection...',
                  );
                }
              }
              _attemptReconnection();
            }
          });

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '⏳ [PushNotification] Subscription initiated for user: ${user.id}',
          );
        }
      }

      // Also subscribe directly to bookings table for confirmed notifications
      await _subscribeToBookingsChanges();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error subscribing to notifications: $e');
        }
      }
      _attemptReconnection();
    }
  }

  /// Subscribe directly to the bookings table to detect status→confirmed changes.
  /// This approach bypasses the notifications table entirely, avoiding RLS issues
  /// that occur when the admin tries to INSERT a notification for another user.
  Future<void> _subscribeToBookingsChanges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Unsubscribe existing channel
      if (_bookingsChannel != null) {
        await _bookingsChannel!.unsubscribe();
        _bookingsChannel = null;
      }

      // Seed the local status cache with current booking statuses so we don't
      // fire a notification for bookings that are already confirmed on first run.
      await _seedBookingStatusCache(user.id);

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '🔌 [PushNotification] Subscribing to bookings table for user: ${user.id}',
          );
        }
      }

      _bookingsChannel = _supabase
          .channel('push_booking_status:${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) async {
              final newStatus = payload.newRecord['status'] as String?;
              final newPaymentStatus =
                  payload.newRecord['payment_status'] as String?;
              final bookingId = payload.newRecord['id'] as String?;

              if (bookingId == null) return;
              if (newStatus == null && newPaymentStatus == null) return;

              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '📡 [PushNotification] Booking update: $bookingId → status=$newStatus, payment_status=$newPaymentStatus',
                  );
                }
              }

              final prefs = await SharedPreferences.getInstance();
              final cache = await _loadBookingStateCache();
              final oldState = cache[bookingId];
              final oldStatus = oldState?['status'];
              final oldPaymentStatus = oldState?['payment_status'];

              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                    '📡 [PushNotification] State transition: status $oldStatus → $newStatus, payment_status $oldPaymentStatus → $newPaymentStatus',
                  );
                }
              }

              final bookingNotifEnabled =
                  prefs.getBool(_keyBookingNotifications) ?? true;
              final soundEnabled = prefs.getBool(_keySound) ?? true;
              final vibrationEnabled = prefs.getBool(_keyVibration) ?? true;

              Future<void> showNotification(String title, String body) async {
                await _showBookingStatusNotification(
                  id: bookingId.hashCode.abs() % 100000 + body.length,
                  title: title,
                  body: body,
                  payload: bookingId,
                );
                if (soundEnabled) await _playNotificationSound();
                if (vibrationEnabled) await _vibrateDevice();
              }

              if (bookingNotifEnabled) {
                if (newStatus != null && newStatus != oldStatus) {
                  if (newStatus == 'confirmed') {
                    await showNotification(
                      'Booking Disetujui! ✅',
                      'Booking Anda telah dikonfirmasi oleh admin. Tap untuk download E-Tiket.',
                    );
                  } else if (newStatus == 'completed') {
                    await showNotification(
                      'Booking Selesai ✅',
                      'Booking Anda sudah selesai. Berikan review untuk pengalaman Anda.',
                    );
                  } else if (newStatus == 'cancelled') {
                    await showNotification(
                      'Booking Dibatalkan ❌',
                      'Booking Anda telah dibatalkan oleh admin.',
                    );
                  }
                }

                if (newPaymentStatus != null &&
                    newPaymentStatus != oldPaymentStatus) {
                  if (newPaymentStatus == 'verified') {
                    await showNotification(
                      'Pembayaran Terverifikasi! ✅',
                      'Pembayaran Anda telah diverifikasi. Tap untuk download E-Tiket.',
                    );
                  } else if (newPaymentStatus == 'rejected') {
                    await showNotification(
                      'Pembayaran Ditolak ❌',
                      'Pembayaran Anda ditolak. Silakan upload bukti pembayaran yang valid.',
                    );
                  }
                }
              }

              cache[bookingId] = {
                'status': newStatus ?? oldStatus ?? '',
                'payment_status': newPaymentStatus ?? oldPaymentStatus ?? '',
              };
              await _saveBookingStateCache(cache);
            },
          )
          .subscribe((status, [error]) {
            if (kDebugMode) {
              if (kDebugMode) {
                print('📡 [PushNotification] Bookings channel status: $status');
              }
              if (error != null) {
                if (kDebugMode) {
                  print('❌ [PushNotification] Bookings channel error: $error');
                }
              }
            }
          });

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Bookings subscription set up');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error subscribing to bookings: $e');
        }
      }
    }
  }

  /// Seed the booking status cache with current DB values to avoid false
  /// notifications for bookings that are already in their current state.
  Future<void> _seedBookingStatusCache(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('id, status, payment_status')
          .eq('user_id', userId);

      final cache = await _loadBookingStateCache();

      for (final row in response as List) {
        final id = row['id'] as String?;
        final status = row['status'] as String?;
        final paymentStatus = row['payment_status'] as String?;
        if (id != null) {
          cache[id] = {
            'status': status ?? cache[id]?['status'] ?? '',
            'payment_status':
                paymentStatus ?? cache[id]?['payment_status'] ?? '',
          };
        }
      }

      await _saveBookingStateCache(cache);
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ [PushNotification] Booking status cache seeded (${cache.length} entries)',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '⚠️ [PushNotification] Could not seed booking status cache: $e',
          );
        }
      }
    }
  }

  Future<Map<String, Map<String, String>>> _loadBookingStateCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookingStatusCacheKey);

    if (raw == null) {
      return <String, Map<String, String>>{};
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        final cache = <String, Map<String, String>>{};
        for (final entry in decoded.entries) {
          if (entry.value is String) {
            cache[entry.key] = {
              'status': entry.value as String,
              'payment_status': '',
            };
          } else if (entry.value is Map) {
            final state = Map<String, dynamic>.from(entry.value as Map);
            cache[entry.key] = {
              'status': state['status'] as String? ?? '',
              'payment_status': state['payment_status'] as String? ?? '',
            };
          }
        }
        return cache;
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '⚠️ [PushNotification] Failed to parse booking state cache: $e',
          );
        }
      }
    }

    return <String, Map<String, String>>{};
  }

  Future<void> _saveBookingStateCache(
    Map<String, Map<String, String>> cache,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookingStatusCacheKey, json.encode(cache));
  }

  /// Show a local OS notification for a booking status change.
  Future<void> _showBookingStatusNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const channelId = 'sipelor_notifications';
      const channelName = 'SIPELOR Notifications';
      const channelDescription =
          'Notifications for booking updates and important information';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        // Prefix "booking:" agar tap handler bisa membedakan tipe notifikasi
        payload: 'booking:$payload',
      );

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ [PushNotification] Booking status notification shown: $title',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '❌ [PushNotification] Error showing booking status notification: $e',
          );
        }
      }
    }
  }

  /// Attempt to reconnect to the notifications channel
  void _attemptReconnection() {
    // Cancel existing timer if any
    _reconnectionTimer?.cancel();

    // Check if we've exceeded max attempts
    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '❌ [PushNotification] Max reconnection attempts reached. Giving up.',
          );
        }
      }
      return;
    }

    _reconnectionAttempts++;

    // Exponential backoff: 2^attempt seconds (2s, 4s, 8s, 16s, 32s)
    final delaySeconds = (1 << _reconnectionAttempts).clamp(2, 32);

    if (kDebugMode) {
      if (kDebugMode) {
        print(
          '🔄 [PushNotification] Attempting reconnection in $delaySeconds seconds (attempt $_reconnectionAttempts/$_maxReconnectionAttempts)',
        );
      }
    }

    _reconnectionTimer = Timer(Duration(seconds: delaySeconds), () {
      if (kDebugMode) {
        if (kDebugMode) print('🔄 [PushNotification] Reconnecting now...');
      }
      _subscribeToNotifications();
    });
  }

  /// Handle new notification from Supabase
  Future<void> _handleNewNotification(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) {
          print('📬 [PushNotification] Processing notification data: $data');
        }
      }

      final notification = PushNotification.fromJson(data);

      if (kDebugMode) {
        if (kDebugMode) print('📬 [PushNotification] Parsed notification:');
        if (kDebugMode) print('   - Title: ${notification.title}');
        if (kDebugMode) print('   - Body: ${notification.body}');
        if (kDebugMode) print('   - Type: ${notification.type}');
      }

      // Check if this notification type is enabled
      final isEnabled = await _isNotificationTypeEnabled(notification.type);
      if (!isEnabled) {
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '⚠️ [PushNotification] Notification type ${notification.type} is disabled',
            );
          }
        }
        return;
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✓ [PushNotification] Notification type is enabled, proceeding...',
          );
        }
      }

      // Show local notification
      await _showLocalNotification(notification);

      // Play sound if enabled
      final soundEnabled = await _isSoundEnabled();
      if (kDebugMode) {
        if (kDebugMode) {
          print('🔊 [PushNotification] Sound enabled: $soundEnabled');
        }
      }
      if (soundEnabled) {
        await _playNotificationSound();
      }

      // Vibrate if enabled
      final vibrationEnabled = await _isVibrationEnabled();
      if (kDebugMode) {
        if (kDebugMode) {
          print('📳 [PushNotification] Vibration enabled: $vibrationEnabled');
        }
      }
      if (vibrationEnabled) {
        await _vibrateDevice();
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Notification handled successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error handling notification: $e');
        }
        if (kDebugMode) {
          print('❌ [PushNotification] Stack trace: ${StackTrace.current}');
        }
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(PushNotification notification) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) {
          print('🔔 [PushNotification] Showing local notification...');
        }
      }

      // Create separate channels for different notification types
      final channelId = notification.type == NotificationType.chatMessage
          ? 'sipelor_chat_notifications'
          : 'sipelor_notifications';

      final channelName = notification.type == NotificationType.chatMessage
          ? 'SIPELOR Chat'
          : 'SIPELOR Notifications';

      final channelDescription =
          notification.type == NotificationType.chatMessage
          ? 'Notifications for new chat messages'
          : 'Notifications for booking updates and important information';

      if (kDebugMode) {
        if (kDebugMode) print('🔔 [PushNotification] Channel: $channelId');
        if (kDebugMode) {
          print('🔔 [PushNotification] Title: ${notification.title}');
        }
        if (kDebugMode) {
          print('🔔 [PushNotification] Body: ${notification.body}');
        }
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        // Use default notification sound (more reliable)
        styleInformation: BigTextStyleInformation(
          notification.body,
          contentTitle: notification.title,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate a unique integer ID from the UUID string
      // Parse the first 8 hex characters of the UUID as an integer
      final hexString = notification.id.replaceAll('-', '').substring(0, 8);
      final notificationId = int.parse(hexString, radix: 16);

      // Prefix "notification:" atau "chat:" agar tap handler bisa membedakan tipe
      final payloadPrefix = notification.type == NotificationType.chatMessage
          ? 'chat:'
          : 'notification:';

      await _localNotifications.show(
        id: notificationId,
        title: notification.title,
        body: notification.body,
        notificationDetails: details,
        payload: '$payloadPrefix${notification.id}',
      );

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Local notification shown successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error showing notification: $e');
        }
      }
      rethrow;
    }
  }

  /// Handle notification tap — navigasi ke screen yang relevan
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (kDebugMode) {
      print('🔔 [PushNotification] Notification tapped: $payload');
    }

    if (payload == null || payload.isEmpty) return;

    // Routing berdasarkan prefix payload
    if (payload.startsWith('booking:')) {
      // Booking status notification → buka daftar booking user
      if (kDebugMode) {
        print('🔔 [PushNotification] Navigate to UserBookingsScreen');
      }
      AppRouter.push(const UserBookingsScreen());
    } else if (payload.startsWith('chat:')) {
      // Chat notification → buka chat screen
      if (kDebugMode) print('🔔 [PushNotification] Navigate to UserChatScreen');
      AppRouter.push(const UserChatScreen());
    } else {
      // Notifikasi umum → kembali ke home
      if (kDebugMode) print('🔔 [PushNotification] Navigate to /home');
      AppRouter.pushAndRemoveUntil('/home');
    }
  }

  /// Play notification sound
  Future<void> _playNotificationSound() async {
    try {
      // Try to play custom sound from assets
      try {
        await FlutterRingtonePlayer().play(
          fromAsset: "assets/sounds/mixkit-software-interface-back-2575.wav",
          ios: IosSounds.glass,
          looping: false,
          volume: 0.5,
          asAlarm: false,
        );
      } catch (assetError) {
        // If custom sound not found, use default system notification sound
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '⚠️ [PushNotification] Custom sound not found, using default: $assetError',
            );
          }
        }
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.notification,
          ios: IosSounds.glass,
          looping: false,
          volume: 0.5,
          asAlarm: false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [PushNotification] Error playing sound: $e');
      }
    }
  }

  /// Vibrate device
  Future<void> _vibrateDevice() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [PushNotification] Error vibrating: $e');
      }
    }
  }

  /// Check if notification type is enabled
  Future<bool> _isNotificationTypeEnabled(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      switch (type) {
        case NotificationType.bookingApproved:
        case NotificationType.bookingRejected:
        case NotificationType.bookingCompleted:
        case NotificationType.paymentVerified:
        case NotificationType.bookingExpired:
          return prefs.getBool(_keyBookingNotifications) ?? true;

        case NotificationType.paymentReminder:
          return prefs.getBool(_keyPaymentReminders) ?? true;

        case NotificationType.promoAvailable:
          return prefs.getBool(_keyPromoNotifications) ?? true;

        case NotificationType.reviewReminder:
          return prefs.getBool(_keyReviewReminders) ?? true;

        case NotificationType.maintenanceSchedule:
          return prefs.getBool(_keyMaintenanceNotifications) ?? true;

        case NotificationType.chatMessage:
          return prefs.getBool(_keyChatNotifications) ?? true;

        default:
          return true; // General notifications always enabled
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '⚠️ [PushNotification] Error checking notification preference: $e',
          );
        }
      }
      return true; // Default to enabled on error
    }
  }

  /// Check if sound is enabled
  Future<bool> _isSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySound) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Check if vibration is enabled
  Future<bool> _isVibrationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyVibration) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Get notification preference for a specific type
  static Future<bool> getNotificationPreference(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Set notification preference for a specific type
  static Future<void> setNotificationPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Preference saved: $key = $value');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error saving preference: $e');
        }
      }
    }
  }

  /// Fetch all notifications for current user
  static Future<List<PushNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map(
            (json) => PushNotification.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error fetching notifications: $e');
        }
      }
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count();

      return response.count;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error getting unread count: $e');
        }
      }
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ [PushNotification] Marked notification as read: $notificationId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [PushNotification] Error marking as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Marked all notifications as read');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error marking all as read: $e');
        }
      }
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Deleted notification: $notificationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error deleting notification: $e');
        }
      }
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('notifications').delete().eq('user_id', user.id);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [PushNotification] Cleared all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error clearing notifications: $e');
        }
      }
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    try {
      // Cancel auth listener
      _authSubscription?.cancel();
      _authSubscription = null;

      // Cancel reconnection timer
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;

      // Unsubscribe from notifications channel
      if (_notificationChannel != null) {
        await _notificationChannel!.unsubscribe();
        _notificationChannel = null;
      }

      // Unsubscribe from bookings channel
      if (_bookingsChannel != null) {
        await _bookingsChannel!.unsubscribe();
        _bookingsChannel = null;
      }

      _isInitialized = false;

      if (kDebugMode) {
        if (kDebugMode) print('🛑 [PushNotification] Service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error disposing service: $e');
        }
      }
    }
  }

  /// Check if notification service is connected
  static bool get isConnected {
    return _notificationChannel != null && _supabase.auth.currentUser != null;
  }

  /// Get connection status for debugging
  static String get connectionStatus {
    if (!_isInitialized) return 'Not Initialized';
    if (_supabase.auth.currentUser == null) return 'No User Logged In';
    if (_notificationChannel == null) return 'Channel Not Created';
    return 'Connected';
  }

  /// Send a test notification to current user (for debugging)
  static Future<void> sendTestNotification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          if (kDebugMode) {
            print(
              '❌ [PushNotification] Cannot send test notification: No user logged in',
            );
          }
        }
        return;
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '📤 [PushNotification] Sending test notification to ${user.id}...',
          );
        }
      }

      await _supabase.from('notifications').insert({
        'user_id': user.id,
        'type': NotificationType.general,
        'title': 'Test Notification 🧪',
        'body':
            'If you see this, notifications are working! Time: ${DateTime.now().toIso8601String()}',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [PushNotification] Test notification sent successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [PushNotification] Error sending test notification: $e');
        }
      }
      rethrow;
    }
  }

  /// Force reconnect to notifications channel
  static Future<void> forceReconnect() async {
    if (kDebugMode) {
      if (kDebugMode) print('🔄 [PushNotification] Force reconnecting...');
    }
    _reconnectionAttempts = 0;
    await _instance._subscribeToNotifications();
  }

  /// Print current service status (for debugging)
  static void printStatus() {
    if (kDebugMode) {
      if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (kDebugMode) print('📊 [PushNotification] Service Status:');
      if (kDebugMode) print('   Initialized: $_isInitialized');
      if (kDebugMode) {
        print('   User: ${_supabase.auth.currentUser?.id ?? "Not logged in"}');
      }
      if (kDebugMode) {
        print(
          '   Channel: ${_notificationChannel != null ? "Created" : "Null"}',
        );
      }
      if (kDebugMode) print('   Status: $connectionStatus');
      if (kDebugMode) {
        print(
          '   Reconnection attempts: $_reconnectionAttempts/$_maxReconnectionAttempts',
        );
      }
      if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Preference keys (exposed for UI)
  static const String keyBookingNotifications = _keyBookingNotifications;
  static const String keyPaymentReminders = _keyPaymentReminders;
  static const String keyPromoNotifications = _keyPromoNotifications;
  static const String keyReviewReminders = _keyReviewReminders;
  static const String keyMaintenanceNotifications =
      _keyMaintenanceNotifications;
  static const String keyChatNotifications = _keyChatNotifications;
  static const String keySound = _keySound;
  static const String keyVibration = _keyVibration;
}
