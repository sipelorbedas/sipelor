import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';

class TeamRegistrationScreen extends StatefulWidget {
  final Tournament tournament;
  final List<TournamentSport> sports;

  const TeamRegistrationScreen({
    super.key,
    required this.tournament,
    required this.sports,
  });

  @override
  State<TeamRegistrationScreen> createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  static const _cupAmber = Color(0xFFFFB300);
  static const _cupAmberDark = Color(0xFFE65100);

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _teamNameCtrl = TextEditingController();
  final _captainNameCtrl = TextEditingController();
  final _captainPhoneCtrl = TextEditingController();
  final _captainEmailCtrl = TextEditingController();
  final _kecamatanCtrl = TextEditingController();
  final _jumlahPemainCtrl = TextEditingController(text: '0');

  TournamentSport? _selectedSport;
  bool _isSubmitting = false;
  bool _isCheckingExisting = false;
  TournamentTeam? _existingRegistration;
  bool _submitted = false;

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    // Pre-fill data dari user yang login
    final user = _currentUser;
    if (user != null) {
      _captainEmailCtrl.text = user.email ?? '';
      final meta = user.userMetadata;
      if (meta != null) {
        _captainNameCtrl.text = (meta['full_name'] as String? ?? '').trim();
        _captainPhoneCtrl.text = (meta['phone'] as String? ?? '').trim();
      }
    }
    // Jika hanya ada 1 sport, otomatis pilih
    if (widget.sports.length == 1) {
      _selectedSport = widget.sports.first;
    }
    // Cek pendaftaran di level turnamen (1 akun = 1 tim per turnamen)
    _checkExisting();
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _captainNameCtrl.dispose();
    _captainPhoneCtrl.dispose();
    _captainEmailCtrl.dispose();
    _kecamatanCtrl.dispose();
    _jumlahPemainCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final userId = _currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isCheckingExisting = true;
      _existingRegistration = null;
    });

    final existing = await TournamentService.checkExistingRegistration(
      tournamentId: widget.tournament.id,
      userId: userId,
    );

    if (mounted) {
      setState(() {
        _existingRegistration = existing;
        _isCheckingExisting = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSport == null) {
      _showSnack('Pilih cabang olahraga terlebih dahulu', isError: true);
      return;
    }

    final userId = _currentUser?.id;
    if (userId == null) {
      _showSnack('Anda harus login untuk mendaftar', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await TournamentService.registerTeam(
        tournamentId: widget.tournament.id,
        sportId: _selectedSport!.id,
        teamName: _teamNameCtrl.text,
        captainName: _captainNameCtrl.text,
        captainPhone: _captainPhoneCtrl.text,
        captainEmail: _captainEmailCtrl.text,
        captainUserId: userId,
        asalKecamatan: _kecamatanCtrl.text.isEmpty ? null : _kecamatanCtrl.text,
        jumlahPemain: int.tryParse(_jumlahPemainCtrl.text) ?? 0,
      );

      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Gagal mendaftar: ${_parseError(e.toString())}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _parseError(String raw) {
    if (raw.contains('duplicate') || raw.contains('unique')) {
      return 'Tim Anda sudah terdaftar untuk cabang ini.';
    }
    if (raw.contains('violates') || raw.contains('policy')) {
      return 'Anda perlu login untuk mendaftar.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.mulish()),
        backgroundColor: isError ? const Color(0xFFF44336) : _cupAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: _cupAmberDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Daftar Tim',
          style: GoogleFonts.mulish(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: _submitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  // ── Success State ─────────────────────────────────────────────

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pendaftaran Berhasil!',
              style: GoogleFonts.mulish(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tim "${_teamNameCtrl.text}" telah berhasil didaftarkan.\n\nStatus pendaftaran saat ini: Menunggu verifikasi admin.\nKami akan menginformasikan hasilnya sesegera mungkin.',
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: AppColors.secondaryDark,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cupAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cupAmber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _cupAmber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cek tab "Tim" di detail turnamen untuk melihat status pendaftaran Anda.',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        color: _cupAmberDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  'Kembali ke Detail Turnamen',
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cupAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form View ─────────────────────────────────────────────────

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament Info Banner
            _buildTournamentBanner(),
            const SizedBox(height: 20),

            // Existing registration check (level turnamen)
            if (_isCheckingExisting)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _cupAmber),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Memeriksa status pendaftaran...',
                      style: GoogleFonts.mulish(fontSize: 12, color: AppColors.secondaryDark),
                    ),
                  ],
                ),
              ),
            if (_existingRegistration != null) ...[
              _buildAlreadyRegisteredBanner(_existingRegistration!),
              const SizedBox(height: 20),
            ],

            // Sport Selector
            _buildSectionHeader('Cabang Olahraga', Icons.sports_outlined),
            const SizedBox(height: 10),
            _buildSportSelector(),

            const SizedBox(height: 20),

            // Tim Info
            _buildSectionHeader('Informasi Tim', Icons.shield_outlined),
            const SizedBox(height: 10),
            _buildCard(
              child: Column(
                children: [
                  _buildField(
                    controller: _teamNameCtrl,
                    label: 'Nama Tim',
                    hint: 'Contoh: Garuda FC',
                    icon: Icons.shield_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nama tim wajib diisi';
                      if (v.trim().length < 3) return 'Nama tim minimal 3 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _kecamatanCtrl,
                    label: 'Asal Kecamatan',
                    hint: 'Contoh: Baleendah',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _jumlahPemainCtrl,
                    label: 'Jumlah Pemain',
                    hint: 'Contoh: 11',
                    icon: Icons.group_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '') ?? -1;
                      if (n < 0) return 'Masukkan jumlah pemain yang valid';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Kapten Info
            _buildSectionHeader('Informasi Kapten / Penanggung Jawab', Icons.person_outlined),
            const SizedBox(height: 10),
            _buildCard(
              child: Column(
                children: [
                  _buildField(
                    controller: _captainNameCtrl,
                    label: 'Nama Kapten',
                    hint: 'Nama lengkap kapten tim',
                    icon: Icons.person_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nama kapten wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _captainPhoneCtrl,
                    label: 'No. HP Kapten',
                    hint: 'Contoh: 08123456789',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'No. HP wajib diisi';
                      if (v.trim().length < 9) return 'No. HP tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _captainEmailCtrl,
                    label: 'Email Kapten',
                    hint: 'contoh@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Disclaimer
            _buildDisclaimer(),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _existingRegistration != null || _selectedSport == null)
                    ? null
                    : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.how_to_reg_rounded),
                label: Text(
                  _isSubmitting ? 'Mendaftarkan...' : 'Daftar Sekarang',
                  style: GoogleFonts.mulish(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cupAmber,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _cupAmber.withOpacity(0.4),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────

  Widget _buildTournamentBanner() {
    final t = widget.tournament;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.organizerName,
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _cupAmber),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.mulish(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSportSelector() {
    return _buildCard(
      child: DropdownButtonFormField<TournamentSport>(
        initialValue: _selectedSport,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.sports_outlined, size: 20, color: _cupAmber),
          hintText: 'Pilih cabang olahraga',
          hintStyle: GoogleFonts.mulish(
            fontSize: 14,
            color: AppColors.secondaryDark.withOpacity(0.5),
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: GoogleFonts.mulish(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
        items: widget.sports.map((sport) {
          return DropdownMenuItem(
            value: sport,
            child: Row(
              children: [
                Icon(sport.sportIcon, size: 18, color: _cupAmber),
                const SizedBox(width: 8),
                Text(sport.sportName),
              ],
            ),
          );
        }).toList(),
        onChanged: (sport) {
          setState(() => _selectedSport = sport);
        },
        validator: (_) => _selectedSport == null ? 'Pilih cabang olahraga' : null,
      ),
    );
  }

  Widget _buildAlreadyRegisteredBanner(TournamentTeam existing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: existing.status == 'rejected'
            ? const Color(0xFFF44336).withOpacity(0.08)
            : const Color(0xFF4CAF50).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: existing.status == 'rejected'
              ? const Color(0xFFF44336).withOpacity(0.3)
              : const Color(0xFF4CAF50).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            existing.status == 'rejected'
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            color: existing.status == 'rejected'
                ? const Color(0xFFF44336)
                : const Color(0xFF4CAF50),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              existing.status == 'rejected'
                  ? 'Pendaftaran tim "${existing.teamName}" ditolak. Hubungi admin untuk info lebih lanjut.'
                  : 'Anda sudah mendaftarkan tim "${existing.teamName}" di turnamen ini (1 akun = 1 tim). Status: ${existing.statusLabel}.',
              style: GoogleFonts.mulish(
                fontSize: 12,
                color: existing.status == 'rejected'
                    ? const Color(0xFFC62828)
                    : const Color(0xFF2E7D32),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: _cupAmber),
        labelStyle: GoogleFonts.mulish(
          fontSize: 13,
          color: AppColors.secondaryDark,
        ),
        hintStyle: GoogleFonts.mulish(
          fontSize: 13,
          color: AppColors.secondaryDark.withOpacity(0.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _cupAmber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.screenBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pendaftaran berstatus "Menunggu" hingga diverifikasi oleh admin DISPORA. '
              'Pastikan data yang diisi sudah benar dan valid.',
              style: GoogleFonts.mulish(
                fontSize: 12,
                color: Colors.blue.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
