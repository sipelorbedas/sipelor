/// Maintenance status enum
enum MaintenanceStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return 'Dijadwalkan';
      case MaintenanceStatus.inProgress:
        return 'Sedang Berlangsung';
      case MaintenanceStatus.completed:
        return 'Selesai';
      case MaintenanceStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get value {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return 'scheduled';
      case MaintenanceStatus.inProgress:
        return 'in_progress';
      case MaintenanceStatus.completed:
        return 'completed';
      case MaintenanceStatus.cancelled:
        return 'cancelled';
    }
  }

  static MaintenanceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return MaintenanceStatus.scheduled;
      case 'in_progress':
        return MaintenanceStatus.inProgress;
      case 'completed':
        return MaintenanceStatus.completed;
      case 'cancelled':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.scheduled;
    }
  }
}

/// Maintenance schedule model
class MaintenanceSchedule {
  final String id;
  final String venueId;
  final String? fieldId; // Optional: specific field or entire venue
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final MaintenanceStatus status;
  final String? assignedTo; // Staff ID
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined data
  final String? venueName;
  final String? fieldName;
  final String? assignedStaffName;

  MaintenanceSchedule({
    required this.id,
    required this.venueId,
    this.fieldId,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.assignedTo,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.venueName,
    this.fieldName,
    this.assignedStaffName,
  });

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) {
    // Handle nested venue/field data from join
    String? venueName;
    String? fieldName;
    String? assignedStaffName;

    if (json['venues'] != null && json['venues'] is Map) {
      venueName = json['venues']['name'] as String?;
    }
    if (json['fields'] != null && json['fields'] is Map) {
      fieldName = json['fields']['area'] as String?;
    }
    if (json['staff'] != null && json['staff'] is Map) {
      assignedStaffName = json['staff']['name'] as String?;
    }

    return MaintenanceSchedule(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      fieldId: json['field_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: MaintenanceStatus.fromString(json['status'] as String),
      assignedTo: json['assigned_to'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      venueName: venueName,
      fieldName: fieldName,
      assignedStaffName: assignedStaffName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'field_id': fieldId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.value,
      'assigned_to': assignedTo,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaintenanceSchedule copyWith({
    String? id,
    String? venueId,
    String? fieldId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    MaintenanceStatus? status,
    String? assignedTo,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? venueName,
    String? fieldName,
    String? assignedStaffName,
  }) {
    return MaintenanceSchedule(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      fieldId: fieldId ?? this.fieldId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      venueName: venueName ?? this.venueName,
      fieldName: fieldName ?? this.fieldName,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
    );
  }

  bool get isActive => status == MaintenanceStatus.inProgress;
  bool get isPending => status == MaintenanceStatus.scheduled;
  bool get isDone => status == MaintenanceStatus.completed;
}
