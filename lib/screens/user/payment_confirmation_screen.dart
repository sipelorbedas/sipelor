import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/payment_confirmation_data.dart';
import '../../services/supabase_service.dart';
import '../../utils/payment_formatters.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/upload_proof_section.dart';
import 'home_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final PaymentConfirmationData paymentData;
  final String bookingId;
  final String bookingUuid; // UUID for cancellation

  const PaymentConfirmationScreen({
    super.key,
    required this.paymentData,
    required this.bookingId,
    required this.bookingUuid,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isUploading = false;
  bool _isConfirming = false;
  bool _hasUploadedProof = false;
  bool _hasExpired = false;

  // OPD free booking: jika total = 0, tidak perlu upload bukti
  bool get _isOpdFreeBooking => widget.paymentData.isOpdFreeBooking;

  void _handleSelectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        setState(() {
          _selectedFileName = file.name;
          _selectedFilePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal memilih file: $e');
      }
    }
  }

  void _handleUpload() async {
    if (_selectedFilePath == null || _selectedFileName == null) {
      _showErrorDialog('Silakan pilih file terlebih dahulu');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload payment proof to Supabase Storage
      final publicUrl = await SupabaseService.uploadPaymentProof(
        bookingId: widget.bookingId,
        filePath: _selectedFilePath!,
        fileName: _selectedFileName!,
      );

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        _showErrorDialog('Gagal mengupload bukti pembayaran: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Bukti Transfer sudah di Upload',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Set state to hide upload button
                      setState(() {
                        _hasUploadedProof = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  message,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyAccountNumber() {
    Clipboard.setData(ClipboardData(text: widget.paymentData.accountNumber));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Nomor rekening berhasil disalin',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 0, 113, 72),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleConfirmPayment() async {
    setState(() {
      _isConfirming = true;
    });

    try {
      // Show confirmation popup dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon with gradient background
                    Container(
                      width: 80,
                      height: 80,
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
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      'Pembayaran Dikonfirmasi',
                      style: GoogleFonts.mulish(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      _isOpdFreeBooking
                          ? 'Lapangan berhasil dikonfirmasi! Booking Anda telah tercatat dan jadwal sudah diblokir.'
                          : 'Pembayaran Anda sedang diverifikasi oleh admin. Cek halaman Pemesanan untuk status terbaru.',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // OK Button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 0, 113, 72),
                              Color.fromARGB(255, 0, 117, 164),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: Text(
                          'Kembali ke Beranda',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        
        // Navigate to Home Screen after dialog is dismissed
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
            (route) => false,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
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
                      // Venue Information Section
                      _buildVenueInfoSection(),
                      const SizedBox(height: 20),

                      // OPD free: tampilkan info konfirmasi otomatis
                      // Non-OPD: tampilkan section upload bukti
                      if (_isOpdFreeBooking)
                        _buildOpdFreeConfirmSection()
                      else
                        _buildUploadSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom section - Fixed at bottom
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackPress() async {
    // OPD free booking: dapat keluar bebas (sudah auto-confirmed)
    if (_isOpdFreeBooking) {
      Navigator.pop(context);
      return;
    }

    // If payment proof has been uploaded, allow going back directly
    if (_hasUploadedProof) {
      Navigator.pop(context);
      return;
    }

    // If not uploaded, inform user that booking stays pending (NOT cancelled)
    final shouldGoBack = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Pembayaran Belum Selesai',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message — booking stays PENDING, NOT cancelled
                Text(
                  'Anda belum upload bukti pembayaran. Pemesanan Anda akan tetap tersimpan sebagai Pending dan bisa dilanjutkan dari halaman Pemesanan.\n\nSelesaikan pembayaran sebelum batas waktu habis.',
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Upload Dulu',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Nanti Saja',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Keluar tanpa membatalkan booking — booking tetap PENDING di Pemesanan
    if (shouldGoBack == true && mounted) {
      if (kDebugMode) {
        print(
          '✅ [PaymentConfirmation] User exited — booking ${widget.bookingUuid} remains PENDING. '
          'Will be auto-cancelled by BookingExpirationService after 30 min if no proof uploaded.',
        );
      }
      Navigator.pop(context);
    }
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
            onTap: _handleBackPress,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),

          // Center content
          Expanded(
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
                    Icons.article_outlined,
                    size: 12,
                    color: Color.fromARGB(255, 0, 113, 72),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Konfirmasi Pembayaran',
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

  Widget _buildVenueInfoSection() {
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
            'Informasi Pembayaran',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Detail booking anda',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 15),

          // Booking details with labels
          _buildInfoRow('Nama Pemesan', widget.paymentData.userName),
          const SizedBox(height: 12),
          _buildInfoRow('Venue', widget.paymentData.venueName),
          const SizedBox(height: 12),
          if (widget.paymentData.venueType != null) ...[
            _buildInfoRow('Jenis Venue', widget.paymentData.venueType!),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            'Tanggal & Jam Booking',
            PaymentFormatters.extractDate(widget.paymentData.bookingDateTime),
          ),

          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: Colors.grey[300]),

          const SizedBox(height: 20),

          // OPD gratis: rekening tidak perlu ditampilkan
          if (_isOpdFreeBooking) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gratis — tidak diperlukan transfer pembayaran',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[

          // Payment account - BJB (without QR button)
          Text(
            'Rekening Pembayaran',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.screenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo_bjb.png',
                      width: 50,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bank BJB',
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3F414E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Copyable account number
                GestureDetector(
                  onTap: () => _copyAccountNumber(),
                  onLongPress: () => _copyAccountNumber(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.paymentData.accountNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3F414E),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Icon(
                          Icons.copy,
                          size: 20,
                          color: const Color.fromARGB(255, 0, 113, 72),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Tekan untuk menyalin nomor rekening',
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3F414E).withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'a.n. ${widget.paymentData.accountName}',
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3F414E).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ], // end else (non-OPD payment section)
        ],
      ),
    );
  }

  /// Section khusus untuk OPD booking gratis (diskon 100%)
  Widget _buildOpdFreeConfirmSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, size: 36, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(
            'Booking Dikonfirmasi Otomatis',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.green[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sebagai akun OPD dengan diskon 100%, booking Anda langsung dikonfirmasi '
            'tanpa perlu membayar atau mengupload bukti pembayaran.',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.green[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (widget.paymentData.opdName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏛️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.paymentData.opdName!,
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
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
            'Bukti Pembayaran',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _hasUploadedProof 
                ? 'Bukti pembayaran telah diupload'
                : 'Upload bukti transfer anda di sini',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _hasUploadedProof 
                  ? Colors.green 
                  : const Color(0xFF3F414E),
            ),
          ),
          const SizedBox(height: 15),
          if (!_hasUploadedProof)
            UploadProofSection(
              selectedFileName: _selectedFileName,
              onSelectFile: _handleSelectFile,
              onUpload: _handleUpload,
              isUploading: _isUploading,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bukti pembayaran berhasil diupload',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (_selectedFileName != null)
                    Text(
                      _selectedFileName!,
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3F414E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
        ],
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
              // OPD gratis tidak perlu countdown (sudah dikonfirmasi)
              if (!_isOpdFreeBooking)
              CountdownTimer(
                deadline: widget.paymentData.paymentDeadline,
                onExpired: () async {
                  if (mounted) {
                    setState(() {
                      _hasExpired = true;
                    });
                    
                    // Delete incomplete booking immediately when timer expires
                    // (booking_expiration_service also handles this in background)
                    try {
                      if (kDebugMode) print('⏰ [PaymentConfirmation] Timer expired, deleting incomplete booking: ${widget.bookingUuid}');
                      await SupabaseService.deleteIncompleteBooking(widget.bookingUuid);
                      if (kDebugMode) print('✅ [PaymentConfirmation] Expired incomplete booking deleted, slot is now available');
                    } catch (e) {
                      if (kDebugMode) print('⚠️ [PaymentConfirmation] Error deleting expired booking: $e');
                      // Continue with dialog even if deletion fails
                      // (background service will handle it)
                    }
                    
                    // Show expiration dialog
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Warning Icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.timer_off,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Title
                                  Text(
                                    'Waktu Pembayaran Habis',
                                    style: GoogleFonts.mulish(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Message
                                  Text(
                                    'Maaf, waktu pembayaran 30 menit telah habis. Pemesanan Anda telah dibatalkan dan slot sudah tersedia kembali untuk pengguna lain.',
                                    style: GoogleFonts.mulish(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.secondaryDark,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // OK Button
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const HomeScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            offset: const Offset(0, 4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Kembali ke Beranda',
                                        style: GoogleFonts.mulish(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  }
                },
              ),
              if (!_isOpdFreeBooking) const SizedBox(height: 15),
              // Baris diskon OPD (hanya tampil jika ada diskon)
              if (widget.paymentData.discountPercentage > 0 && !_isOpdFreeBooking) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harga Normal',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF211A2C).withOpacity(0.6),
                      ),
                    ),
                    Text(
                      PaymentFormatters.formatCurrency(widget.paymentData.originalPrice),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF211A2C).withOpacity(0.6),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diskon OPD (${widget.paymentData.discountPercentage}%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      '- ${PaymentFormatters.formatCurrency(widget.paymentData.originalPrice - widget.paymentData.totalPrice)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
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
                  _isOpdFreeBooking
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'GRATIS',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          PaymentFormatters.formatCurrency(
                            widget.paymentData.totalPrice,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF211A2C),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 10),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3F414E).withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3F414E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    // OPD gratis: tidak perlu upload proof, langsung bisa konfirmasi
    final canConfirm = _isOpdFreeBooking || _hasUploadedProof;
    final isDisabled = _isConfirming || _hasExpired || !canConfirm;

    // Determine button text
    String buttonText;
    if (_hasExpired) {
      buttonText = 'Waktu Habis';
    } else if (_isOpdFreeBooking) {
      buttonText = 'Konfirmasi Booking Gratis';
    } else if (!_hasUploadedProof) {
      buttonText = 'Upload Bukti Pembayaran Dulu';
    } else {
      buttonText = 'Konfirmasi Pembayaran';
    }
    
    return GestureDetector(
      onTap: isDisabled ? null : _handleConfirmPayment,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDisabled
                  ? [Colors.grey, Colors.grey]
                  : [
                      const Color.fromARGB(255, 0, 113, 72),
                      const Color.fromARGB(255, 0, 117, 164),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDisabled 
                    ? Colors.grey.withOpacity(0.3)
                    : const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: _isConfirming
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 17.92,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
