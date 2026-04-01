import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/payment_success_data.dart';
import '../../utils/payment_formatters.dart';
import 'e_ticket_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentSuccessData successData;

  const PaymentSuccessScreen({
    super.key,
    required this.successData,
  });

  void _handleViewTicket(BuildContext context) {
    // Navigate to e-ticket screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ETicketScreen(
          venueName: successData.venueName,
          fieldName: successData.fieldName,
          bookingDateTime:
              '${successData.bookingDate} | ${successData.bookingTime}',
          bookingCode: successData.bookingCode,
          totalAmount: successData.totalAmount,
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
            // Header - same style as Order Screen
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Success Card
                    _buildSuccessCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom button
            _buildBottomButton(context),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: Color.fromARGB(255, 0, 113, 72),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Pembayaran Berhasil',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
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
        children: [
          // Large check icon with circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 113, 72),
                  Color.fromARGB(255, 0, 117, 164),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 30,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Title
          Text(
            'Pembayaran Venue Berhasil',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 15),
          
          // Booking details section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label
              Text(
                'Data Sewa Venue:',
                style: GoogleFonts.mulish(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF3F414E),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Details rows
              _buildDetailRow('Kode Booking', successData.bookingCode),
              const SizedBox(height: 8),
              _buildDetailRow('Tanggal', successData.bookingDate),
              const SizedBox(height: 8),
              _buildDetailRow('Waktu', successData.bookingTime),
              const SizedBox(height: 8),
              _buildDetailRow('Nama Venue', successData.venueName),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFDFDFDF),
          ),
          
          const SizedBox(height: 15),
          
          // Payment method
          _buildDetailRow('Metode Pembayaran', successData.paymentMethod),
          
          const SizedBox(height: 15),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFDFDFDF),
          ),
          
          const SizedBox(height: 15),
          
          // Total amount section with gradient background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Biaya',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  PaymentFormatters.formatCurrency(successData.totalAmount),
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3F414E),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
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
          child: GestureDetector(
            onTap: () => _handleViewTicket(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 113, 72),
                    Color.fromARGB(255, 0, 117, 164),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Lihat E-Tiket',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
