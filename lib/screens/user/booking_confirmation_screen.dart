import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/field.dart';
import '../../models/payment_confirmation_data.dart';
import '../../services/supabase_service.dart';
import '../../services/booking_expiration_service.dart';
import '../../services/email_verification_service.dart';
import '../../utils/payment_formatters.dart';
import '../../widgets/animated_gradient_button.dart';
import '../../widgets/booking_date_time_sheet.dart';
import '../../widgets/payment_method_sheet.dart';
import 'payment_confirmation_screen.dart';
import 'user_bookings_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Field field;
  final String venueId;
  final String venueName;

  const BookingConfirmationScreen({
    super.key,
    required this.field,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int _durationDays = 1; // jumlah hari yang dipilih di BookingDateTimeSheet
  final _notesController = TextEditingController();
  bool _isProcessing = false;
  bool _isLoadingProfile = true;

  // User profile data
  String _userName = '';
  String _userPhone = '';

  // OPD data
  Map<String, dynamic>? _opdInfo;
  int get _opdDiscountPct =>
      (_opdInfo?['discount_percentage'] as num?)?.toInt() ?? 0;
  bool get _isOpdAccount => _opdInfo != null;

  // Payment method
  PaymentMethod _selectedPaymentMethod = PaymentMethod.bjb;

  // People count (for perOrang booking mode)
  int _peopleCount = 1;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isAdvanceBookingWithoutPayment(DateTime bookingDate) {
    // Advance booking beyond the H-3 payment window should be saved as pending
    // and the user redirected to the Pemesanan screen instead of immediate payment.
    final daysUntilBooking = BookingExpirationService.getDaysUntilBooking(
      bookingDate,
    );
    return daysUntilBooking > 3;
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Load profile dan OPD info secara paralel
        final futures = await Future.wait<Map<String, dynamic>?>([
          SupabaseService.getUserProfile(user.id),
          SupabaseService.getOpdInfo(),
        ]);
        final profile = futures[0];
        final opdInfo = futures[1];

        if (mounted) {
          setState(() {
            _userName =
                profile?['full_name'] as String? ??
                profile?['username'] as String? ??
                'Pengguna';
            _userPhone = profile?['phone_number'] as String? ?? '-';
            _opdInfo = opdInfo;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Pengguna';
          _userPhone = '-';
          _isLoadingProfile = false;
        });
      }
    }
  }

  int get _durationHours {
    if (_selectedTimeSlot == null) return 0;
    final times = _selectedTimeSlot!.split(' - ');
    if (times.length != 2) return 0;

    final start = _parseTime(times[0]);
    final end = _parseTime(times[1]);

    return end.difference(start).inHours;
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2000, 1, 1, hour, minute);
  }

  BookingMode get _bookingMode =>
      BookingMode.fromField(widget.field.satuan, widget.field.venueName);

  /// True untuk lapangan harian dengan durasi tetap < 24 jam (resepsi18, resepsi8).
  /// Mode ini: user hanya pilih tanggal + jam — tanpa sesi/durasi selector.
  bool get _isFixedHourHarian {
    if (_bookingMode != BookingMode.harian) return false;
    // Check satuan for explicit number
    final s = (widget.field.satuan ?? '').toLowerCase().trim();
    final match = RegExp(r'\d+').firstMatch(s);
    if (match != null) {
      final parsed = int.tryParse(match.group(0)!);
      if (parsed != null && parsed > 0 && parsed < 24) return true;
    }
    // Fallback: venueName like "Resepsi 8" or "Resepsi18"
    return BookingMode.resepsiDurationFromName(widget.field.venueName) != null;
  }

  /// Durasi tetap dalam jam — venueName diprioritaskan untuk resepsi.
  /// Contoh: venueName "Resepsi 8" → 8, satuan "2 jam" diabaikan.
  int get _fixedSessionHours {
    // Resepsi fields: always derive duration from venueName first.
    final nameNum = BookingMode.resepsiDurationFromName(widget.field.venueName);
    if (nameNum != null) return nameNum;
    // Non-resepsi: use satuan number.
    final s = (widget.field.satuan ?? '').toLowerCase().trim();
    final match = RegExp(r'\d+').firstMatch(s);
    if (match != null) {
      final parsed = int.tryParse(match.group(0)!);
      if (parsed != null && parsed > 0) return parsed;
    }
    return _durationHours > 0 ? _durationHours : 1;
  }

  int get _baseAmount {
    final price = widget.field.pricePerHour;
    final hours = _durationHours > 0 ? _durationHours : 1;
    switch (_bookingMode) {
      case BookingMode.perSesi:
      case BookingMode.harian:
        // price = price per session / price per day
        return price * _durationDays;
      case BookingMode.perOrang:
        // price per person per hour
        return price * hours * _peopleCount;
      case BookingMode.perJam:
        return price * hours * _durationDays;
    }
  }

  int get _totalAmount {
    if (_opdDiscountPct <= 0) return _baseAmount;
    final discount = (_baseAmount * _opdDiscountPct / 100).round();
    return (_baseAmount - discount).clamp(0, _baseAmount);
  }

  void _showDateTimePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: BookingDateTimeSheet(
          initialDate: DateTime.now(),
          fieldId: widget.field.id,
          field: widget.field,
          onConfirm: (date, timeSlot, durationDays, peopleCount) {
            setState(() {
              _selectedDate = date;
              _selectedTimeSlot = timeSlot;
              _durationDays = durationDays;
              _peopleCount = peopleCount;
            });
          },
        ),
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: PaymentMethodSheet(
            initialMethod: _getPaymentMethodSheetName(_selectedPaymentMethod),
            onConfirm: (String method) {
              setState(() {
                _selectedPaymentMethod = _convertStringToPaymentMethod(method);
              });
            },
          ),
        );
      },
    );
  }

  String _getPaymentMethodSheetName(PaymentMethod method) {
    // Return the exact name used in PaymentMethodSheet
    switch (method) {
      case PaymentMethod.bjb:
        return 'BJB';
      case PaymentMethod.mandiri:
        return 'Mandiri';
      case PaymentMethod.bri:
        return 'BRI';
      case PaymentMethod.gopay:
        return 'GOPAY';
      case PaymentMethod.ovo:
        return 'OVO';
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.linkaja:
        return 'LINKAJA';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  PaymentMethod _convertStringToPaymentMethod(String method) {
    // Handle both formats: from PaymentMethodSheet and from getPaymentMethodName
    final normalizedMethod = method.toUpperCase().trim();

    switch (normalizedMethod) {
      case 'BJB':
        return PaymentMethod.bjb;
      case 'MANDIRI':
        return PaymentMethod.mandiri;
      case 'BRI':
        return PaymentMethod.bri;
      case 'GOPAY':
        return PaymentMethod.gopay;
      case 'OVO':
        return PaymentMethod.ovo;
      case 'DANA':
        return PaymentMethod.dana;
      case 'LINKAJA':
        return PaymentMethod.linkaja;
      case 'QRIS':
        return PaymentMethod.qris;
      default:
        // Default fallback
        if (normalizedMethod.contains('BJB')) return PaymentMethod.bjb;
        if (normalizedMethod.contains('MANDIRI')) return PaymentMethod.mandiri;
        if (normalizedMethod.contains('BRI')) return PaymentMethod.bri;
        if (normalizedMethod.contains('GOPAY')) return PaymentMethod.gopay;
        if (normalizedMethod.contains('OVO')) return PaymentMethod.ovo;
        if (normalizedMethod.contains('QRIS')) return PaymentMethod.qris;
        return PaymentMethod.bjb; // Ultimate fallback
    }
  }

  Future<void> _processBooking() async {
    // Check email verification first
    final verificationError = EmailVerificationService.checkActionAllowed(
      'booking',
    );
    if (verificationError != null) {
      _showEmailVerificationDialog();
      return;
    }

    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal dan waktu terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Extract start and end time from time slot
      final times = _selectedTimeSlot!.split(' - ');
      final startTime = times[0];
      final endTime = times[1];

      // Buat SATU booking saja (termasuk untuk multi-hari)
      final userNotes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      // Untuk multi-hari: sertakan info tanggal akhir di catatan
      String? combinedNotes = userNotes;
      if (_durationDays > 1) {
        final endDate = _selectedDate!.add(Duration(days: _durationDays - 1));
        final multiInfo =
            'Booking $_durationDays hari: ${_formatDate(_selectedDate!)} s/d ${_formatDate(endDate)}';
        combinedNotes = userNotes != null
            ? '$multiInfo | $userNotes'
            : multiInfo;
      }
      // Tambahkan info jumlah orang untuk mode perOrang
      if (_bookingMode == BookingMode.perOrang && _peopleCount > 1) {
        final peopleInfo = 'Jumlah orang: $_peopleCount';
        combinedNotes = combinedNotes != null
            ? '$peopleInfo | $combinedNotes'
            : peopleInfo;
      }

      final booking = await SupabaseService.createBooking(
        fieldId: widget.field.id,
        venueId: widget.venueId,
        bookingDate: _selectedDate!,
        startTime: startTime,
        endTime: endTime,
        durationHours: _durationDays > 1
            ? _durationDays
            : (_durationHours > 0 ? _durationHours : 1),
        totalAmount: _totalAmount,
        notes: combinedNotes,
        discountPercentage: _opdDiscountPct,
        opdId: _opdInfo?['id'] as String?,
        bookingType: _isOpdAccount ? 'opd' : 'regular',
      );

      if (mounted) {
        // Format booking date and time for display
        final endDate = _selectedDate!.add(Duration(days: _durationDays - 1));
        final formattedDateTime = _durationDays > 1
            ? '${_formatDate(_selectedDate!)} s/d ${_formatDate(endDate)}'
                  ' • $_selectedTimeSlot'
            : '${_formatDate(_selectedDate!)} • $_selectedTimeSlot';

        // Calculate payment deadline (30 minutes from booking creation)
        // Convert UTC createdAt to local time to avoid timezone issues
        final localCreatedAt = booking.createdAt.toLocal();
        final paymentDeadline =
            BookingExpirationService.calculatePaymentDeadline(localCreatedAt);

        // Advance booking beyond H-3 should be saved as pending and shown in Pemesanan.
        if (_isAdvanceBookingWithoutPayment(_selectedDate!)) {
          if (mounted) {
            final advanceDueDate =
                BookingExpirationService.calculateAdvancePaymentDueDate(
                  _selectedDate!,
                );
            final dueDateText =
                '${advanceDueDate.day.toString().padLeft(2, '0')}-'
                '${advanceDueDate.month.toString().padLeft(2, '0')}-'
                '${advanceDueDate.year}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Advance booking berhasil disimpan. Pembayaran akan dibuka pada $dueDateText. Cek halaman Pemesanan.',
                ),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UserBookingsScreen(),
              ),
            );
          }
        } else {
          // Create payment confirmation data
          final paymentData = PaymentConfirmationData(
            venueName: widget.venueName,
            fieldName: widget.field.venueName,
            bookingDateTime: formattedDateTime,
            paymentMethod: _selectedPaymentMethod,
            accountNumber:
                '0075787111001', // This should come from app settings/config
            accountName:
                'Bendahara Penerimaan DISPORA', // This should come from app settings/config
            totalPrice: _totalAmount.toDouble(),
            paymentDeadline: paymentDeadline,
            userName: _userName,
            venueType: widget.field.venueType,
            // OPD fields
            discountPercentage: _opdDiscountPct,
            originalPrice: _baseAmount.toDouble(),
            isOpdFreeBooking: _isOpdAccount && _opdDiscountPct >= 100,
            opdName: _opdInfo?['name'] as String?,
          );

          // Navigate to payment confirmation screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationScreen(
                paymentData: paymentData,
                bookingId: booking.bookingId,
                bookingUuid: booking.id, // Pass UUID for cancellation
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing, // Prevent back during processing
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 113, 72),
          elevation: 0,
          leading: IconButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            'Konfirmasi Booking',
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue Info Card
                  _buildVenueInfoCard(),
                  const SizedBox(height: 20),

                  // Date & Time Selection
                  _buildDateTimeSelection(),
                  const SizedBox(height: 20),

                  // Pemesan Section
                  _buildPemesanSection(),
                  const SizedBox(height: 20),

                  // Payment Method Section
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 20),

                  // Notes
                  _buildNotesSection(),
                  const SizedBox(height: 20),

                  // Price Summary
                  _buildPriceSummary(),

                  const SizedBox(height: 120), // Space for fixed button
                ],
              ),
            ),

            // Fixed bottom button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFixedBottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 113, 72),
            Color.fromARGB(255, 0, 117, 164),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.venueName,
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.field.area,
                  style: GoogleFonts.mulish(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.field.venueType,
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Container(
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
          Text(
            'Tanggal & Waktu',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _showDateTimePicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDate != null
                              ? _durationDays > 1
                                    ? '${_formatDate(_selectedDate!)} s/d '
                                          '${_formatDate(_selectedDate!.add(Duration(days: _durationDays - 1)))}'
                                    : _formatDate(_selectedDate!)
                              : 'Pilih tanggal',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        if (_selectedTimeSlot != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _buildTimeSlotDisplay(),
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap untuk pilih ${(_bookingMode == BookingMode.harian && !_isFixedHourHarian) ? 'tanggal' : 'tanggal & jam'}',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              color: const Color(0xFF00693E),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPemesanSection() {
    return Container(
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
          Text(
            'Pemesan',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informasi pemesan lapangan',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.screenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoadingProfile
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color.fromARGB(255, 0, 113, 72),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: GoogleFonts.mulish(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userPhone,
                              style: GoogleFonts.mulish(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
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
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih metode pembayaran Anda',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showPaymentMethodPicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 35,
                    child: Center(
                      child: Image.asset(
                        PaymentFormatters.getPaymentMethodLogo(
                          _selectedPaymentMethod,
                        ),
                        width: _selectedPaymentMethod == PaymentMethod.qris
                            ? 60
                            : _selectedPaymentMethod == PaymentMethod.bjb
                            ? 60
                            : 50,
                        height: _selectedPaymentMethod == PaymentMethod.qris
                            ? 35
                            : _selectedPaymentMethod == PaymentMethod.bjb
                            ? 35
                            : 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: _selectedPaymentMethod == PaymentMethod.qris
                              ? 60
                              : _selectedPaymentMethod == PaymentMethod.bjb
                              ? 35
                              : 50,
                          height: _selectedPaymentMethod == PaymentMethod.qris
                              ? 35
                              : _selectedPaymentMethod == PaymentMethod.bjb
                              ? 35
                              : 20,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PaymentFormatters.getPaymentMethodName(
                            _selectedPaymentMethod,
                          ),
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getPaymentMethodDescription(_selectedPaymentMethod),
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.qris:
        return 'Pembayaran dengan scan QR';
      case PaymentMethod.gopay:
      case PaymentMethod.ovo:
      case PaymentMethod.dana:
      case PaymentMethod.linkaja:
        return 'Transfer E-Wallet';
      default:
        return 'Transfer Bank';
    }
  }

  Widget _buildNotesSection() {
    return Container(
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
          Text(
            'Catatan (Opsional)',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan untuk booking Anda...',
              hintStyle: GoogleFonts.mulish(
                fontSize: 14,
                color: AppColors.secondaryDark,
              ),
              filled: true,
              fillColor: AppColors.screenBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 0, 113, 72),
                ),
              ),
            ),
            style: GoogleFonts.mulish(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 113, 72),
            Color.fromARGB(255, 0, 117, 164),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Badge OPD
          if (_isOpdAccount) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Text('🏛️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun OPD — Diskon $_opdDiscountPct%${_opdInfo?['name'] != null ? ' (${_opdInfo!['name']})' : ''}',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildPriceRow(
            _bookingMode == BookingMode.harian
                ? (_isFixedHourHarian ? 'Harga/Sesi' : 'Harga/Hari')
                : _bookingMode == BookingMode.perSesi
                ? 'Harga/Sesi'
                : _bookingMode == BookingMode.perOrang
                ? 'Harga/Orang/Jam'
                : 'Harga/Jam',
            PaymentFormatters.formatCurrency(
              widget.field.pricePerHour.toDouble(),
            ),
          ),
          // Mode-specific detail rows
          if (_bookingMode == BookingMode.perOrang) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Jumlah Orang', '$_peopleCount orang'),
            if (_durationHours > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Durasi', '$_durationHours jam'),
            ],
          ] else if (_bookingMode == BookingMode.harian) ...[
            const SizedBox(height: 8),
            // Resepsi: tampilkan durasi jam tetap, bukan "jumlah hari"
            if (_isFixedHourHarian) ...[
              _buildPriceRow('Durasi', '$_fixedSessionHours Jam'),
            ] else ...[
              _buildPriceRow('Jumlah Hari', '$_durationDays hari'),
            ],
          ] else if (_bookingMode == BookingMode.perSesi) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Mode',
              '1 sesi (${widget.field.satuan ?? 'per sesi'})',
            ),
          ] else ...[
            if (_durationDays == 1 && _durationHours > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Durasi', '$_durationHours jam'),
            ],
            if (_durationDays > 1) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Jumlah Hari', '$_durationDays hari'),
            ],
          ],
          if (_baseAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Harga Normal',
              PaymentFormatters.formatCurrency(_baseAmount.toDouble()),
            ),
          ],
          if (_isOpdAccount && _opdDiscountPct > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Diskon OPD ($_opdDiscountPct%)',
              '- ${PaymentFormatters.formatCurrency((_baseAmount * _opdDiscountPct / 100).floorToDouble())}',
            ),
          ],
          const Divider(color: Colors.white54, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                _totalAmount == 0
                    ? 'GRATIS'
                    : PaymentFormatters.formatCurrency(_totalAmount.toDouble()),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _totalAmount == 0
                      ? const Color(0xFF86EFAC)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFixedBottomButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewPadding.bottom > 0 ? 8 : 16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: AnimatedGradientButton(
              text: _isProcessing ? 'Memproses...' : 'Konfirmasi Booking',
              onPressed: _isProcessing ? null : _processBooking,
              gradientColors: const [
                Color.fromARGB(255, 0, 113, 72),
                Color.fromARGB(255, 0, 117, 164),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Email Belum Diverifikasi',
                style: GoogleFonts.mulish(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          content: Text(
            'Anda perlu memverifikasi email terlebih dahulu sebelum dapat melakukan booking. Silakan cek inbox email Anda untuk link verifikasi.',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: GoogleFonts.mulish(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final error =
                    await EmailVerificationService.resendVerificationEmail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error ??
                            'Email verifikasi telah dikirim. Silakan cek inbox Anda.',
                      ),
                      backgroundColor: error == null
                          ? Colors.green
                          : Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Kirim Ulang Email',
                style: GoogleFonts.mulish(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildTimeSlotDisplay() {
    if (_selectedTimeSlot == null) return '';
    final parts = <String>[];
    if (_bookingMode == BookingMode.harian) {
      // Resepsi (fixed-hour): tampilkan jam aktual, bukan "Satu hari penuh"
      if (_isFixedHourHarian && _selectedTimeSlot != null) {
        parts.add(_selectedTimeSlot!);
      } else {
        parts.add('Satu hari penuh');
      }
      if (_durationDays > 1) parts.add('$_durationDays Hari');
    } else {
      parts.add(_selectedTimeSlot!);
      if (_durationDays > 1) parts.add('$_durationDays Hari');
      if (_bookingMode == BookingMode.perOrang && _peopleCount > 1) {
        parts.add('$_peopleCount Orang');
      }
    }
    return parts.join('  •  ');
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
}
