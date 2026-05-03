import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:charms/models/http_exception.dart';
import 'package:charms/services/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charms/constants/user_roles.dart';

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
  String? _profilePic;

  // Flag: true when the user authenticated via HR DB fallback.
  // DashboardScreen checks this to skip main-DB fetches that would 404.
  bool _isHRUser = false;

  // normalized host (no trailing slash)
  String get _host => AppConfig.hostname.replaceAll(RegExp(r'\/+$'), '');

  String get hostname => _host;
  String get username => _username;
  bool get isAuth => token != null;
  String? get token => _token;
  int get usertype => _usertype;
  String? get profilePic => _profilePic;

  /// True when the current session was authenticated via the HR DB fallback.
  /// Use this in DashboardScreen to skip `fetchIndividual` (main DB only).
  bool get isHRUser => UserRoles.hrAdmin.contains(_usertype);

  int? get userId {
    if (_token == null) return null;
    return int.tryParse(_token!);
  }

  Future<void> authenticate(String username, String passkey) async {
    final mainUrl = Uri.parse('$_host/api/users/login');

    try {
      final mainResponse = await http.post(
        mainUrl,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({'username': username, 'passkey': passkey}),
      );

      print('MAIN LOGIN STATUS: ${mainResponse.statusCode}');
      print('MAIN LOGIN BODY: ${mainResponse.body}');

      // ── Main DB success ──────────────────────────────────────────
      if (mainResponse.statusCode == 200) {
        final responseData = jsonDecode(mainResponse.body);
        final userData = responseData['user'];
        final status = userData['status'] ?? 'approved';

        if (status != 'approved') {
          if (status == 'pending') throw HttpException('account_pending');
          if (status == 'rejected') throw HttpException('account_rejected');
          throw HttpException('account_status_unknown');
        }

        _token = userData['userid'].toString();
        _username = userData['username'];
        _usertype = userData['usertype'];
        _isHRUser = false; // main DB user — normal dashboard fetches apply
        _expiryDate = DateTime.now().add(const Duration(minutes: 30));

        // ── DEBUG: main DB login ──────────────────────────────────
        debugPrint('=== AUTH SUCCESS (MAIN DB) ===');
        debugPrint('username: $_username');
        debugPrint('usertype: $_usertype');
        debugPrint('token: $_token');
        debugPrint('isHRUser: $_isHRUser');
        // ─────────────────────────────────────────────────────────

        _autoLogout();
        notifyListeners();
        await _savePrefs();
        return;
      }

      // ── Main DB failed with 401 → try HR DB ──────────────────────
      if (mainResponse.statusCode == 401) {
        final hrUrl =
            Uri.parse('https://devcms.com.my/charmsAPI/api/user/auth');
        final hrResponse = await http.post(
          hrUrl,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode({'username': username, 'password': passkey}),
        );

        print('HR LOGIN STATUS: ${hrResponse.statusCode}');
        print('HR LOGIN BODY: ${hrResponse.body}');

        if (hrResponse.statusCode == 200) {
          final hrData = jsonDecode(hrResponse.body);
          if (hrData['success'] == true) {
            final data = hrData['data'];
            _token = (data['id'] ?? data['userid']).toString();
            _username = data['username'] ?? username;
            _usertype = int.tryParse(data['usertype'].toString()) ?? 2;
            _isHRUser = true; // HR DB user — skip main-DB-only fetches
            _expiryDate = DateTime.now().add(const Duration(minutes: 30));
            _profilePic = data['staff_image_url']?.toString() ?? '';

            // ── DEBUG: HR DB login ──────────────────────────────────
            debugPrint('=== AUTH SUCCESS (HR DB) ===');
            debugPrint('username: $_username');
            debugPrint('usertype: $_usertype');
            debugPrint('token: $_token');
            debugPrint('isHRUser: $_isHRUser');
            debugPrint('🌟 Stored profilePic: $_profilePic');
            // ─────────────────────────────────────────────────────────

            _autoLogout();
            notifyListeners();
            await _savePrefs();
            return;
          }
        }

        // HR DB also failed
        throw HttpException('invalid_credentials');
      }

      // ── Other error codes ────────────────────────────────────────
      if (mainResponse.statusCode == 404) throw HttpException('user_not_found');
      final responseData = jsonDecode(mainResponse.body);
      throw HttpException(responseData['message'] ?? 'Authentication failed');
    } on http.ClientException catch (e) {
      throw SocketException('Network error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // ── Save prefs helper ────────────────────────────────────────────
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'userData',
      json.encode({
        'token': _token,
        'usertype': _usertype,
        'username': _username,
        'expiryDate': _expiryDate.toIso8601String(),
        'isHRUser': _isHRUser, // persisted so it survives app restarts
        'profilePic': _profilePic, // persisted so it survives app restarts
      }),
    );
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
    _isHRUser = false; // reset HR flag on logout
    _expiryDate = DateTime.now();

    if (_authTimer.isActive) {
      _authTimer.cancel();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');

    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('userData')) return false;

    final extractedData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

    final expiryDate = DateTime.parse(extractedData['expiryDate'] as String);
    if (expiryDate.isBefore(DateTime.now())) return false;

    _token = extractedData['token'] as String?;
    _usertype = extractedData['usertype'] as int? ?? 2;
    _username = extractedData['username'] as String? ?? '';
    _isHRUser = extractedData['isHRUser'] == true; // restore HR flag
    _profilePic = extractedData['profilePic'] as String? ?? ''; // restore profile picture
    _expiryDate = expiryDate;

    _autoLogout();
    notifyListeners();
    return true;
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
      _isHRUser = false; // social login goes through main DB
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
        'isHRUser': _isHRUser, // always false for social, but kept consistent
        'profilePic': _profilePic, // persist profile picture
      }),
    );
  }
}