import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/app_colors.dart';

class QrCodeDialog extends StatelessWidget {
  final String accountNumber;
  final String accountName;
  final String? bankName;

  const QrCodeDialog({
    super.key,
    required this.accountNumber,
    required this.accountName,
    this.bankName,
  });

  @override
  Widget build(BuildContext context) {
    // Create QR data with account information
    final qrData = '$accountNumber\n$accountName${bankName != null ? '\n$bankName' : ''}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'QR Code Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan QR code untuk melakukan pembayaran',
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryDark.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderGray,
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),

            const SizedBox(height: 24),

            // Account Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderGray,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bankName != null) ...[
                    Text(
                      bankName!,
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryDark.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    accountNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'a.n. $accountName',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
