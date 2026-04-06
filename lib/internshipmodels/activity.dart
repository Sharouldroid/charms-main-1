class Activity {
  final int? id;
  final int internId;
  final String activityDescription;
  final DateTime createdAt;
  final String? internName;

  Activity({
    this.id,
    required this.internId,
    required this.activityDescription,
    required this.createdAt,
    this.internName,
  });

  // Convert Activity object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intern_id': internId,
      'activity_description': activityDescription,
      'created_at': createdAt.toIso8601String(),
      'intern_name': internName,
    };
  }

  // Create Activity object from JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      internId: json['intern_id'],
      activityDescription: json['activity_description'],
      createdAt: DateTime.parse(json['created_at']),
      internName: json['intern_name'],
    );
  }
}
