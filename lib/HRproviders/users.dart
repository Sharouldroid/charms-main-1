import 'dart:convert';
import 'package:charms/HRmodels/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Users with ChangeNotifier {
  // Updated hostname to match your CHARMS API production URL
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';
  
  List<User> _userlist = [];

  List<User> get userlist => [..._userlist];

  User findUserById(String id) {
    return _userlist.firstWhere((user) => user.id == id);
  }

  // Aligned with Route::get('/', [HRUserController::class, 'fetchUsers'])
  Future<void> fetchUsers(String hostname) async {
  // normalize incoming hostname from HR Auth provider
  final base = hostname.replaceAll(RegExp(r'\/+$'), ''); // remove trailing /
  final url = '$base/user'; // no trailing slash needed

  try {
    final response = await http
        .get(
          Uri.parse(url),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('fetchUsers failed (${response.statusCode}): ${response.body}');
    }

    final extractedData = jsonDecode(response.body);

    if (extractedData['success'] == true && extractedData['data'] != null) {
      final List<dynamic> extractedUsers = extractedData['data'];
      final List<User> loadedUsers = extractedUsers.map((userData) {
        return User(
          id: userData['id'].toString(),
          firstname: userData['firstname'] ?? '',
          lastname: userData['lastname'] ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          dob: userData['dob'] ?? '',
          address1: userData['address1'] ?? '',
          address2: userData['address2'],
          city: userData['city'] ?? '',
          postcode: userData['postcode'] ?? 0,
          state: userData['state'] ?? '',
          country: userData['country'] ?? '',
          occupation: userData['occupation'] ?? '',
          username: userData['username'] ?? '',
          password: userData['passkey'] ?? '',
          usertype: userData['usertype'] ?? 0,
          gender: userData['gender'] ?? 1,
          staff_id: userData['staff_id'],
          category: userData['category'],
          nationality: userData['nationality'],
          religion: userData['religion'],
          marital_status: userData['marital_status'],
          office_phone: userData['office_phone'],
          emergency_name: userData['emergency_name'],
          emergency_ic: userData['emergency_ic'],
          emergency_relation: userData['emergency_relation'],
          emergency_gender: userData['emergency_gender'],
          emergency_phone: userData['emergency_phone'],
        );
      }).toList();

      _userlist = loadedUsers;
      notifyListeners();
      return;
    }

    throw Exception('Invalid API response: ${response.body}');
  } catch (error) {
    debugPrint('Error fetching users: $error');
    rethrow;
  }
}

  // Aligned with Route::get('/data/{username}', [HRUserController::class, 'fetchUserByUsername'])
  Future<void> fetchUserByUsername(String username) async {
    final url = '$_hostname/user/data/$username';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);

      if (extractedData['success'] == true && extractedData['data'] != null) {
        final userData = extractedData['data'];
        final User user = User(
          id: userData['id'].toString(),
          firstname: userData['firstname'] ?? '',
          lastname: userData['lastname'] ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          dob: userData['dob'] ?? '',
          address1: userData['address1'] ?? '',
          address2: userData['address2'],
          city: userData['city'] ?? '',
          postcode: userData['postcode'] ?? 0,
          state: userData['state'] ?? '',
          country: userData['country'] ?? '',
          occupation: userData['occupation'] ?? '',
          username: userData['username'] ?? '',
          password: userData['passkey'] ?? '',
          usertype: userData['usertype'] ?? 0,
          gender: userData['gender'] ?? 1,
          staff_id: userData['staff_id'],
          category: userData['category'],
          nationality: userData['nationality'],
          religion: userData['religion'],
          marital_status: userData['marital_status'],
          office_phone: userData['office_phone'],
          emergency_name: userData['emergency_name'],
          emergency_ic: userData['emergency_ic'],
          emergency_relation: userData['emergency_relation'],
          emergency_gender: userData['emergency_gender'],
          emergency_phone: userData['emergency_phone'],
        );
        _userlist = [user];
        notifyListeners();
      }
    } catch (error) {
      print('Error fetching user by username: $error');
      rethrow;
    }
  }

  // Aligned with Route::put('/{id}', [HRUserController::class, 'updateUser'])
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    final url = '$_hostname/user/$userId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        // Refresh data
        if (_userlist.isNotEmpty) {
          await fetchUserByUsername(_userlist.first.username);
        }
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (error) {
      print('Error updating user: $error');
      rethrow;
    }
  }

  // Aligned with Route::post('/auth', [HRUserController::class, 'loginUser'])
  Future<bool> login(String username, String password) async {
    final url = '$_hostname/user/auth';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        // You might want to store the user data here
        return true;
      }
      return false;
    } catch (error) {
      print('Login error: $error');
      return false;
    }
  }
}