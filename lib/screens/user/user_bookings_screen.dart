import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/booking.dart';
import '../../models/field.dart';
import '../../models/payment_confirmation_data.dart' hide PaymentStatus;
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart';
import '../../services/booking_expiration_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_cache_service.dart';
import '../../widgets/offline_banner.dart';
import '../../utils/payment_formatters.dart';
import '../../widgets/home/bottom_nav_bar.dart';
import '../../widgets/review_dialog.dart';
import 'e_ticket_screen.dart';
import 'home_screen.dart';
import '../venue/venue_list_screen.dart';
import 'profile_screen.dart';
import 'booking_detail_screen.dart';
import 'payment_confirmation_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  RealtimeChannel? _bookingsSubscription;
  int _bookingNotificationCount = 0;
  int _chatNotificationCount = 0;
  int _completedBookingsNeedingReview = 0;

  final List<String> _filters = [
    'Semua',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadChatNotifications();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _bookingsSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    // Subscribe to bookings table changes for current user
    _bookingsSubscription = supabase
        .channel('user_bookings_changes')
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
            if (kDebugMode) {
              print(
                '📡 [Realtime] User bookings changed: ${payload.eventType}',
              );
            }
            _loadBookings();
          },
        )
        .subscribe();

    if (kDebugMode) print('✅ [Realtime] User bookings subscription set up');
  }

  Future<void> _loadChatNotifications() async {
    try {
      final unreadCount = await ChatService.getUnreadCount();

      if (mounted) {
        setState(() {
          _chatNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading chat notifications: $e');
    }
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => _isLoading = true);

      final isOnline = await ConnectivityService().checkConnectivity();
      List<Booking> bookings;

      if (isOnline) {
        bookings = await SupabaseService.fetchUserBookings();
        // Simpan ke offline cache
        await OfflineCacheService().cacheBookings(bookings);
      } else {
        // Gunakan cached bookings saat offline
        bookings = await OfflineCacheService().getCachedBookings() ?? [];
        if (kDebugMode) {
          print(
            '📴 [UserBookings] Offline mode — loaded ${bookings.length} cached bookings',
          );
        }
      }

      if (mounted) {
        // Calculate unread count for navbar badge
        final unreadCount = await NotificationService.getUnreadCount(bookings);

        // Count completed bookings needing review (only when online)
        int completedNeedingReview = 0;
        if (isOnline) {
          for (final booking in bookings) {
            if (booking.status == BookingStatus.completed) {
              final review = await SupabaseService.fetchReviewByBookingId(
                bookingId: booking.id,
              );
              if (review == null) {
                completedNeedingReview++;
              }
            }
          }
        }

        setState(() {
          _bookings = bookings;
          _bookingNotificationCount = unreadCount;
          _completedBookingsNeedingReview = completedNeedingReview;
          _isLoading = false;
        });

        // NOTE: Removed duplicate notification here since home_screen.dart
        // already shows notification via realtime subscription when booking is confirmed.
        // This prevents double notifications.

        // Mark all bookings as seen when user views this screen
        await NotificationService.markAllAsSeen(bookings);
        if (kDebugMode) print('✅ [UserBookings] Marked all bookings as seen');

        // Update notification count after marking as seen (should be 0)
        final updatedUnreadCount = await NotificationService.getUnreadCount(
          bookings,
        );
        if (mounted) {
          setState(() {
            _bookingNotificationCount = updatedUnreadCount;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading bookings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Booking> get _filteredBookings {
    if (_selectedFilter == 'Semua') {
      return _bookings;
    }
    return _bookings.where((booking) {
      return booking.status.value.toLowerCase() ==
          _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 113, 72),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Pemesanan Saya',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Offline Banner
          const OfflineBanner(cacheKey: 'bookings'),

          // Filter Section
          _buildFilterSection(),

          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = _filteredBookings[index];
                        return _buildBookingCard(booking);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Pemesanan tab
        bookingNotificationCount: _bookingNotificationCount,
        chatNotificationCount: _chatNotificationCount,
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            // Navigate to Venue List
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VenueListScreen()),
            );
          } else if (index == 2) {
            // Already on Pemesanan, do nothing or refresh
            _loadBookings();
          } else if (index == 4) {
            // Navigate to Profile
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 0, 113, 72),
                              Color.fromARGB(255, 0, 117, 164),
                            ],
                          )
                        : null,
                    color: isSelected ? null : AppColors.screenBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.secondaryDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isAdvancePaymentBooking(Booking booking) {
    return booking.paymentStatus == PaymentStatus.pending &&
        !booking.hasPaymentProof &&
        BookingExpirationService.getDaysUntilBooking(booking.bookingDate) >= 3;
  }

  bool _isAdvancePaymentH3Window(Booking booking) {
    return booking.paymentStatus == PaymentStatus.pending &&
        !booking.hasPaymentProof &&
        BookingExpirationService.getDaysUntilBooking(booking.bookingDate) == 3;
  }

  Widget _buildAdvancePaymentInfo(Booking booking) {
    final advanceDueDate =
        BookingExpirationService.calculateAdvancePaymentDueDate(
          booking.bookingDate,
        );
    final remaining = BookingExpirationService.getAdvancePaymentRemainingTime(
      booking.bookingDate,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isAdvancePaymentH3Window(booking)
                ? 'Pembayaran H-3 dibuka hari ini'
                : 'Pembayaran akan dibuka pada H-3',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdvancePaymentH3Window(booking)
                ? 'Sisa waktu pembayaran: ${BookingExpirationService.formatRemainingTime(remaining)}'
                : 'Bayar mulai pada ${_formatDate(advanceDueDate)}.',
            style: GoogleFonts.mulish(
              fontSize: 12,
              color: const Color(0xFF0D47A1),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.fetchReviewByBookingId(bookingId: booking.id),
      builder: (context, snapshot) {
        final hasReview = snapshot.data != null;
        final review = snapshot.data;

        // Pending bookings without payment proof → lanjut ke PaymentConfirmationScreen
        final isPendingWithoutProof =
            booking.status == BookingStatus.pending && !booking.hasPaymentProof;

        return GestureDetector(
          onTap: () async {
            if (isPendingWithoutProof) {
              await _continuePendingPayment(booking);
            } else {
              if (kDebugMode) {
                print(
                  '🔍 [UserBookings] Opening detail for booking: ${booking.bookingId}',
                );
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(booking: booking),
                ),
              );
            }
            _loadBookings();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Booking ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            booking.bookingId,
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          if (hasReview) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    review?['rating']?.toString() ?? '',
                                    style: GoogleFonts.mulish(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Booking Details
                _buildDetailRow(Icons.event, _formatDate(booking.bookingDate)),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.access_time,
                  '${booking.startTime} - ${booking.endTime}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.sports_soccer,
                  booking.venueName ?? 'Venue',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.location_on,
                  booking.fieldArea ??
                      'Lapangan ${_extractFieldNumber(booking.fieldId)}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.category,
                  booking.venueType ?? 'Jenis Venue',
                ),
                const SizedBox(height: 12),

                // Divider
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // Amount and Payment Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PaymentFormatters.formatCurrency(
                            booking.totalAmount.toDouble(),
                          ),
                          style: GoogleFonts.mulish(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    // Hide payment status badge if it's pending (Menunggu Verifikasi)
                    if (booking.paymentStatus != PaymentStatus.pending)
                      _buildPaymentStatusBadge(booking.paymentStatus),
                  ],
                ),

                if (_isAdvancePaymentBooking(booking))
                  _buildAdvancePaymentInfo(booking),

                // Display Review if exists
                if (hasReview && review != null) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  _buildReviewSection(review),
                ],

                // Lanjut Bayar button for pending bookings without payment proof
                if (isPendingWithoutProof) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bukti pembayaran belum diupload. Segera selesaikan pembayaran sebelum batas waktu habis.',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _continuePendingPayment(booking),
                      icon: const Icon(Icons.payment, size: 18),
                      label: Text(
                        'Lanjut Bayar',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],

                // E-Tiket Button (show if status is Confirmed or Completed)
                // Tombol muncul setelah admin mengonfirmasi pemesanan
                // User dapat mendownload E-Tiket untuk ditunjukkan saat datang
                if (booking.status == BookingStatus.confirmed ||
                    booking.status == BookingStatus.completed) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewETicket(booking),
                      icon: const Icon(Icons.confirmation_number, size: 20),
                      label: Text(
                        'Download E-Tiket',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],

                // Review Button (show only for completed bookings without review)
                if (booking.status == BookingStatus.completed &&
                    !hasReview) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFA726), // Orange
                          Color(0xFFFF7043), // Deep Orange
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA726).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(booking),
                      icon: const Icon(Icons.star, size: 20),
                      label: Text(
                        'Berikan Review',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Reconstruct PaymentConfirmationData from a booking and navigate to PaymentConfirmationScreen
  Future<void> _continuePendingPayment(Booking booking) async {
    try {
      // Check if payment deadline has passed
      final localCreatedAt = booking.createdAt.toLocal();
      final deadline = BookingExpirationService.calculatePaymentDeadline(
        localCreatedAt,
      );
      if (DateTime.now().isAfter(deadline)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Batas waktu pembayaran sudah habis. Pesanan dibatalkan.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        _loadBookings();
        return;
      }

      // Fetch field details if not already available
      final Field? field = await SupabaseService.fetchFieldById(
        booking.fieldId,
      );
      final venueName = field?.venueName ?? booking.venueName ?? 'Venue';
      final venueType = field?.venueType ?? booking.venueType;

      // Fetch user profile for name
      String userName = 'Pengguna';
      try {
        final user = SupabaseService.currentUser;
        if (user != null) {
          final profile = await SupabaseService.getUserProfile(user.id);
          if (profile != null) {
            userName =
                profile['full_name'] as String? ??
                profile['username'] as String? ??
                'Pengguna';
          }
        }
      } catch (_) {}

      // Format booking date time
      final formattedDateTime =
          '${_formatDate(booking.bookingDate)} • ${booking.startTime} - ${booking.endTime}';

      final paymentData = PaymentConfirmationData(
        venueName: venueName,
        fieldName: field?.area ?? booking.fieldArea ?? venueName,
        bookingDateTime: formattedDateTime,
        paymentMethod:
            PaymentMethod.bjb, // default; user can see bank info again
        accountNumber: '0075787111001',
        accountName: 'Bendahara Penerimaan DISPORA',
        totalPrice: booking.totalAmount.toDouble(),
        paymentDeadline: deadline,
        userName: userName,
        venueType: venueType,
      );

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              paymentData: paymentData,
              bookingId: booking.bookingId,
              bookingUuid: booking.id,
            ),
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserBookings] Error continuing pending payment: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka halaman pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewETicket(Booking booking) async {
    try {
      // Fetch field info to get venue name
      final field = await SupabaseService.fetchFieldById(booking.fieldId);
      final venueName = field?.venueName ?? 'Venue';
      final fieldName =
          field?.area ?? 'Lapangan ${_extractFieldNumber(booking.fieldId)}';

      // Format booking date time
      final bookingDateTime =
          '${_formatDate(booking.bookingDate)}, ${booking.startTime} - ${booking.endTime}';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ETicketScreen(
              venueName: venueName,
              fieldName: fieldName,
              bookingDateTime: bookingDateTime,
              bookingCode: booking.bookingId,
              totalAmount: booking.totalAmount.toDouble(),
              area: booking.fieldArea,
              venueType: booking.venueType,
              duration: booking.durationHours > 0
                  ? '${booking.durationHours} Jam'
                  : null,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error navigating to E-Ticket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka E-Tiket', style: GoogleFonts.mulish()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryDark),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.mulish(fontSize: 14, color: AppColors.primaryDark),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    final backgroundColor = switch (status) {
      BookingStatus.pending => Colors.orange.shade100,
      BookingStatus.confirmed => Colors.blue.shade100,
      BookingStatus.completed => Colors.green.shade100,
      BookingStatus.cancelled => Colors.red.shade100,
    };
    final textColor = switch (status) {
      BookingStatus.pending => Colors.orange.shade700,
      BookingStatus.confirmed => Colors.blue.shade700,
      BookingStatus.completed => Colors.green.shade700,
      BookingStatus.cancelled => Colors.red.shade700,
    };
    final statusText = switch (status) {
      BookingStatus.pending => 'Pending',
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.completed => 'Completed',
      BookingStatus.cancelled => 'Cancelled',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.mulish(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(PaymentStatus status) {
    final backgroundColor = switch (status) {
      PaymentStatus.pending => Colors.orange.shade100,
      PaymentStatus.verified => Colors.green.shade100,
      PaymentStatus.rejected => Colors.red.shade100,
    };
    final textColor = switch (status) {
      PaymentStatus.pending => Colors.orange.shade700,
      PaymentStatus.verified => Colors.green.shade700,
      PaymentStatus.rejected => Colors.red.shade700,
    };
    final statusText = switch (status) {
      PaymentStatus.pending => 'Menunggu Verifikasi',
      PaymentStatus.verified => 'Terverifikasi',
      PaymentStatus.rejected => 'Ditolak',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.mulish(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildReviewSection(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final comment = review['comment'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                'Review Anda',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: GoogleFonts.mulish(
                fontSize: 13,
                color: AppColors.secondaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(Booking booking) async {
    try {
      // Fetch field info to get venue name
      final field = await SupabaseService.fetchFieldById(booking.fieldId);
      final venueName = field?.venueName ?? 'Venue';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => ReviewDialog(
            bookingId: booking.id,
            bookingCode: booking.bookingId,
            venueName: venueName,
            onReviewSubmitted: () {
              // Refresh bookings to show the new review
              _loadBookings();
            },
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error showing review dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuka form review',
              style: GoogleFonts.mulish(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada pemesanan',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pemesanan Anda akan muncul di sini',
            style: GoogleFonts.mulish(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _extractFieldNumber(String fieldId) {
    // Try to extract number from field ID or return the ID itself
    final match = RegExp(r'\d+').firstMatch(fieldId);
    return match != null ? match.group(0)! : '1';
  }
}
