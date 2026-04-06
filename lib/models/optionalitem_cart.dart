import 'package:flutter/foundation.dart';

class OptionalItemCart {
  final String id;
  final String itemname;
  final int price;
  final int quantity;

  const OptionalItemCart({
    required this.id,
    required this.itemname,
    required this.price,
    required this.quantity,
  });
}

class OptionalItemCartOut with ChangeNotifier {
  Map<String, OptionalItemCart> _items = {};

  Map<String, OptionalItemCart> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.isEmpty ? 0 : _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
    String productId,
    String itemname,
    int price,
    int quantity,
  ) {
    if (!_items.containsKey(productId)) {
      _items.putIfAbsent(
        productId,
        () => OptionalItemCart(
          id: productId,
          itemname: itemname,
          price: price,
          quantity: quantity,
        ),
      );
    } else {
      _items.update(
        productId,
        (existingOptionalItemCart) => OptionalItemCart(
          id: existingOptionalItemCart.id,
          itemname: existingOptionalItemCart.itemname,
          price: existingOptionalItemCart.price,
          quantity: existingOptionalItemCart.quantity + 1,
        ),
      );
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // --- THIS IS THE FIXED FUNCTION ---
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }

    if (_items[productId]!.quantity > 1) {
      // If quantity is more than 1, decrease it by 1
      _items.update(
        productId,
        (existingCartItem) => OptionalItemCart(
          id: existingCartItem.id,
          itemname: existingCartItem.itemname,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      // If quantity is 1, remove it entirely
      _items.remove(productId);
    }

    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}