class PaymentRecord {
  final int id;
  final int confirmnum;
  final double amount;
  final int paymentstatus;
  final String paymentid;
  final String date;

  const PaymentRecord({
    required this.id,
    required this.confirmnum,
    required this.amount,
    required this.paymentstatus,
    required this.paymentid,
    required this.date,
  });
}
