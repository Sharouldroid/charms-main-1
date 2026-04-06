import 'dart:convert';

class Leave {
  final int leaveId;
  final int staffId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? proofFileName;
  final String? proofFileType;
  final List<int>? proofFile;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Leave({
    required this.leaveId,
    required this.staffId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.proofFileName,
    this.proofFileType,
    this.proofFile,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
  List<int>? proofFileData;
  if (json['proof_file'] != null) {
    if (json['proof_file'] is Map && json['proof_file']['data'] != null) {
      // Handle Buffer format from backend
      proofFileData = List<int>.from(json['proof_file']['data']);
    } else if (json['proof_file'] is String) {
      // Handle base64 string format
      proofFileData = base64Decode(json['proof_file']);
    }
  }

  return Leave(
    leaveId: json['leave_id'] ?? 0,
    staffId: json['staff_id'] ?? 0,
    leaveType: json['leave_type'] ?? '',
    startDate: DateTime.parse(json['start_date']),
    endDate: DateTime.parse(json['end_date']),
    reason: json['reason'] ?? '',
    proofFileName: json['proof_file_name'],
    proofFileType: json['proof_file_type'],
    proofFile: proofFileData,
    status: json['status'] ?? 'Pending',
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}
  

  
  // Update toJson method to handle List<int>
  Map<String, dynamic> toJson() {
    return {
      'leave_id': leaveId,
      'staff_id': staffId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'reason': reason,
      'proof_file_name': proofFileName,
      'proof_file_type': proofFileType,
      'proof_file': proofFile != null ? base64Encode(proofFile!) : null,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}