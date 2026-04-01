import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

/// Services Agreement screen
/// Displays the services agreement and terms of using SIPELOR BEDAS
class ServicesAgreementScreen extends StatelessWidget {
  const ServicesAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: AppBar(
        title: Text(
          'Perjanjian Layanan',
          style: GoogleFonts.mulish(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'PERJANJIAN LAYANAN SIPELOR BEDAS',
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistem Pemesanan Lapangan Olahraga\nDinas Pemuda dan Olahraga Kabupaten Bandung',
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Sections
            _buildSection(
              title: '1. Definisi Layanan',
              content:
                  'SIPELOR BEDAS ("Layanan") adalah aplikasi pemesanan lapangan olahraga yang dikelola oleh '
                  'Dinas Pemuda dan Olahraga (DISPORA) Kabupaten Bandung. Layanan ini menyediakan platform untuk:\n\n'
                  '• Pencarian dan browsing fasilitas olahraga\n'
                  '• Pemesanan lapangan olahraga secara online\n'
                  '• Pembayaran dan verifikasi booking\n'
                  '• E-ticket dan QR code untuk akses venue\n'
                  '• Review dan rating fasilitas\n'
                  '• Komunikasi dengan pengelola venue',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '2. Persetujuan Pengguna',
              content:
                  'Dengan mendaftar dan menggunakan Layanan ini, Anda ("Pengguna") menyatakan bahwa:\n\n'
                  '• Anda telah membaca dan memahami Perjanjian Layanan ini\n'
                  '• Anda menyetujui semua ketentuan yang tercantum\n'
                  '• Anda berusia minimal 13 tahun atau memiliki izin orang tua/wali\n'
                  '• Informasi yang Anda berikan adalah akurat dan lengkap\n'
                  '• Anda bertanggung jawab penuh atas penggunaan akun Anda',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '3. Hak dan Kewajiban Pengguna',
              content:
                  'Sebagai Pengguna, Anda berhak untuk:\n\n'
                  '• Mengakses dan menggunakan Layanan sesuai ketentuan\n'
                  '• Melakukan booking lapangan yang tersedia\n'
                  '• Menerima konfirmasi dan e-ticket booking\n'
                  '• Memberikan review dan rating\n'
                  '• Mengajukan keluhan atau bantuan\n\n'
                  'Anda berkewajiban untuk:\n\n'
                  '• Memberikan informasi yang benar dan valid\n'
                  '• Menjaga kerahasiaan akun dan password\n'
                  '• Melakukan pembayaran tepat waktu\n'
                  '• Menggunakan fasilitas sesuai aturan venue\n'
                  '• Tidak menyalahgunakan Layanan\n'
                  '• Menghormati pengguna lain dan pengelola venue',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '4. Ketentuan Pemesanan (Booking)',
              content:
                  'Proses booking mencakup:\n\n'
                  '• Pemilihan venue, lapangan, tanggal, dan waktu\n'
                  '• Konfirmasi detail dan total pembayaran\n'
                  '• Upload bukti pembayaran yang valid\n'
                  '• Menunggu verifikasi dari admin/pengelola\n'
                  '• Menerima e-ticket setelah pembayaran diverifikasi\n\n'
                  'Ketentuan khusus:\n\n'
                  '• Booking bersifat sementara hingga pembayaran diverifikasi\n'
                  '• Verifikasi pembayaran memerlukan waktu maksimal 1x24 jam\n'
                  '• Booking otomatis dibatalkan jika tidak ada pembayaran dalam 3 jam\n'
                  '• Email verifikasi wajib sebelum dapat melakukan booking\n'
                  '• Satu pengguna dapat memiliki maksimal 3 booking aktif',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '5. Ketentuan Pembayaran',
              content:
                  'Pembayaran booking dilakukan dengan ketentuan:\n\n'
                  '• Metode: Transfer bank ke rekening yang ditentukan\n'
                  '• Bukti transfer harus diunggah dalam format JPG/PNG/PDF\n'
                  '• Total pembayaran sudah termasuk biaya administrasi (jika ada)\n'
                  '• Pembayaran harus sesuai dengan nominal yang tertera\n'
                  '• Bukti transfer palsu/manipulasi akan dikenakan sanksi\n'
                  '• Pembayaran yang sudah diverifikasi tidak dapat dikembalikan (lihat kebijakan pembatalan)',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '6. Kebijakan Pembatalan dan Pengembalian Dana',
              content:
                  'Pembatalan oleh Pengguna:\n\n'
                  '• Lebih dari 48 jam sebelum waktu booking: Pengembalian 100%\n'
                  '• 24-48 jam sebelum waktu booking: Pengembalian 75%\n'
                  '• 12-24 jam sebelum waktu booking: Pengembalian 50%\n'
                  '• Kurang dari 12 jam: Tidak ada pengembalian dana\n\n'
                  'Pembatalan oleh Pengelola/Admin:\n\n'
                  '• Karena maintenance venue: Pengembalian 100%\n'
                  '• Force majeure (bencana alam, dll): Pengembalian 100%\n'
                  '• Kesalahan sistem: Pengembalian 100% + kompensasi\n\n'
                  'Proses pengembalian dana:\n\n'
                  '• Diproses dalam 3-7 hari kerja\n'
                  '• Dikembalikan ke rekening yang sama dengan pembayaran\n'
                  '• Notifikasi dikirim via email dan aplikasi',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '7. E-Ticket dan QR Code',
              content:
                  'Setelah pembayaran diverifikasi, Pengguna menerima:\n\n'
                  '• E-ticket digital dengan QR code unik\n'
                  '• Dapat diakses melalui aplikasi atau email\n'
                  '• Harus ditunjukkan saat check-in di venue\n'
                  '• Tidak dapat dipindahtangankan tanpa persetujuan\n'
                  '• QR code hanya valid untuk satu kali scan\n'
                  '• Screenshot e-ticket tetap valid',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '8. Review dan Rating',
              content:
                  'Pengguna dapat memberikan review setelah booking selesai:\n\n'
                  '• Rating: 1-5 bintang\n'
                  '• Komentar: maksimal 500 karakter\n'
                  '• Review harus sopan dan relevan\n'
                  '• Tidak boleh mengandung SARA, spam, atau konten ilegal\n'
                  '• Review yang melanggar dapat dihapus tanpa pemberitahuan\n'
                  '• Pengelola dapat memberikan tanggapan atas review',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '9. Keamanan dan Privasi',
              content:
                  'SIPELOR BEDAS menerapkan langkah keamanan berikut:\n\n'
                  '• Enkripsi data end-to-end (SSL/TLS)\n'
                  '• Password hashing dengan algoritma aman\n'
                  '• Penyimpanan data terenkripsi (AES-256)\n'
                  '• Biometric authentication (fingerprint/face ID)\n'
                  '• Rate limiting untuk mencegah brute force\n'
                  '• Auto-logout setelah 15 menit tidak aktif\n'
                  '• Monitoring dan audit logging\n\n'
                  'Untuk detail privasi, lihat Kebijakan Privasi kami.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '10. Larangan Penggunaan',
              content:
                  'Pengguna DILARANG untuk:\n\n'
                  '• Menggunakan Layanan untuk tujuan ilegal\n'
                  '• Menyalahgunakan atau memanipulasi sistem\n'
                  '• Melakukan booking palsu atau spam\n'
                  '• Mengakses akun pengguna lain tanpa izin\n'
                  '• Reverse engineering atau decompile aplikasi\n'
                  '• Menggunakan bot atau automated tools\n'
                  '• Mengirim malware, virus, atau kode berbahaya\n'
                  '• Mengganggu atau merusak server dan infrastruktur\n\n'
                  'Pelanggaran akan dikenakan sanksi berupa peringatan, penangguhan, atau penghapusan akun permanen.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '11. Batasan Tanggung Jawab',
              content:
                  'SIPELOR BEDAS dan DISPORA TIDAK bertanggung jawab atas:\n\n'
                  '• Kualitas fasilitas dan layanan venue (tanggungan pengelola venue)\n'
                  '• Cedera atau kerugian yang terjadi di venue\n'
                  '• Kehilangan barang pribadi di venue\n'
                  '• Gangguan layanan karena force majeure\n'
                  '• Kesalahan informasi yang diberikan venue\n'
                  '• Kerugian akibat penggunaan Layanan oleh pihak ketiga yang tidak sah\n\n'
                  'Layanan disediakan "as is" tanpa jaminan tersurat atau tersirat.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '12. Perubahan Layanan dan Perjanjian',
              content:
                  'DISPORA berhak untuk:\n\n'
                  '• Mengubah, menambah, atau menghapus fitur Layanan\n'
                  '• Memperbarui Perjanjian Layanan ini sewaktu-waktu\n'
                  '• Menangguhkan Layanan untuk maintenance\n'
                  '• Menghentikan Layanan dengan pemberitahuan sebelumnya\n\n'
                  'Perubahan akan dinotifikasikan melalui aplikasi atau email. '
                  'Penggunaan Layanan setelah perubahan berarti Anda menyetujui perubahan tersebut.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '13. Penyelesaian Sengketa',
              content:
                  'Setiap sengketa atau perselisihan akan diselesaikan melalui:\n\n'
                  '• Musyawarah antara Pengguna dan DISPORA\n'
                  '• Mediasi jika diperlukan\n'
                  '• Jalur hukum sebagai opsi terakhir\n\n'
                  'Perjanjian ini diatur oleh hukum Republik Indonesia. '
                  'Pengadilan yang berwenang adalah Pengadilan Negeri Kabupaten Bandung.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '14. Kontak dan Dukungan',
              content:
                  'Untuk bantuan, pertanyaan, atau keluhan:\n\n'
                  'Email: support@sipelor.app\n'
                  'Telepon: (022) 1234-5678\n'
                  'WhatsApp: +62 812-3456-7890\n'
                  'Alamat: Dinas Pemuda dan Olahraga Kabupaten Bandung\n'
                  'Jl. Raya Soreang, Kabupaten Bandung, Jawa Barat\n\n'
                  'Jam Layanan: Senin - Jumat, 08:00 - 16:00 WIB',
            ),
            const SizedBox(height: 24),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Berlaku: 28 Januari 2026',
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi: 1.0',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dengan menggunakan SIPELOR BEDAS, Anda telah membaca, memahami, dan menyetujui seluruh isi Perjanjian Layanan ini.',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryDark,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
