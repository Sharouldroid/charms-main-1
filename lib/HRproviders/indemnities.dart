import 'dart:convert';

import 'package:charms/HRmodels/indemnity.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Indemnitites with ChangeNotifier {
  List<Indemnity> _indemlist = [];

  List<Indemnity> get indemlist {
    return [..._indemlist];
  }

  Indemnity findById(String id) {
    return _indemlist.firstWhere((item) => item.id == id);
  }

  Future<void> fetchIndemnitiesbyStatus(String hostname, int status) async {
    // Path updated to match Route::prefix('indemnity-general')
    final url = '${hostname}indemnity-general/$status';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<Indemnity> loadedIndem = [];
      extactedData.forEach((indemData) {
        loadedIndem.add(Indemnity(
          id: indemData['id'],
          indemitems: indemData['indemitem'],
          type: indemData['type'],
          status: indemData['status'],
        ));
      });
      _indemlist = loadedIndem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchIndemnitiesbyType(String hostname, int type) async {
    // Path updated to match Route::prefix('indemnity-general')
    final url = '${hostname}indemnity-general/bytype/$type';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<Indemnity> loadedIndem = [];
      extactedData.forEach((indemData) {
        loadedIndem.add(Indemnity(
          id: indemData['id'],
          indemitems: indemData['indemitem'],
          type: indemData['type'],
          status: indemData['status'],
        ));
      });
      _indemlist = loadedIndem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createIndemnity(
      String hostname, Indemnity newIndem, int userid) async {
    // Path updated to match Route::prefix('indemnity-general')
    final url = '${hostname}indemnity-general/create';

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'indemitem': newIndem.indemitems,
          'type': newIndem.type,
          'createdby': userid,
        }),
      );

      final newIndemnity = Indemnity(
        id: 0, // Note: Consider updating this with the ID returned from the server if needed
        indemitems: newIndem.indemitems,
        type: newIndem.type,
      );
      _indemlist.add(newIndemnity);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}