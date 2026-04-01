import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../screens/info/security_tips_screen.dart';

class SecurityWarningDialog extends StatelessWidget {
  const SecurityWarningDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SecurityWarningDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 0, 113, 72),
                      Color.fromARGB(255, 0, 117, 164),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                '🔒 Tips Keamanan',
                style: GoogleFonts.mulish(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Lindungi akun Anda dengan mengikuti panduan keamanan berikut:',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryDark,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Warning Items
              _buildWarningItem(
                icon: Icons.password,
                iconColor: Colors.orange,
                text: 'Tim SIPELOR TIDAK AKAN PERNAH meminta password Anda',
              ),
              
              const SizedBox(height: 16),
              
              _buildWarningItem(
                icon: Icons.phone_disabled,
                iconColor: Colors.red,
                text: 'Jangan bagikan password melalui email, telepon, atau WhatsApp',
              ),
              
              const SizedBox(height: 16),
              
              _buildWarningItem(
                icon: Icons.download_outlined,
                iconColor: Colors.blue,
                text: 'Download aplikasi hanya dari Play Store resmi',
              ),
              
              const SizedBox(height: 16),
              
              _buildWarningItem(
                icon: Icons.link_off,
                iconColor: Colors.purple,
                text: 'Hati-hati dengan link dan aplikasi palsu yang mengaku SIPELOR',
              ),
              
              const SizedBox(height: 24),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Simpan pesan ini untuk referensi keamanan Anda',
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecurityTipsScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 0, 113, 72),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Pelajari Lebih',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 0, 113, 72),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Mengerti',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
