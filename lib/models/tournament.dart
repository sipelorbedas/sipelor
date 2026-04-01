import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────
// Tournament — Event turnamen utama
// ──────────────────────────────────────────────────────────────────
class Tournament {
  final String id;
  final String name;
  final String? description;
  final String? posterUrl;
  final String? location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;
  final String status; // 'draft','open','ongoing','completed','cancelled'
  final String organizerName;
  final int maxTeamsPerSport;
  final DateTime createdAt;

  const Tournament({
    required this.id,
    required this.name,
    this.description,
    this.posterUrl,
    this.location,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    required this.status,
    required this.organizerName,
    required this.maxTeamsPerSport,
    required this.createdAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      posterUrl: json['poster_url'] as String?,
      location: json['location'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      organizerName:
          json['organizer_name'] as String? ?? 'DISPORA Kabupaten Bandung',
      maxTeamsPerSport: (json['max_teams_per_sport'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Pendaftaran Dibuka';
      case 'ongoing':
        return 'Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'draft':
      default:
        return 'Persiapan';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return const Color(0xFF4CAF50);
      case 'ongoing':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF9E9E9E);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'draft':
      default:
        return const Color(0xFFFFB300);
    }
  }
}

// ──────────────────────────────────────────────────────────────────
// TournamentSport — Cabang olahraga per turnamen
// ──────────────────────────────────────────────────────────────────
class TournamentSport {
  final String id;
  final String tournamentId;
  final String sportName;
  final String format;
  final int groupCount;
  final int teamsAdvancePerGroup;
  final int maxTeams;
  final String status; // 'registration','group_stage','knockout','completed'
  final DateTime createdAt;

  const TournamentSport({
    required this.id,
    required this.tournamentId,
    required this.sportName,
    required this.format,
    required this.groupCount,
    required this.teamsAdvancePerGroup,
    required this.maxTeams,
    required this.status,
    required this.createdAt,
  });

  factory TournamentSport.fromJson(Map<String, dynamic> json) {
    return TournamentSport(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      sportName: json['sport_name'] as String,
      format: json['format'] as String? ?? 'group_knockout',
      groupCount: (json['group_count'] as num?)?.toInt() ?? 2,
      teamsAdvancePerGroup:
          (json['teams_advance_per_group'] as num?)?.toInt() ?? 2,
      maxTeams: (json['max_teams'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'registration',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'registration':
        return 'Pendaftaran';
      case 'group_stage':
        return 'Fase Grup';
      case 'knockout':
        return 'Fase Gugur';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  IconData get sportIcon {
    final s = sportName.toLowerCase();
    if (s.contains('futsal') || s.contains('sepak') || s.contains('bola')) {
      return Icons.sports_soccer;
    } else if (s.contains('badminton') || s.contains('bulutangkis')) {
      return Icons.sports_tennis;
    } else if (s.contains('basket')) {
      return Icons.sports_basketball;
    } else if (s.contains('voli') || s.contains('volly') || s.contains('volleyball')) {
      return Icons.sports_volleyball;
    } else if (s.contains('tenis') && !s.contains('meja')) {
      return Icons.sports_tennis;
    } else if (s.contains('meja') || s.contains('pingpong')) {
      return Icons.sports_tennis;
    } else if (s.contains('renang') || s.contains('swim')) {
      return Icons.pool;
    } else if (s.contains('lari') || s.contains('atletik')) {
      return Icons.directions_run;
    } else {
      return Icons.emoji_events;
    }
  }
}

// ──────────────────────────────────────────────────────────────────
// TournamentTeam — Tim peserta
// ──────────────────────────────────────────────────────────────────
class TournamentTeam {
  final String id;
  final String tournamentId;
  final String sportId;
  final String teamName;
  final String? teamLogoUrl;
  final String captainName;
  final String? captainPhone;
  final String? asalKecamatan;
  final int jumlahPemain;
  final String status; // 'pending','approved','rejected'
  final String? groupName;
  final int seeding;
  final String? notes;

  const TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.sportId,
    required this.teamName,
    this.teamLogoUrl,
    required this.captainName,
    this.captainPhone,
    this.asalKecamatan,
    required this.jumlahPemain,
    required this.status,
    this.groupName,
    required this.seeding,
    this.notes,
  });

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      sportId: json['sport_id'] as String,
      teamName: json['team_name'] as String,
      teamLogoUrl: json['team_logo_url'] as String?,
      captainName: json['captain_name'] as String? ?? '',
      captainPhone: json['captain_phone'] as String?,
      asalKecamatan: json['asal_kecamatan'] as String?,
      jumlahPemain: (json['jumlah_pemain'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      groupName: json['group_name'] as String?,
      seeding: (json['seeding'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFFB300);
    }
  }
}

// ──────────────────────────────────────────────────────────────────
// TournamentMatch — Jadwal pertandingan
// ──────────────────────────────────────────────────────────────────
class TournamentMatch {
  final String id;
  final String tournamentId;
  final String sportId;
  final String phase;
  final int round;
  final int matchNumber;
  final String? groupName;
  final String? teamAId;
  final String? teamBId;
  final String? teamAName;
  final String? teamBName;
  final int? teamAScore;
  final int? teamBScore;
  final String? winnerId;
  final bool isDraw;
  final DateTime? scheduledAt;
  final String? venueName;
  final String status; // 'scheduled','ongoing','completed','cancelled','walkover'
  final String? notes;

  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.sportId,
    required this.phase,
    required this.round,
    required this.matchNumber,
    this.groupName,
    this.teamAId,
    this.teamBId,
    this.teamAName,
    this.teamBName,
    this.teamAScore,
    this.teamBScore,
    this.winnerId,
    required this.isDraw,
    this.scheduledAt,
    this.venueName,
    required this.status,
    this.notes,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      sportId: json['sport_id'] as String,
      phase: json['phase'] as String,
      round: (json['round'] as num?)?.toInt() ?? 1,
      matchNumber: (json['match_number'] as num?)?.toInt() ?? 1,
      groupName: json['group_name'] as String?,
      teamAId: json['team_a_id'] as String?,
      teamBId: json['team_b_id'] as String?,
      teamAName: json['team_a_name'] as String?,
      teamBName: json['team_b_name'] as String?,
      teamAScore: (json['team_a_score'] as num?)?.toInt(),
      teamBScore: (json['team_b_score'] as num?)?.toInt(),
      winnerId: json['winner_id'] as String?,
      isDraw: json['is_draw'] as bool? ?? false,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      venueName: json['venue_name'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      notes: json['notes'] as String?,
    );
  }

  TournamentMatch copyWith({
    String? teamAId,
    String? teamBId,
    String? teamAName,
    String? teamBName,
    int? teamAScore,
    int? teamBScore,
    String? winnerId,
    String? status,
  }) {
    return TournamentMatch(
      id: id,
      tournamentId: tournamentId,
      sportId: sportId,
      phase: phase,
      round: round,
      matchNumber: matchNumber,
      groupName: groupName,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      winnerId: winnerId ?? this.winnerId,
      isDraw: isDraw,
      scheduledAt: scheduledAt,
      venueName: venueName,
      status: status ?? this.status,
      notes: notes,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isOngoing => status == 'ongoing';
  bool get hasScore => teamAScore != null && teamBScore != null;

  String get phaseLabel {
    switch (phase) {
      case 'group':
        return 'Fase Grup';
      case 'round_of_16':
        return '16 Besar';
      case 'quarterfinal':
        return 'Perempat Final';
      case 'semifinal':
        return 'Semi Final';
      case 'final':
        return 'Final';
      case 'third_place':
        return 'Perebutan Juara 3';
      default:
        return phase;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'ongoing':
        return 'Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'walkover':
        return 'WO';
      case 'scheduled':
      default:
        return 'Dijadwalkan';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'ongoing':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'walkover':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFFFFB300);
    }
  }
}

// ──────────────────────────────────────────────────────────────────
// TournamentStanding — Klasemen grup
// ──────────────────────────────────────────────────────────────────
class TournamentStanding {
  final String id;
  final String tournamentId;
  final String sportId;
  final String groupName;
  final String teamId;
  final String? teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const TournamentStanding({
    required this.id,
    required this.tournamentId,
    required this.sportId,
    required this.groupName,
    required this.teamId,
    this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory TournamentStanding.fromJson(Map<String, dynamic> json) {
    return TournamentStanding(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      sportId: json['sport_id'] as String,
      groupName: json['group_name'] as String,
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String?,
      played: (json['played'] as num?)?.toInt() ?? 0,
      won: (json['won'] as num?)?.toInt() ?? 0,
      drawn: (json['drawn'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      goalsFor: (json['goals_for'] as num?)?.toInt() ?? 0,
      goalsAgainst: (json['goals_against'] as num?)?.toInt() ?? 0,
      goalDifference: (json['goal_difference'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}
