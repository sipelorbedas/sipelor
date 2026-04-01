import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/payment_formatters.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  Design tokens (matches website pesan.html)
// ─────────────────────────────────────────────────────────────────
const _kEmerald      = Color(0xFF00693E);
const _kNavy         = Color(0xFF1A2B4A);
const _kEmeraldPale  = Color(0xFFEAF7F0);
const _kLabelColor   = Color(0xFF9CA3AF);   // gray-400
const _kValueColor   = Color(0xFF1F2937);   // gray-800
const _kDividerColor = Color(0xFFE5E7EB);   // gray-100 dashed
const _kTearBg       = Color(0xFFF3F4F6);

const _kGradientColors = [
  Color.fromARGB(255, 0, 113, 72),
  Color.fromARGB(255, 0, 82, 158),
];

// ─────────────────────────────────────────────────────────────────
class ETicketScreen extends StatefulWidget {
  final String venueName;
  final String fieldName;
  final String bookingDateTime; // e.g. "Senin, 13 Mar 2026 | 08:00 - 10:00"
  final String bookingCode;
  final double totalAmount;
  final String? area;
  final String? userName;
  final String? userPhone;
  final String? duration;    // e.g. "2 Jam"
  final String? venueType;   // e.g. "Futsal"
  final String? peopleCount; // e.g. "8 orang" — for perOrang mode

  const ETicketScreen({
    super.key,
    required this.venueName,
    required this.fieldName,
    required this.bookingDateTime,
    required this.bookingCode,
    this.totalAmount = 0,
    this.area,
    this.userName,
    this.userPhone,
    this.duration,
    this.venueType,
    this.peopleCount,
  });

  @override
  State<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends State<ETicketScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // ── download ──────────────────────────────────────────────────
  Future<void> _downloadTicket() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Izin penyimpanan diperlukan untuk mengunduh e-tiket',
                    style: GoogleFonts.mulish()),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Mengunduh e-tiket...', style: GoogleFonts.mulish()),
              ],
            ),
            backgroundColor: _kEmerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final Uint8List? image =
          await _screenshotController.capture(pixelRatio: 3.0);
      if (image == null) throw Exception('Failed to capture ticket');

      final tempDir  = await getTemporaryDirectory();
      final fileName =
          'e_ticket_${widget.bookingCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(image);
      await Gal.putImage(filePath, album: 'SIPELOR');
      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-Tiket berhasil diunduh ke galeri',
                style: GoogleFonts.mulish()),
            backgroundColor: _kEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh e-tiket: ${e.toString()}',
                style: GoogleFonts.mulish()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── QR data ───────────────────────────────────────────────────
  String _generateQRData() {
    return jsonEncode({
      'booking_code': widget.bookingCode,
      'venue': widget.venueName,
      'field': widget.fieldName,
      'datetime': widget.bookingDateTime,
      'type': 'SIPELOR_BOOKING',
      'version': '1.0',
    });
  }

  // ── build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    Screenshot(
                      controller: _screenshotController,
                      child: _buildTicketCard(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  // ── app bar ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _kGradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'E-Tiket Anda',
                    style: GoogleFonts.mulish(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 36), // balance back button
        ],
      ),
    );
  }

  // ── main ticket card ──────────────────────────────────────────
  Widget _buildTicketCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: Column(
        children: [
          // 1 ── Gradient header with brand + stamp
          _buildTicketHeader(),

          // 2 ── White body: info rows
          _buildTicketBody(),

          // 3 ── Tear line
          _buildTearLine(),

          // 4 ── Footer: booking code + QR
          _buildTicketFooter(),
        ],
      ),
    );
  }

  // ── 1. Ticket header ──────────────────────────────────────────
  Widget _buildTicketHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _kGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + brand
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.sports_soccer_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIPELOR BEDAS',
                  style: GoogleFonts.mulish(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'DISPORA Kab. Bandung',
                  style: GoogleFonts.mulish(
                    fontSize: 10, fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.65),
                    letterSpacing: 0.8, height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // E-TIKET stamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.40), width: 1.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'E-TIKET',
              style: GoogleFonts.mulish(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Ticket body rows ───────────────────────────────────────
  Widget _buildTicketBody() {
    // Parse date & time from bookingDateTime
    final parts    = widget.bookingDateTime.split('|');
    final dateStr  = parts.isNotEmpty ? parts[0].trim() : widget.bookingDateTime;
    final timeStr  = parts.length > 1 ? parts[1].trim() : null;

    // Lapangan label
    final lapanganVal = widget.venueType != null && widget.venueType!.isNotEmpty
        ? '${widget.venueName} · ${widget.venueType}'
        : widget.venueName;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        children: [
          if (widget.userName != null) ...[
            _buildInfoRow('NAMA', widget.userName!),
          ],
          if (widget.userPhone != null) ...[
            _buildInfoRow('NO. HP', widget.userPhone!),
          ],
          _buildInfoRow('LAPANGAN', lapanganVal),
          if (widget.fieldName.isNotEmpty && widget.fieldName != widget.venueName)
            _buildInfoRow('AREA/LOKASI', widget.fieldName),
          if (widget.area != null && widget.area!.isNotEmpty)
            _buildInfoRow('WILAYAH', widget.area!),
          _buildInfoRow('TANGGAL', dateStr),
          if (timeStr != null)
            _buildInfoRow(
              'JAM',
              widget.duration != null
                  ? '$timeStr (${widget.duration})'
                  : timeStr,
            ),
          if (widget.peopleCount != null)
            _buildInfoRow('PESERTA', widget.peopleCount!),

          const SizedBox(height: 12),

          // Total payment — emerald pale box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kEmeraldPale,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _kEmerald.withOpacity(0.20), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL PEMBAYARAN',
                  style: GoogleFonts.mulish(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: _kEmerald, letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.totalAmount > 0
                      ? PaymentFormatters.formatCurrency(widget.totalAmount)
                      : 'GRATIS',
                  style: GoogleFonts.mulish(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: _kEmerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _kDividerColor, width: 1,
              style: BorderStyle.solid),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: _kLabelColor, letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.mulish(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _kValueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Tear line ─────────────────────────────────────────────
  Widget _buildTearLine() {
    const circleSize = 24.0;

    return SizedBox(
      height: circleSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gray background strip
          Positioned.fill(
            child: Container(color: _kTearBg),
          ),
          // Dashed line centered vertically
          Positioned.fill(
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
          // Left half-circle (screen-bg color = cutout illusion)
          Positioned(
            left: -circleSize / 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: circleSize, height: circleSize,
              decoration: const BoxDecoration(
                color: AppColors.screenBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right half-circle
          Positioned(
            right: -circleSize / 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: circleSize, height: circleSize,
              decoration: const BoxDecoration(
                color: AppColors.screenBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Footer: booking code + QR ─────────────────────────────
  Widget _buildTicketFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          // "Nomor Booking" label
          Text(
            'NOMOR BOOKING',
            style: GoogleFonts.mulish(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: _kLabelColor, letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          // Booking code — large, letter-spaced, navy
          Text(
            widget.bookingCode,
            style: GoogleFonts.mulish(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: _kNavy, letterSpacing: 2.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDividerColor, width: 1.5),
            ),
            child: QrImageView(
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: _kNavy,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: _kNavy,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Caption
          Text(
            'Tunjukkan e-tiket ini kepada petugas lapangan',
            style: GoogleFonts.mulish(
              fontSize: 11, fontWeight: FontWeight.w400,
              color: _kLabelColor, fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── bottom buttons ─────────────────────────────────────────────
  Widget _buildBottomButtons(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              // Kembali (outlined)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: Text(
                      'Beranda',
                      style: GoogleFonts.mulish(
                        fontSize: 14, fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kEmerald,
                      side: const BorderSide(color: _kEmerald, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Unduh (gradient)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: _kGradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _downloadTicket,
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.white, size: 18),
                      label: Text(
                        'Unduh',
                        style: GoogleFonts.mulish(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Dashed line painter for tear strip
// ─────────────────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB) // gray-300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashW = 7.0;
    const gapW  = 5.0;
    final y     = size.height / 2;
    double x    = 16; // offset from edges (past circle area)

    while (x < size.width - 16) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
