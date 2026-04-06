class Optionalitem {
  final int id;
  final String name;
  final String desc;
  final int price;
  final String picture;
  final int status;

  const Optionalitem({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    this.picture = '',
    this.status = 1,
  });
}

class PurchasedItem {
  final int id;
  final String name;
  final int quantity;
  final int price;

  const PurchasedItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });
}
