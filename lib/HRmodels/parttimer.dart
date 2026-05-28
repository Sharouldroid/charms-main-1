class PartTimer {
  final int partTimerId;
  final int staffId;           // Links to User/Staff
  final String name;
  final String email;
  final String phone;
  final int status;            // 0=inactive, 1=active
  final int? maxClaimsPerDay;  // Optional limit
  final int? maxDaysPerMonth;  // Optional limit
  final DateTime createdAt;
  final DateTime updatedAt;

  PartTimer({
    required this.partTimerId,
    required this.staffId,
    required this.name,
    required this.email,
    required this.phone,
    this.status = 1,
    this.maxClaimsPerDay,
    this.maxDaysPerMonth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartTimer.fromJson(Map<String, dynamic> json) {
    return PartTimer(
      partTimerId: json['part_timer_id'] ?? 0,
      staffId: json['staff_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 1,
      maxClaimsPerDay: json['max_claims_per_day'],
      maxDaysPerMonth: json['max_days_per_month'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_timer_id': partTimerId,
      'staff_id': staffId,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'max_claims_per_day': maxClaimsPerDay,
      'max_days_per_month': maxDaysPerMonth,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}