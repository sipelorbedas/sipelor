import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class SecurityTipsScreen extends StatelessWidget {
  const SecurityTipsScreen({super.key});

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
          'Tips Keamanan',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          _buildHeaderCard(),
          
          const SizedBox(height: 24),
          
          // Tips Section
          _buildSectionTitle('🛡️ Lindungi Akun Anda'),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.password,
            iconColor: Colors.orange,
            title: 'Jangan Bagikan Password',
            description: 'Tim SIPELOR TIDAK AKAN PERNAH meminta password Anda melalui email, telepon, WhatsApp, atau SMS. Jangan berikan password ke siapapun.',
            importance: 'SANGAT PENTING',
          ),
          
          const SizedBox(height: 16),
          _buildTipCard(
            icon: Icons.shield_outlined,
            iconColor: const Color.fromARGB(255, 0, 113, 72),
            title: 'Gunakan Password Kuat',
            description: 'Gunakan kombinasi huruf besar, huruf kecil, angka, dan karakter khusus. Minimal 8 karakter. Contoh: Test@12345',
            importance: 'PENTING',
          ),
          
          const SizedBox(height: 16),
          _buildTipCard(
            icon: Icons.fingerprint,
            iconColor: Colors.purple,
            title: 'Aktifkan Biometric Login',
            description: 'Gunakan fingerprint atau Face ID untuk keamanan tambahan. Anda dapat mengaktifkannya di menu Pengaturan Keamanan.',
            importance: 'DISARANKAN',
          ),
          
          const SizedBox(height: 24),
          
          // Phishing Warning Section
          _buildSectionTitle('🎣 Waspadai Phishing'),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.security,
            iconColor: Colors.red,
            title: 'Download dari Sumber Resmi',
            description: 'Download aplikasi SIPELOR hanya dari Google Play Store resmi. Jangan download dari link mencurigakan atau website tidak resmi.',
            importance: 'SANGAT PENTING',
          ),
          
          const SizedBox(height: 16),
          _buildTipCard(
            icon: Icons.link_off,
            iconColor: Colors.orange.shade700,
            title: 'Hati-hati dengan Link Palsu',
            description: 'Jangan klik link mencurigakan yang mengaku dari tim SIPELOR. Pastikan selalu menggunakan aplikasi resmi untuk login.',
            importance: 'PENTING',
          ),
          
          const SizedBox(height: 24),
          
          // Contact Warning Section
          _buildSectionTitle('📞 Verifikasi Kontak'),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.verified_user,
            iconColor: Colors.blue,
            title: 'Verifikasi Identitas Penghubung',
            description: 'Jika ada yang mengaku dari tim SIPELOR dan meminta informasi pribadi, verifikasi melalui kontak resmi kami sebelum memberikan informasi apapun.',
            importance: 'PENTING',
          ),
          
          const SizedBox(height: 24),
          
          // Best Practices Section
          _buildSectionTitle('✅ Praktik Terbaik'),
          const SizedBox(height: 12),
          _buildBestPracticesList(),
          
          const SizedBox(height: 24),
          
          // Emergency Contact Card
          _buildEmergencyContactCard(context),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 0, 113, 72),
            Color.fromARGB(255, 0, 117, 164),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keamanan Akun Anda',
            style: GoogleFonts.mulish(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pelajari cara melindungi akun Anda dari ancaman keamanan dan penipuan online',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.mulish(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String importance,
  }) {
    Color importanceColor;
    Color importanceBgColor;
    
    switch (importance) {
      case 'SANGAT PENTING':
        importanceColor = Colors.red.shade700;
        importanceBgColor = Colors.red.shade50;
        break;
      case 'PENTING':
        importanceColor = Colors.orange.shade700;
        importanceBgColor = Colors.orange.shade50;
        break;
      default:
        importanceColor = Colors.blue.shade700;
        importanceBgColor = Colors.blue.shade50;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: importanceBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                importance,
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: importanceColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestPracticesList() {
    final practices = [
      '🔒 Selalu logout setelah selesai menggunakan aplikasi',
      '📱 Jangan simpan password di notes atau screenshot',
      '⏱️ Ganti password secara berkala (setiap 3-6 bulan)',
      '👁️ Periksa aktivitas login di menu keamanan',
      '🔔 Aktifkan notifikasi untuk aktivitas mencurigakan',
      '💻 Jangan login di perangkat umum atau WiFi publik',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < practices.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        practices[i],
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < practices.length - 1)
                Divider(
                  color: AppColors.borderGray.withOpacity(0.3),
                  height: 1,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.report_problem,
                  size: 24,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lapor Aktivitas Mencurigakan',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Jika Anda menemukan aktivitas mencurigakan atau seseorang yang mengaku dari tim SIPELOR meminta informasi pribadi, segera hubungi kami.',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hubungi: support@sipelor.com',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.contact_support),
              label: Text(
                'Hubungi Tim Support',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
