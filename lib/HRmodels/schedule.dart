import 'package:charms/HRmodels/break_period.dart';
import 'package:charms/HRmodels/working_period.dart';

class Schedule {
  final int schedId;
  final int staffId;
  final DateTime workDate;
  final int workLocation; // 1: Chagar Hutang, 2: Turtle Lab, 3: UMT
  final int staffType; // 1: Permanent Staff, 2: Intern
  final int? internSlot; // 1-4 for interns, null for permanent staff
  final bool hrDismissed; // true if HR dismissed the schedule, false otherwise
  
  // For permanent staff
  final String? workStartTime;
  final String? workEndTime;
  final String? breakStartTime;
  final String? breakEndTime;

  // For interns (based on slot)
  final List<WorkingPeriod>? workingPeriods;
  final List<BreakPeriod>? breakPeriods;

  final int acceptanceStatus; // 0=Pending, 1=Accepted, 2=Rejected
  final String? staffNote;
  final DateTime? staffViewedAt;

  Schedule({
    required this.schedId,
    required this.staffId,
    required this.workDate,
    required this.workLocation,
    required this.staffType,
    this.internSlot,
    this.workStartTime,
    this.workEndTime,
    this.breakStartTime,
    this.breakEndTime,
    this.workingPeriods,
    this.breakPeriods,
    this.acceptanceStatus = 0,
    this.staffNote,
    this.hrDismissed = false,
    this.staffViewedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
  return Schedule(
    schedId: json['sched_id'] is int ? json['sched_id'] : int.tryParse(json['sched_id'].toString()) ?? 0,
    staffId: json['staff_id'] is int ? json['staff_id'] : int.tryParse(json['staff_id'].toString()) ?? 0,
    workDate: DateTime.parse(json['work_date']),
    workLocation: json['work_location'] is int ? json['work_location'] : int.tryParse(json['work_location'].toString()) ?? 1,
    staffType: json['staff_type'] is int ? json['staff_type'] : int.tryParse(json['staff_type'].toString()) ?? 1,
    internSlot: json['intern_slot'] == null ? null
      : (json['intern_slot'] is int ? json['intern_slot'] : int.tryParse(json['intern_slot'].toString())),
    workStartTime: json['work_start_time'],
    workEndTime: json['work_end_time'],
    breakStartTime: json['break_start_time'],
    breakEndTime: json['break_end_time'],
    workingPeriods: json['working_periods'] != null
        ? (json['working_periods'] as List)
            .map((period) => WorkingPeriod.fromJson(period))
            .toList()
        : null,
    breakPeriods: json['break_periods'] != null
        ? (json['break_periods'] as List)
            .map((period) => BreakPeriod.fromJson(period))
            .toList()
        : null,
        acceptanceStatus: int.tryParse(json['acceptance_status']?.toString() ?? '') ?? 0,
      staffNote: json['staff_note'],
       hrDismissed:      (json['hr_dismissed'] as bool?) ?? false,
       staffViewedAt: json['staff_viewed_at'] != null
        ? DateTime.tryParse(json['staff_viewed_at'])
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'sched_id': schedId,
      'staff_id': staffId,
      'work_date': workDate.toIso8601String(),
      'work_location': workLocation.toString(),
      'staff_type': staffType.toString(),
      'intern_slot': internSlot,
      'work_start_time': workStartTime,
      'work_end_time': workEndTime,
      'break_start_time': breakStartTime,
      'break_end_time': breakEndTime,
      'working_periods': workingPeriods?.map((period) => period.toJson()).toList(),
      'break_periods': breakPeriods?.map((period) => period.toJson()).toList(),
       'acceptance_status': acceptanceStatus,
      'staff_note':      staffNote,
      'hr_dismissed': hrDismissed,
      'staff_viewed_at': staffViewedAt?.toIso8601String(),
    };
  }
}