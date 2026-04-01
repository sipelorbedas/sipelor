import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/field.dart';
import '../../models/booking.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../services/email_verification_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/category_grid.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/promo_carousel.dart';
import '../../widgets/home/venue_card.dart';
import '../../widgets/home/bottom_nav_bar.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_cache_service.dart';
import '../../widgets/email_verification_banner.dart';
import '../../widgets/guest_login_banner.dart';
import '../../widgets/offline_banner.dart';
import '../../services/popup_service.dart';
import '../../widgets/popup_banner_dialog.dart';
import '../admin/admin_chat_list_screen.dart';
import '../venue/venue_list_screen.dart';
import 'user_bookings_screen.dart';
import 'user_chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  List<Field> _fields = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _fetchError; // error selain offline (RLS, server error, dll)
  String _userName = 'User'; // Default fallback
  String? _userAvatarUrl; // User's profile avatar URL
  Key _headerKey = UniqueKey(); // For forcing header rebuild
  int _bookingNotificationCount = 0;
  int _chatNotificationCount = 0;
  bool _isAdmin = false; // Whether current user is admin
  List<Booking> _userBookings = [];
  RealtimeChannel? _bookingsSubscription;
  RealtimeChannel? _chatSubscription; // Realtime chat messages subscription
  Timer? _periodicRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use addPostFrameCallback to ensure navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  // Check if user is authenticated before loading any data
  Future<void> _checkAuthentication() async {
    if (!mounted) return;

    final isLoggedIn = SupabaseService.isLoggedIn;

    if (kDebugMode) {
      if (kDebugMode) {
        print('🔐 [HomeScreen] Checking authentication: $isLoggedIn');
      }
    }

    // Load fields for all users (public browsing)
    _loadFields();

    if (!isLoggedIn) {
      // Guest user - can browse venues but no personal features
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '👤 [HomeScreen] Guest mode - showing venues without authentication',
          );
        }
      }

      setState(() {
        _userName = 'Guest';
        _userAvatarUrl = null;
        _isLoading = false;
      });
      return;
    }

    // User is authenticated, proceed with loading personal data
    if (kDebugMode) {
      if (kDebugMode) print('✅ [HomeScreen] Authenticated, loading user data');
    }

    _loadUserData();
    _loadBookingNotifications();
    _loadChatNotifications();
    _setupRealtimeSubscription();
    _setupChatRealtimeSubscription();
    _setupPeriodicRefresh();
    _checkAdminRole();
    _checkAndShowPopup();
  }

  void _setupPeriodicRefresh() {
    // PERFORMANCE: Increased interval from 30 to 60 seconds to reduce overhead
    // Fallback: Refresh notifications every 60 seconds
    // This ensures updates even if realtime fails
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      if (mounted) {
        _loadChatNotifications();
        if (kDebugMode) print('⏰ [Periodic] Auto-refreshing notifications...');
        _loadBookingNotifications();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh notifications when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('🔄 [Lifecycle] App resumed, refreshing notifications...');
      }
      _loadBookingNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicRefreshTimer?.cancel();
    _bookingsSubscription?.unsubscribe();
    _chatSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (kDebugMode) {
        print('⚠️  [Realtime] No user ID, skipping subscription setup');
      }
      return;
    }

    // If subscription already exists, unsubscribe first to prevent duplicates
    if (_bookingsSubscription != null) {
      if (kDebugMode) {
        print(
          '⚠️  [Realtime] Subscription already exists, unsubscribing first...',
        );
      }
      _bookingsSubscription!.unsubscribe();
      _bookingsSubscription = null;
    }

    if (kDebugMode) {
      print('🔄 [Realtime] Setting up subscription for user: $userId');
    }

    // Subscribe to bookings table changes for current user
    _bookingsSubscription = supabase
        .channel('home_bookings_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) print('📡 [Realtime] Booking change detected!');
            if (kDebugMode) {
              print('📡 [Realtime] Event type: ${payload.eventType}');
            }

            // Force reload notifications when any booking changes
            _loadBookingNotifications();
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (kDebugMode) {
              print(
                '✅ [Realtime] Successfully subscribed to booking notifications',
              );
            }
          } else if (status == RealtimeSubscribeStatus.channelError) {
            if (kDebugMode) print('❌ [Realtime] Channel error: $error');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            if (kDebugMode) print('⏱️  [Realtime] Subscription timed out');
          } else if (status == RealtimeSubscribeStatus.closed) {
            if (kDebugMode) print('🔒 [Realtime] Channel closed');
          }
        });
  }

  /// Detect admin role once on startup so we can route chat correctly.
  Future<void> _checkAdminRole() async {
    try {
      final isAdmin = await SupabaseService.isAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
      if (kDebugMode) print('🔑 [HomeScreen] isAdmin: $isAdmin');
    } catch (e) {
      if (kDebugMode) print('⚠️  [HomeScreen] Admin check failed: $e');
    }
  }

  /// Realtime subscription that immediately updates the chat badge when a new
  /// message arrives with receiver_id = current user (works for both admin and user).
  void _setupChatRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _chatSubscription = supabase
        .channel('home_chat_badge_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              if (kDebugMode) {
                print(
                  '💬 [Realtime] New chat message detected — refreshing badge',
                );
              }
            }
            if (mounted) _loadChatNotifications();
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (kDebugMode) {
              print('💬 [Realtime] Chat subscription status: $status');
            }
            if (error != null) print('💬 [Realtime] Chat error: $error');
          }
        });
  }

  Future<void> _loadBookingNotifications() async {
    try {
      if (kDebugMode) {
        print('🔄 [Notifications] Loading booking notifications...');
      }
      final bookings = await SupabaseService.fetchUserBookings();
      if (kDebugMode) {
        print('📊 [Notifications] Fetched ${bookings.length} bookings');
      }

      // Debug: Print booking statuses
      for (final booking in bookings) {
        if (kDebugMode) {
          print(
            '📦 [Booking] ${booking.bookingId}: status=${booking.status.value}, payment=${booking.paymentStatus.value}',
          );
        }
      }

      final unreadCount = await NotificationService.getUnreadCount(bookings);
      if (kDebugMode) {
        print('🔔 [Notifications] Calculated unread count: $unreadCount');
      }

      if (mounted) {
        setState(() {
          _userBookings = bookings;
          _bookingNotificationCount = unreadCount;
        });
        if (kDebugMode) {
          print(
            '✅ [Notifications] Updated UI with $unreadCount unread notifications',
          );
        }

        // NOTE: Removed duplicate notification here.
        // Realtime subscription (line 313-331) already shows notification
        // immediately when booking status changes to 'confirmed'
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Notifications] Error loading notifications: $e');
      }
      if (kDebugMode) {
        print('❌ [Notifications] Stack trace: ${StackTrace.current}');
      }
    }
  }

  Future<void> _loadChatNotifications() async {
    try {
      if (kDebugMode) print('💬 [Chat] Loading chat notifications...');

      // Admin uses a dedicated method that counts all unread user→admin messages.
      // Regular users count messages sent to them by admin.
      final unreadCount = _isAdmin
          ? await ChatService.getUnreadChatCountForAdmin()
          : await ChatService.getUnreadCount();

      if (kDebugMode) print('💬 [Chat] Unread messages: $unreadCount');

      if (mounted) {
        setState(() => _chatNotificationCount = unreadCount);
        if (kDebugMode) {
          if (kDebugMode) {
            print('✅ [Chat] Updated badge with $unreadCount unread messages');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ [Chat] Error loading notifications: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.currentUser;
      if (kDebugMode) print('🔍 [LoadUserData] Current user: ${user?.id}');

      if (user != null) {
        if (kDebugMode) print('🔍 [LoadUserData] User email: ${user.email}');

        Map<String, dynamic>? profile;
        final isOnline = ConnectivityService().isOnline;
        if (isOnline) {
          profile = await SupabaseService.getUserProfile(user.id);
          // Simpan ke offline cache
          if (profile != null) {
            await OfflineCacheService().cacheUserProfile(profile);
          }
        } else {
          // Ambil dari offline cache saat offline
          profile = await OfflineCacheService().getCachedUserProfile();
        }
        if (kDebugMode) print('🔍 [LoadUserData] Profile data: $profile');

        if (profile != null && mounted) {
          final username = profile['username'] as String?;
          final fullName = profile['full_name'] as String?;
          final email = profile['email'] as String?;
          final avatarUrl = profile['avatar_url'] as String?;

          if (kDebugMode) print('🔍 [LoadUserData] Username: $username');
          if (kDebugMode) print('🔍 [LoadUserData] Full name: $fullName');
          if (kDebugMode) print('🔍 [LoadUserData] Email: $email');
          if (kDebugMode) print('🔍 [LoadUserData] Avatar URL: $avatarUrl');

          // Priority: username > full_name > email username part > User
          final displayName =
              username ?? fullName ?? (email?.split('@').first) ?? 'User';

          // Evict old avatar from cache if it changed
          if (_userAvatarUrl != null && _userAvatarUrl != avatarUrl) {
            if (kDebugMode) {
              print(
                '🔄 [LoadUserData] Avatar changed, evicting old from cache',
              );
            }
            final oldImageProvider = NetworkImage(_userAvatarUrl!);
            oldImageProvider.evict();
          }

          // Evict new avatar to force fresh load
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            final newImageProvider = NetworkImage(avatarUrl);
            newImageProvider.evict();
          }

          setState(() {
            _userName = displayName;
            _userAvatarUrl = avatarUrl;
            _headerKey = UniqueKey(); // Force header rebuild
          });

          if (kDebugMode) print('✅ [LoadUserData] Set username to: $_userName');
          if (kDebugMode) {
            print('✅ [LoadUserData] Set avatar URL to: $_userAvatarUrl');
          }
        } else {
          if (kDebugMode) {
            print('⚠️  [LoadUserData] Profile is null or widget unmounted');
          }
        }
      } else {
        if (kDebugMode) print('⚠️  [LoadUserData] No user logged in');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [LoadUserData] Error loading user data: $e');
      if (kDebugMode) print('❌ [LoadUserData] Error type: ${e.runtimeType}');
      if (e is Exception) {
        if (kDebugMode) {
          print('❌ [LoadUserData] Exception message: ${e.toString()}');
        }
      }
      // Keep default username on error
    }
  }

  Future<void> _loadFields() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _fetchError = null;
      });
    }
    try {
      // PENTING: Selalu coba fetch tanpa cek connectivity dulu.
      // connectivity_plus hanya mengecek network interface (WiFi/cellular adapter),
      // bukan apakah internet sungguhan bisa diakses (false-negative di beberapa
      // perangkat Android). Akibatnya fetch diskip → cache kosong → pesan "offline".
      // Solusi: coba fetch dulu, baru cek koneksi jika gagal untuk tentukan pesan.
      final fields = await SupabaseService.fetchFields()
          .timeout(const Duration(seconds: 15));

      // Simpan ke offline cache untuk akses berikutnya tanpa internet
      await OfflineCacheService().cacheFields(fields);

      if (mounted) {
        setState(() {
          _fields = fields;
          _isLoading = false;
          _isOffline = false;
          _fetchError = null;
        });
      }
      // PERFORMANCE: Precache venue images di background
      _precacheVenueImages();
    } catch (e) {
      if (kDebugMode) print('❌ [HomeScreen] Error loading fields: $e');

      // ── DEBUG MODE: gunakan mock data agar UI tetap bisa diuji ─────────────
      // Ini terjadi saat Supabase terhubung tetapi query gagal (misal RLS policy
      // belum mengizinkan public read, atau kredensial dev berbeda).
      // Di production (release mode) tetap menggunakan cache / pesan error biasa.
      if (kDebugMode) {
        final cached = await OfflineCacheService().getCachedFields();
        if (cached == null || cached.isEmpty) {
          if (mounted) {
            setState(() {
              _fields = _getMockFields();
              _isLoading = false;
              _isOffline = false;
              _fetchError = null;
            });
          }
          print(
            '⚠️  [HomeScreen] Menampilkan data lapangan mock untuk debug.\n'
            '   Penyebab fetch gagal: $e\n'
            '   → Pastikan RLS tabel "fields" mengizinkan SELECT publik:\n'
            '      website/admin/sql/fix_rls_fields_and_bookings.sql',
          );
          return;
        }
      }

      // Setelah fetch gagal, BARU cek koneksi untuk menentukan penyebabnya
      final isOnline = await ConnectivityService().checkConnectivity();
      await _loadFieldsFromCache(isActuallyOnline: isOnline, error: e);
    }
  }

  /// Mock fields untuk keperluan development / debug mode.
  /// Hanya digunakan saat `kDebugMode == true` dan cache kosong.
  List<Field> _getMockFields() {
    final now = DateTime.now();
    return [
      Field(
        id: 'mock-001',
        venueName: 'Lapangan Sepak Bola (Mock)',
        venueType: 'Sepak Bola',
        area: 'SOR Jalak Harupat',
        satuan: 'per jam',
        pricePerHour: 300000,
        status: FieldStatus.available,
        imageUrls: null,
        createdAt: now,
        updatedAt: now,
      ),
      Field(
        id: 'mock-002',
        venueName: 'Lapangan Futsal A (Mock)',
        venueType: 'Futsal',
        area: 'SOR Jalak Harupat',
        satuan: 'per jam',
        pricePerHour: 150000,
        status: FieldStatus.available,
        imageUrls: null,
        createdAt: now,
        updatedAt: now,
      ),
      Field(
        id: 'mock-003',
        venueName: 'GOR Badminton (Mock)',
        venueType: 'Badminton',
        area: 'SOR Jalak Harupat',
        satuan: 'per sesi',
        pricePerHour: 100000,
        status: FieldStatus.available,
        imageUrls: null,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<void> _loadFieldsFromCache({
    bool isActuallyOnline = false,
    Object? error,
  }) async {
    final cached = await OfflineCacheService().getCachedFields();
    if (mounted) {
      setState(() {
        _fields = cached ?? [];
        _isLoading = false;
        // _isOffline hanya true jika memang tidak ada jaringan
        _isOffline = !isActuallyOnline;
        // Jika online tapi gagal, simpan pesan error teknis
        if (isActuallyOnline && error != null) {
          // Debug mode: tampilkan ringkasan error agar developer tahu penyebabnya
          _fetchError = kDebugMode
              ? 'Gagal memuat data lapangan. Ketuk untuk coba lagi.\n[Debug] ${error.toString().length > 120 ? '${error.toString().substring(0, 120)}…' : error}'
              : 'Gagal memuat data lapangan. Ketuk untuk coba lagi.';
        } else {
          _fetchError = null;
        }
      });
    }
    if (kDebugMode) {
      print(
        '📴 [HomeScreen] Fallback cache — ${cached?.length ?? 0} fields, '
        'isOnline: $isActuallyOnline, error: $error',
      );
    }
  }

  // PERFORMANCE: Precache venue images to improve perceived loading speed
  Future<void> _precacheVenueImages() async {
    if (!mounted || _fields.isEmpty) return;

    try {
      for (final field in _fields) {
        if (field.imageUrls != null && field.imageUrls!.isNotEmpty) {
          final imageUrl = field.imageUrls!.first;
          if (imageUrl.startsWith('http://') ||
              imageUrl.startsWith('https://')) {
            // Precache network images
            await precacheImage(
              NetworkImage(imageUrl),
              context,
              onError: (exception, stackTrace) {
                if (kDebugMode) {
                  if (kDebugMode) {
                    print('⚠️  Failed to precache image: $imageUrl');
                  }
                }
              },
            );
          }
        }
      }
      if (kDebugMode) {
        if (kDebugMode) print('✅ [Performance] Venue images precached');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  Error precaching images: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          // Header Section
          HomeHeader(
            key: _headerKey,
            userName: _userName,
            avatarUrl: _userAvatarUrl,
          ),

          // Offline Banner — muncul otomatis saat tidak ada internet
          const OfflineBanner(cacheKey: 'fields'),

          // Show Guest Login Banner if not logged in
          // Show Email Verification Banner if logged in but email not verified
          if (!SupabaseService.isLoggedIn)
            const GuestLoginBanner()
          else
            EmailVerificationBanner(
              onResendTap: () async {
                final error =
                    await EmailVerificationService.resendVerificationEmail();
                if (mounted) {
                  if (error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Email verifikasi terkirim. Silakan cek inbox Anda.',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengirim email: $error'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 11),

                    // Promo Carousel - Auto-rotating single card
                    const PromoCarousel(),

                    const SizedBox(height: 20),

                    // Category Grid
                    const CategoryGrid(),

                    const SizedBox(height: 22),

                    // Venue Section
                    SectionHeader(
                      title: 'Venue SOR Jalak Harupat',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VenueListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Venue Cards — Horizontal scroll (geser ke kiri)
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _fields.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isOffline
                                      ? Icons.wifi_off_rounded
                                      : _fetchError != null
                                          ? Icons.cloud_off_rounded
                                          : Icons.sports_soccer_outlined,
                                  size: 36,
                                  color: AppColors.secondaryDark.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isOffline
                                      ? 'Tidak ada koneksi internet.\nSambungkan ke internet untuk memuat lapangan.'
                                      : _fetchError ??
                                            'Belum ada lapangan tersedia',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.mulish(
                                    fontSize: 13,
                                    color: AppColors.secondaryDark,
                                  ),
                                ),
                                // Tombol retry jika gagal (offline atau error)
                                if (_isOffline || _fetchError != null) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _loadFields,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 16),
                                    label: Text(
                                      'Coba Lagi',
                                      style: GoogleFonts.mulish(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryDark,
                                      side: BorderSide(
                                          color: AppColors.primaryDark
                                              .withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _fields.length,
                              itemBuilder: (context, index) {
                                final field = _fields[index];
                                final imageUrl =
                                    field.imageUrls != null &&
                                        field.imageUrls!.isNotEmpty
                                    ? field.imageUrls!.first
                                    : null;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < _fields.length - 1 ? 12 : 0,
                                  ),
                                  child: StreamBuilder<List<Map<String, dynamic>>>(
                                    stream:
                                        SupabaseService.streamReviewsByVenueId(
                                          venueId: field.id,
                                        ),
                                    builder: (context, reviewSnapshot) {
                                      final reviews = reviewSnapshot.data ?? [];
                                      final rating = reviews.isEmpty
                                          ? 0.0
                                          : reviews.fold<double>(
                                                  0,
                                                  (sum, review) =>
                                                      sum +
                                                      (review['rating'] as int),
                                                ) /
                                                reviews.length;
                                      final reviewCount = reviews.length;

                                      return VenueCard(
                                        imagePath:
                                            imageUrl ??
                                            'assets/images/stadium_jalak_harupat.jpg',
                                        title: field.venueName,
                                        address: field.area,
                                        rating: rating,
                                        reviewCount: reviewCount,
                                        price:
                                            'Rp. ${_formatPriceNumber(field.pricePerHour)}',
                                        venueType: field.venueType,
                                        satuan: field.satuan ?? 'per jam',
                                        venue: null,
                                        fields: [field],
                                        venueId: field.id,
                                        latitude: field.latitude ?? -6.996321,
                                        longitude:
                                            field.longitude ?? 107.529595,
                                        isFullWidth: false,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                    const SizedBox(
                      height: 20,
                    ), // Reduced spacing for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        bookingNotificationCount: _bookingNotificationCount,
        chatNotificationCount: _chatNotificationCount,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });

          // Navigate to Venue List screen when "Lapangan" is tapped
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VenueListScreen()),
            );
          }

          // Navigate to User Bookings screen when "Pemesanan" is tapped
          if (index == 2) {
            if (!SupabaseService.isLoggedIn) {
              _showLoginRequiredDialog();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserBookingsScreen(),
              ),
            ).then((_) {
              // Refresh notifications when returning from bookings screen
              if (kDebugMode) {
                print(
                  '🔄 [Navigation] Returned from UserBookingsScreen, refreshing...',
                );
              }
              _loadBookingNotifications();
            });
          }

          // Navigate to Chat screen when "Chat" is tapped
          if (index == 3) {
            if (!SupabaseService.isLoggedIn) {
              _showLoginRequiredDialog();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _isAdmin
                    ? const AdminChatListScreen()
                    : const UserChatScreen(),
              ),
            ).then((_) {
              // Refresh chat badge when returning from chat screen
              _loadChatNotifications();
            });
          }

          // Navigate to Profile screen when "Profil" is tapped
          if (index == 4) {
            if (!SupabaseService.isLoggedIn) {
              _showLoginRequiredDialog();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) {
              // Refresh user data when returning from profile screen
              if (kDebugMode) {
                print(
                  '🔄 [Navigation] Returned from ProfileScreen, refreshing user data...',
                );
              }

              // PERFORMANCE: Only evict specific avatar from cache instead of clearing everything
              // This preserves other cached images (venue images, etc.) for better performance
              if (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty) {
                final avatarProvider = NetworkImage(_userAvatarUrl!);
                avatarProvider.evict();
              }

              // Reload user data including avatar
              _loadUserData();
            });
          }
        },
      ),
    );
  }

  /// Cek dan tampilkan popup banner setiap kali user login.
  Future<void> _checkAndShowPopup() async {
    if (!mounted) return;
    try {
      final popup = await PopupService.fetchActivePopup();
      if (popup == null || !mounted) return;

      // Beri jeda agar home screen selesai render dulu
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => PopupBannerDialog(popup: popup),
      );
    } catch (e) {
      if (kDebugMode) print('⚠️  [HomeScreen] Popup check error: $e');
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primaryDark, size: 28),
            const SizedBox(width: 12),
            const Text('Login Diperlukan'),
          ],
        ),
        content: const Text(
          'Anda perlu login untuk mengakses fitur ini. Silakan login atau daftar akun baru.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  String _formatPriceNumber(int price) {
    // Format number with thousand separators
    final priceStr = price.toString();
    final buffer = StringBuffer();
    var count = 0;

    for (var i = priceStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceStr[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join('');
  }
}
