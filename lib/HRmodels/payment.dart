class Payment {
  final int paymentId;
  final int staffId;
  final DateTime workDate;
  final double basicPay;
  final double totalBonus;
  final double totalDeduction;
  final double totalSalary;
  final String? pdfPath;
  final DateTime createdAt;
  final String status; // 'pending' or 'published'


  Payment({
    required this.paymentId,
    required this.staffId,
    required this.workDate,
    required this.basicPay,
    required this.totalBonus,
    required this.totalDeduction,
    required this.totalSalary,
    this.pdfPath,
    required this.createdAt,
    this.status = 'pending',
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['payment_id'],
      staffId: json['staff_id'],
      workDate: DateTime.parse(json['work_date']),
      basicPay: double.parse(json['basic_pay'].toString()),
      totalBonus: double.parse(json['total_bonus'].toString()),
      totalDeduction: double.parse(json['total_deduction'].toString()),
      totalSalary: double.parse(json['total_salary'].toString()),
      pdfPath: json['pdf_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'staff_id': staffId,
      'work_date': workDate.toIso8601String(),
      'basic_pay': basicPay,
      'total_bonus': totalBonus,
      'total_deduction': totalDeduction,
      'total_salary': totalSalary,
      'pdf_path': pdfPath,
    };
  }
}