import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import 'team_registration_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with TickerProviderStateMixin {
  static const _cupAmber = Color(0xFFFFB300);
  static const _cupAmberDark = Color(0xFFE65100);

  late TabController _tabController;

  List<TournamentSport> _sports = [];
  int _selectedSportIndex = 0;
  bool _sportsLoading = true;

  // Per-sport data (lazy loaded when sport is selected)
  final Map<String, List<TournamentMatch>> _matchesCache = {};
  final Map<String, List<TournamentStanding>> _standingsCache = {};
  final Map<String, List<TournamentTeam>> _teamsCache = {};

  bool _contentLoading = false;

  // Realtime subscription — auto-refresh bracket when admin updates a match
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSports();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  /// Subscribe to Supabase Realtime changes on tournament_matches for [sportId].
  /// When admin updates a match result, the bracket is re-fetched and re-resolved.
  void _subscribeToMatchChanges(String sportId) {
    // Unsubscribe from previous sport's channel first
    _realtimeChannel?.unsubscribe();

    _realtimeChannel = Supabase.instance.client
        .channel('matches_sport_$sportId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tournament_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sport_id',
            value: sportId,
          ),
          callback: (_) {
            if (!mounted) return;
            // Clear cache and re-fetch so bracket resolves with fresh data
            _matchesCache.remove(sportId);
            _loadSportData(sportId);
          },
        )
        .subscribe();
  }

  Future<void> _loadSports({bool refresh = false}) async {
    setState(() => _sportsLoading = true);
    if (refresh) {
      _matchesCache.clear();
      _standingsCache.clear();
      _teamsCache.clear();
    }
    final sports = await TournamentService.fetchSports(widget.tournament.id);
    if (mounted) {
      setState(() {
        _sports = sports;
        _sportsLoading = false;
      });
      if (sports.isNotEmpty) _loadSportData(sports[0].id);
    }
  }

  Future<void> _loadSportData(String sportId, {bool forceReload = false}) async {
    if (!forceReload && _matchesCache.containsKey(sportId)) return; // already loaded
    setState(() => _contentLoading = true);

    final results = await Future.wait([
      TournamentService.fetchMatches(sportId),
      TournamentService.fetchStandings(sportId),
      TournamentService.fetchTeams(sportId),
    ]);

    if (mounted) {
      // Auto-resolve knockout bracket: winners fill the next round's 'Menunggu' slots.
      final rawMatches = results[0] as List<TournamentMatch>;
      _matchesCache[sportId] = TournamentService.resolveKnockoutBracket(rawMatches);
      _standingsCache[sportId] = results[1] as List<TournamentStanding>;
      _teamsCache[sportId] = results[2] as List<TournamentTeam>;
      setState(() => _contentLoading = false);

      // Start listening for real-time match updates for this sport
      _subscribeToMatchChanges(sportId);
    }
  }

  TournamentSport? get _currentSport =>
      _sports.isEmpty ? null : _sports[_selectedSportIndex];

  List<TournamentMatch> get _currentMatches =>
      _matchesCache[_currentSport?.id] ?? [];
  List<TournamentStanding> get _currentStandings =>
      _standingsCache[_currentSport?.id] ?? [];
  List<TournamentTeam> get _currentTeams =>
      _teamsCache[_currentSport?.id] ?? [];

  bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentUser != null;

  /// Status selain completed & cancelled masih bisa di-tap (dengan pesan)
  bool get _canShowRegisterButton {
    final s = widget.tournament.status;
    return s != 'completed' && s != 'cancelled' && s != 'ongoing';
  }

  void _goToRegistration() {
    final status = widget.tournament.status;

    // Belum dibuka
    if (status == 'draft') {
      _showInfoDialog(
        icon: Icons.schedule_rounded,
        iconColor: const Color(0xFFFFB300),
        title: 'Pendaftaran Belum Dibuka',
        message: 'Pendaftaran tim untuk turnamen ini belum dibuka oleh admin. '
            'Pantau terus informasi terbaru di halaman ini.',
      );
      return;
    }

    // Sedang berlangsung
    if (status == 'ongoing') {
      _showInfoDialog(
        icon: Icons.sports_score_rounded,
        iconColor: const Color(0xFF2196F3),
        title: 'Turnamen Sedang Berlangsung',
        message: 'Pendaftaran sudah ditutup karena turnamen sedang berlangsung.',
      );
      return;
    }

    // Cek login
    if (!_isLoggedIn) {
      _showInfoDialog(
        icon: Icons.lock_outlined,
        iconColor: const Color(0xFFF44336),
        title: 'Perlu Login',
        message: 'Anda harus login terlebih dahulu untuk mendaftarkan tim.',
      );
      return;
    }

    // Tidak ada cabang olahraga
    if (_sports.isEmpty) {
      _showInfoDialog(
        icon: Icons.sports_outlined,
        iconColor: const Color(0xFFFFB300),
        title: 'Belum Ada Cabang Olahraga',
        message: 'Admin belum menambahkan cabang olahraga untuk turnamen ini.',
      );
      return;
    }

    // Buka form pendaftaran
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamRegistrationScreen(
          tournament: widget.tournament,
          sports: _sports,
        ),
      ),
    );
  }

  void _showInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.mulish(
                fontSize: 13,
                color: AppColors.secondaryDark,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mengerti',
              style: GoogleFonts.mulish(
                fontWeight: FontWeight.w700,
                color: _cupAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      floatingActionButton: _canShowRegisterButton
          ? FloatingActionButton.extended(
              onPressed: _goToRegistration,
              backgroundColor: widget.tournament.status == 'open'
                  ? const Color(0xFFFFB300)
                  : const Color(0xFFFFB300).withOpacity(0.7),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.how_to_reg_rounded),
              label: Text(
                'Daftar Tim',
                style: GoogleFonts.mulish(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(),
          _buildInfoSliver(),
          if (!_sportsLoading && _sports.isNotEmpty)
            _buildSportSelectorSliver(),
          _buildTabBarSliver(),
        ],
        body: RefreshIndicator(
          color: _cupAmber,
          onRefresh: () => _loadSports(refresh: true),
          child: _contentLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _cupAmber),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _JadwalTab(matches: _currentMatches),
                    _KlasemenTab(standings: _currentStandings),
                    _TimTab(teams: _currentTeams),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Slivers ────────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    final t = widget.tournament;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _cupAmberDark,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        t.name,
        style: GoogleFonts.mulish(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildPoster(t),
      ),
    );
  }

  Widget _buildPoster(Tournament t) {
    if (t.posterUrl != null && t.posterUrl!.isNotEmpty) {
      return Image.network(
        t.posterUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPosterFallback(t),
      );
    }
    return _buildPosterFallback(t);
  }

  Widget _buildPosterFallback(Tournament t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              t.name,
              style: GoogleFonts.mulish(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildInfoSliver() {
    final t = widget.tournament;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.name,
                    style: GoogleFonts.mulish(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(label: t.statusLabel, color: t.statusColor),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Info rows
            _DetailInfoRow(
              icon: Icons.account_balance_outlined,
              label: 'Penyelenggara',
              value: t.organizerName,
            ),
            const SizedBox(height: 8),
            _DetailInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value:
                  '${dateFmt.format(t.startDate)} – ${dateFmt.format(t.endDate)}',
            ),
            if (t.location != null) ...[
              const SizedBox(height: 8),
              _DetailInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Lokasi',
                value: t.location!,
              ),
            ],
            if (t.registrationDeadline != null) ...[
              const SizedBox(height: 8),
              _DetailInfoRow(
                icon: Icons.access_time_outlined,
                label: 'Status Pendaftaran',
                value:
                    'Tutup ${dateFmt.format(t.registrationDeadline!)}',
                valueColor: t.status == 'open'
                    ? const Color(0xFF4CAF50)
                    : AppColors.secondaryDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSportSelectorSliver() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              'Cabang Olahraga',
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_sports.length, (i) {
                  final sport = _sports[i];
                  final selected = i == _selectedSportIndex;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _sports.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedSportIndex = i);
                        _loadSportData(sport.id);
                        // Switch Realtime subscription to the newly selected sport
                        _subscribeToMatchChanges(sport.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? _cupAmber
                              : _cupAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? _cupAmber
                                : _cupAmber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sport.sportIcon,
                              size: 16,
                              color:
                                  selected ? Colors.white : _cupAmber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sport.sportName,
                              style: GoogleFonts.mulish(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : _cupAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPersistentHeader _buildTabBarSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: _cupAmber,
          unselectedLabelColor: AppColors.secondaryDark,
          indicatorColor: _cupAmber,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.mulish(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.mulish(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Jadwal'),
            Tab(text: 'Klasemen'),
            Tab(text: 'Tim'),
          ],
        ),
      ),
    );
  }
}

// ── Tab Bar Delegate ──────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ── Tab: Jadwal ───────────────────────────────────────────────────

class _JadwalTab extends StatelessWidget {
  final List<TournamentMatch> matches;

  const _JadwalTab({required this.matches});

  @override
  Widget build(BuildContext context) {
    // Hide phantom bracket slots where both teams are still TBD and the
    // match hasn't started yet — this happens when a bracket is pre-generated
    // for e.g. 8 teams but only 6 teams actually registered.
    final visibleMatches = matches.where((m) {
      final aEmpty = m.teamAName == null ||
          m.teamAName!.trim().isEmpty ||
          m.teamAName!.trim().toUpperCase() == 'TBD';
      final bEmpty = m.teamBName == null ||
          m.teamBName!.trim().isEmpty ||
          m.teamBName!.trim().toUpperCase() == 'TBD';
      // Keep the match if at least one team is known, or if it's already
      // ongoing / completed / cancelled (so admin-recorded results still show).
      final isActive =
          m.status == 'ongoing' || m.status == 'completed' || m.status == 'cancelled';
      return !(aEmpty && bEmpty && !isActive);
    }).toList();

    if (visibleMatches.isEmpty) {
      return _emptyState(
        icon: Icons.calendar_today_outlined,
        message: 'Belum ada pertandingan',
      );
    }

    // Group matches by phase
    final Map<String, List<TournamentMatch>> grouped = {};
    for (final m in visibleMatches) {
      grouped.putIfAbsent(m.phaseLabel, () => []).add(m);
    }

    final phaseOrder = [
      'Fase Grup',
      '16 Besar',
      'Perempat Final',
      'Semi Final',
      'Perebutan Juara 3',
      'Final',
    ];
    final sortedPhases = grouped.keys.toList()
      ..sort((a, b) {
        final ai = phaseOrder.indexOf(a);
        final bi = phaseOrder.indexOf(b);
        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final phase in sortedPhases) ...[
          _PhaseHeader(phase: phase),
          const SizedBox(height: 8),
          ...grouped[phase]!.map((m) => _MatchCard(match: m)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final String phase;
  const _PhaseHeader({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          phase,
          style: GoogleFonts.mulish(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final TournamentMatch match;

  const _MatchCard({required this.match});

  static final _dateFmt = DateFormat('EEE, d MMM', 'id_ID');
  static final _timeFmt = DateFormat('HH:mm', 'id_ID');

  /// Returns 'Menunggu' when team name is null, empty, or the placeholder 'TBD'.
  static String _teamName(String? name) {
    if (name == null || name.trim().isEmpty || name.trim().toUpperCase() == 'TBD') {
      return 'Menunggu';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final m = match;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: group / match number + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.groupName != null
                    ? 'Grup ${m.groupName} · Babak ${m.round}'
                    : 'Pertandingan ${m.matchNumber}',
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  color: AppColors.secondaryDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: m.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  m.statusLabel,
                  style: GoogleFonts.mulish(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: m.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Teams vs Score
          Row(
            children: [
              // Team A
              Expanded(
                child: Text(
                  _teamName(m.teamAName),
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Score / VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: m.hasScore
                    ? Row(
                        children: [
                          _ScoreBox(
                            score: m.teamAScore!,
                            isWinner: m.winnerId == m.teamAId,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '–',
                              style: GoogleFonts.mulish(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ),
                          _ScoreBox(
                            score: m.teamBScore!,
                            isWinner: m.winnerId == m.teamBId,
                          ),
                        ],
                      )
                    : Text(
                        'VS',
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFB300),
                        ),
                      ),
              ),
              // Team B
              Expanded(
                child: Text(
                  _teamName(m.teamBName),
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Date + Venue
          if (m.scheduledAt != null || m.venueName != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                if (m.scheduledAt != null) ...[
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.secondaryDark),
                  const SizedBox(width: 4),
                  Text(
                    '${_dateFmt.format(m.scheduledAt!)} · ${_timeFmt.format(m.scheduledAt!)}',
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
                if (m.scheduledAt != null && m.venueName != null)
                  const SizedBox(width: 12),
                if (m.venueName != null) ...[
                  Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.secondaryDark),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      m.venueName!,
                      style: GoogleFonts.mulish(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  final bool isWinner;
  const _ScoreBox({required this.score, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0xFFFFB300)
            : AppColors.screenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$score',
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isWinner ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

// ── Tab: Klasemen ─────────────────────────────────────────────────

class _KlasemenTab extends StatelessWidget {
  final List<TournamentStanding> standings;

  const _KlasemenTab({required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return _emptyState(
        icon: Icons.table_chart_outlined,
        message: 'Belum ada klasemen',
      );
    }

    // Group by group name
    final Map<String, List<TournamentStanding>> grouped = {};
    for (final s in standings) {
      grouped.putIfAbsent(s.groupName, () => []).add(s);
    }
    final sortedGroups = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final group in sortedGroups) ...[
          if (sortedGroups.length > 1) ...[
            _PhaseHeader(phase: 'Grup $group'),
            const SizedBox(height: 8),
          ],
          _StandingsTable(standings: grouped[group]!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<TournamentStanding> standings;
  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _HeaderCell('#', width: 24, align: TextAlign.center),
                _HeaderCell('Tim', flex: 3),
                _HeaderCell('M', width: 30, align: TextAlign.center),
                _HeaderCell('W', width: 30, align: TextAlign.center),
                _HeaderCell('D', width: 30, align: TextAlign.center),
                _HeaderCell('L', width: 30, align: TextAlign.center),
                _HeaderCell('SG', width: 36, align: TextAlign.center),
                _HeaderCell('Poin', width: 40, align: TextAlign.center),
              ],
            ),
          ),
          // Rows
          ...List.generate(standings.length, (i) {
            final s = standings[i];
            final isTop = i < 2;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isTop
                    ? const Color(0xFFFFB300).withOpacity(0.07)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: i < standings.length - 1
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Position
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isTop
                            ? const Color(0xFFFFB300)
                            : AppColors.secondaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Team name
                  Expanded(
                    flex: 3,
                    child: Text(
                      s.teamName ?? '–',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _DataCell('${s.played}', width: 30),
                  _DataCell('${s.won}', width: 30),
                  _DataCell('${s.drawn}', width: 30),
                  _DataCell('${s.lost}', width: 30),
                  _DataCell(
                    s.goalDifference >= 0
                        ? '+${s.goalDifference}'
                        : '${s.goalDifference}',
                    width: 36,
                    color: s.goalDifference > 0
                        ? const Color(0xFF4CAF50)
                        : s.goalDifference < 0
                            ? const Color(0xFFF44336)
                            : null,
                  ),
                  _DataCell(
                    '${s.points}',
                    width: 40,
                    bold: true,
                    color: const Color(0xFFFFB300),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double? width;
  final int? flex;
  final TextAlign align;

  const _HeaderCell(
    this.label, {
    this.width,
    this.flex,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: GoogleFonts.mulish(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      textAlign: align,
    );
    if (flex != null) return Expanded(flex: flex!, child: text);
    return SizedBox(width: width, child: text);
  }
}

class _DataCell extends StatelessWidget {
  final String value;
  final double width;
  final bool bold;
  final Color? color;

  const _DataCell(
    this.value, {
    required this.width,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: GoogleFonts.mulish(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color ?? AppColors.secondaryDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Tab: Tim ──────────────────────────────────────────────────────

class _TimTab extends StatelessWidget {
  final List<TournamentTeam> teams;

  const _TimTab({required this.teams});

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return _emptyState(
        icon: Icons.group_outlined,
        message: 'Belum ada tim terdaftar',
      );
    }

    // Group by group_name
    final ungrouped = teams.where((t) => t.groupName == null).toList();
    final Map<String, List<TournamentTeam>> grouped = {};
    for (final t in teams.where((t) => t.groupName != null)) {
      grouped.putIfAbsent(t.groupName!, () => []).add(t);
    }
    final sortedGroups = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (ungrouped.isNotEmpty) ...ungrouped.map((t) => _TeamCard(team: t)),
        for (final group in sortedGroups) ...[
          _PhaseHeader(phase: 'Grup $group'),
          const SizedBox(height: 8),
          ...grouped[group]!.map((t) => _TeamCard(team: t)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TournamentTeam team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final t = team;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo or avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: t.teamLogoUrl != null
                ? ClipOval(
                    child: Image.network(
                      t.teamLogoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFFFB300),
                        size: 26,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFFFB300),
                    size: 26,
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.teamName,
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: t.statusLabel,
                      color: t.statusColor,
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kapten: ${t.captainName}',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    color: AppColors.secondaryDark,
                  ),
                ),
                if (t.asalKecamatan != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.secondaryDark.withOpacity(0.7),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        t.asalKecamatan!,
                        style: GoogleFonts.mulish(
                          fontSize: 11,
                          color: AppColors.secondaryDark.withOpacity(0.7),
                        ),
                      ),
                      if (t.jumlahPemain > 0) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.group_outlined,
                          size: 12,
                          color: AppColors.secondaryDark.withOpacity(0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${t.jumlahPemain} pemain',
                          style: GoogleFonts.mulish(
                            fontSize: 11,
                            color:
                                AppColors.secondaryDark.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const _StatusChip({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.mulish(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFFB300)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  color: AppColors.secondaryDark,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _emptyState({required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 52,
          color: AppColors.secondaryDark.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: GoogleFonts.mulish(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Data akan muncul setelah diinput oleh admin',
          style: GoogleFonts.mulish(
            fontSize: 12,
            color: AppColors.secondaryDark.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
