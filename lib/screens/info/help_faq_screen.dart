import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Akun',
    'Booking',
    'Pembayaran',
    'E-Ticket',
    'Lainnya',
  ];

  final List<FaqItem> _allFaqs = [
    // AKUN
    FaqItem(
      category: 'Akun',
      question: 'Bagaimana cara mendaftar di SIPELOR?',
      answer: 'Untuk mendaftar:\n'
          '1. Buka aplikasi SIPELOR\n'
          '2. Klik "Daftar" atau "Sign Up"\n'
          '3. Masukkan email, username, dan password\n'
          '4. Verifikasi email Anda melalui link yang dikirim\n'
          '5. Login dan lengkapi profil Anda',
    ),
    FaqItem(
      category: 'Akun',
      question: 'Lupa password, bagaimana cara reset?',
      answer: 'Jika lupa password:\n'
          '1. Klik "Lupa Password" di halaman login\n'
          '2. Masukkan email yang terdaftar\n'
          '3. Cek email untuk link reset password\n'
          '4. Klik link dan buat password baru\n'
          '5. Login dengan password baru',
    ),
    FaqItem(
      category: 'Akun',
      question: 'Bagaimana cara mengubah profil saya?',
      answer: 'Untuk mengubah profil:\n'
          '1. Buka menu "Profil"\n'
          '2. Klik "Edit Profil"\n'
          '3. Ubah informasi yang diperlukan (nama, nomor HP, foto profil)\n'
          '4. Klik "Simpan" untuk menyimpan perubahan',
    ),

    // BOOKING
    FaqItem(
      category: 'Booking',
      question: 'Bagaimana cara booking lapangan?',
      answer: 'Cara booking lapangan:\n'
          '1. Pilih lapangan yang diinginkan dari daftar\n'
          '2. Pilih tanggal dan waktu yang tersedia\n'
          '3. Periksa detail booking dan total harga\n'
          '4. Konfirmasi booking\n'
          '5. Lakukan pembayaran dalam 30 menit\n'
          '6. Upload bukti pembayaran\n'
          '7. Tunggu verifikasi admin',
    ),
    FaqItem(
      category: 'Booking',
      question: 'Berapa lama sebelumnya saya bisa booking?',
      answer: 'Anda dapat melakukan booking untuk tanggal maksimal 30 hari ke depan dari hari ini. '
          'Booking minimal dilakukan H-1 (1 hari sebelum tanggal main).',
    ),
    FaqItem(
      category: 'Booking',
      question: 'Apakah bisa booking lebih dari 1 lapangan sekaligus?',
      answer: 'Ya, Anda dapat melakukan booking untuk beberapa lapangan sekaligus. '
          'Setiap booking akan memiliki nomor booking yang berbeda dan harus dibayar secara terpisah.',
    ),
    FaqItem(
      category: 'Booking',
      question: 'Bagaimana cara membatalkan booking?',
      answer: 'Untuk membatalkan booking:\n'
          '1. Buka menu "Riwayat Booking"\n'
          '2. Pilih booking yang ingin dibatalkan\n'
          '3. Klik tombol "Batalkan Booking"\n'
          '4. Konfirmasi pembatalan\n\n'
          'Catatan: Booking hanya bisa dibatalkan jika statusnya masih "Menunggu" atau belum dibayar.',
    ),
    FaqItem(
      category: 'Booking',
      question: 'Apakah ada denda jika membatalkan booking?',
      answer: 'Pembatalan booking yang belum dibayar TIDAK dikenakan denda. '
          'Namun, jika booking sudah dibayar dan terverifikasi, pembatalan akan dikenakan potongan biaya admin 20% dari total pembayaran. '
          'Dana akan dikembalikan dalam 3-5 hari kerja.',
    ),
    FaqItem(
      category: 'Booking',
      question: 'Berapa lama booking akan otomatis dibatalkan jika tidak bayar?',
      answer: 'Booking akan otomatis dibatalkan jika pembayaran tidak dilakukan dalam waktu 30 menit sejak booking dibuat. '
          'Pastikan Anda segera melakukan pembayaran setelah booking.',
    ),

    // PEMBAYARAN
    FaqItem(
      category: 'Pembayaran',
      question: 'Metode pembayaran apa saja yang tersedia?',
      answer: 'Saat ini pembayaran dilakukan melalui transfer bank ke rekening:\n\n'
          '• BCA - 1234567890\n'
          '• BRI - 0987654321\n'
          '• Mandiri - 1122334455\n'
          '• BNI - 5566778899\n\n'
          'a.n. DISPORA Kabupaten Bandung\n\n'
          'Setelah transfer, upload bukti pembayaran di aplikasi.',
    ),
    FaqItem(
      category: 'Pembayaran',
      question: 'Bagaimana cara upload bukti pembayaran?',
      answer: 'Untuk upload bukti pembayaran:\n'
          '1. Buka detail booking Anda\n'
          '2. Klik tombol "Upload Bukti Bayar"\n'
          '3. Pilih foto/file bukti transfer dari galeri atau kamera\n'
          '4. Klik "Upload"\n'
          '5. Tunggu verifikasi dari admin (maksimal 24 jam)',
    ),
    FaqItem(
      category: 'Pembayaran',
      question: 'Berapa lama verifikasi pembayaran?',
      answer: 'Verifikasi pembayaran biasanya dilakukan dalam waktu 1-24 jam pada hari kerja (Senin-Jumat). '
          'Untuk pembayaran di akhir pekan, verifikasi akan dilakukan pada hari kerja berikutnya. '
          'Anda akan mendapat notifikasi setelah pembayaran terverifikasi.',
    ),
    FaqItem(
      category: 'Pembayaran',
      question: 'Apa yang terjadi jika pembayaran saya ditolak?',
      answer: 'Jika pembayaran ditolak:\n'
          '1. Anda akan menerima notifikasi penolakan\n'
          '2. Periksa alasan penolakan di detail booking\n'
          '3. Upload ulang bukti pembayaran yang benar\n'
          '4. Hubungi customer service jika ada kendala\n\n'
          'Alasan umum penolakan: bukti tidak jelas, nominal tidak sesuai, atau rekening tujuan salah.',
    ),
    FaqItem(
      category: 'Pembayaran',
      question: 'Apakah ada biaya tambahan selain harga sewa lapangan?',
      answer: 'Tidak ada biaya tambahan. Harga yang tertera sudah termasuk semua biaya. '
          'Yang perlu Anda bayar adalah total harga sesuai durasi booking yang dipilih.',
    ),

    // E-TICKET
    FaqItem(
      category: 'E-Ticket',
      question: 'Bagaimana cara mendapatkan e-ticket?',
      answer: 'Setelah pembayaran terverifikasi:\n'
          '1. Buka menu "Riwayat Booking"\n'
          '2. Pilih booking yang sudah dikonfirmasi\n'
          '3. Klik tombol "Lihat E-Ticket"\n'
          '4. E-ticket dengan QR code akan muncul\n'
          '5. Anda bisa download atau simpan screenshot',
    ),
    FaqItem(
      category: 'E-Ticket',
      question: 'Apakah harus cetak e-ticket?',
      answer: 'Tidak harus cetak. Anda cukup tunjukkan e-ticket digital dari smartphone saat datang ke lapangan. '
          'Petugas akan melakukan scan QR code untuk validasi.',
    ),
    FaqItem(
      category: 'E-Ticket',
      question: 'Apa yang harus dibawa saat datang ke lapangan?',
      answer: 'Yang harus dibawa:\n'
          '1. E-ticket (digital di HP atau print)\n'
          '2. KTP/Identitas yang sesuai dengan nama booking\n'
          '3. Perlengkapan olahraga pribadi\n\n'
          'Tunjukkan e-ticket dan identitas ke petugas saat check-in.',
    ),
    FaqItem(
      category: 'E-Ticket',
      question: 'Berapa lama sebelum waktu main harus datang?',
      answer: 'Disarankan datang 15-30 menit sebelum waktu booking untuk proses check-in. '
          'Keterlambatan lebih dari 30 menit dapat mengakibatkan pembatalan otomatis tanpa refund.',
    ),

    // LAINNYA
    FaqItem(
      category: 'Lainnya',
      question: 'Apa itu harga khusus untuk pimpinan?',
      answer: 'Harga khusus adalah benefit yang diberikan kepada pejabat/pimpinan tertentu yang telah ditentukan oleh DISPORA. '
          'Pengguna dengan username yang terdaftar akan otomatis mendapat harga khusus atau gratis sesuai kebijakan yang berlaku.',
    ),
    FaqItem(
      category: 'Lainnya',
      question: 'Bagaimana cara memberikan review/rating?',
      answer: 'Untuk memberikan review:\n'
          '1. Review hanya bisa diberikan setelah booking selesai (status "Selesai")\n'
          '2. Buka detail booking\n'
          '3. Klik "Berikan Review"\n'
          '4. Pilih rating bintang (1-5)\n'
          '5. Tulis komentar/ulasan Anda\n'
          '6. Klik "Kirim Review"',
    ),
    FaqItem(
      category: 'Lainnya',
      question: 'Fasilitas apa saja yang tersedia di lapangan?',
      answer: 'Fasilitas yang tersedia bervariasi tergantung lokasi lapangan:\n'
          '• Kamar ganti/ruang ganti\n'
          '• Toilet/kamar mandi\n'
          '• Tempat parkir\n'
          '• Kantin (di beberapa lokasi)\n'
          '• Mushola\n'
          '• Tribun penonton\n\n'
          'Cek detail lapangan untuk informasi fasilitas lengkap.',
    ),
    FaqItem(
      category: 'Lainnya',
      question: 'Bagaimana jika cuaca buruk/hujan saat jadwal booking?',
      answer: 'Untuk lapangan outdoor:\n'
          '• Jika hujan, Anda bisa reschedule dengan menghubungi admin\n'
          '• Reschedule dapat dilakukan maksimal 1 kali tanpa biaya tambahan\n'
          '• Bukti cuaca buruk dapat berupa foto/video saat waktu booking\n\n'
          'Untuk lapangan indoor: tidak terpengaruh cuaca.',
    ),
    FaqItem(
      category: 'Lainnya',
      question: 'Apakah bisa booking untuk turnamen atau event?',
      answer: 'Ya, untuk booking event/turnamen dengan durasi panjang atau multi-lapangan:\n'
          '1. Hubungi admin/customer service terlebih dahulu\n'
          '2. Diskusikan kebutuhan dan jadwal event\n'
          '3. Admin akan memberikan penawaran khusus\n'
          '4. Pembayaran dapat dilakukan dengan sistem DP\n\n'
          'Kontak: (022) 1234-5678 atau email: dispora@bandungkab.go.id',
    ),
    FaqItem(
      category: 'Lainnya',
      question: 'Apakah ada program member atau diskon?',
      answer: 'Saat ini belum ada program membership khusus. Namun:\n'
          '• User yang sering booking dapat reward point (coming soon)\n'
          '• Promo spesial di hari-hari tertentu\n'
          '• Diskon untuk booking di hari kerja\n'
          '• Follow sosial media DISPORA untuk info promo terbaru',
    ),
  ];

  List<FaqItem> get _filteredFaqs {
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'Semua' || faq.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Bantuan & FAQ',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section with Search
          _buildHeaderSection(),

          // Category Tabs
          _buildCategoryTabs(),

          // FAQ List
          Expanded(
            child: _filteredFaqs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      return _buildFaqCard(_filteredFaqs[index]);
                    },
                  ),
          ),

          // Contact Support Button
          _buildContactSupportButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 0, 113, 72),
            Color.fromARGB(255, 0, 117, 164),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.help_outline,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Ada yang bisa kami bantu?',
            style: GoogleFonts.mulish(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan jawaban untuk pertanyaan Anda',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari pertanyaan...',
                hintStyle: GoogleFonts.mulish(
                  fontSize: 14,
                  color: AppColors.secondaryDark.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.secondaryDark.withOpacity(0.5),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.secondaryDark.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 0, 113, 72),
                            Color.fromARGB(255, 0, 117, 164),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.borderGray.withOpacity(0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color.fromARGB(255, 0, 113, 72)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.secondaryDark,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqCard(FaqItem faq) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                size: 20,
                color: Color.fromARGB(255, 0, 113, 72),
              ),
            ),
            title: Text(
              faq.question,
              style: GoogleFonts.mulish(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  faq.answer,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.secondaryDark.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau pilih kategori berbeda',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupportButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masih butuh bantuan?',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showContactDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.support_agent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Hubungi Customer Service',
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.support_agent,
                size: 48,
                color: Color.fromARGB(255, 0, 113, 72),
              ),
              const SizedBox(height: 12),
              Text(
                'Hubungi Kami',
                style: GoogleFonts.mulish(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih metode untuk menghubungi customer service kami',
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  color: AppColors.secondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildContactOption(
                icon: Icons.phone,
                label: 'Telepon',
                value: '(022) 1234-5678',
              ),
              const SizedBox(height: 12),
              _buildContactOption(
                icon: Icons.email,
                label: 'Email',
                value: 'dispora@bandungkab.go.id',
              ),
              const SizedBox(height: 12),
              _buildContactOption(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                value: '0812-3456-7890',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 0, 113, 72),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color.fromARGB(255, 0, 113, 72),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryDark,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FaqItem {
  final String category;
  final String question;
  final String answer;

  FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}
