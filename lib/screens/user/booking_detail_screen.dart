import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/booking.dart';
import '../../services/supabase_service.dart';
import '../../utils/payment_formatters.dart';
import 'dart:async';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _review;
  bool _isLoadingReview = true;
  late Booking _currentBooking;
  RealtimeChannel? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReview();
    _subscribeToBookingUpdates();
    // Always fetch the latest booking data on open (in case Realtime was missed)
    _refreshBooking();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      // Switched to Review tab, reload review
      if (kDebugMode) print('📱 [BookingDetail] Switched to Review tab, reloading review...');
      _loadReview();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _bookingSubscription?.unsubscribe();
    super.dispose();
  }

  /// Fetch latest booking data from database (fallback when Realtime doesn't fire)
  Future<void> _refreshBooking() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('bookings')
          .select()
          .eq('id', widget.booking.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentBooking = Booking.fromJson({
            ...response,
            'fields': {
              'venue_name': _currentBooking.venueName,
              'area': _currentBooking.fieldArea,
              'venue_type': _currentBooking.venueType,
            },
          });
        });
        if (kDebugMode) print('🔄 [BookingDetail] Booking refreshed from DB: status=${_currentBooking.status.value}, payment_status=${_currentBooking.paymentStatus.value}');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [BookingDetail] Error refreshing booking: $e');
    }
  }

  void _subscribeToBookingUpdates() {
    final supabase = Supabase.instance.client;
    
    _bookingSubscription = supabase
        .channel('booking_${widget.booking.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.booking.id,
          ),
          callback: (payload) {
            if (kDebugMode) print('🔄 [BookingDetail] Booking updated: ${payload.newRecord}');
            
            if (mounted) {
              setState(() {
                // Update the current booking with new data
                _currentBooking = Booking.fromJson({
                  ...payload.newRecord,
                  // Preserve venue info from original booking
                  'fields': {
                    'venue_name': _currentBooking.venueName,
                    'area': _currentBooking.fieldArea,
                    'venue_type': _currentBooking.venueType,
                  },
                });
              });
              
              // Show snackbar notification for payment status changes
              // Compare against _currentBooking (not the original widget.booking) to detect incremental changes
              if (payload.newRecord['payment_status'] != null &&
                  payload.newRecord['payment_status'] != _currentBooking.paymentStatus.value) {
                final newStatus = PaymentStatus.fromString(
                  payload.newRecord['payment_status'] as String,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Status pembayaran diperbarui: ${newStatus.displayName}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadReview() async {
    setState(() => _isLoadingReview = true);
    try {
      if (kDebugMode) print('🔍 [BookingDetail] Loading review for booking ID: ${widget.booking.id}');
      if (kDebugMode) print('🔍 [BookingDetail] Booking code: ${widget.booking.bookingId}');
      
      final review = await SupabaseService.fetchReviewByBookingId(
        bookingId: widget.booking.id,
      );
      
      if (kDebugMode) print('🔍 [BookingDetail] Review data received: $review');
      
      if (mounted) {
        setState(() {
          _review = review;
          _isLoadingReview = false;
        });
        
        if (review != null) {
          if (kDebugMode) print('✅ [BookingDetail] Review loaded successfully - Rating: ${review['rating']}');
        } else {
          if (kDebugMode) print('ℹ️ [BookingDetail] No review found for this booking');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ [BookingDetail] Error loading review: $e');
      if (mounted) {
        setState(() {
          _review = null;
          _isLoadingReview = false;
        });
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Pemesanan',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Detail Booking'),
            Tab(text: 'Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailTab(),
          _buildReviewTab(),
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    return RefreshIndicator(
      onRefresh: _refreshBooking,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking ID Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 113, 72),
                  Color.fromARGB(255, 0, 117, 164),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Kode Booking',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentBooking.bookingId,
                  style: GoogleFonts.mulish(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusBadge(_currentBooking.status),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Booking Information
          _buildSectionTitle('Informasi Pemesanan'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              Icons.event,
              'Tanggal',
              _formatDate(_currentBooking.bookingDate),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Waktu',
              '${_currentBooking.startTime} - ${_currentBooking.endTime}',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.schedule,
              'Durasi',
              '${_currentBooking.durationHours} jam',
            ),
          ]),

          const SizedBox(height: 24),

          // Venue Information
          _buildSectionTitle('Informasi Venue'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              Icons.sports_soccer,
              'Venue',
              _currentBooking.venueName ?? 'Venue',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.location_on,
              'Lapangan',
              _currentBooking.fieldArea ??
                  'Lapangan ${_extractFieldNumber(_currentBooking.fieldId)}',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.category,
              'Jenis',
              _currentBooking.venueType ?? 'Jenis Venue',
            ),
          ]),

          const SizedBox(height: 24),

          // Payment Information
          _buildSectionTitle('Informasi Pembayaran'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              Icons.payments,
              'Total Pembayaran',
              PaymentFormatters.formatCurrency(
                _currentBooking.totalAmount.toDouble(),
              ),
              valueStyle: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color.fromARGB(255, 0, 113, 72),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.check_circle,
              'Status Pembayaran',
              _currentBooking.paymentStatus.displayName,
            ),
          ]),

          // Notes if available
          if (_currentBooking.notes != null &&
              _currentBooking.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Catatan'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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
              child: Text(
                _currentBooking.notes!,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  color: AppColors.primaryDark,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Timestamps
          _buildSectionTitle('Informasi Tambahan'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              Icons.schedule,
              'Dibuat pada',
              _formatDateTime(_currentBooking.createdAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.update,
              'Terakhir diupdate',
              _formatDateTime(_currentBooking.updatedAt),
            ),
          ]),
        ],
      ),
    ), // closes SingleChildScrollView
    ); // closes RefreshIndicator
  }

  Widget _buildReviewTab() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadReview,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main content
                _isLoadingReview
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _review != null
                        ? _buildReviewContent()
                        : _buildNoReviewContent(),
              ],
            ),
          ),
        ),
        
        // Floating refresh button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: const Color.fromARGB(255, 0, 113, 72),
            onPressed: () {
              if (kDebugMode) print('🔄 [BookingDetail] Manual refresh triggered');
              _loadReview();
            },
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewContent() {
    final rating = _review!['rating'] as int;
    final comment = _review!['comment'] as String?;
    final createdAt = DateTime.parse(_review!['created_at'] as String);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Review Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Rating Anda',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.white,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$rating dari 5',
                style: GoogleFonts.mulish(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Comment Section
        if (comment != null && comment.isNotEmpty) ...[
          _buildSectionTitle('Komentar Anda'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review Anda',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    color: AppColors.primaryDark,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Review Date
        _buildSectionTitle('Informasi Review'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            children: [
              _buildInfoRow(
                Icons.calendar_today,
                'Tanggal Review',
                _formatDateTime(createdAt),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.assignment_turned_in,
                'Status',
                'Review Terkirim',
                valueColor: const Color.fromARGB(255, 0, 113, 72),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Thank you message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Terima kasih atas review Anda! Feedback Anda sangat berharga bagi kami.',
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    color: Colors.green.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoReviewContent() {
    final isCompleted = _currentBooking.status == BookingStatus.completed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isCompleted ? 'Belum ada review' : 'Review belum tersedia',
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Anda belum memberikan review untuk pemesanan ini'
                  : 'Review hanya tersedia untuk pemesanan yang sudah selesai',
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: AppColors.secondaryDark,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // The review dialog will be triggered from the bookings screen
                },
                icon: const Icon(Icons.star, size: 20),
                label: Text(
                  'Berikan Review',
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color.fromARGB(255, 0, 113, 72),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.mulish(
                  fontSize: 12,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: valueStyle ??
                    GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.primaryDark,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        statusText = 'Pending';
        break;
      case BookingStatus.confirmed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        statusText = 'Confirmed';
        break;
      case BookingStatus.completed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        statusText = 'Completed';
        break;
      case BookingStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.mulish(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _extractFieldNumber(String fieldId) {
    final match = RegExp(r'\d+').firstMatch(fieldId);
    return match != null ? match.group(0)! : '1';
  }
}
