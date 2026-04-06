import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:charms/models/http_exception.dart';
import 'package:charms/services/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class ApiConfig {
  // Use centralized AppConfig for base URL
  static String get baseUrl => AppConfig.hostname.replaceAll('/api/', '/charmsAPI/api');

  // Example endpoints (you can add more as needed)
  static String get campsiteIssues => "$baseUrl/campsite-issues";
  static String get facilities => "$baseUrl/facilities";
  static String get kitchenMaintenance => "$baseUrl/kitchen-maintenance";
  static String get quartersMaintenance => "$baseUrl/quarters-maintenance";
  static String get outdoorClassroom => "$baseUrl/outdoorclassroom-maintenance";
  static String get waterSportArea => "$baseUrl/watersportmaintenance";
  static String get officeMaintenance => "$baseUrl/office-maintenance";
  static String get surauMaintenance => "$baseUrl/surau-maintenance";
  static String get firstaid => "$baseUrl/firstaid";
}

class Auth with ChangeNotifier {
  String? _token;
  DateTime _expiryDate = DateTime.now();
  int _usertype = 2;
  Timer _authTimer = Timer(const Duration(hours: 0), () {});
  String _username = '';

  // Use centralized AppConfig for hostname
  String get hostname => AppConfig.hostname;

  String get username {
    return _username;
  }

  bool get isAuth {
    return token != null;
  }

  String? get token {
    return _token;
  }

  int get usertype {
    return _usertype;
  }

  int? get userId {
    if (_token == null) return null;
    return int.tryParse(_token!);
  }

  Future<void> authenticate(String username, String passkey) async {
    final url = Uri.parse('${hostname}users/login');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({'username': username, 'passkey': passkey}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // --- START ADDED STATUS CHECK ---
        final userData = responseData['user'];
        final status = userData['status'] ?? 'approved';
        if (status != 'approved') {
          if (status == 'pending') {
            throw HttpException('account_pending');
          } else if (status == 'rejected') {
            throw HttpException('account_rejected');
          } else {
            throw HttpException('account_status_unknown');
          }
        }
        // --- END STATUS CHECK ---

        // Successful login
        _token = responseData['user']['userid'].toString();
        _username = responseData['user']['username'];
        _usertype = responseData['user']['usertype'];
        _expiryDate = DateTime.now().add(const Duration(minutes: 30));

        _autoLogout();
        notifyListeners();

        final prefs = await SharedPreferences.getInstance();
        final userData2 = json.encode({
          'token': _token,
          'usertype': _usertype,
          'username': _username,
          'expiryDate': _expiryDate.toIso8601String(),
        });
        await prefs.setString('userData', userData2);
      } else {
        // Handle different error statuses
        if (response.statusCode == 401) {
          throw HttpException('invalid_credentials');
        } else if (response.statusCode == 404) {
          throw HttpException('user_not_found');
        } else {
          throw HttpException(
            responseData['message'] ?? 'Authentication failed',
          );
        }
      }
    } on http.ClientException catch (e) {
      throw SocketException('Network error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> register(User newUser) async {
    final url = Uri.parse('${hostname}users/create');

    final response = await http.post(
      url,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'firstname': newUser.firstname,
        'lastname': newUser.lastname,
        'phone': newUser.phone,
        'dob': newUser.dob,
        'address1': newUser.address1,
        'address2': newUser.address2,
        'city': newUser.city,
        'postcode': newUser.postcode,
        'state': newUser.state,
        'country': newUser.country,
        'occupation': newUser.occupation,
        'email': newUser.email,
        'username': newUser.username,
        'passkey': newUser.password,
        'usertype': newUser.usertype,
        'gender': newUser.gender,
        'idnum': newUser.idnum,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Registration Successful');
      return {
        'status': response.statusCode,
        'message': responseData['message'] ?? 'User created successfully',
      };
    } else {
      print('❌ Registration Failed: ${response.body}');
      return {
        'status': response.statusCode,
        'message': responseData['message'] ?? 'Registration failed',
      };
    }
  }

  Future<void> logout() async {
    // Clear all authentication data
    _token = null;
    _usertype = 0;
    _username = '';
    _expiryDate = DateTime.now();

    // Cancel any active timer
    if (_authTimer.isActive) {
      _authTimer.cancel();
    }

    // Clear all stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    // DON'T clear 'username' and 'passkey' - those are for Remember Me
    // await prefs.remove('username');
    // await prefs.remove('passkey');

    // DON'T call clearAll - it wipes Remember Me credentials!
    // await SecureStorageService.clearAll();

    // Notify listeners about the change
    notifyListeners();
  }

  // Update your tryAutoLogin to use userData instead of username/passkey
  Future<bool> tryAutoLogin() async {
    // Always return false to force login screen on every start
    return false;
  }

  void _autoLogout() {
    if (_authTimer.isActive) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  Future<void> handleGoogleLogin() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser!.authentication;
      final nameParts =
          googleUser.displayName?.split(' ') ?? ['Google', 'User'];

      final response = await http.post(
        Uri.parse('${hostname}social-login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'provider': 'google',
          'provider_id': googleUser.id,
          'email': googleUser.email,
          'firstname': nameParts.first,
          'lastname':
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User',
          'avatar': googleUser.photoUrl,
        }),
      );

      _handleSocialResponse(response);
    } catch (error) {
      throw HttpException('Google login failed: $error');
    }
  }

  void _handleSocialResponse(http.Response response) {
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _token = responseData['user']['userid'].toString();
      _username = responseData['user']['username'];
      _usertype = responseData['user']['usertype'];
      _expiryDate = DateTime.now().add(const Duration(minutes: 30));

      _autoLogout();
      notifyListeners();

      // Save to shared preferences
      _saveAuthData();
    } else {
      throw HttpException(responseData['message'] ?? 'Social login failed');
    }
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'userData',
      json.encode({
        'token': _token,
        'usertype': _usertype,
        'username': _username,
        'expiryDate': _expiryDate.toIso8601String(),
        'isSocial': true, // Add social login flag
      }),
    );
  }
}