/// Fixed list of career/life statuses an alumnus can report.
const List<String> kAlumniStatuses = [
  'Employed',
  'Studying',
  'Job Seeking',
  'Other',
];

class AlumniUpdate {
  final int id;
  final int userId;
  final String status;
  final String organisation;
  final String roleOrProgramme;
  final String notes;
  final DateTime submittedAt;

  AlumniUpdate({
    required this.id,
    required this.userId,
    required this.status,
    required this.organisation,
    required this.roleOrProgramme,
    required this.notes,
    required this.submittedAt,
  });

  factory AlumniUpdate.fromJson(Map<String, dynamic> json) {
    return AlumniUpdate(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status'] ?? 'Other',
      organisation: json['organisation'] ?? '',
      roleOrProgramme: json['role_or_programme'] ?? '',
      notes: json['notes'] ?? '',
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'status': status,
        'organisation': organisation,
        'role_or_programme': roleOrProgramme,
        'notes': notes,
      };
}
