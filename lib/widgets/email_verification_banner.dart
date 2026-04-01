import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/email_verification_service.dart';

/// Persistent banner shown when email is not verified
/// Displays at the top of the screen and allows user to resend verification email
class EmailVerificationBanner extends StatelessWidget {
  final VoidCallback? onResendTap;

  const EmailVerificationBanner({
    super.key,
    this.onResendTap,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if email is already verified
    if (EmailVerificationService.isEmailVerified()) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Email Belum Diverifikasi',
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verifikasi email untuk akses penuh',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onResendTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Kirim Ulang',
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
}
