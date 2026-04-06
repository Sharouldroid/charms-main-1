class Schedule {
  final int id;
  final DateTime startDate; // Replace date with startDate
  final DateTime endDate; // Add endDate
  final String description;
  final int duration;

  Schedule({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.duration,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']), // Parse startDate
      endDate: DateTime.parse(json['endDate']), // Parse endDate
      description: json['description'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate':
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}", // Format as YYYY-MM-DD
        'endDate':
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}", // Format as YYYY-MM-DD
        'description': description,
        'duration': duration,
      };
}
