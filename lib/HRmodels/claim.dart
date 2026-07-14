import 'dart:convert';

class Claim {
  final int claimId;
  final int staffId;
  final String claimType;
  final double amount;
  final DateTime claimDate;
  final String description;

  final List<int>? proofFile; // legacy
  final String? proofFileName;
  final String? proofFileType;

  final String? proofFilePath; // NEW
  final String? proofFileUrl;  // NEW

  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? staffViewedAt;   

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
    this.proofFilePath,
    this.proofFileUrl,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.staffViewedAt,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    List<int>? proofFileData;
    String? proofPath;
    String? proofUrl = json['proof_file_url'];

    final rawProof = json['proof_file'];

    if (rawProof != null) {
      if (rawProof is Map && rawProof['data'] != null) {
        proofFileData = List<int>.from(rawProof['data']);
      } else if (rawProof is String) {
        if (rawProof.startsWith('claim_proofs/')) {
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

    proofUrl ??= (proofPath != null && proofPath.isNotEmpty)
        ? 'https://devcms.com.my/charmsAPI/public/storage/$proofPath'
        : null;

    return Claim(
      claimId: json['claim_id'] ?? 0,
      staffId: json['staff_id'] ?? 0,
      claimType: json['claim_type'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      claimDate: DateTime.parse(json['claim_date']),
      description: json['description'] ?? '',
      proofFile: proofFileData,
      proofFileName: json['proof_file_name'],
      proofFileType: json['proof_file_type'],
      proofFilePath: proofPath,
      proofFileUrl: proofUrl,
      status: json['status'] ?? 'Pending',
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      staffViewedAt: json['staff_viewed_at'] != null
          ? DateTime.tryParse(json['staff_viewed_at'])
          : null,
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
      'proof_file': proofFile != null ? base64Encode(proofFile!) : proofFilePath,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'staff_viewed_at': staffViewedAt?.toIso8601String(),
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
    String? rejectionReason,
    String? proofFileType,
    String? proofFileName,
    List<int>? proofFile,
    String? proofFilePath,
    String? proofFileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? staffViewedAt,
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
      proofFilePath: proofFilePath ?? this.proofFilePath,
      proofFileUrl: proofFileUrl ?? this.proofFileUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffViewedAt: staffViewedAt ?? this.staffViewedAt,
    );
  }
}