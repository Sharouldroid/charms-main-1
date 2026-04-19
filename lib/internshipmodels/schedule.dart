class Schedule {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final String duration; // keep as String because Laravel validation uses string

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
      startDate: DateTime.parse(json['start_date']), // snake_case
      endDate: DateTime.parse(json['end_date']),     // snake_case
      description: json['description'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_date':
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
        'end_date':
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
        'description': description,
        'duration': duration,
      };
}
