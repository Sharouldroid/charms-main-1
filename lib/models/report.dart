class ReportPax {
  final int confirmedbooking;
  final int cancelledbooking;

  const ReportPax({
    required this.confirmedbooking,
    required this.cancelledbooking,
  });
}

class ReportPayment {
  final double totalamount; // Change int to double
  final double totalrefund; // Change int to double

  ReportPayment({
    required this.totalamount,
    required this.totalrefund,
  });
}

class ReportData {
  final int title;
  final int sum;
  final double totalamount; // ✅ Changed from int to double

  const ReportData({
    required this.title,
    required this.sum,
    required this.totalamount,
  });
}
