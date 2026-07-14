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
  final List<int>? proofFile; // legacy/base64
  final String? proofFilePath; // e.g. leave_proofs/abc.jpg
  final String? proofFileUrl;  // full URL
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;
  final DateTime? staffViewedAt;

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
    this.proofFilePath,
    this.proofFileUrl,
    this.rejectionReason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.staffViewedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    List<int>? proofFileData;
    String? proofPath;
    String? proofUrl = json['proof_file_url'];

    final rawProof = json['proof_file'];

    if (rawProof != null) {
      if (rawProof is Map && rawProof['data'] != null) {
        proofFileData = List<int>.from(rawProof['data']);
      } else if (rawProof is String) {
        if (rawProof.startsWith('leave_proofs/')) {
          proofPath = rawProof;
        } else {
          try {
            proofFileData = base64Decode(rawProof);
          } catch (_) {
            proofPath = rawProof;
          }
        }
      }
    }

    // fallback: build URL yourself if backend didn't send proof_file_url
    proofUrl ??= (proofPath != null && proofPath.isNotEmpty)
        ? 'https://devcms.com.my/charmsAPI/public/storage/$proofPath'
        : null;

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
      proofFilePath: proofPath,
      proofFileUrl: proofUrl,
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      rejectionReason: json['rejection_reason'],
      staffViewedAt: json['staff_viewed_at'] != null
          ? DateTime.tryParse(json['staff_viewed_at'])
          : null,
    );
  }

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
      'proof_file': proofFile != null ? base64Encode(proofFile!) : proofFilePath,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'staff_viewed_at': staffViewedAt?.toIso8601String(),
    };
  }

  Leave copyWith({
    int? leaveId,
    int? staffId,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? proofFileName,
    String? proofFileType,
    List<int>? proofFile,
    String? proofFilePath,
    String? proofFileUrl,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? staffViewedAt,
  }) {
    return Leave(
      leaveId: leaveId ?? this.leaveId,
      staffId: staffId ?? this.staffId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      proofFileName: proofFileName ?? this.proofFileName,
      proofFileType: proofFileType ?? this.proofFileType,
      proofFile: proofFile ?? this.proofFile,
      proofFilePath: proofFilePath ?? this.proofFilePath,
      proofFileUrl: proofFileUrl ?? this.proofFileUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffViewedAt: staffViewedAt ?? this.staffViewedAt,
    );
  }
}