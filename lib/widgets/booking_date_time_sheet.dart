import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../models/booking.dart';
import '../models/field.dart';
import '../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────
//  Jam operasional lapangan (bisa disesuaikan)
// ─────────────────────────────────────────────────────────────────
const int _kOpStart = 6; // 06:00
const int _kOpEnd = 22; // 22:00  (last booking can END here)

class BookingDateTimeSheet extends StatefulWidget {
  final DateTime initialDate;

  /// Called when the user confirms. [durationDays] is always ≥ 1.
  /// [peopleCount] is the number of people (relevant for perOrang mode).
  final Function(
    DateTime date,
    String timeSlot,
    int durationDays,
    int peopleCount,
  )?
  onConfirm;
  final String fieldId;

  /// Optional field data used to determine booking mode (e.g. perOrang).
  final Field? field;

  const BookingDateTimeSheet({
    super.key,
    required this.initialDate,
    this.onConfirm,
    required this.fieldId,
    this.field,
  });

  @override
  State<BookingDateTimeSheet> createState() => _BookingDateTimeSheetState();
}

class _BookingDateTimeSheetState extends State<BookingDateTimeSheet> {
  late DateTime _selectedDate;
  String? _selectedStartTime; // e.g. "08:00"
  String? _selectedTimeSlot; // e.g. "08:00 - 10:00"
  int _selectedDuration = 1; // jam (durasi per sesi)
  int _selectedDays = 1; // hari (jumlah hari booking)
  late DateTime _currentMonth;

  int _peopleCount = 1; // for perOrang mode

  List<Booking> _existingBookings = [];
  bool _isLoadingBookings = false;
  RealtimeChannel? _realtimeChannel;
  bool _realtimeConnected = false;
  Timer? _autoRefreshTimer;

  // ── init ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    // Untuk mode durasi tetap, kunci durasi & hari langsung
    if (_bookingMode == BookingMode.perSesi ||
        _bookingMode == BookingMode.harian) {
      _selectedDays = 1;
      _selectedDuration = _fixedSessionDuration;

      // Harian 24 jam penuh → auto-select 00:00.
      if (_isFullDayBooking) {
        _selectedStartTime = '00:00';
        _selectedTimeSlot = '00:00 - 00:00';
      }
      // Resepsi (durasi tetap < 24 jam) → kunci jam mulai ke 06:00 (jam operasional).
      // Cocok dengan website: resepsi8 = 06:00–14:00, resepsi18 = 06:00–00:00.
      else if (_isFixedHourHarian) {
        _selectedStartTime = '${_kOpStart.toString().padLeft(2, '0')}:00';
        _selectedTimeSlot =
            '$_selectedStartTime - ${_calcEndTime(_selectedStartTime!, _selectedDuration)}';
      }
    }

    _loadBookingsForDate(_selectedDate);
    _setupRealtimeSubscription();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ── auto-refresh (fallback jika realtime tidak aktif) ─────────
  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadBookingsForDate(_selectedDate);
    });
  }

  // ── realtime subscription (anti-double booking) ───────────────
  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('bookings-field-${widget.fieldId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'field_id',
              value: widget.fieldId,
            ),
            callback: (payload) {
              if (mounted) {
                setState(() => _realtimeConnected = true);
                _loadBookingsForDate(_selectedDate);
              }
            },
          )
          .subscribe((status, [error]) {
            if (mounted) {
              setState(() => _realtimeConnected = status == 'SUBSCRIBED');
            }
          });
    } catch (e) {
      if (mounted) setState(() => _realtimeConnected = false);
    }
  }

  // ── load bookings untuk tanggal yang dipilih ──────────────────
  Future<void> _loadBookingsForDate(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoadingBookings = true);
    try {
      final bookings = await SupabaseService.fetchFieldBookingsByDate(
        fieldId: widget.fieldId,
        date: date,
      );
      if (mounted) {
        setState(() {
          _existingBookings = bookings;
          _isLoadingBookings = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBookings = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadBookingsForDate(_selectedDate);
  }

  // ── helpers ───────────────────────────────────────────────────

  /// Booking mode derived from satuan, with venueName as fallback for resepsi fields.
  BookingMode get _bookingMode =>
      BookingMode.fromField(widget.field?.satuan, widget.field?.venueName);

  /// Durasi sesi tetap (jam) yang diekstrak dari venueName (prioritas) lalu satuan.
  /// Untuk resepsi: "Resepsi 8" → 8, "Resepsi18" → 18 (mengabaikan satuan "2 jam").
  /// Fallback: harian → 24 jam, perSesi → 2 jam.
  int get _fixedSessionDuration {
    // Resepsi fields: always derive duration from venueName first.
    final nameNum = BookingMode.resepsiDurationFromName(
      widget.field?.venueName,
    );
    if (nameNum != null) return nameNum;
    // Non-resepsi: use satuan number.
    final s = (widget.field?.satuan ?? '').toLowerCase().trim();
    final match = RegExp(r'\d+').firstMatch(s);
    if (match != null) {
      final parsed = int.tryParse(match.group(0)!);
      if (parsed != null && parsed > 0) return parsed;
    }
    switch (_bookingMode) {
      case BookingMode.harian:
        return 24; // satu hari penuh jika tidak ada angka
      case BookingMode.perSesi:
        return 2;
      default:
        return 1;
    }
  }

  /// True untuk mode yang durasinya sudah tetap (tidak dipilih user).
  bool get _hasFixedDuration =>
      _bookingMode == BookingMode.perSesi || _bookingMode == BookingMode.harian;

  /// True jika harian 24 jam penuh (00:00–00:00), tidak perlu pilih jam mulai.
  bool get _isFullDayBooking =>
      _bookingMode == BookingMode.harian && _fixedSessionDuration >= 24;

  /// True untuk harian dengan durasi tetap < 24 jam (contoh: resepsi18, resepsi8).
  /// Mode ini hanya memilih tanggal + jam mulai — tanpa sesi/durasi selector.
  bool get _isFixedHourHarian => _hasFixedDuration && !_isFullDayBooking;

  /// Max capacity parsed from kapasitas string (e.g. "14 orang" → 14)
  int get _maxPeople {
    final raw = widget.field?.kapasitas ?? '';
    final parsed = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
    return (parsed != null && parsed > 0) ? parsed : 20;
  }

  /// Daftar jam mulai yang valid: dari _kOpStart sampai (_kOpEnd - durasi)
  /// Step size berdasarkan mode: perSesi menggunakan durasi sebagai step (2 jam),
  /// mode lain menggunakan 1 jam per step
  List<String> get _startTimes {
    final step = _bookingMode == BookingMode.perSesi ? _selectedDuration : 1;
    final lastStart = _kOpEnd - _selectedDuration;
    if (lastStart < _kOpStart) {
      // Durasi melebihi jendela operasional — hanya satu opsi: jam paling awal
      return ['${_kOpStart.toString().padLeft(2, '0')}:00'];
    }

    final count = ((lastStart - _kOpStart) ~/ step) + 1;
    return List.generate(
      count,
      (i) => '${(_kOpStart + (i * step)).toString().padLeft(2, '0')}:00',
    );
  }

  /// Hitung jam selesai (handle overflow ≥ 24:00)
  String _calcEndTime(String startTime, int duration) {
    final h = int.parse(startTime.split(':')[0]);
    final endH = h + duration;
    return '${(endH % 24).toString().padLeft(2, '0')}:00';
  }

  /// Parse time ke menit (handles "H:mm", "HH:mm", "HH:mm:ss")
  int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Potong label OPD agar muat di tile kecil (maks 8 karakter)
  String _truncateOpdLabel(String label) {
    // Ambil kata pertama dari label agar tetap informatif di tile kecil
    final firstWord = label.split(' ').first;
    return firstWord.length > 10 ? '${firstWord.substring(0, 9)}…' : firstWord;
  }

  /// Normalisasi waktu: "06:00:00" → "06:00"
  String _normalizeTime(String t) {
    final p = t.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : t;
  }

  /// Cek apakah dua range waktu overlap
  bool _timeRangesOverlap(String s1, String e1, String s2, String e2) {
    final a = _toMinutes(s1), b = _toMinutes(e1);
    final c = _toMinutes(s2), d = _toMinutes(e2);
    return (a < d) && (c < b);
  }

  /// Cek apakah suatu blok 1 jam sudah di-booking
  bool _isHourBooked(String blockStart, String blockEnd) {
    for (final b in _existingBookings) {
      if (b.status == BookingStatus.cancelled ||
          b.status == BookingStatus.completed) {
        continue;
      }
      final bs = _normalizeTime(b.startTime);
      final be = _normalizeTime(b.endTime);
      if (_timeRangesOverlap(blockStart, blockEnd, bs, be)) return true;
    }
    return false;
  }

  /// Cek apakah suatu blok jam diblokir oleh OPD/Pimpinan.
  ///
  /// Mengecek SELURUH RANGE yang dipilih (dari startTime hingga startTime + duration jam)
  /// untuk menemukan blocking OPD/Pimpinan. Ini memastikan jika ada OPD block di jam manapun
  /// dalam range yang dipilih (termasuk jam ke-2, ke-3, dll), label OPD akan ditampilkan.
  ///
  /// Label yang dikembalikan (prioritas):
  ///   1. opdName  (nama organisasi dari opd_organizations)
  ///   2. bookedForLabel (keterangan acara, misal "Bupati Cup 2026")
  ///   3. displayName tipe booking ("OPD" / "Pimpinan")
  String? _getOpdLabelForSlot(String startTime, int duration) {
    // Cek SELURUH RANGE (bukan hanya jam pertama) untuk blokir OPD
    // Contoh: jika user mau booking 08:00-10:00 (2 jam), cek 08:00-10:00 penuh
    // untuk OPD block, agar label muncul meski OPD block ada di jam ke-2
    final rangeEnd = _calcEndTime(startTime, duration);

    for (final b in _existingBookings) {
      if (b.status == BookingStatus.cancelled ||
          b.status == BookingStatus.completed) {
        continue;
      }
      if (!b.bookingType.isOfficialBooking) continue;
      final bs = _normalizeTime(b.startTime);
      final be = _normalizeTime(b.endTime);
      // Cek overlap dengan SELURUH range yang dipilih
      if (_timeRangesOverlap(startTime, rangeEnd, bs, be)) {
        // Tampilkan: nama OPD → keterangan acara → tipe booking
        return b.opdName ?? b.bookedForLabel ?? b.bookingType.displayName;
      }
    }
    return null;
  }

  /// Cek apakah range (startTime + duration jam) sepenuhnya tersedia
  bool _isRangeAvailable(String startTime, int duration) {
    final startH = int.parse(startTime.split(':')[0]);
    for (int h = startH; h < startH + duration; h++) {
      final bs = '${h.toString().padLeft(2, '0')}:00';
      final be = '${(h + 1).toString().padLeft(2, '0')}:00';
      if (_isHourBooked(bs, be)) return false;
    }
    return true;
  }

  // ── calendar helpers ──────────────────────────────────────────
  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final days = <DateTime>[];
    final offset = first.weekday % 7;
    for (int i = 0; i < offset; i++) {
      days.add(DateTime(0));
    }
    for (int i = 1; i <= lastDay; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  String _monthYearStr(DateTime d) {
    const m = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${m[d.month - 1]} ${d.year}';
  }

  // ── build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pilih Tanggal & Waktu',
                    style: GoogleFonts.mulish(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                // Realtime dot
                Tooltip(
                  message: _realtimeConnected
                      ? 'Pembaruan otomatis aktif'
                      : 'Tekan refresh untuk update manual',
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _realtimeConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoadingBookings ? null : _refreshData,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: _isLoadingBookings
                        ? Colors.grey
                        : AppColors.primaryDark,
                  ),
                  tooltip: 'Refresh ketersediaan',
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 24),

                  // ── Info durasi tetap (perSesi / harian) ───
                  // Ditampilkan untuk semua mode dengan durasi tetap
                  if (_hasFixedDuration) ...[
                    _buildFixedSessionInfo(),
                    const SizedBox(height: 20),
                  ],

                  // ── Durasi Bermain (Hari) – untuk unit Hari
                  if (_bookingMode == BookingMode.harian) ...[
                    _sectionTitle('📅  Durasi Bermain'),
                    const SizedBox(height: 10),
                    _buildDayDurationSelector(),
                    const SizedBox(height: 20),
                  ] else if (!_hasFixedDuration) ...[
                    _sectionTitle('📅  Durasi Bermain'),
                    const SizedBox(height: 10),
                    _buildDayDurationSelector(),
                    const SizedBox(height: 20),
                  ],

                  // ── Durasi Per Sesi (Jam) – hanya perJam/perOrang, 1 hari ──
                  if (!_hasFixedDuration) ...[
                    if (_selectedDays == 1) ...[
                      _sectionTitle('⏱️  Durasi Per Sesi'),
                      const SizedBox(height: 10),
                      _buildDurationSelector(),
                      const SizedBox(height: 20),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Booking lebih dari 1 hari dihitung per hari. Durasi sesi tidak diperlukan.',
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],

                  // Summary durasi (tampil jika time slot sudah dipilih)
                  if (_selectedStartTime != null) ...[
                    _buildDurationSummary(),
                    const SizedBox(height: 16),
                  ],

                  // ── Jumlah Orang (hanya untuk mode perOrang) ─────
                  if (_bookingMode == BookingMode.perOrang) ...[
                    _sectionTitle('👥  Jumlah Peserta'),
                    const SizedBox(height: 10),
                    _buildPeopleCounter(),
                    const SizedBox(height: 20),
                  ],

                  // ── Resepsi: info waktu tetap (tidak ada grid jam) ────────
                  if (BookingMode.resepsiDurationFromName(
                        widget.field?.venueName,
                      ) !=
                      null) ...[
                    _buildResepsiFixedTimeInfo(),
                    const SizedBox(height: 20),
                  ],

                  // ── Jam Mulai – untuk semua mode kecuali full-day ──
                  if (!_isFullDayBooking) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('⏰  Pilih Jam Mulai'),
                        if (_isLoadingBookings)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jam selesai otomatis terhitung dari durasi yang dipilih',
                      style: GoogleFonts.mulish(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStartTimeGrid(),
                  ] else if (_isFullDayBooking && _isLoadingBookings) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],

                  // Legend & realtime info – sembunyikan untuk full-day
                  if (!_isFullDayBooking) ...[
                    // Legend
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _legendItem(
                            const Color(0xFFF0F9F4),
                            const Color.fromARGB(255, 0, 113, 72),
                            'Tersedia',
                          ),
                          _legendItem(
                            const Color(0xFFE0E0E0),
                            const Color(0xFFBDBDBD),
                            'Penuh / Terpesan',
                          ),
                          _legendItem(
                            const Color.fromARGB(255, 0, 113, 72),
                            const Color.fromARGB(255, 0, 113, 72),
                            'Dipilih',
                          ),
                          _legendItem(
                            const Color(0xFFFFF8E1),
                            const Color(0xFFFFA726),
                            'Diblokir OPD/Pimpinan',
                          ),
                        ],
                      ),
                    ),

                    // Realtime info
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            _realtimeConnected
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 14,
                            color: _realtimeConnected
                                ? Colors.green[600]
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _realtimeConnected
                                  ? 'Jadwal diperbarui otomatis saat ada booking baru'
                                  : 'Tekan tombol refresh untuk memperbarui ketersediaan',
                              style: GoogleFonts.mulish(
                                fontSize: 11,
                                color: _realtimeConnected
                                    ? Colors.green[600]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Tombol konfirmasi
          _buildConfirmButton(),
        ],
      ),
    );
  }

  // ── section title ─────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryDark,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── duration summary ──────────────────────────────────────────
  Widget _buildDurationSummary() {
    final end = _calcEndTime(_selectedStartTime!, _selectedDuration);
    final endDate = _selectedDate.add(Duration(days: _selectedDays - 1));
    final isMultiDay = _selectedDays > 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: Color.fromARGB(255, 0, 113, 72),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedDays > 1
                      ? '$_selectedStartTime – $end'
                      : '$_selectedStartTime – $end  ($_selectedDuration jam)',
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 0, 113, 72),
                  ),
                ),
              ),
            ],
          ),
          if (isMultiDay) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 16,
                  color: Color.fromARGB(255, 0, 113, 72),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDateShort(_selectedDate)} – ${_formatDateShort(endDate)}'
                    '  ($_selectedDays hari)',
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 0, 113, 72),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── calendar ──────────────────────────────────────────────────
  Widget _buildCalendar() {
    final days = _getDaysInMonth(_currentMonth);
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month - 1,
                    1,
                  );
                }),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.primaryDark,
              ),
              Text(
                _monthYearStr(_currentMonth),
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                    1,
                  );
                }),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.primaryDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map(
                  (d) => SizedBox(
                    width: 40,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              if (day.year == 0) return const SizedBox.shrink();

              final isSelected =
                  day.year == _selectedDate.year &&
                  day.month == _selectedDate.month &&
                  day.day == _selectedDate.day;
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final isPast = day.isBefore(
                DateTime(today.year, today.month, today.day),
              );

              return GestureDetector(
                onTap: isPast
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = day;
                          _selectedStartTime = null;
                          _selectedTimeSlot = null;
                        });
                        if (_isFullDayBooking) {
                          // Harian 24 jam: setelah load selesai, langsung set slot penuh
                          _loadBookingsForDate(day).then((_) {
                            if (mounted) {
                              setState(() {
                                _selectedStartTime = '00:00';
                                _selectedTimeSlot = '00:00 - 00:00';
                              });
                            }
                          });
                        } else if (_isFixedHourHarian) {
                          // Resepsi: re-lock jam ke 06:00 setelah tanggal berubah
                          _loadBookingsForDate(day).then((_) {
                            if (mounted) {
                              final start =
                                  '${_kOpStart.toString().padLeft(2, '0')}:00';
                              setState(() {
                                _selectedStartTime = start;
                                _selectedTimeSlot =
                                    '$start - ${_calcEndTime(start, _selectedDuration)}';
                              });
                            }
                          });
                        } else {
                          _loadBookingsForDate(day);
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 0, 113, 72),
                              Color.fromARGB(255, 0, 117, 164),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isToday ? Colors.blue[50] : null),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: Colors.blue, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isPast
                            ? Colors.grey[400]
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── day duration selector (1 – 7 hari) ───────────────────────
  Widget _buildDayDurationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final days = i + 1;
        final isSelected = _selectedDays == days;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDays = days;
            if (!_hasFixedDuration && days > 1) {
              // Untuk multi-hari, durasi sesi dikunci ke 1 jam
              _selectedDuration = 1;
              // Recalculate time slot with duration 1
              if (_selectedStartTime != null) {
                if (_isRangeAvailable(_selectedStartTime!, 1)) {
                  _selectedTimeSlot =
                      '$_selectedStartTime - ${_calcEndTime(_selectedStartTime!, 1)}';
                } else {
                  _selectedStartTime = null;
                  _selectedTimeSlot = null;
                }
              }
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          0,
                          113,
                          72,
                        ).withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$days Hari',
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.secondaryDark,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── duration selector ─────────────────────────────────────────
  Widget _buildDurationSelector() {
    return Row(
      children: [1, 2, 3, 4].map((hours) {
        final isSelected = _selectedDuration == hours;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedDuration = hours;
              if (_selectedStartTime != null) {
                if (_isRangeAvailable(_selectedStartTime!, hours)) {
                  _selectedTimeSlot =
                      '$_selectedStartTime - ${_calcEndTime(_selectedStartTime!, hours)}';
                } else {
                  _selectedStartTime = null;
                  _selectedTimeSlot = null;
                }
              }
            }),
            child: Container(
              margin: EdgeInsets.only(right: hours < 4 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            0,
                            113,
                            72,
                          ).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$hours Jam',
                textAlign: TextAlign.center,
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.secondaryDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── start time grid ───────────────────────────────────────────
  Widget _buildStartTimeGrid() {
    if (_isLoadingBookings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final starts = _startTimes;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3, // Increased for 2-line time display
      ),
      itemCount: starts.length,
      itemBuilder: (context, idx) {
        final startTime = starts[idx];
        final endTime = _calcEndTime(startTime, _selectedDuration);
        final isSelected = _selectedStartTime == startTime;
        final isAvailable = _isRangeAvailable(startTime, _selectedDuration);
        final isUnavailable = !isAvailable;
        final opdLabel = isUnavailable
            ? _getOpdLabelForSlot(startTime, _selectedDuration)
            : null;
        final isOpdSlot = opdLabel != null;

        final Color bgColor, borderColor, timeColor, subColor;
        if (isSelected) {
          bgColor = Colors.transparent;
          borderColor = Colors.transparent;
          timeColor = Colors.white;
          subColor = Colors.white.withOpacity(0.85);
        } else if (isOpdSlot) {
          bgColor = const Color(0xFFFFF8E1);
          borderColor = Colors.orange.shade400;
          timeColor = Colors.orange.shade800;
          subColor = Colors.orange.shade700;
        } else if (isUnavailable) {
          bgColor = const Color(0xFFE0E0E0);
          borderColor = const Color(0xFFBDBDBD);
          timeColor = const Color(0xFF9E9E9E);
          subColor = const Color(0xFF9E9E9E);
        } else {
          bgColor = const Color(0xFFF0F9F4);
          borderColor = const Color.fromARGB(255, 0, 113, 72);
          timeColor = AppColors.primaryDark;
          subColor = const Color.fromARGB(255, 0, 113, 72);
        }

        return GestureDetector(
          onTap: isUnavailable
              ? () => _showUnavailableDialog(
                  startTime,
                  endTime,
                  opdLabel: opdLabel,
                )
              : () async {
                  // Final availability check before selecting
                  await _refreshData();
                  if (!mounted) return;
                  if (_isRangeAvailable(startTime, _selectedDuration)) {
                    setState(() {
                      _selectedStartTime = startTime;
                      _selectedTimeSlot = '$startTime - $endTime';
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Maaf, jadwal ini baru saja dipesan. Silakan pilih jam lain.',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 0, 113, 72),
                        Color.fromARGB(255, 0, 117, 164),
                      ],
                    )
                  : null,
              color: isSelected ? null : bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isOpdSlot)
                  const Icon(
                    Icons.account_balance,
                    size: 11,
                    color: Colors.orange,
                  ),
                Text(
                  // For perSesi mode, show time range instead of duration
                  _bookingMode == BookingMode.perSesi
                      ? '$startTime - $endTime'
                      : startTime,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                if (isOpdSlot || isUnavailable)
                  Text(
                    isOpdSlot ? _truncateOpdLabel(opdLabel) : 'Penuh',
                    style: GoogleFonts.mulish(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: subColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUnavailableDialog(String start, String end, {String? opdLabel}) {
    final isOpd = opdLabel != null;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isOpd ? Icons.account_balance : Icons.warning_amber_rounded,
              color: isOpd ? Colors.orange : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOpd ? 'Diblokir OPD / Pimpinan' : 'Jadwal Tidak Tersedia',
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOpd
                  ? 'Jam $start – $end diblokir untuk keperluan resmi:'
                  : 'Jam $start – $end sudah dipesan. Silakan pilih jam lain.',
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: AppColors.secondaryDark,
              ),
            ),
            if (isOpd) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_note,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opdLabel,
                        style: GoogleFonts.mulish(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mengerti',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 0, 113, 72),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── legend ────────────────────────────────────────────────────
  Widget _legendItem(Color color, Color borderColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 11,
            color: AppColors.secondaryDark,
          ),
        ),
      ],
    );
  }

  // ── people counter (perOrang mode) ───────────────────────────
  Widget _buildPeopleCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline,
            size: 18,
            color: Color.fromARGB(255, 0, 113, 72),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Jumlah Peserta (maks. $_maxPeople orang)',
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          IconButton(
            onPressed: _peopleCount > 1
                ? () => setState(() => _peopleCount--)
                : null,
            icon: Icon(
              Icons.remove_circle_outline,
              color: _peopleCount > 1
                  ? const Color.fromARGB(255, 0, 113, 72)
                  : Colors.grey[400],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$_peopleCount',
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          IconButton(
            onPressed: _peopleCount < _maxPeople
                ? () => setState(() => _peopleCount++)
                : null,
            icon: Icon(
              Icons.add_circle_outline,
              color: _peopleCount < _maxPeople
                  ? const Color.fromARGB(255, 0, 113, 72)
                  : Colors.grey[400],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ── fixed session info (untuk perSesi & harian) ───────────────
  Widget _buildFixedSessionInfo() {
    final isHarian = _bookingMode == BookingMode.harian;
    final duration = _fixedSessionDuration;
    final start = '${_kOpStart.toString().padLeft(2, '0')}:00';
    final end = _calcEndTime(start, duration);

    final bool isPertandingan = (widget.field?.satuan ?? '')
        .toLowerCase()
        .contains('pertandingan');

    final String durationText;
    if (isHarian) {
      if (isPertandingan) {
        durationText = 'Durasi Bermain: Satu Hari';
      } else if (_isFullDayBooking) {
        durationText = 'Durasi Bermain: Satu hari penuh (24 jam)';
      } else {
        durationText = 'Durasi Bermain: $duration jam';
      }
    } else {
      durationText = 'Durasi Sesi: $duration jam';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: Color.fromARGB(255, 0, 113, 72),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  durationText,
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 0, 113, 72),
                  ),
                ),
                if (isHarian) ...[
                  const SizedBox(height: 4),
                  Text(
                    isPertandingan
                        ? 'Pilih tanggal di kalender - Waktu Sesuai Pertandingan'
                        : _isFullDayBooking
                        ? 'Pilih tanggal di kalender — waktu sudah otomatis ditetapkan.'
                        : 'Pilih tanggal lalu pilih jam mulai di bawah.',
                    style: GoogleFonts.mulish(
                      fontSize: 11,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── resepsi fixed time info ───────────────────────────────────
  /// Info card waktu tetap untuk lapangan resepsi (cocok dengan chip di website).
  /// resepsi8  → 06:00 – 14:00 (8 jam eksklusif)
  /// resepsi18 → 06:00 – 00:00 (18 jam eksklusif)
  Widget _buildResepsiFixedTimeInfo() {
    final startStr = '${_kOpStart.toString().padLeft(2, '0')}:00';
    final endStr = _calcEndTime(startStr, _fixedSessionDuration);
    final duration = _fixedSessionDuration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎪', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paket Resepsi $duration Jam Eksklusif',
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6D28D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 6),
              Text(
                'Waktu: $startStr – $endStr  ($duration jam)',
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih tanggal di kalender. Waktu sudah ditetapkan secara otomatis.',
            style: GoogleFonts.mulish(
              fontSize: 11,
              color: const Color(0xFF7C3AED).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── confirm button ────────────────────────────────────────────
  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview jadwal yang dipilih
            if (_selectedTimeSlot != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color.fromARGB(
                      255,
                      0,
                      113,
                      72,
                    ).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 18,
                      color: Color.fromARGB(255, 0, 113, 72),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDateShort(_selectedDate)}  •  $_selectedTimeSlot'
                        '  •  $_selectedDays Hari',
                        style: GoogleFonts.mulish(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTimeSlot != null
                    ? () async {
                        // Final check sebelum konfirmasi
                        await _refreshData();
                        if (!mounted) return;

                        final stillAvailable =
                            _selectedStartTime != null &&
                            _isRangeAvailable(
                              _selectedStartTime!,
                              _selectedDuration,
                            );

                        if (stillAvailable) {
                          widget.onConfirm?.call(
                            _selectedDate,
                            _selectedTimeSlot!,
                            _selectedDays,
                            _peopleCount,
                          );
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _selectedStartTime = null;
                            _selectedTimeSlot = null;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Maaf, jadwal ini baru saja dipesan oleh pengguna lain. Silakan pilih jadwal lain.',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTimeSlot != null
                      ? const Color.fromARGB(255, 0, 113, 72)
                      : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _selectedTimeSlot != null
                      ? 'Konfirmasi Booking'
                      : _isFixedHourHarian
                      ? 'Pilih tanggal terlebih dahulu'
                      : (_bookingMode == BookingMode.harian)
                      ? 'Pilih tanggal terlebih dahulu'
                      : 'Pilih jam terlebih dahulu',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTimeSlot != null
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
