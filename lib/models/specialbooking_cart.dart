import 'package:flutter/foundation.dart';

class SpecialBookingCart {
  final String id;
  final String eventname;
  final int userid;
  final int pax;
  final String indemnities;
  final int boatprice;
  final int eventprice;
  final String startdate;
  final String enddate;
  // final String title;
  // final String department;
  // final String institution;
  // final String location;
  // final String filename;

  const SpecialBookingCart({
    required this.id,
    required this.eventname,
    required this.userid,
    required this.pax,
    required this.indemnities,
    required this.boatprice,
    required this.eventprice,
    required this.startdate,
    required this.enddate,
    // required this.title,
    // required this.department,
    // required this.institution,
    // required this.location,
    // required this.filename,
  });
}

class SpecialBookingCartOut with ChangeNotifier {
  Map<String, SpecialBookingCart> _items = {};

  Map<String, SpecialBookingCart> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.isEmpty ? 0 : _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, SpecialBookingCart) {
      total += SpecialBookingCart.boatprice + SpecialBookingCart.eventprice;
    });
    return total;
  }

  void addItem(
    productId,
    String eventname,
    int userid,
    int pax,
    String indemnities,
    int boatprice,
    int eventprice,
    String startdate,
    String enddate,
    // String title,
    // String department,
    // String institution,
    // String location,
    // String filename,
  ) {
    if (!_items.containsKey(productId)) {
      _items.putIfAbsent(
        productId,
        () => SpecialBookingCart(
          id: productId,
          eventname: eventname,
          userid: userid,
          pax: pax,
          indemnities: indemnities,
          boatprice: boatprice,
          eventprice: eventprice,
          startdate: startdate,
          enddate: enddate,
          // title: title,
          // department: department,
          // institution: institution,
          // location: location,
          // filename: filename,
        ),
      );
    } else {
      _items.update(
        productId,
        (existingSpecialBookingCart) => SpecialBookingCart(
          id: existingSpecialBookingCart.id,
          eventname: existingSpecialBookingCart.eventname,
          userid: existingSpecialBookingCart.userid,
          pax: existingSpecialBookingCart.pax,
          indemnities: indemnities,
          boatprice: existingSpecialBookingCart.boatprice,
          eventprice: existingSpecialBookingCart.eventprice,
          startdate: existingSpecialBookingCart.startdate,
          enddate: existingSpecialBookingCart.enddate,
          // title: existingSpecialBookingCart.title,
          // department: existingSpecialBookingCart.department,
          // institution: existingSpecialBookingCart.institution,
          // location: existingSpecialBookingCart.location,
          // filename: existingSpecialBookingCart.filename,
        ),
      );
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }

    _items.remove(productId);

    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
