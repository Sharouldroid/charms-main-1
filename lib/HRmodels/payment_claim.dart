class ClaimDailyAttendance {
  final DateTime workDate;
  final String? clockInTime;
  final String? clockOutTime;

  ClaimDailyAttendance({
    required this.workDate,
    this.clockInTime,
    this.clockOutTime,
  });

  factory ClaimDailyAttendance.fromJson(Map<String, dynamic> json) {
    return ClaimDailyAttendance(
      workDate: DateTime.tryParse(json['work_date'] ?? '') ?? DateTime.now(),
      clockInTime: json['clock_in_time'],
      clockOutTime: json['clock_out_time'],
    );
  }
}

class PaymentClaim {
  final int claimId;
  final int staffId;
  final int month;
  final int year;
  final int totalDays;
  final double dayRate;
  final double totalAmount;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int? reviewedBy;
  final DateTime? paidAt;
  final String? receiptPath;
  final DateTime? receiptSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // joined fields (from dashboard/getAllClaims)
  final String? staffName;
  final String? staffPhoto;
  final List<ClaimDailyAttendance> dailyAttendance;

  PaymentClaim({
    required this.claimId,
    required this.staffId,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.dayRate,
    required this.totalAmount,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.paidAt,
    this.receiptPath,
    this.receiptSentAt,
    required this.createdAt,
    required this.updatedAt,
    this.staffName,
    this.staffPhoto,
    this.dailyAttendance = const [],
  });

  factory PaymentClaim.fromJson(Map<String, dynamic> json) {
    return PaymentClaim(
      claimId:         json['claim_id'] ?? 0,
      staffId:         json['staff_id'] ?? 0,
      month:           json['month'] ?? 0,
      year:            json['year'] ?? 0,
      totalDays:       json['total_days'] ?? 0,
      dayRate:         double.tryParse(json['day_rate'].toString()) ?? 0.0,
      totalAmount:     double.tryParse(json['total_amount'].toString()) ?? 0.0,
      status:          json['status'] ?? 'Pending',
      rejectionReason: json['rejection_reason'],
      submittedAt:     json['submitted_at'] != null
                         ? DateTime.tryParse(json['submitted_at'])
                         : null,
      reviewedAt:      json['reviewed_at'] != null
                         ? DateTime.tryParse(json['reviewed_at'])
                         : null,
      reviewedBy:      json['reviewed_by'],
      paidAt: json['paid_at'] != null 
    ? DateTime.tryParse(json['paid_at'])
    : null,
    receiptPath: json['receipt_path'],
      receiptSentAt: json['receipt_sent_at'] != null
                         ? DateTime.tryParse(json['receipt_sent_at'])
                         : null,
      createdAt: json['created_at'] != null 
    ? DateTime.parse(json['created_at']) 
    : DateTime.now(),
      updatedAt: json['updated_at'] != null 
    ? DateTime.parse(json['updated_at']) 
    : DateTime.now(),
      staffName:       json['staff_name'],
      staffPhoto:      json['staff_photo_url'],
      dailyAttendance: json['daily_attendance'] != null
          ? (json['daily_attendance'] as List)
              .map((e) => ClaimDailyAttendance.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claim_id':         claimId,
      'staff_id':         staffId,
      'month':            month,
      'year':             year,
      'total_days':       totalDays,
      'day_rate':         dayRate,
      'total_amount':     totalAmount,
      'status':           status,
      'rejection_reason': rejectionReason,
      'submitted_at':     submittedAt?.toIso8601String(),
      'reviewed_at':      reviewedAt?.toIso8601String(),
      'reviewed_by':      reviewedBy,
      'paid_at': paidAt?.toIso8601String(),
      'receipt_path': receiptPath,
      'receipt_sent_at': receiptSentAt?.toIso8601String(),
      'created_at':       createdAt.toIso8601String(),
      'updated_at':       updatedAt.toIso8601String(),
    };
  }

  PaymentClaim copyWith({
    int? claimId,
    int? staffId,
    int? month,
    int? year,
    int? totalDays,
    double? dayRate,
    double? totalAmount,
    DateTime? paidAt,
    String? receiptPath,
    DateTime? receiptSentAt,
    String? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    int? reviewedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? staffName,
    String? staffPhoto,
    List<ClaimDailyAttendance>? dailyAttendance,
  }) {
    return PaymentClaim(
      claimId:         claimId ?? this.claimId,
      staffId:         staffId ?? this.staffId,
      month:           month ?? this.month,
      year:            year ?? this.year,
      totalDays:       totalDays ?? this.totalDays,
      dayRate:         dayRate ?? this.dayRate,
      totalAmount:     totalAmount ?? this.totalAmount,
      status:          status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt:     submittedAt ?? this.submittedAt,
      reviewedAt:      reviewedAt ?? this.reviewedAt,
      reviewedBy:      reviewedBy ?? this.reviewedBy,
      createdAt:       createdAt ?? this.createdAt,
      updatedAt:       updatedAt ?? this.updatedAt,
      staffName:       staffName ?? this.staffName,
      staffPhoto:      staffPhoto ?? this.staffPhoto,
      paidAt:            paidAt ?? this.paidAt,
      receiptPath:       receiptPath ?? this.receiptPath,
      receiptSentAt:     receiptSentAt ?? this.receiptSentAt,
    );
  }
}