import 'package:charms/HRmodels/break_period.dart';
import 'package:charms/HRmodels/working_period.dart';

class Schedule {
  final int schedId;
  final int staffId;
  final DateTime workDate;
  final int workLocation; // 1: Chagar Hutang, 2: Turtle Lab, 3: UMT
  final int staffType; // 1: Permanent Staff, 2: Intern
  final int? internSlot; // 1-4 for interns, null for permanent staff
  
  // For permanent staff
  final String? workStartTime;
  final String? workEndTime;
  final String? breakStartTime;
  final String? breakEndTime;

  // For interns (based on slot)
  final List<WorkingPeriod>? workingPeriods;
  final List<BreakPeriod>? breakPeriods;

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
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      schedId: json['sched_id'] ?? 0,
      staffId: json['staff_id'] ?? 0,
      workDate: DateTime.parse(json['work_date']),
      workLocation: json['work_location'] ?? 1,
      staffType: json['staff_type'] ?? 1,
      internSlot: json['intern_slot'],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sched_id': schedId,
      'staff_id': staffId,
      'work_date': workDate.toIso8601String(),
      'work_location': workLocation,
      'staff_type': staffType,
      'intern_slot': internSlot,
      'work_start_time': workStartTime,
      'work_end_time': workEndTime,
      'break_start_time': breakStartTime,
      'break_end_time': breakEndTime,
      'working_periods': workingPeriods?.map((period) => period.toJson()).toList(),
      'break_periods': breakPeriods?.map((period) => period.toJson()).toList(),
    };
  }
}