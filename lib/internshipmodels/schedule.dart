class Schedule {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final String duration; // kept as String for backend compatibility
  final int maxRegistrations; // ✅ ADDED

  Schedule({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.duration,
    this.maxRegistrations = 5, // ✅ Default value
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'],
      duration: json['duration'].toString(), // ✅ Convert to string
      maxRegistrations: json['max_registrations'] ?? 5, // ✅ ADDED
    );
  }

  Map<String, dynamic> toJson() => {
        'start_date':
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
        'end_date':
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
        'description': description,
        'duration': duration,
        'max_registrations': maxRegistrations, // ✅ ADDED
      };
}