import 'package:flutter/material.dart';
import '../../widgets/legal_document_template.dart';

/// Terms of Service screen — legal review styled document
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _sections = [
    LegalSection(
      title: 'Penerimaan Syarat',
      content:
          'Dengan mengunduh, menginstal, mendaftar, atau menggunakan aplikasi SIPELOR BEDAS, '
          'Anda menyatakan telah membaca, memahami, dan menyetujui untuk terikat dengan Syarat '
          'dan Ketentuan ini serta Kebijakan Privasi kami.\n\n'
          'Jika Anda tidak menyetujui salah satu ketentuan yang tercantum, harap segera menghentikan '
          'penggunaan aplikasi ini.',
    ),
    LegalSection(
      title: 'Kelayakan Pengguna',
      content:
          'Untuk menggunakan aplikasi ini secara sah, Anda harus memenuhi persyaratan berikut:\n\n'
          '• Berusia minimal 13 tahun, atau memiliki izin tertulis dari orang tua/wali\n'
          '• Memiliki kapasitas hukum yang cukup untuk mengikat perjanjian\n'
          '• Menyediakan informasi pendaftaran yang akurat, lengkap, dan terkini\n'
          '• Menjaga kerahasiaan dan keamanan akun serta kata sandi Anda\n'
          '• Bertanggung jawab penuh atas seluruh aktivitas yang terjadi pada akun Anda',
    ),
    LegalSection(
      title: 'Penggunaan Layanan',
      content:
          'Dengan menggunakan layanan ini, Anda setuju untuk:\n\n'
          '• Menggunakan aplikasi hanya untuk tujuan yang sah dan sesuai peraturan\n'
          '• Tidak menggunakan aplikasi untuk aktivitas ilegal atau merugikan pihak lain\n'
          '• Tidak mencoba mengakses sistem, data, atau akun tanpa otorisasi\n'
          '• Tidak mengganggu, merusak, atau membebani infrastruktur layanan\n'
          '• Tidak menyebarkan konten berbahaya, menyesatkan, atau melanggar hukum\n'
          '• Mematuhi seluruh hukum, peraturan, dan kebijakan yang berlaku di Indonesia',
    ),
    LegalSection(
      title: 'Ketentuan Booking',
      content:
          'Proses pemesanan lapangan mencakup ketentuan berikut:\n\n'
          '• Pemilihan venue, lapangan, tanggal, dan slot waktu\n'
          '• Konfirmasi detail booking dan nominal pembayaran\n'
          '• Upload bukti pembayaran yang valid dalam format JPG/PNG/PDF\n'
          '• Menunggu verifikasi dari admin/pengelola (maks. 1×24 jam kerja)\n'
          '• Menerima e-ticket dengan QR code setelah pembayaran terverifikasi\n\n'
          'Catatan penting:\n\n'
          '• Booking berstatus sementara hingga pembayaran diverifikasi\n'
          '• Booking otomatis dibatalkan jika tidak ada pembayaran dalam 3 jam\n'
          '• Verifikasi email wajib diselesaikan sebelum dapat melakukan booking\n'
          '• Satu pengguna dapat memiliki maksimal 3 booking aktif secara bersamaan',
    ),
    LegalSection(
      title: 'Pembatalan dan Pengembalian Dana',
      content:
          'Kebijakan pembatalan oleh pengguna:\n\n'
          '• Lebih dari 48 jam sebelum waktu booking → Pengembalian 100%\n'
          '• 24–48 jam sebelum waktu booking → Pengembalian 75%\n'
          '• 12–24 jam sebelum waktu booking → Pengembalian 50%\n'
          '• Kurang dari 12 jam sebelum waktu booking → Tidak ada pengembalian dana\n\n'
          'Pembatalan oleh pengelola/admin:\n\n'
          '• Karena pemeliharaan venue → Pengembalian 100%\n'
          '• Force majeure (bencana alam, dll.) → Pengembalian 100%\n'
          '• Kesalahan sistem → Pengembalian 100% + kompensasi\n\n'
          'Proses pengembalian dana diproses dalam 3–7 hari kerja ke rekening asal pembayaran.',
    ),
    LegalSection(
      title: 'Ketentuan Pembayaran',
      content:
          'Pembayaran booking dilakukan dengan ketentuan berikut:\n\n'
          '• Metode: Transfer bank ke rekening yang ditentukan aplikasi\n'
          '• Bukti transfer diunggah dalam format JPG, PNG, atau PDF\n'
          '• Total pembayaran sudah termasuk biaya administrasi (jika ada)\n'
          '• Nominal pembayaran harus sesuai dengan yang tertera di aplikasi\n'
          '• Bukti transfer yang dipalsukan atau dimanipulasi dikenakan sanksi tegas\n'
          '• Pembayaran yang telah diverifikasi tidak dapat dikembalikan (kecuali pembatalan)\n'
          '• Bukti bayar melalui format PDF harus dapat terbaca dan tidak dimodifikasi',
    ),
    LegalSection(
      title: 'E-Ticket dan QR Code',
      content:
          'Setelah pembayaran diverifikasi, pengguna menerima e-ticket digital dengan ketentuan:\n\n'
          '• E-ticket berisi QR code unik yang hanya berlaku untuk satu sesi booking\n'
          '• Dapat diakses melalui menu "Booking Saya" di aplikasi atau melalui email\n'
          '• Wajib ditunjukkan saat check-in di venue (digital atau screenshot)\n'
          '• E-ticket tidak dapat dipindahtangankan tanpa persetujuan tertulis admin\n'
          '• QR code divalidasi oleh petugas venue dan hanya dapat di-scan satu kali\n'
          '• Kehilangan e-ticket dapat diajukan cetak ulang melalui fitur dukungan',
    ),
    LegalSection(
      title: 'Review dan Rating',
      content:
          'Pengguna dapat memberikan ulasan dan penilaian setelah booking selesai dilaksanakan:\n\n'
          '• Skala rating: 1–5 bintang\n'
          '• Komentar ulasan: maksimal 500 karakter\n'
          '• Ulasan harus bersifat jujur, sopan, dan relevan dengan pengalaman di venue\n'
          '• Ulasan yang mengandung unsur SARA, spam, atau konten ilegal dilarang keras\n'
          '• Ulasan yang melanggar ketentuan dapat dihapus tanpa pemberitahuan\n'
          '• Pengelola venue dapat memberikan tanggapan resmi atas ulasan yang diterima\n'
          '• Penyalahgunaan fitur review dapat mengakibatkan penangguhan akun',
    ),
    LegalSection(
      title: 'Kekayaan Intelektual',
      content:
          'Seluruh konten dan elemen dalam aplikasi, termasuk namun tidak terbatas pada:\n\n'
          '• Logo, merek dagang, dan identitas visual\n'
          '• Desain antarmuka, layout, dan elemen UI/UX\n'
          '• Teks, gambar, grafis, dan konten multimedia\n'
          '• Kode sumber dan perangkat lunak aplikasi\n\n'
          'merupakan milik eksklusif SIPELOR BEDAS / DISPORA Kabupaten Bandung atau pemberi '
          'lisensinya. Anda TIDAK diperkenankan menyalin, memodifikasi, mendistribusikan, atau '
          'menggunakan aset tersebut tanpa izin tertulis yang sah.',
    ),
    LegalSection(
      title: 'Larangan Penggunaan',
      content:
          'Pengguna secara tegas DILARANG melakukan hal-hal berikut:\n\n'
          '• Menggunakan layanan untuk tujuan ilegal atau penipuan\n'
          '• Melakukan booking fiktif, spam, atau manipulasi sistem\n'
          '• Mengakses akun pengguna lain tanpa izin\n'
          '• Melakukan reverse engineering, decompile, atau disassembly terhadap aplikasi\n'
          '• Menggunakan bot, crawler, atau automated tool untuk berinteraksi dengan layanan\n'
          '• Mengunggah malware, virus, atau kode berbahaya lainnya\n'
          '• Mencoba mengganggu atau merusak server, jaringan, dan infrastruktur layanan\n\n'
          'Pelanggaran dikenakan sanksi berupa peringatan tertulis, penangguhan sementara, '
          'atau penghapusan akun secara permanen.',
    ),
    LegalSection(
      title: 'Batasan Tanggung Jawab',
      content:
          'SIPELOR BEDAS dan DISPORA Kabupaten Bandung TIDAK bertanggung jawab atas:\n\n'
          '• Kualitas fasilitas dan pelayanan di venue (tanggung jawab pengelola venue)\n'
          '• Cedera, kecelakaan, atau kerugian fisik yang terjadi di area venue\n'
          '• Kehilangan barang bawaan pribadi pengguna di lokasi\n'
          '• Gangguan layanan akibat force majeure atau pemeliharaan sistem\n'
          '• Kerugian akibat akses tidak sah oleh pihak ketiga ke akun pengguna\n\n'
          'Layanan disediakan dalam kondisi "sebagaimana adanya" (as-is) tanpa jaminan '
          'tersurat maupun tersirat dalam batas yang diperbolehkan hukum.',
    ),
    LegalSection(
      title: 'Penangguhan dan Penghentian Akun',
      content:
          'DISPORA berhak melakukan tindakan berikut terhadap akun yang melanggar ketentuan:\n\n'
          '• Memberikan peringatan tertulis untuk pelanggaran ringan\n'
          '• Menangguhkan akun sementara selama investigasi berlangsung\n'
          '• Membatasi akses ke fitur atau layanan tertentu\n'
          '• Menghapus konten yang melanggar tanpa pemberitahuan\n'
          '• Menghapus akun secara permanen untuk pelanggaran berat\n'
          '• Mengambil tindakan hukum jika diperlukan\n\n'
          'Penangguhan atau penghentian dapat dilakukan tanpa pemberitahuan terlebih dahulu '
          'apabila terdapat pelanggaran serius atau ancaman keamanan terhadap sistem.',
    ),
    LegalSection(
      title: 'Hukum yang Berlaku dan Penyelesaian Sengketa',
      content:
          'Syarat dan Ketentuan ini diatur oleh dan ditafsirkan sesuai dengan hukum Negara '
          'Kesatuan Republik Indonesia.\n\n'
          'Setiap sengketa atau perselisihan yang timbul dari penggunaan layanan akan diselesaikan '
          'melalui tahapan berikut:\n\n'
          '1. Musyawarah antara Pengguna dan DISPORA (maks. 30 hari)\n'
          '2. Mediasi melalui lembaga mediasi yang disepakati bersama\n'
          '3. Arbitrase atau jalur hukum melalui Pengadilan Negeri Kabupaten Bandung\n\n'
          'Bahasa resmi yang berlaku dalam Syarat dan Ketentuan ini adalah Bahasa Indonesia.',
    ),
    LegalSection(
      title: 'Perubahan Syarat dan Ketentuan',
      content:
          'DISPORA berhak untuk memperbarui, mengubah, atau merevisi Syarat dan Ketentuan ini '
          'kapan saja sesuai kebutuhan operasional atau perubahan regulasi.\n\n'
          'Perubahan yang material akan dinotifikasikan kepada pengguna melalui:\n\n'
          '• Pemberitahuan banner dalam aplikasi\n'
          '• Notifikasi push (jika diaktifkan)\n'
          '• Email ke alamat yang terdaftar\n\n'
          'Penggunaan berkelanjutan setelah tanggal berlakunya perubahan dianggap sebagai '
          'persetujuan Anda terhadap syarat yang telah diperbarui.',
    ),
    LegalSection(
      title: 'Kontak dan Dukungan',
      content:
          'Untuk pertanyaan, keluhan, atau informasi lebih lanjut terkait Syarat dan Ketentuan:\n\n'
          'Email: legal@sipelor.app\n'
          'Telepon: (022) 1234-5678\n'
          'WhatsApp: +62 812-3456-7890\n'
          'Alamat: Dinas Pemuda dan Olahraga Kabupaten Bandung\n'
          'Jl. Raya Soreang, Kabupaten Bandung, Jawa Barat 40900\n\n'
          'Jam Layanan: Senin – Jumat, 08.00 – 16.00 WIB\n'
          'Respons keluhan dijamin dalam 5 hari kerja',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalDocumentTemplate(
      title: 'Syarat & Ketentuan',
      subtitle:
          'SIPELOR BEDAS · Dinas Pemuda dan Olahraga\nKabupaten Bandung',
      documentNumber: 'SK/SIPELOR/2026/001',
      version: 'v1.0',
      effectiveDate: '26 Januari 2026',
      lastUpdated: '1 Maret 2026',
      reviewStatus: LegalReviewStatus.approved,
      sections: _sections,
      contactEmail: 'legal@sipelor.app',
      contactPhone: '(022) 1234-5678',
      headerGradientStart: const Color(0xFF1B5E20),
      headerGradientEnd: const Color(0xFF2E7D32),
      headerIcon: Icons.balance,
      footerNote:
          'Dengan mendaftar dan menggunakan SIPELOR BEDAS, Anda menyatakan telah membaca, '
          'memahami, dan menyetujui seluruh isi Syarat dan Ketentuan ini.',
    );
  }
}
