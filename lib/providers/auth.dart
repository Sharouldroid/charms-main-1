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
  // Normalize hostname once (remove trailing slash)
  static String get _host =>
      AppConfig.hostname.replaceAll(RegExp(r'\/+$'), '');

  // Keep /api base explicit and consistent
  static String get baseUrl => '$_host/api';

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

  // normalized host (no trailing slash)
  String get _host => AppConfig.hostname.replaceAll(RegExp(r'\/+$'), '');

  String get hostname => _host;

  String get username => _username;

  bool get isAuth => token != null;

  String? get token => _token;

  int get usertype => _usertype;

  int? get userId {
    if (_token == null) return null;
    return int.tryParse(_token!);
  }

  Future<void> authenticate(String username, String passkey) async {
    final url = Uri.parse('$_host/api/users/login');
    print('LOGIN URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({'username': username, 'passkey': passkey}),
      );

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN BODY: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userData = responseData['user'];
        final status = userData['status'] ?? 'approved';

        if (status != 'approved') {
          if (status == 'pending') throw HttpException('account_pending');
          if (status == 'rejected') throw HttpException('account_rejected');
          throw HttpException('account_status_unknown');
        }

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
        if (response.statusCode == 401) {
          throw HttpException('invalid_credentials');
        } else if (response.statusCode == 404) {
          throw HttpException('user_not_found');
        } else {
          throw HttpException(responseData['message'] ?? 'Authentication failed');
        }
      }
    } on http.ClientException catch (e) {
      throw SocketException('Network error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> register(User newUser) async {
    final url = Uri.parse('$_host/api/users/create');
    print('REGISTER URL: $url');

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

    print('REGISTER STATUS: ${response.statusCode}');
    print('REGISTER BODY: ${response.body}');

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'status': response.statusCode,
        'message': responseData['message'] ?? 'User created successfully',
      };
    } else {
      return {
        'status': response.statusCode,
        'message': responseData['message'] ?? 'Registration failed',
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _usertype = 0;
    _username = '';
    _expiryDate = DateTime.now();

    if (_authTimer.isActive) {
      _authTimer.cancel();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');

    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
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

      final url = Uri.parse('$_host/api/social-login');
      print('GOOGLE LOGIN URL: $url');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'provider': 'google',
          'provider_id': googleUser.id,
          'email': googleUser.email,
          'firstname': nameParts.first,
          'lastname':
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User',
          'avatar': googleUser.photoUrl,
          'google_access_token': googleAuth.accessToken,
          'google_id_token': googleAuth.idToken,
        }),
      );

      print('GOOGLE LOGIN STATUS: ${response.statusCode}');
      print('GOOGLE LOGIN BODY: ${response.body}');

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
        'isSocial': true,
      }),
    );
  }
}