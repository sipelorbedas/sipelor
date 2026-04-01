import 'package:flutter/material.dart';
import '../../widgets/legal_document_template.dart';

/// Privacy Policy screen — legal review styled document
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    LegalSection(
      title: 'Pendahuluan',
      content:
          'SIPELOR BEDAS ("kami", "aplikasi") berkomitmen untuk melindungi privasi dan keamanan data '
          'pengguna. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, '
          'dan melindungi informasi pribadi Anda saat menggunakan layanan pemesanan lapangan '
          'olahraga yang dikelola oleh Dinas Pemuda dan Olahraga (DISPORA) Kabupaten Bandung.',
    ),
    LegalSection(
      title: 'Informasi yang Kami Kumpulkan',
      content:
          'Kami mengumpulkan informasi berikut:\n\n'
          '• Informasi Akun: nama lengkap, alamat email, username, dan kata sandi (terenkripsi)\n'
          '• Informasi Profil: foto profil, bio singkat, dan nomor telepon\n'
          '• Informasi Booking: detail pemesanan lapangan, tanggal, waktu, dan riwayat pembayaran\n'
          '• Data Penggunaan: log aktivitas, preferensi aplikasi, dan interaksi fitur\n'
          '• Data Perangkat: model perangkat, sistem operasi, dan versi aplikasi\n'
          '• Data Lokasi: untuk menampilkan venue terdekat (bersifat opsional, memerlukan izin eksplisit)',
    ),
    LegalSection(
      title: 'Bagaimana Kami Menggunakan Informasi',
      content:
          'Informasi Anda digunakan untuk keperluan berikut:\n\n'
          '• Menyediakan dan meningkatkan kualitas layanan aplikasi\n'
          '• Memproses booking lapangan dan verifikasi pembayaran\n'
          '• Mengirimkan notifikasi terkait status booking dan informasi penting\n'
          '• Menganalisis pola penggunaan aplikasi untuk peningkatan layanan\n'
          '• Mencegah penipuan, penyalahgunaan, dan akses tidak sah\n'
          '• Memenuhi kewajiban hukum dan peraturan yang berlaku',
    ),
    LegalSection(
      title: 'Keamanan Data',
      content:
          'Kami menerapkan langkah-langkah keamanan berlapis, antara lain:\n\n'
          '• Enkripsi SSL/TLS untuk seluruh komunikasi data\n'
          '• Hashing kata sandi menggunakan algoritma bcrypt\n'
          '• Penyimpanan aman menggunakan Flutter Secure Storage\n'
          '• SSL Certificate Pinning untuk mencegah serangan MITM\n'
          '• Rate limiting untuk mencegah serangan brute force\n'
          '• Audit logging terhadap seluruh aktivitas sensitif\n'
          '• Auto-logout otomatis setelah 15 menit tidak aktif\n'
          '• Enkripsi data lokal menggunakan AES-256',
    ),
    LegalSection(
      title: 'Berbagi Informasi',
      content:
          'Kami TIDAK menjual, menyewakan, atau memperjualbelikan data pribadi Anda kepada pihak '
          'ketiga mana pun. Informasi hanya dapat dibagikan dalam kondisi berikut:\n\n'
          '• Penyedia layanan teknis yang mendukung operasional (hosting, push notification)\n'
          '• Otoritas penegak hukum jika diwajibkan oleh hukum yang berlaku\n'
          '• Pengelola venue untuk keperluan pemrosesan dan konfirmasi booking\n'
          '• Proses mediasi atau sengketa hukum yang melibatkan transaksi layanan',
    ),
    LegalSection(
      title: 'Hak Pengguna',
      content:
          'Sebagai pengguna, Anda memiliki hak penuh untuk:\n\n'
          '• Mengakses dan melihat data pribadi yang kami simpan\n'
          '• Memperbarui, mengoreksi, atau melengkapi data profil Anda\n'
          '• Menghapus akun beserta seluruh data terkait (sesuai ketentuan retensi)\n'
          '• Menolak penggunaan data untuk keperluan pemasaran\n'
          '• Mengekspor data Anda dalam format yang dapat dibaca (portabilitas data)\n'
          '• Mengajukan keberatan atas pemrosesan data yang dianggap tidak sesuai',
    ),
    LegalSection(
      title: 'Cookies dan Teknologi Tracking',
      content:
          'Aplikasi kami menggunakan teknologi tracking terbatas untuk meningkatkan pengalaman '
          'pengguna. Data yang dikumpulkan mencakup:\n\n'
          '• Data sesi untuk menjaga status login pengguna\n'
          '• Preferensi aplikasi seperti tema dan pengaturan tampilan\n'
          '• Data analitik anonim untuk memahami pola penggunaan fitur\n\n'
          'Anda dapat menolak pengumpulan data analitik melalui pengaturan aplikasi tanpa memengaruhi '
          'fungsionalitas utama layanan.',
    ),
    LegalSection(
      title: 'Data Anak-anak',
      content:
          'Aplikasi SIPELOR BEDAS tidak ditujukan untuk anak-anak di bawah usia 13 tahun. '
          'Kami tidak secara sengaja mengumpulkan data pribadi dari pengguna di bawah umur.\n\n'
          'Apabila Anda adalah orang tua atau wali dan mengetahui bahwa anak Anda telah memberikan '
          'data pribadi tanpa izin, segera hubungi kami agar data tersebut dapat segera dihapus.',
    ),
    LegalSection(
      title: 'Retensi Data',
      content:
          'Data pribadi Anda akan kami simpan selama akun aktif atau selama diperlukan untuk '
          'keperluan layanan. Setelah penghapusan akun:\n\n'
          '• Data profil: dihapus permanen dalam 30 hari\n'
          '• Riwayat booking yang sudah selesai: diarsipkan selama 5 tahun (kewajiban hukum)\n'
          '• Bukti pembayaran: disimpan selama 7 tahun sesuai ketentuan perpajakan\n'
          '• Log audit keamanan: disimpan selama 1 tahun\n'
          '• Data chat: dihapus otomatis setelah 24 jam',
    ),
    LegalSection(
      title: 'Perubahan Kebijakan Privasi',
      content:
          'Kami dapat memperbarui Kebijakan Privasi ini sewaktu-waktu. Setiap perubahan yang '
          'material akan dinotifikasikan kepada pengguna melalui:\n\n'
          '• Pemberitahuan dalam aplikasi\n'
          '• Notifikasi push (jika diaktifkan)\n'
          '• Email ke alamat yang terdaftar\n\n'
          'Penggunaan aplikasi setelah tanggal berlakunya perubahan berarti Anda menyetujui '
          'kebijakan yang telah diperbarui.',
    ),
    LegalSection(
      title: 'Kontak dan Pengaduan',
      content:
          'Jika Anda memiliki pertanyaan, keberatan, atau pengaduan terkait Kebijakan Privasi ini, '
          'silakan menghubungi kami melalui:\n\n'
          'Email: sipelor@bandungkab.go.id\n'
          'Telepon: (022) 1234-5678\n'
          'Alamat: Dinas Pemuda dan Olahraga Kabupaten Bandung\n'
          'Jl. Raya Soreang, Kabupaten Bandung, Jawa Barat 40900\n\n'
          'Jam Layanan: Senin – Jumat, 08.00 – 16.00 WIB\n'
          'Respons pengaduan: maksimal 5 hari kerja',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalDocumentTemplate(
      title: 'Kebijakan Privasi',
      subtitle:
          'SIPELOR BEDAS · Dinas Pemuda dan Olahraga\nKabupaten Bandung',
      documentNumber: 'KP/SIPELOR/2026/001',
      version: 'v1.0',
      effectiveDate: '26 Januari 2026',
      lastUpdated: '1 Maret 2026',
      reviewStatus: LegalReviewStatus.approved,
      sections: _sections,
      contactEmail: 'sipelor@bandungkab.go.id',
      contactPhone: '(022) 1234-5678',
      headerGradientStart: const Color(0xFF1A237E),
      headerGradientEnd: const Color(0xFF1565C0),
      headerIcon: Icons.privacy_tip_outlined,
      footerNote:
          'Dengan mendaftar dan menggunakan SIPELOR BEDAS, Anda menyatakan telah membaca, '
          'memahami, dan menyetujui seluruh isi Kebijakan Privasi ini.',
    );
  }
}
