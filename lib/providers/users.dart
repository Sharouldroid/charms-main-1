import 'dart:async';
import 'dart:convert';

import 'package:charms/models/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Users with ChangeNotifier {
  List<User> _userlist = [];

  List<User> get userlist {
    return [..._userlist];
  }

  User findById(String id) {
    return _userlist.firstWhere(
      (user) => user.id == id,
      orElse: () => throw Exception('User not found'),
    );
  }

  // all checked 23 Mar 2025

  Future<void> fetchUser(String hostname) async {
    final url = '${hostname}users/';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedStaff = jsonDecode(response.body);
      final List<User> loadedUser = [];
      extractedStaff.forEach((userData) {
        loadedUser.add(
          User(
            id: userData['id'].toString(),
            firstname: userData['firstname'] ?? '',
            lastname: userData['lastname'] ?? '',
            phone: userData['phone'] ?? '',
            email: userData['login']['email'] ?? '',
            dob: userData['dob'] ?? '',
            address1: userData['address1'] ?? '',
            address2: userData['address2'] ?? '',
            city: userData['city'] ?? '',
            postcode: userData['postcode'] ?? '',
            state: userData['state'] ?? '',
            country: userData['country'] ?? '',
            occupation: userData['occupation'] ?? '',
            username: userData['login']['username'] ?? '',
            password: userData['login']['passkey'] ?? '',
            usertype: userData['login']['usertype'] ?? 2,
            status: userData['status'] ?? '',
            gender: userData['gender'] ?? 1,
            idnum: userData['idnum'].toString(),
          ),
        );
      });
      _userlist = loadedUser;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> update(String hostname, User editedUser, int userid) async {
    final userIndex = _userlist.indexWhere(
      (user) => user.id == userid.toString(),
    );
    final url = '${hostname}users/$userid';
    try {
      await http.put(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'firstname': editedUser.firstname,
          'lastname': editedUser.lastname,
          'phone': editedUser.phone,
          'dob': editedUser.dob,
          'address1': editedUser.address1,
          'address2': editedUser.address2,
          'city': editedUser.city,
          'postcode': editedUser.postcode,
          'state': editedUser.state,
          'country': editedUser.country,
          'occupation': editedUser.occupation,
          'email': editedUser.email,
          'username': editedUser.username,
          'usertype': editedUser.usertype,
          'gender': editedUser.gender,
          'idnum': editedUser.idnum,
          'id': userid,
        }),
      );

      _userlist[userIndex] = editedUser;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateLogin(String hostname, UserLogin user, int userid) async {
    // final userIndex =
    //     _userlist.indexWhere((user) => user.id == userid.toString());
    final url = '${hostname}users/$userid';
    try {
      await http.put(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          // 'username': user.username,
          'passkey': user.password,
          'id': userid,
        }),
      );

      // _userlist[userIndex] = user;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateUserRole(String hostname, int usertype, int userid) async {
    final url = '${hostname}users/$userid';
    try {
      await http.put(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          // 'username': user.username,
          'usertype': usertype,
          'id': userid,
        }),
      );

      // _userlist[userIndex] = user;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> resetPassword(
    String hostname,
    String password,
    int userid,
  ) async {
    // final userIndex =
    //     _userlist.indexWhere((user) => user.id == userid.toString());
    final url = '${hostname}users/$userid';
    try {
      await http.put(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          // 'username': user.username,
          'passkey': password,
          'id': userid,
        }),
      );

      // _userlist[userIndex] = user;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<User> fetchIndividual(String hostname, int userid) async {
    final url = '${hostname}users/$userid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);

      // If your backend returns the user under a 'user' key
      final userData = extractedData['user'] ?? extractedData;

      final user = User(
        id: userData['id'].toString(),
        firstname: userData['firstname'] ?? '',
        lastname: userData['lastname'] ?? '',
        phone: userData['phone'] ?? '',
        email: userData['login']['email'] ?? '',
        dob: userData['dob'] ?? '',
        address1: userData['address1'] ?? '',
        address2: userData['address2'] ?? '',
        city: userData['city'] ?? '',
        postcode: userData['postcode'] ?? 0,
        state: userData['state'] ?? '',
        country: userData['country'] ?? '',
        occupation: userData['occupation'] ?? '',
        username: userData['login']['username'] ?? '',
        password: userData['login']['passkey'] ?? '',
        usertype: userData['login']['usertype'] ?? 3,
        status: userData['status'] ?? '',
        gender: userData['gender'] ?? 1,
        idnum: userData['idnum'].toString(),
      );

      _userlist = [user];
      notifyListeners();
      return user;
    } catch (error) {
      rethrow;
    }
  }
}

Future<void> softDeleteUser(String hostname, int userid) async {
  final url = '${hostname}users/soft-delete/$userid'; // ✅ match route
  try {
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user. Status: ${response.statusCode}');
    }
  } catch (error) {
    rethrow;
  }
}


// all checked 23 Mar 2025
