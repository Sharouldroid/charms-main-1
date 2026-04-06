import 'package:flutter/foundation.dart';

class BookingCart {
  final String id;
  final String eventname;
  final double price;
  final int confirmnum;
  final int userid;
  final int pax;
  final int booktype;
  // final List<int> indemnities;
  final String indemnities;
  final String shirtsize;
  final String diet; // NEW FIELD
  final String health;
  final Uint8List? signature;
  

  const BookingCart({
    required this.id,
    required this.eventname,
    required this.price,
    required this.confirmnum,
    required this.userid,
    required this.pax,
    required this.booktype,
    required this.indemnities,
    required this.shirtsize,
    required this.diet,
    required this.health,
    this.signature, // NEW REQUIRED PARAMETER
  });
}

class BookingCartOut with ChangeNotifier {
  Map<String, BookingCart> _items = {};

  Map<String, BookingCart> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.isEmpty ? 0 : _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, BookingCart) {
      total += BookingCart.price * BookingCart.pax;
    });
    return total;
  }

  void addItem(
    productId,
    String eventname,
    double price,
    int confirmnum,
    int userid,
    int pax,
    int booktype,
    // List<int> indemnities,
    String indemnities,
    String shirtsize,
    String diet,
    String health, // NEW PARAMETER (10th Argument)
    {Uint8List? signature}
  ) {
    if (!_items.containsKey(productId)) {
      _items.putIfAbsent(
        productId,
        () => BookingCart(
          id: productId,
          eventname: eventname,
          price: price,
          confirmnum: confirmnum,
          userid: userid,
          pax: pax,
          booktype: booktype,
          indemnities: indemnities,
          shirtsize: shirtsize,
          diet: diet,
          health: health, // Saved here
          signature: signature,
        ),
      );
    } else {
      _items.update(
        productId,
        (existingBookingCart) => BookingCart(
          id: existingBookingCart.id,
          eventname: existingBookingCart.eventname,
          price: existingBookingCart.price,
          confirmnum: existingBookingCart.confirmnum,
          userid: existingBookingCart.userid,
          pax: existingBookingCart.pax,
          booktype: existingBookingCart.booktype,
          indemnities: indemnities,
          shirtsize: existingBookingCart.shirtsize,
          diet: diet,
          health: health, // Updated here if changed
          signature: signature,
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