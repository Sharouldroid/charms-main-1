import 'package:flutter/foundation.dart';

class GroupMembers {
  final String id;
  final String name;
  final String idnum;
  final String email;
  final String shirtsize;
  final int confirmnum;
  final int ischild;
  final int eventid;
  final String diet;
  final String health;

  const GroupMembers({
    required this.id,
    required this.name,
    required this.idnum,
    required this.email,
    required this.shirtsize,
    required this.confirmnum,
    this.ischild = 0,
    required this.eventid,
    required this.diet,
    required this.health,
  });
}

class GroupMembersOut with ChangeNotifier {
  Map<String, GroupMembers> _items = {};

  Map<String, GroupMembers> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.isEmpty ? 0 : _items.length;
  }

  // double get totalAmount {
  //   var total = 0.0;
  //   _items.forEach((key, GroupMembers) {
  //     total += GroupMembers.price * GroupMembers.pax;
  //   });
  //   return total;
  // }

  void addItem(
    tempId,
    String name,
    String idnum,
    String email,
    int eventid,
    int confirmnum,
    String shirtsize,
    String diet,
    String health,

  ) {
    if (!_items.containsKey(tempId)) {
      _items.putIfAbsent(
        tempId,
        () => GroupMembers(
          id: tempId,
          name: name,
          idnum: idnum,
          email: email,
          eventid: eventid,
          confirmnum: confirmnum,
          shirtsize: shirtsize,
          ischild: 0,
          diet: diet,
          health: health,
        ),
      );
    } else {
      _items.update(
        tempId,
        (existingGroupMembers) => GroupMembers(
          id: existingGroupMembers.id,
          name: name,
          idnum: idnum,
          email: email,
          eventid: eventid,
          shirtsize: shirtsize,
          confirmnum: existingGroupMembers.confirmnum,
          ischild: 0,
          diet: diet,
          health: health,
        ),
      );
    }

    notifyListeners();
  }

  void removeItem(String tempId) {
    _items.remove(tempId);
    notifyListeners();
  }

  void removeSingleItem(String tempId) {
    if (!_items.containsKey(tempId)) {
      return;
    }

    _items.remove(tempId);
    // }

    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }

  // void incrementItem(
  //   tempId,
  // ) {
  //   if (_items.containsKey(tempId)) {
  //     _items.update(
  //       tempId,
  //       (existingGroupMembers) => GroupMembers(
  //         id: existingGroupMembers.id,
  //         title: existingGroupMembers.title,
  //         price: existingGroupMembers.price,
  //         plate: existingGroupMembers.plate,
  //         quantity: existingGroupMembers.quantity + 1,
  //         menuid: existingGroupMembers.menuid,
  //         menutype: existingGroupMembers.menutype,
  //         remark: existingGroupMembers.remark,
  //         remarkId: existingGroupMembers.remarkId,
  //         remarkPrice: existingGroupMembers.remarkPrice,
  //       ),
  //     );
  //   }
  //   notifyListeners();
  // }

  // void decrementItem(
  //   tempId,
  // ) {
  //   if (_items.containsKey(tempId) && _items[tempId]!.quantity > 1) {
  //     _items.update(
  //       tempId,
  //       (existingGroupMembers) => GroupMembers(
  //         id: existingGroupMembers.id,
  //         title: existingGroupMembers.title,
  //         price: existingGroupMembers.price,
  //         plate: existingGroupMembers.plate,
  //         quantity: existingGroupMembers.quantity - 1,
  //         menuid: existingGroupMembers.menuid,
  //         menutype: existingGroupMembers.menutype,
  //         remark: existingGroupMembers.remark,
  //         remarkId: existingGroupMembers.remarkId,
  //         remarkPrice: existingGroupMembers.remarkPrice,
  //       ),
  //     );
  //   }
  //   notifyListeners();
  // }
}
