class Attendance {
  final int attendanceId;
  final int staffId;
  final int scheduleId;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInLocation;  // ← REPLACES clockInImage/clockInImagePath/clockInImageUrl
  final int attendanceStatus;
  final DateTime createdAt;

  Attendance({
    required this.attendanceId,
    required this.staffId,
    required this.scheduleId,
    this.clockInTime,
    this.clockOutTime,
    this.clockInLocation,
    this.attendanceStatus = 1,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId:     json['attendance_id'],
      staffId:          json['staff_id'],
      scheduleId:       json['schedule_id'],
      clockInTime:      json['clock_in_time'] != null
                          ? DateTime.parse(json['clock_in_time'])
                          : null,
      clockOutTime:     json['clock_out_time'] != null
                          ? DateTime.parse(json['clock_out_time'])
                          : null,
      clockInLocation:  json['clock_in_location'],   // ← NEW
      attendanceStatus: json['attendance_status'] ?? 1,
      createdAt:        DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance_id':    attendanceId,
      'staff_id':         staffId,
      'schedule_id':      scheduleId,
      'clock_in_time':    clockInTime?.toIso8601String(),
      'clock_out_time':   clockOutTime?.toIso8601String(),
      'clock_in_location': clockInLocation,
      'attendance_status': attendanceStatus,
    };
  }
}