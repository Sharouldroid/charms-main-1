/// A single one-on-one interview time slot created by an admin.
/// Unlike [Schedule] (a shared intake/team batch), each InterviewSession
/// belongs to exactly one intern once booked.
class InterviewSession {
  final int id;
  final DateTime date;
  final String startTime; // e.g. "10:00"
  final String endTime; // e.g. "10:30"
  final String status; // 'available' | 'booked' | 'completed' | 'cancelled'
  final String? meetingLink;
  final int? userId; // set once booked
  final String? internName; // convenience display field from backend join

  InterviewSession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.meetingLink,
    this.userId,
    this.internName,
  });

  bool get isAvailable => status == 'available';
  bool get isBooked => status == 'booked';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    return InterviewSession(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date']),
      startTime: json['start_time'].toString(),
      endTime: json['end_time'].toString(),
      status: json['status'] ?? 'available',
      meetingLink: json['meeting_link'],
      userId: json['user_id'] != null ? (json['user_id'] as num).toInt() : null,
      internName: json['intern_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'date':
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        'meeting_link': meetingLink,
        'user_id': userId,
      };
}
