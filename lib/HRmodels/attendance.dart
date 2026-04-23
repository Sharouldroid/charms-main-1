import 'dart:convert';

class Attendance {
  final int attendanceId;
  final int staffId;
  final int scheduleId;
  final DateTime? clockInTime;
  final dynamic clockInImage;
  final String? clockInImagePath; 
  final String? clockInImageUrl;
  final int attendanceStatus;
  final DateTime createdAt;

  Attendance({
    required this.attendanceId,
    required this.staffId,
    required this.scheduleId,
    this.clockInTime,
    this.clockInImage,
    this.clockInImagePath,
    this.clockInImageUrl,
    this.attendanceStatus = 1,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendance_id'],
      staffId: json['staff_id'],
      scheduleId: json['schedule_id'],
      clockInTime: json['clock_in_time'] != null
          ? DateTime.parse(json['clock_in_time'])
          : null,
      clockInImage: json['clock_in_image'],
      clockInImagePath: json['clock_in_image_path'],
      clockInImageUrl: json['clock_in_image_url'], 
      attendanceStatus: json['attendance_status'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance_id': attendanceId,
      'staff_id': staffId,
      'schedule_id': scheduleId,
      'clock_in_time': clockInTime?.toIso8601String(),
      'attendance_status': attendanceStatus,
    };
  }
}