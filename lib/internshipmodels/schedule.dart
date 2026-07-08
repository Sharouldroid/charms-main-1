class Schedule {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String description; // now holds one of the fixed team names
  final String duration; // kept as String for backend compatibility
  final int maxRegistrations;
  final num? allowance; // Elaun (RM/bulan) — admin-adjustable per schedule

  Schedule({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.duration,
    this.maxRegistrations = kUnlimitedRegistrations,
    this.allowance,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'],
      duration: json['duration'].toString(),
      maxRegistrations:
          (json['max_registrations'] as num?)?.toInt() ?? kUnlimitedRegistrations,
      allowance: json['allowance'] != null
          ? num.tryParse(json['allowance'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'start_date':
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
        'end_date':
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
        'description': description,
        'duration': duration,
        'max_registrations': maxRegistrations,
        if (allowance != null) 'allowance': allowance,
      };
}

/// Fixed list of internship teams. Used both for the "Create Schedule"
/// dropdown and for filtering on the calendar / slot details screens.
const List<String> kInternshipTeams = [
  'Administration Team',
  'Digital Team',
  'Chagar Hutang Team',
  'Turtle Lab Team',
];

/// Sentinel value meaning "no limit" on registrations. The backend column
/// likely still requires an integer, so we send a very large number rather
/// than null. See the note at the end of this answer about updating the
/// Laravel side too, since this alone only stops the *app* from blocking
/// registrations — the API's own check-registration logic also needs to
/// stop enforcing a cap.
const int kUnlimitedRegistrations = 999999;