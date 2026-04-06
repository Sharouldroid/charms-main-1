import 'dart:convert';

class Attendance {
  final int attendanceId;
  final int staffId;
  final int scheduleId;
  final DateTime? clockInTime;
  final dynamic clockInImage;
  final int attendanceStatus;
  final DateTime createdAt;

  Attendance({
    required this.attendanceId,
    required this.staffId,
    required this.scheduleId,
    this.clockInTime,
    this.clockInImage,
    this.attendanceStatus = 1,
    required this.createdAt,
  });

  String? getImageAsBase64() {
    if (clockInImage == null) return null;
    
    if (clockInImage is Map && clockInImage['data'] != null) {
      // Handle Buffer format from backend
      final List<int> imageData = List<int>.from(clockInImage['data']);
      return base64Encode(imageData);
    } else if (clockInImage is String) {
      // Return as-is if already base64
      return clockInImage;
    }
    return null;
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendance_id'],
      staffId: json['staff_id'],
      scheduleId: json['schedule_id'],
      clockInTime: json['clock_in_time'] != null ? DateTime.parse(json['clock_in_time']) : null,
      clockInImage: json['clock_in_image'],
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
      'clock_in_image': getImageAsBase64(),
      'attendance_status': attendanceStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}