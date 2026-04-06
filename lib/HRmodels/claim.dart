import 'dart:convert';

class Claim {
  final int claimId;
  final int staffId;
  final String claimType;
  final double amount;
  final DateTime claimDate;
  final String description;
  final List<int>? proofFile;
  final String? proofFileName;
  final String? proofFileType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Claim({
    required this.claimId,
    required this.staffId,
    required this.claimType,
    required this.amount,
    required this.claimDate,
    required this.description,
    this.proofFile,
    this.proofFileName,
    this.proofFileType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    List<int>? proofFileData;
    if (json['proof_file'] != null) {
      if (json['proof_file'] is Map && json['proof_file']['data'] != null) {
        proofFileData = List<int>.from(json['proof_file']['data']);
      } else if (json['proof_file'] is String) {
        proofFileData = base64Decode(json['proof_file']);
      }
    }

    return Claim(
      claimId: json['claim_id'] ?? 0,
      staffId: json['staff_id'] ?? 0,
      claimType: json['claim_type'] ?? '',
      amount: double.parse(json['amount'].toString()),
      claimDate: DateTime.parse(json['claim_date']),
      description: json['description'] ?? '',
      proofFile: proofFileData,
      proofFileName: json['proof_file_name'],
      proofFileType: json['proof_file_type'],
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claim_id': claimId,
      'staff_id': staffId,
      'claim_type': claimType,
      'amount': amount,
      'claim_date': claimDate.toIso8601String(),
      'description': description,
      'proof_file_name': proofFileName,
      'proof_file_type': proofFileType,
      'proof_file': proofFile != null ? base64Encode(proofFile!) : null,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Claim copyWith({
    int? claimId,
    int? staffId,
    String? claimType,
    double? amount,
    DateTime? claimDate,
    String? description,
    String? status,
    String? proofFileType,
    String? proofFileName,
    List<int>? proofFile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Claim(
      claimId: claimId ?? this.claimId,
      staffId: staffId ?? this.staffId,
      claimType: claimType ?? this.claimType,
      amount: amount ?? this.amount,
      claimDate: claimDate ?? this.claimDate,
      description: description ?? this.description,
      status: status ?? this.status,
      proofFileType: proofFileType ?? this.proofFileType,
      proofFileName: proofFileName ?? this.proofFileName,
      proofFile: proofFile ?? this.proofFile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
