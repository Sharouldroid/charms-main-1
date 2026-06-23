class Activity {
  final int? id;
  final int internId;
  final String? title;
  final String activityDescription;
  final DateTime createdAt;
  final String? internName;

  Activity({
    this.id,
    required this.internId,
    this.title,
    required this.activityDescription,
    required this.createdAt,
    this.internName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intern_id': internId,
      if (title != null) 'title': title,
      'activity_description': activityDescription,
      'created_at': createdAt.toIso8601String(),
      'intern_name': internName,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      internId: json['intern_id'],
      title: json['title']?.toString(),
      activityDescription: json['activity_description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      internName: json['intern_name'],
    );
  }
}
