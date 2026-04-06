import 'dart:convert';

import 'package:charms/models/bookingsetting.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingSettings with ChangeNotifier {
  List<Bookingsetting> _itemlist = [];

  List<Bookingsetting> get itemlist {
    return [..._itemlist];
  }

  // Future<void> addItem(String hostname, Bookingsetting item) async {
  //   final url = '${hostname}booksetting/create';

  //   await http.post(
  //     Uri.parse(url),
  //     headers: {
  //       'Content-type': 'application/json',
  //       'Accept': 'application/json',
  //     },
  //     encoding: Encoding.getByName('utf-8'),
  //     body: jsonEncode({
  //       'item': item.item,
  //       'price': item.price,
  //       'itemtype': item.itemtype,
  //     }),
  //   );
  //   _itemlist.add(item);
  //   notifyListeners();
  // }

  Future<void> updateItem(String hostname, Bookingsetting item, int id) async {
    final itemIndex = _itemlist.indexWhere((item) => item.id == id.toString());
    final url = '${hostname}booksetting/edit/$id';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'item': item.item,
        'price': item.price,
        'itemtype': item.itemtype,
        'status': 1,
        // 'id': id
      }),
    );

    _itemlist[itemIndex] = item;

    notifyListeners();
  }

  Future<void> fetchSettingbytype(
      String hostname, int itemtype, int status) async {
    final url = '${hostname}booksetting/fetch/$itemtype/$status';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<Bookingsetting> loadeditem = [];
      extractedEvent.forEach((itemdata) {
        loadeditem.add(Bookingsetting(
          id: itemdata['id'],
          item: itemdata['item'],
          price: itemdata['price'],
          itemtype: itemdata['itemtype'],
        ));
      });
      _itemlist = loadeditem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, int>> fetchSettingbystatus(
      String hostname, int itemtype, int status) async {
    final url = '${hostname}booksetting/fetch/$itemtype/$status';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      int priceperpax = data.isNotEmpty ? data[0]['price'] : 0;
      int boatperpax = data.length > 1 ? data[1]['price'] : 0;

      notifyListeners();
      return {
        'value1': priceperpax,
        'value2': boatperpax,
      };
    } catch (error) {
      rethrow;
    }
  }
}
