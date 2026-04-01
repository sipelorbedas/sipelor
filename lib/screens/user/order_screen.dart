import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/animated_gradient_button.dart';
import '../../widgets/booking_date_time_sheet.dart';
import '../../widgets/payment_method_sheet.dart';
import '../../models/payment_confirmation_data.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late DateTime _selectedDate;
  String _selectedTime = '';
  String _selectedPaymentMethod = '';

  @override
  void initState() {
    super.initState();
    // Set to today's date
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _showDateTimePicker() {
    // Note: order_screen.dart needs a fieldId to work properly
    // This screen appears to be a demo/mock screen
    // For now, we'll use a placeholder fieldId
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: BookingDateTimeSheet(
          initialDate: _selectedDate,
          fieldId: 'demo-field-id', // Placeholder for demo screen
          onConfirm: (date, time, _, __) {
            setState(() {
              _selectedDate = date;
              _selectedTime = time;
            });
          },
        ),
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: PaymentMethodSheet(
          initialMethod: _selectedPaymentMethod.isNotEmpty
              ? _selectedPaymentMethod
              : null,
          onConfirm: (method) {
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Data Pesanan Section
                    _buildDataPesananSection(),
                    const SizedBox(height: 30),

                    // Pemesan Section
                    _buildPemesanSection(),
                    const SizedBox(height: 30),

                    // Pembayaran Section
                    _buildPembayaranSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 113, 72),
            Color.fromARGB(255, 0, 117, 164),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/icons/arrow_left.svg',
                width: 18,
                height: 11,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Center content
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/menu_icon.svg',
                  width: 18,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pesanan Anda',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Spacer to balance the back button
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _buildDataPesananSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pesanan',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ringkasan pesanan lapangan anda',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.screenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3F414E),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Lapangan 2',
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3F414E),
                        ),
                      ),
                      if (_selectedTime.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          _selectedTime,
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 0, 113, 72),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildUbahButton(),
              ],
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
            blurRadius: 8,
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
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Kami akan mengirimkan semua e-tiket/voucher dari pesanan ini kepada kontak yang diisi di profil kamu',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.screenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alfan',
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3F414E),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '+62812345678',
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3F414E),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildUbahButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPembayaranSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pembayaran',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Lakukan pembayaran anda dengan mudah',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.screenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_selectedPaymentMethod.isNotEmpty &&
                    _getPaymentMethodLogo(
                      _selectedPaymentMethod,
                    ).isNotEmpty) ...[
                  SizedBox(
                    width: 70,
                    height: 35,
                    child: Center(
                      child: Image.asset(
                        _getPaymentMethodLogo(_selectedPaymentMethod),
                        width: _selectedPaymentMethod == 'QRIS'
                            ? 60
                            : _selectedPaymentMethod == 'BJB'
                            ? 70
                            : 50,
                        height: _selectedPaymentMethod == 'QRIS'
                            ? 35
                            : _selectedPaymentMethod == 'BJB'
                            ? 35
                            : 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: _selectedPaymentMethod == 'QRIS'
                              ? 60
                              : _selectedPaymentMethod == 'BJB'
                              ? 70
                              : 50,
                          height: _selectedPaymentMethod == 'QRIS'
                              ? 35
                              : _selectedPaymentMethod == 'BJB'
                              ? 35
                              : 20,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPaymentMethod.isNotEmpty
                            ? _selectedPaymentMethod
                            : 'Pilih Metode Pembayaran',
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3F414E),
                        ),
                      ),
                      if (_selectedPaymentMethod.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getPaymentMethodDescription(_selectedPaymentMethod),
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF3F414E).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildUbahButtonPayment(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodDescription(String method) {
    if (method == 'QRIS') {
      return 'Pembayaran dengan scan QR';
    } else if (['OVO', 'DANA', 'GOPAY', 'LINKAJA'].contains(method)) {
      return 'Transfer E-Wallet';
    } else {
      return 'Transfer Bank';
    }
  }

  String _getPaymentMethodLogo(String method) {
    final Map<String, String> logos = {
      'QRIS': 'assets/images/QRIS.png',
      'BJB': 'assets/images/logo_bjb.png',
      'BRI': 'assets/images/logo_bri.png',
      'Mandiri': 'assets/images/logo_mandiri.png',
      'OVO': 'assets/images/logo_ovo.png',
      'DANA': 'assets/images/logo_dana.png',
      'GOPAY': 'assets/images/logo_gopay.png',
      'LINKAJA': 'assets/images/logo_linkaja.png',
    };
    return logos[method] ?? '';
  }

  PaymentMethod _mapToPaymentMethod(String method) {
    switch (method) {
      case 'BJB':
        return PaymentMethod.bjb;
      case 'Mandiri':
        return PaymentMethod.mandiri;
      case 'BRI':
        return PaymentMethod.bri;
      case 'GOPAY':
        return PaymentMethod.gopay;
      case 'OVO':
        return PaymentMethod.ovo;
      case 'QRIS':
        return PaymentMethod.qris;
      default:
        return PaymentMethod.bjb;
    }
  }

  void _handlePayment() {
    // Validate that payment method is selected
    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan pilih metode pembayaran terlebih dahulu',
            style: GoogleFonts.mulish(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that date and time is selected
    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan pilih tanggal dan waktu terlebih dahulu',
            style: GoogleFonts.mulish(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
  }

  Widget _buildUbahButton() {
    return GestureDetector(
      onTap: _showDateTimePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 113, 72),
              Color.fromARGB(255, 0, 117, 164),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Ubah',
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUbahButtonPayment() {
    return GestureDetector(
      onTap: _showPaymentMethodPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 113, 72),
              Color.fromARGB(255, 0, 117, 164),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Ubah',
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Harga Total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF211A2C),
                    ),
                  ),
                  Text(
                    'Rp. 300.000',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF211A2C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedGradientButton(
                text: 'Pembayaran',
                onPressed: _handlePayment,
                gradientColors: const [
                  Color.fromARGB(255, 0, 113, 72),
                  Color.fromARGB(255, 0, 117, 164),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
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

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    return '$dayName, ${date.day} $monthName ${date.year}';
  }
}
