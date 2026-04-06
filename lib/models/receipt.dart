class BookingReceipt {
  final int id;
  final int pax;
  // final int booktype;
  final String datebook;
  final double total;
  final String clientname;
  final String clientaddress;
  final String clientcity;
  final int clientpostcode;
  final String clientcountry;
  final String clientstate;
  final String clientemail;
  final String paymentid;
  final String paymentdate;
  final int confirmnum;
  final double price;

  const BookingReceipt({
    required this.id,
    required this.pax,
    // required this.booktype,
    required this.datebook,
    required this.total,
    required this.clientname,
    required this.clientaddress,
    required this.clientcity,
    required this.clientpostcode,
    required this.clientcountry,
    required this.clientstate,
    required this.clientemail,
    required this.paymentid,
    required this.paymentdate,
    required this.confirmnum,
    required this.price,
  });
}

class BookingAddon {
  final int id;
  final String item;
  final int price;
  final int quantity;

  const BookingAddon({
    required this.id,
    required this.item,
    required this.price,
    required this.quantity,
  });
}

class SpecialReceipt {
  final String receiptNumber;
  final DateTime paymentDate;
  final String clientName;
  final String clientEmail;
  final String clientInstitution;
  final DateTime startDate;
  final DateTime endDate;
  final bool needBoat;
  final int pax;
  final List<String> groupMembers;
  final double slotFee;
  final double boatFee;
  final double additionalFees;
  final double totalAmount;
  final String paymentMethod;
  final String transactionId;
  final int status;

  const SpecialReceipt({
    required this.receiptNumber,
    required this.paymentDate,
    required this.clientName,
    required this.clientEmail,
    required this.clientInstitution,
    required this.startDate,
    required this.endDate,
    required this.needBoat,
    required this.pax,
    required this.groupMembers,
    required this.slotFee,
    required this.boatFee,
    required this.additionalFees,
    required this.totalAmount,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
  });
}
