import 'package:flutter/material.dart';

class ScheduleExchange {
  final int exchangeId;
  final int requesterId;
  final int targetId;
  final int requesterSched;
  final int targetSched;
  final int status;
  final String? requesterNote;
  final String? targetNote;
  final String? hrNote;
  final DateTime? createdAt;
  final DateTime? staffViewedAt;

  // Populated from API joins
  final String? requesterName;
  final String? targetName;
  final String? requesterWorkDate;
  final String? targetWorkDate;
  final String? requesterStartTime;
  final String? targetStartTime;
  final String? requesterWorkLocation;
  final String? targetWorkLocation;
  final String? requesterDepartment;
  final String? targetDepartment;

  ScheduleExchange({
    required this.exchangeId,
    required this.requesterId,
    required this.targetId,
    required this.requesterSched,
    required this.targetSched,
    required this.status,
    this.requesterNote,
    this.targetNote,
    this.hrNote,
    this.createdAt,
    this.requesterName,
    this.targetName,
    this.requesterWorkDate,
    this.targetWorkDate,
    this.requesterStartTime,
    this.targetStartTime,
    this.requesterDepartment,
    this.targetDepartment,
    this.requesterWorkLocation,
    this.targetWorkLocation,
    this.staffViewedAt,
  });

  factory ScheduleExchange.fromJson(Map<String, dynamic> json) {
    return ScheduleExchange(
      exchangeId:    int.tryParse(json['exchange_id']?.toString() ?? '') ?? 0,
      requesterId:   int.tryParse(json['requester_id']?.toString() ?? '') ?? 0,
      targetId:      int.tryParse(json['target_id']?.toString() ?? '') ?? 0,
      requesterSched: int.tryParse(json['requester_sched']?.toString() ?? '') ?? 0,
      targetSched:   int.tryParse(json['target_sched']?.toString() ?? '') ?? 0,
      status:        int.tryParse(json['status']?.toString() ?? '') ?? 0,
      requesterNote: json['requester_note'],
      targetNote:    json['target_note'],
      hrNote:        json['hr_note'],
      createdAt:     json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      requesterName:       json['requester_name'],
      targetName:          json['target_name'],
      requesterWorkDate:   json['requester_work_date'],
      targetWorkDate:      json['target_work_date'],
      requesterStartTime:  json['requester_start_time'],
      targetStartTime:     json['target_start_time'],
      requesterDepartment: json['requester_department'],
      targetDepartment:    json['target_department'],
      requesterWorkLocation: json['requester_work_location']?.toString(),
      targetWorkLocation:    json['target_work_location']?.toString(),
      staffViewedAt: json['staff_viewed_at'] != null
          ? DateTime.tryParse(json['staff_viewed_at'])
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 0: return 'Waiting for Response';
      case 1: return 'Target Accepted';
      case 2: return 'Target Rejected';
      case 3: return 'HR Approved ✅';
      case 4: return 'HR Rejected ❌';
      default: return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 0: return const Color(0xFFF59E0B); // amber
      case 1: return const Color(0xFF0891B2); // teal
      case 2: return const Color(0xFFEF4444); // red
      case 3: return const Color(0xFF16A34A); // green
      case 4: return const Color(0xFFEF4444); // red
      default: return const Color(0xFF64748B);
    }
  }
}