class InternAttendanceRecord {
  final int id;
  final int scheduleId;
  final String scheduleDescription;
  final DateTime? workDate;          
  final DateTime? scheduleStartDate;
  final DateTime? scheduleEndDate;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInLocation;

  InternAttendanceRecord({
    required this.id,
    required this.scheduleId,
    required this.scheduleDescription,
    this.workDate,
    this.scheduleStartDate,
    this.scheduleEndDate,
    this.clockInTime,
    this.clockOutTime,
    this.clockInLocation,
  });

  factory InternAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return InternAttendanceRecord(
      id: (json['id'] as num).toInt(),
      scheduleId: (json['schedule_id'] as num).toInt(),
      scheduleDescription: json['schedule_description']?.toString() ?? '-',
      workDate: json['work_date'] != null
          ? DateTime.tryParse(json['work_date'].toString())
          : null,
      scheduleStartDate: json['schedule_start_date'] != null
          ? DateTime.tryParse(json['schedule_start_date'].toString())
          : null,
      scheduleEndDate: json['schedule_end_date'] != null
          ? DateTime.tryParse(json['schedule_end_date'].toString())
          : null,
      clockInTime: json['clock_in_time'] != null
          ? DateTime.tryParse(json['clock_in_time'].toString())
          : null,
      clockOutTime: json['clock_out_time'] != null
          ? DateTime.tryParse(json['clock_out_time'].toString())
          : null,
      clockInLocation: json['clock_in_location']?.toString(),
    );
  }

  bool get hasClockOut => clockOutTime != null;

  Duration? get shiftDuration {
    if (clockInTime == null || clockOutTime == null) return null;
    return clockOutTime!.difference(clockInTime!);
  }

  String get shiftDurationFormatted {
    final d = shiftDuration;
    if (d == null) return 'In progress';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}