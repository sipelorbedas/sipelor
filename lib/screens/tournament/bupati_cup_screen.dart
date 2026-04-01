import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import 'tournament_detail_screen.dart';
import 'team_registration_screen.dart';

class BupatiCupScreen extends StatefulWidget {
  const BupatiCupScreen({super.key});

  @override
  State<BupatiCupScreen> createState() => _BupatiCupScreenState();
}

class _BupatiCupScreenState extends State<BupatiCupScreen> {
  static const _cupAmber = Color(0xFFFFB300);
  static const _cupAmberDark = Color(0xFFE65100);

  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;
  bool _showErrorDetail = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _handleRegister(BuildContext ctx, Tournament t) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (t.status != 'open') {
      final msg = t.status == 'draft'
          ? 'Pendaftaran belum dibuka oleh admin.'
          : t.status == 'ongoing'
              ? 'Turnamen sedang berlangsung, pendaftaran sudah ditutup.'
              : 'Pendaftaran tidak tersedia.';
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.mulish()),
          backgroundColor: _cupAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Login terlebih dahulu untuk mendaftar', style: GoogleFonts.mulish()),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Fetch sports dulu
    final sports = await TournamentService.fetchSports(t.id);
    if (!mounted) return;

    if (sports.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Belum ada cabang olahraga tersedia', style: GoogleFonts.mulish()),
          backgroundColor: _cupAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TeamRegistrationScreen(tournament: t, sports: sports),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await TournamentService.fetchTournaments(publicOnly: false);
      if (mounted) {
        setState(() {
          // Sembunyikan turnamen selesai & dibatalkan dari list Bupati Cup.
          // Data tetap ada di database sampai dihapus oleh scheduled job
          // (lihat: website/admin/sql/scheduled_tournament_cleanup.sql).
          _tournaments = data
              .where((t) => t.status != 'completed' && t.status != 'cancelled')
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: RefreshIndicator(
          color: _cupAmber,
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      floating: false,
      backgroundColor: _cupAmberDark,
      iconTheme: const IconThemeData(color: Colors.white),
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          'Bupati Cup',
          style: GoogleFonts.mulish(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroHeader(),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            'DISPORA Kabupaten Bandung',
                            style: GoogleFonts.mulish(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bupati Cup',
                          style: GoogleFonts.mulish(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Turnamen Olahraga Resmi\nKabupaten Bandung',
                          style: GoogleFonts.mulish(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFB300),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_tournaments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _tournaments.length,
      itemBuilder: (context, index) {
        return _TournamentCard(
          tournament: _tournaments[index],
          cardIndex: index,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TournamentDetailScreen(tournament: _tournaments[index]),
            ),
          ),
          onRegister: () => _handleRegister(context, _tournaments[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: AppColors.secondaryDark.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada turnamen',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Turnamen yang dibuat di Web Admin\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: GoogleFonts.mulish(
              fontSize: 13,
              color: AppColors.secondaryDark.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Pastikan tabel Supabase sudah dibuat:\nwebsite/admin/sql/create_tournament_tables.sql',
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(
                fontSize: 11,
                color: Colors.orange.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    // Cek apakah error terkait tabel belum dibuat di Supabase
    final isTableMissing = _error != null &&
        (_error!.contains('relation') ||
            _error!.contains('does not exist') ||
            _error!.contains('PGRST') ||
            _error!.contains('tournaments'));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTableMissing
                  ? Icons.storage_outlined
                  : Icons.wifi_off_rounded,
              size: 52,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isTableMissing
                  ? 'Tabel database belum dibuat'
                  : 'Gagal memuat data',
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (isTableMissing)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Jalankan file:\nwebsite/admin/sql/create_tournament_tables.sql\ndi Supabase Dashboard → SQL Editor',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                'Periksa koneksi internet Anda',
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  color: AppColors.secondaryDark,
                ),
              ),
            // Tampilkan detail error untuk debug
            if (_error != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _showErrorDetail = !_showErrorDetail);
                },
                child: Text(
                  _showErrorDetail ? 'Sembunyikan detail ▲' : 'Lihat detail error ▼',
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    color: AppColors.secondaryDark.withOpacity(0.6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (_showErrorDetail) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cupAmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tournament Card ────────────────────────────────────────────────

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final int cardIndex;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  static const _cupAmber = Color(0xFFFFB300);
  static final _dateFmt = DateFormat('d MMM yyyy', 'id_ID');

  /// Palette of gradient pairs for varied card colors.
  static const _gradients = [
    [Color(0xFFFF8F00), Color(0xFFFFB300)],   // amber/orange
    [Color(0xFF1565C0), Color(0xFF1E88E5)],   // blue
    [Color(0xFF2E7D32), Color(0xFF43A047)],   // green
    [Color(0xFF6A1B9A), Color(0xFF8E24AA)],   // purple
    [Color(0xFF00695C), Color(0xFF00897B)],   // teal
    [Color(0xFFC62828), Color(0xFFE53935)],   // red
  ];

  const _TournamentCard({
    required this.tournament,
    required this.cardIndex,
    required this.onTap,
    this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster / Header Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildPoster(t),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: t.statusLabel,
                        color: t.statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Organizer
                  _InfoRow(
                    icon: Icons.account_balance_outlined,
                    text: t.organizerName,
                  ),
                  const SizedBox(height: 6),

                  // Dates
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text:
                        '${_dateFmt.format(t.startDate)} – ${_dateFmt.format(t.endDate)}',
                  ),

                  // Location
                  if (t.location != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: t.location!,
                    ),
                  ],

                  // Registration deadline
                  if (t.registrationDeadline != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.access_time_outlined,
                      text:
                          'Daftar s.d ${_dateFmt.format(t.registrationDeadline!)}',
                      iconColor: t.status == 'open'
                          ? const Color(0xFF4CAF50)
                          : AppColors.secondaryDark,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Buttons Row
                  Builder(builder: (context) {
                    final isRegistrationClosed =
                        tournament.status == 'ongoing' ||
                        tournament.status == 'completed';
                    return Row(
                      children: [
                        // Lihat Detail
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.info_outline_rounded, size: 16),
                            label: Text(
                              'Detail',
                              style: GoogleFonts.mulish(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _cupAmber,
                              side: const BorderSide(color: _cupAmber),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        // Daftar Tim — hidden when ongoing or completed
                        if (!isRegistrationClosed) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onRegister,
                              icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                              label: Text(
                                'Daftar Tim',
                                style: GoogleFonts.mulish(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tournament.status == 'open'
                                    ? _cupAmber
                                    : _cupAmber.withOpacity(0.55),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(Tournament t) {
    if (t.posterUrl != null && t.posterUrl!.isNotEmpty) {
      return Image.network(
        t.posterUrl!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPosterFallback(t),
      );
    }
    return _buildPosterFallback(t);
  }

  Widget _buildPosterFallback(Tournament t) {
    final gradientColors = _gradients[cardIndex % _gradients.length];
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 52,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  t.name,
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.mulish(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? AppColors.secondaryDark,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
