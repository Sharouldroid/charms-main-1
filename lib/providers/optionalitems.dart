import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:charms/models/optionalitem.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Optionalitems with ChangeNotifier {
  List<Optionalitem> _itemlist = [];
  List<PurchasedItem> _purchaseditem = [];

  List<Optionalitem> get itemlist {
    return [..._itemlist];
  }

  List<PurchasedItem> get purchaseditem {
    return [..._purchaseditem];
  }

  // --- USED BY CUSTOMER (AddOn Screen) ---
  // Fetches only status=1 (Active) items
  Future<void> fetchOptionalItemsbyStatus(String hostname, int status) async {
    final url = '${hostname}optionalitem/status/$status';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode >= 400) {
        throw Exception('Failed to load items');
      }

      final extactedData = jsonDecode(response.body);
      final List<Optionalitem> loadedItem = [];

      if (extactedData is List) {
        for (var itemdata in extactedData) {
          loadedItem.add(Optionalitem(
            id: itemdata['id'],
            name: itemdata['name'],
            desc: itemdata['description'],
            price: itemdata['price'],
            picture: itemdata['picture'] ?? '', // Fix: Handle null picture
            status: itemdata['status'],
          ));
        }
      }
      _itemlist = loadedItem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // --- USED BY ADMIN (Manage Screen) ---
  // Fetches ALL items so Admin can see hidden/inactive ones
  Future<void> fetchAllOptionalItems(String hostname) async {
    final url = '${hostname}optionalitem/status/all';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode >= 400) {
        throw Exception('Failed to load items');
      }

      final extactedData = jsonDecode(response.body);
      final List<Optionalitem> loadedItem = [];

      if (extactedData is List) {
        for (var itemdata in extactedData) {
          loadedItem.add(Optionalitem(
            id: itemdata['id'],
            name: itemdata['name'],
            desc: itemdata['description'],
            price: itemdata['price'],
            picture: itemdata['picture'] ?? '', // Fix: Handle null picture
            status: itemdata['status'],
          ));
        }
      }
      _itemlist = loadedItem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createOptionalItem(
      String hostname, Optionalitem newItem, int userid) async {
    final url = '${hostname}optionalitem/create';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'name': newItem.name,
          'description': newItem.desc,
          'price': newItem.price,
          'picture': newItem.picture, // Sends the filename/path
          'createdby': userid,
          'status': newItem.status.toString(), // Fix: Send as string
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Server Error: ${response.body}');
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateOptionalItem(
      String hostname, Optionalitem newItem, int itemid) async {
    try {
      final url = Uri.parse('${hostname}optionalitem/update');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id': itemid,
          'name': newItem.name,
          'description': newItem.desc,
          'price': newItem.price,
          'picture': newItem.picture, // Update picture field
          'status': newItem.status.toString(), // Fix: Send as string
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update item: ${response.body}');
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  Future<void> purchaseOptionalItem(
    String hostname,
    String itemname,
    int itemprice,
    int userid,
    int quantity,
    int confirmnum,
  ) async {
    final url = '${hostname}optionalitem/purchase';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'name': itemname,
        'quantity': quantity,
        'confirmnum': confirmnum,
        'userid': userid,
        'price': itemprice,
      }),
    );

    if (response.statusCode == 200) {
      notifyListeners();
    }
  }

  Future<void> fetchPurchasedItems(String hostname, int confirmnum) async {
    final url = '${hostname}optionalitem/purchased/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<PurchasedItem> loadedItem = [];

      if (extactedData is List) {
        for (var itemdata in extactedData) {
          loadedItem.add(PurchasedItem(
            id: itemdata['id'],
            name: itemdata['name'],
            quantity: itemdata['quantity'],
            price: itemdata['price'],
          ));
        }
      }
      _purchaseditem = loadedItem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // --- UPDATED: Returns String? (filename/url) instead of void ---
  Future<String?> uploadImage(String hostname, XFile imageFile) async {
    // Assuming the API route for upload is something like: hostname + 'fileupload/upload'
    // Adjust based on your actual Laravel route structure
    final url = Uri.parse('${hostname}fileupload/upload');

    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Expected response: {"url": "path/to/image.jpg"} or {"filename": "..."}
        final data = jsonDecode(responseData);
        // Adjust the key 'url' based on what your PHP returns
        return data['url'] ?? data['filename'];
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }
}