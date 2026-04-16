import 'dart:convert';
import 'package:charms/HRmodels/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Users with ChangeNotifier {
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';
  
  List<User> _userlist = [];

  List<User> get userlist => [..._userlist];

  User findUserById(String id) {
    return _userlist.firstWhere((user) => user.id == id);
  }

  Map<String, String> _authHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> fetchUsers(String hostname, {String? token}) async {
    final base = hostname.replaceAll(RegExp(r'\/+$'), '');
    final url = '$base/user';

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('fetchUsers failed (${response.statusCode}): ${response.body}');
      }

      final extractedData = jsonDecode(response.body);

      if (extractedData['success'] == true && extractedData['data'] != null) {
        final List<dynamic> extractedUsers = extractedData['data'];
        final List<User> loadedUsers = extractedUsers.map((userData) {
          return User.fromJson(userData);
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

  Future<void> fetchUserByUsername(String username, {String? token}) async {
    final url = '$_hostname/user/data/$username';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('fetchUserByUsername failed (${response.statusCode}): ${response.body}');
      }

      final extractedData = jsonDecode(response.body);

      if (extractedData['success'] == true && extractedData['data'] != null) {
        final userData = extractedData['data'];
        final User user = User.fromJson(userData);
        _userlist = [user];
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error fetching user by username: $error');
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData, {String? token}) async {
    final url = '$_hostname/user/$userId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _authHeaders(token),
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        if (_userlist.isNotEmpty) {
          await fetchUserByUsername(_userlist.first.username, token: token);
        }
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error updating user: $error');
      rethrow;
    }
  }

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
        return true;
      }
      return false;
    } catch (error) {
      debugPrint('Login error: $error');
      return false;
    }
  }
}