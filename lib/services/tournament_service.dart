import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tournament.dart';

class TournamentService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ── Tournaments ────────────────────────────────────────────────

  /// Fetch all tournaments, newest first.
  /// [publicOnly] jika true, sembunyikan 'draft' dari tampilan publik.
  static Future<List<Tournament>> fetchTournaments({
    bool publicOnly = false, // tampilkan semua termasuk draft
  }) async {
    try {
      final response = await _client
          .from('tournaments')
          .select()
          .order('start_date', ascending: false);

      final all = (response as List)
          .map((j) => Tournament.fromJson(j as Map<String, dynamic>))
          .toList();

      if (publicOnly) {
        return all.where((t) => t.status != 'draft').toList();
      }
      return all;
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] fetchTournaments: $e');
      // Re-throw agar UI bisa menampilkan pesan error yang spesifik
      rethrow;
    }
  }

  /// Fetch a single tournament by ID.
  static Future<Tournament?> fetchTournamentById(String id) async {
    try {
      final response = await _client
          .from('tournaments')
          .select()
          .eq('id', id)
          .single();
      return Tournament.fromJson(response);
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] fetchTournamentById: $e');
      return null;
    }
  }

  // ── Tournament Sports ──────────────────────────────────────────

  /// Fetch all cabang olahraga for a given tournament.
  static Future<List<TournamentSport>> fetchSports(
    String tournamentId,
  ) async {
    try {
      final response = await _client
          .from('tournament_sports')
          .select()
          .eq('tournament_id', tournamentId)
          .order('sport_name', ascending: true);

      return (response as List)
          .map((j) => TournamentSport.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] fetchSports: $e');
      return [];
    }
  }

  // ── Teams ──────────────────────────────────────────────────────

  /// Fetch teams for a given sport. Optionally filter by status.
  static Future<List<TournamentTeam>> fetchTeams(
    String sportId, {
    String? status, // 'pending' | 'approved' | 'rejected'
  }) async {
    try {
      var query = _client
          .from('tournament_teams')
          .select()
          .eq('sport_id', sportId)
          .order('seeding', ascending: true);

      final response = await query;
      final teams = (response as List)
          .map((j) => TournamentTeam.fromJson(j as Map<String, dynamic>))
          .toList();

      if (status != null) {
        return teams.where((t) => t.status == status).toList();
      }
      return teams;
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] fetchTeams: $e');
      return [];
    }
  }

  // ── Matches ────────────────────────────────────────────────────

  /// Fetch matches for a given sport, optionally filtered by phase.
  static Future<List<TournamentMatch>> fetchMatches(
    String sportId, {
    String? phase,
  }) async {
    try {
      var query = _client
          .from('tournament_matches')
          .select()
          .eq('sport_id', sportId)
          .order('scheduled_at', ascending: true);

      final response = await query;
      final matches = (response as List)
          .map((j) => TournamentMatch.fromJson(j as Map<String, dynamic>))
          .toList();

      if (phase != null) {
        return matches.where((m) => m.phase == phase).toList();
      }
      return matches;
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] fetchMatches: $e');
      return [];
    }
  }

  // ── Team Registration ──────────────────────────────────────────

  /// Cek apakah user sudah mendaftarkan tim di turnamen ini (1 akun = 1 tim per turnamen).
  static Future<TournamentTeam?> checkExistingRegistration({
    required String tournamentId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('tournament_teams')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('captain_user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return TournamentTeam.fromJson(response);
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] checkExistingRegistration: $e');
      return null;
    }
  }

  /// Daftarkan tim baru ke turnamen.
  static Future<TournamentTeam> registerTeam({
    required String tournamentId,
    required String sportId,
    required String teamName,
    required String captainName,
    required String captainPhone,
    required String captainEmail,
    required String captainUserId,
    String? asalKecamatan,
    int jumlahPemain = 0,
  }) async {
    final data = {
      'tournament_id': tournamentId,
      'sport_id': sportId,
      'team_name': teamName.trim(),
      'captain_name': captainName.trim(),
      'captain_phone': captainPhone.trim(),
      'captain_email': captainEmail.trim(),
      'captain_user_id': captainUserId,
      'asal_kecamatan': asalKecamatan?.trim(),
      'jumlah_pemain': jumlahPemain,
      'status': 'pending',
    };

    final response = await _client
        .from('tournament_teams')
        .insert(data)
        .select()
        .single();

    return TournamentTeam.fromJson(response);
  }

  // ── Bracket Advancement ────────────────────────────────────────

  /// Resolves knockout bracket advancement entirely client-side.
  ///
  /// Winners from completed matches are propagated into the next-round slots
  /// using **relative per-phase ordering** (sorted by matchNumber within each
  /// phase), so the logic is correct regardless of whether the DB uses
  /// per-phase or global/sequential match numbers.
  ///
  /// Slot assignment within the next-round match:
  ///   - relative index 0, 2, 4 … (even) → teamA slot
  ///   - relative index 1, 3, 5 … (odd)  → teamB slot
  ///   - nextMatchIndex = relativeIndex ~/ 2
  ///
  /// Semi-final *losers* are additionally placed into the third-place match.
  /// Only null / empty / "TBD" slots are overwritten — existing real values
  /// are always preserved.
  ///
  /// Returns a new list (original order preserved) with resolved names.
  static List<TournamentMatch> resolveKnockoutBracket(
    List<TournamentMatch> matches,
  ) {
    // Mutable map keyed by match id so we can patch in-place.
    final resolved = <String, TournamentMatch>{
      for (final m in matches) m.id: m,
    };

    // Phase progression for winner advancement.
    const phaseNext = <String, String>{
      'round_of_16': 'quarterfinal',
      'quarterfinal': 'semifinal',
      'semifinal': 'final',
    };

    // A slot needs filling when the team name is absent or still a placeholder.
    // We intentionally do NOT require teamId to be present — many setups store
    // only names in the match row without repeating the team UUID.
    bool needsFill(String? name) =>
        name == null ||
        name.trim().isEmpty ||
        name.trim().toUpperCase() == 'TBD';

    // Resolve winner name from a completed match.
    // Returns null when the winner cannot be determined safely.
    String? winnerName0(TournamentMatch m) {
      final wid = m.winnerId;
      if (wid == null) return null;

      // Prefer ID-based resolution when team IDs are available.
      if (m.teamAId != null || m.teamBId != null) {
        if (m.teamAId != null && wid == m.teamAId) return m.teamAName;
        if (m.teamBId != null && wid == m.teamBId) return m.teamBName;
        // winner_id doesn't match either stored ID — data inconsistency, skip.
        return null;
      }

      // IDs absent — cannot determine winner safely.
      return null;
    }

    // ── Winner advancement: round_of_16 → quarterfinal → semifinal → final ──
    for (final phase in ['round_of_16', 'quarterfinal', 'semifinal']) {
      final nextPhase = phaseNext[phase]!;

      // Sort current-phase matches by matchNumber for stable relative indexing.
      final phaseMatches = resolved.values
          .where((m) => m.phase == phase)
          .toList()
        ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

      // Sort next-phase matches by matchNumber for stable target lookup.
      final nextPhaseMatches = resolved.values
          .where((m) => m.phase == nextPhase)
          .toList()
        ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

      if (nextPhaseMatches.isEmpty) continue;

      for (int i = 0; i < phaseMatches.length; i++) {
        final match = phaseMatches[i];
        if (match.status != 'completed' || match.winnerId == null) continue;

        final winnerName = winnerName0(match);
        if (winnerName == null) continue;
        final winnerId = match.winnerId!;

        // Relative index → which next-phase match and which slot.
        final nextMatchIndex = i ~/ 2;
        final isSlotA = i % 2 == 0;

        if (nextMatchIndex >= nextPhaseMatches.length) continue;
        var target = nextPhaseMatches[nextMatchIndex];

        final currentName = isSlotA ? target.teamAName : target.teamBName;
        if (!needsFill(currentName)) continue; // preserve existing value

        final patched = isSlotA
            ? target.copyWith(teamAId: winnerId, teamAName: winnerName)
            : target.copyWith(teamBId: winnerId, teamBName: winnerName);

        resolved[target.id] = patched;
        // Keep the in-memory list in sync for subsequent iterations.
        nextPhaseMatches[nextMatchIndex] = patched;
      }
    }

    // ── Loser advancement: semifinal → third_place ─────────────────────────
    final thirdPlaceList = resolved.values
        .where((m) => m.phase == 'third_place')
        .toList();
    if (thirdPlaceList.isNotEmpty) {
      var tp = thirdPlaceList.first;
      final semis = resolved.values
          .where((m) =>
              m.phase == 'semifinal' &&
              m.status == 'completed' &&
              m.winnerId != null)
          .toList()
        ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

      for (int i = 0; i < semis.length && i < 2; i++) {
        final sf = semis[i];

        // Null-safe loser resolution.
        String? loserName;
        String? loserId;
        if (sf.teamAId != null && sf.winnerId == sf.teamAId) {
          loserName = sf.teamBName;
          loserId = sf.teamBId;
        } else if (sf.teamBId != null && sf.winnerId == sf.teamBId) {
          loserName = sf.teamAName;
          loserId = sf.teamAId;
        } else {
          continue;
        }
        if (loserName == null || loserId == null) continue;

        final isSlotA = i == 0;
        final currentName = isSlotA ? tp.teamAName : tp.teamBName;
        if (!needsFill(currentName)) continue;

        tp = isSlotA
            ? tp.copyWith(teamAId: loserId, teamAName: loserName)
            : tp.copyWith(teamBId: loserId, teamBName: loserName);
      }
      resolved[tp.id] = tp;
    }

    // Return in the same order as the original list.
    return matches.map((m) => resolved[m.id] ?? m).toList();
  }

  // ── Standings ──────────────────────────────────────────────────

  /// Fetch klasemen for a given sport, ordered by points desc.
  static Future<List<TournamentStanding>> fetchStandings(
    String sportId,
  ) async {
    try {
      final response = await _client
          .from('tournament_standings')
          .select()
          .eq('sport_id', sportId)
          .order('points', ascending: false)
          .order('goal_difference', ascending: false);

      return (response as List)
          .map((j) => TournamentStanding.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ [TournamentService] fetchStandings: $e');
      return [];
    }
  }
}
