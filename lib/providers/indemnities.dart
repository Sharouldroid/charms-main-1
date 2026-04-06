import 'dart:convert';
import 'dart:typed_data';
import 'package:charms/models/indemnity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Indemnitites with ChangeNotifier {
  List<Indemnity> _indemlist = [];
  final List<Indemnity> _parentindem = [];

  List<IndemnityResponse> _indemAnswer = [];

  List<Indemnity> get indemlist {
    return [..._indemlist];
  }

  List<Indemnity> get parentindem {
    return [..._parentindem];
  }

  List<IndemnityResponse> get indemAnswer {
    return [..._indemAnswer];
  }

  Indemnity findById(String id) {
    return _indemlist.firstWhere((item) => item.id == id);
  }

  Indemnity findIndem2ById(String id) {
    return _parentindem.firstWhere((item) => item.id == id);
  }

  Future<void> fetchIndemnitiesbyStatus(String hostname, int status) async {
    final url = '${hostname}indemnity/status/$status';

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
    final url = '${hostname}indemnity/bytype/$type';

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
    final url = '${hostname}indemnity/create';

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
        id: 0,
        indemitems: newIndem.indemitems,
        type: newIndem.type,
      );
      _indemlist.add(newIndemnity);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateIndemnity(
      String hostname, Indemnity newIndem, int userid, int id) async {
    final url = '${hostname}indemnity/update';
    final indemIndex = _indemlist.indexWhere((indem) => indem.id == id);

    try {
      await http.put(
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
          'id': id
        }),
      );

      _indemlist[indemIndex] = newIndem;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addIndemnitiestoBooking(
      String hostname, int userid, String answers, int confirmnum, Uint8List? signatureBytes) async {
    final url = '${hostname}indemnity/addtobooking';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add text fields
      request.fields['userid'] = userid.toString();
      request.fields['confirmnum'] = confirmnum.toString();
      request.fields['indemitem'] = answers;

      // Add Signature File if exists
      if (signatureBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'signature',
          signatureBytes,
          filename: 'signature.png',
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 400) {
        print('Server Error: ${response.body}');
        throw Exception('Server Error: ${response.body}');
      }

      notifyListeners();
    } catch (error) {
      print('Indemnity Error: $error');
      rethrow;
    }
  }

  Future<void> fetchUserIndemnities(
      String hostname, int userid, int confirmnum) async {
    final url = '${hostname}indemnity?userid=$userid&confirmnum=$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<IndemnityResponse> loadedIndem = [];
      extactedData.forEach((indemData) {
        loadedIndem.add(IndemnityResponse(
            // userid: indemData['userid'],
            // confirmnum: indemData['confirmnum'],
            // answers: indemData['responddata']?.split(',').map<int>((e) {
            //   return int.parse(e);
            // }).toList(),
            answers: indemData['indemnities']));
      });
      _indemAnswer = loadedIndem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> fetchMemberIndemnities(
      String hostname, String email, int confirmnum) async {
    final url = '${hostname}indemnity/$email/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      notifyListeners();

      print(extactedData[0]['indemnities']);

      if (extactedData[0]['indemnities'] != null) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateUserIndemnity(
      String hostname, int userid, String answers, int confirmnum) async {
    final url = '${hostname}indemnity/userupdate';

    await http.patch(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'confirmnum': confirmnum,
        'indemitem': answers,
      }),
    );
    notifyListeners();
  }

  // 1. Check Registration
  Future<bool> checkUserRegistration(String hostname, String email) async {
    final url = '${hostname}user/check-registration/$email';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_registered'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking registration: $e');
      return false;
    }
  }

  // 2. Check Indemnity Status
  Future<bool> checkIndemnityStatus(String hostname, String email, int confirmnum) async {
    final url = '${hostname}indemnity/check-status/$email/$confirmnum';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking indemnity: $e');
      return false;
    }
  }

  // Future<int> fetchUserIdbyEmail(String hostname, String email) async {
  //   final url = '${hostname}user/byemail/$email';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     final extactedData = jsonDecode(response.body);
  // print(extactedData[0]['id']);
  // final List<IndemnityResponse> loadedIndem = [];
  // extactedData.forEach((indemData) {
  //   loadedIndem.add(IndemnityResponse(
  //       answers: indemData['responddata']?.split(',').map<int>((e) {
  //         return int.parse(e);
  //       }).toList(),
  //       indemcount: indemData['indemcount']));
  // });
  // _indemAnswer = loadedIndem;
  // notifyListeners();
  // print(extactedData[0]['id']);
  //     return extactedData[0]['id'];
  //   } catch (error) {
  //     rethrow;
  //   }
  // }
}
