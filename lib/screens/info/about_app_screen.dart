import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
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
          'Tentang Aplikasi',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: 24),

            // Description Section
            _buildSection(
              context,
              icon: Icons.info_outline,
              title: 'Apa itu SIPELOR?',
              content:
                  'SIPELOR (Sistem Informasi Penyewaan Lapangan Olahraga) adalah '
                  'platform digital yang memudahkan masyarakat Kabupaten Bandung untuk '
                  'melakukan booking lapangan olahraga secara online, mudah, cepat, dan terpercaya.\n\n'
                  'Aplikasi ini dikembangkan untuk meningkatkan pelayanan publik dalam '
                  'penyewaan fasilitas olahraga di wilayah Kabupaten Bandung.',
            ),

            const SizedBox(height: 16),

            // Features Section
            _buildFeaturesSection(context),

            const SizedBox(height: 16),

            // How to Use Section
            _buildHowToUseSection(context),

            const SizedBox(height: 16),

            // Benefits Section
            _buildBenefitsSection(context),

            const SizedBox(height: 16),

            // Contact Section
            _buildContactSection(context),

            const SizedBox(height: 16),

            // App Info Section
            _buildAppInfoSection(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 0, 113, 72),
            Color.fromARGB(255, 0, 117, 164),
          ],
        ),
      ),
      child: Column(
        children: [
          // App Logo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/sipelor.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App Name
          Text(
            'SIPELOR BEDAS',
            style: GoogleFonts.mulish(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // App Subtitle
          Text(
            'Sistem Informasi Penyewaan Lapangan Olahraga',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Kabupaten Bandung',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      0,
                      113,
                      72,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: const Color.fromARGB(255, 0, 113, 72),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.mulish(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.search,
        title: 'Browse Lapangan',
        description:
            'Cari dan temukan lapangan olahraga yang sesuai kebutuhan Anda',
      ),
      _FeatureItem(
        icon: Icons.calendar_today,
        title: 'Booking Online',
        description: 'Pesan lapangan secara online kapan saja dan dimana saja',
      ),
      _FeatureItem(
        icon: Icons.payment,
        title: 'Pembayaran Mudah',
        description: 'Upload bukti pembayaran dan tunggu verifikasi admin',
      ),
      _FeatureItem(
        icon: Icons.qr_code,
        title: 'E-Ticket',
        description: 'Dapatkan e-ticket dengan QR code untuk validasi',
      ),
      _FeatureItem(
        icon: Icons.star,
        title: 'Review & Rating',
        description:
            'Berikan penilaian dan ulasan setelah menggunakan lapangan',
      ),
      _FeatureItem(
        icon: Icons.history,
        title: 'Riwayat Booking',
        description: 'Lihat semua riwayat booking Anda dengan lengkap',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      0,
                      113,
                      72,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.featured_play_list,
                    size: 24,
                    color: Color.fromARGB(255, 0, 113, 72),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Fitur Utama',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map((feature) => _buildFeatureItem(feature)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(_FeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              feature.icon,
              size: 20,
              color: const Color.fromARGB(255, 0, 113, 72),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseSection(BuildContext context) {
    final steps = [
      _StepItem(
        number: 1,
        title: 'Buat Akun',
        description: 'Daftar menggunakan email dan buat password',
      ),
      _StepItem(
        number: 2,
        title: 'Pilih Lapangan',
        description: 'Browse dan pilih lapangan yang Anda inginkan',
      ),
      _StepItem(
        number: 3,
        title: 'Pilih Jadwal',
        description: 'Tentukan tanggal dan waktu booking',
      ),
      _StepItem(
        number: 4,
        title: 'Lakukan Pembayaran',
        description: 'Upload bukti transfer pembayaran',
      ),
      _StepItem(
        number: 5,
        title: 'Tunggu Verifikasi',
        description: 'Admin akan memverifikasi pembayaran Anda',
      ),
      _StepItem(
        number: 6,
        title: 'Download E-Ticket',
        description: 'Dapatkan e-ticket dengan QR code',
      ),
      _StepItem(
        number: 7,
        title: 'Datang & Main',
        description: 'Tunjukkan e-ticket saat datang ke lapangan',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      0,
                      117,
                      164,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 24,
                    color: Color.fromARGB(255, 0, 117, 164),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cara Menggunakan',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...steps.map((step) => _buildStepItem(step, steps.length)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(_StepItem step, int totalSteps) {
    final isLast = step.number == totalSteps;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 113, 72),
                    Color.fromARGB(255, 0, 117, 164),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${step.number}',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final benefits = [
      _BenefitItem(
        icon: Icons.timer,
        title: 'Hemat Waktu',
        description: 'Booking cepat tanpa harus datang langsung',
      ),
      _BenefitItem(
        icon: Icons.verified_user,
        title: 'Terpercaya',
        description: 'Dikelola oleh DISPORA Kabupaten Bandung',
      ),
      _BenefitItem(
        icon: Icons.phone_android,
        title: 'Praktis',
        description: 'Akses dari smartphone kapan saja',
      ),
      _BenefitItem(
        icon: Icons.receipt_long,
        title: 'Transparan',
        description: 'Harga jelas dan riwayat lengkap',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      0,
                      113,
                      72,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.thumb_up_outlined,
                    size: 24,
                    color: Color.fromARGB(255, 0, 113, 72),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Keuntungan',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: benefits.length,
              itemBuilder: (context, index) {
                return _buildBenefitCard(benefits[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard(_BenefitItem benefit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            benefit.icon,
            size: 32,
            color: const Color.fromARGB(255, 0, 113, 72),
          ),
          const SizedBox(height: 12),
          Text(
            benefit.title,
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            benefit.description,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Butuh Bantuan?',
              style: GoogleFonts.mulish(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hubungi kami untuk pertanyaan atau bantuan',
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildContactButton(
              icon: Icons.phone,
              label: '(022) 1234-5678',
              onTap: () {
                // TODO: Open phone dialer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur telepon akan segera tersedia'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildContactButton(
              icon: Icons.email,
              label: 'dispora@bandungkab.go.id',
              onTap: () {
                // TODO: Open email
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur email akan segera tersedia'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildContactButton(
              icon: Icons.public,
              label: 'www.dispora.bandungkab.go.id',
              onTap: () {
                // TODO: Open website
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur website akan segera tersedia'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildInfoRow('Versi Aplikasi', '1.0.0'),
            const Divider(height: 24),
            _buildInfoRow('Developer', 'DISPORA Kabupaten Bandung'),
            const Divider(height: 24),
            _buildInfoRow('Tahun', '2026'),
            const SizedBox(height: 20),
            Text(
              '© 2026 SIPELOR BEDAS\nDinas Pemuda dan Olahraga\nKabupaten Bandung',
              style: GoogleFonts.mulish(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryDark,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

// Helper classes for data
class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _StepItem {
  final int number;
  final String title;
  final String description;

  _StepItem({
    required this.number,
    required this.title,
    required this.description,
  });
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
