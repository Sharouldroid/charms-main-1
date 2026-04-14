import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../HRmodels/user.dart';

class Auth with ChangeNotifier {
  DateTime? lastLoginTime;
  String? _token;
  DateTime _expiryDate = DateTime.now();
  int _usertype = 2;
  Timer _authTimer = Timer(const Duration(hours: 0), () {});
  String _username = '';

  static const String _hostname = 'https://devcms.com.my/charmsAPI/api/';

  String get username => _username;
  String get hostname => _hostname;
  bool get isAuth => token != null;
  String? get token => _token;
  int get usertype => _usertype;

  // Login
  Future<int> authenticate(String username, String passkey) async {
    const url = '${_hostname}user/auth';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': passkey,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      final data = responseData['data'];

      _token = (data['id'] ?? data['userid']).toString();
      _username = data['username'] ?? username;
      _usertype =
          data['usertype'] != null ? int.parse(data['usertype'].toString()) : 2;

      _expiryDate = DateTime.now().add(const Duration(hours: 3));
      lastLoginTime = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'usertype': _usertype,
        'username': _username,
        'expiryDate': _expiryDate.toIso8601String(),
        'lastLoginTime': lastLoginTime?.toIso8601String(),
      });
      prefs.setString('userData', userData);

      _autoLogout();
      notifyListeners();
      return _usertype;
    }

    throw Exception(responseData['message'] ?? 'Authentication failed');
  }

  // Generic register
  Future<void> register(User newUser) async {
    const url = '${_hostname}user/create';
    await http.post(
      Uri.parse(url),
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
        'password': newUser.password,
        'passkey': newUser.password,
        'usertype': newUser.usertype,
        'gender': newUser.gender,
        'staff_id': newUser.staff_id,
        'nationality': newUser.nationality,
        'religion': newUser.religion,
        'marital_status': newUser.marital_status,
        'office_phone': newUser.office_phone,
      }),
    );

    notifyListeners();
  }

  // Register staff (3-step):
  // 1) HR_userdata -> /staff/create
  // 2) HR_userlogin -> /user/create (userid = HR_userdata.id)
  // 3) HR_staff -> /staff/profile/create (user_id = HR_userdata.id)  <-- IMPORTANT
  Future<void> registerStaff(Map<String, String> staffData) async {
    const staffDataUrl = '${_hostname}staff/create';
    const userUrl = '${_hostname}user/create';
    const staffProfileUrl = '${_hostname}staff/profile/create';

    try {
      // STEP 1: create HR_userdata
      final staffPayload = {
        'firstname': staffData['firstname'],
        'lastname': staffData['lastname'],
        'id_num': staffData['id_num'],
        'phone': staffData['phone'],
        'email': staffData['email'],
        'dob': staffData['dob'],
        'address1': staffData['address1'],
        'address2': staffData['address2'],
        'city': staffData['city'],
        'postcode': staffData['postcode'],
        'state': staffData['state'],
        'country': staffData['country'],
        'occupation': staffData['occupation'],
        'gender': staffData['gender'],
        'filename': staffData['filename'],
      };

      debugPrint('STAFF DATA CREATE URL: $staffDataUrl');
      debugPrint('STAFF DATA CREATE PAYLOAD: ${jsonEncode(staffPayload)}');

      final staffRes = await http.post(
        Uri.parse(staffDataUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(staffPayload),
      );

      debugPrint('STAFF DATA CREATE STATUS: ${staffRes.statusCode}');
      debugPrint('STAFF DATA CREATE RESPONSE: ${staffRes.body}');

      if (staffRes.statusCode != 200 && staffRes.statusCode != 201) {
        throw Exception('Staff data creation failed: ${staffRes.body}');
      }

      final staffJson = jsonDecode(staffRes.body);
      final dynamic rawStaffId = staffJson['data']?['id'] ?? staffJson['id'];

      final int? createdStaffId = rawStaffId is int
          ? rawStaffId
          : int.tryParse(rawStaffId?.toString() ?? '');

      if (createdStaffId == null) {
        throw Exception('Staff data created but id not returned: ${staffRes.body}');
      }

      // STEP 2: create HR_userlogin
      final cleanPass = (staffData['passkey'] ?? staffData['password'] ?? '').trim();

      final userPayload = {
        'userid': createdStaffId,
        'username': staffData['username'],
        'email': staffData['email'],
        'usertype': staffData['usertype'],
        'password': cleanPass,
        'passkey': cleanPass,
      };

      debugPrint('USER CREATE URL: $userUrl');
      debugPrint('USER CREATE PAYLOAD: ${jsonEncode(userPayload)}');

      final userRes = await http.post(
        Uri.parse(userUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userPayload),
      );

      debugPrint('USER CREATE STATUS: ${userRes.statusCode}');
      debugPrint('USER CREATE RESPONSE: ${userRes.body}');

      if (userRes.statusCode != 200 && userRes.statusCode != 201) {
        throw Exception('User creation failed: ${userRes.body}');
      }

      // Optional parse (kept for debug visibility)
      final userJson = jsonDecode(userRes.body);
      final dynamic rawLoginId = userJson['data']?['id'] ?? userJson['id'];
      final int? createdLoginId = rawLoginId is int
          ? rawLoginId
          : int.tryParse(rawLoginId?.toString() ?? '');
      debugPrint('USER LOGIN ID (not used for HR_staff FK): $createdLoginId');

      // STEP 3: create HR_staff profile
      // IMPORTANT: FK HR_staff.user_id references HR_userdata.id
      final staffProfilePayload = {
        'user_id': createdStaffId, // <-- FIXED
        'category': staffData['category'],
        'nationality': staffData['nationality'],
        'religion': staffData['religion'],
        'marital_status': staffData['marital_status'],
        'office_phone': staffData['office_phone'],
        'emergency_name': staffData['emergency_name'],
        'emergency_ic': staffData['emergency_ic'],
        'emergency_relation': staffData['emergency_relation'],
        'emergency_gender': staffData['emergency_gender'],
        'emergency_phone': staffData['emergency_phone'],
      };

      debugPrint('STAFF PROFILE CREATE URL: $staffProfileUrl');
      debugPrint('STAFF PROFILE CREATE PAYLOAD: ${jsonEncode(staffProfilePayload)}');

      final staffProfileRes = await http.post(
        Uri.parse(staffProfileUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(staffProfilePayload),
      );

      debugPrint('STAFF PROFILE CREATE STATUS: ${staffProfileRes.statusCode}');
      debugPrint('STAFF PROFILE CREATE RESPONSE: ${staffProfileRes.body}');

      if (staffProfileRes.statusCode != 200 && staffProfileRes.statusCode != 201) {
        throw Exception('Staff profile creation failed: ${staffProfileRes.body}');
      }

      notifyListeners();
    } catch (error) {
      debugPrint('Error during registerStaff: $error');
      rethrow;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return false;

    final extractedData =
        json.decode(prefs.getString('userData')!) as Map<String, Object>;

    final expiryDate = DateTime.parse(extractedData['expiryDate'].toString());
    if (expiryDate.isAfter(DateTime.now())) return false;

    _token = extractedData['token'].toString();
    _usertype = int.parse(extractedData['usertype'].toString());
    _username = extractedData['username'].toString();
    lastLoginTime = DateTime.now();

    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = '';
    _usertype = 0;
    _username = '';
    _expiryDate = DateTime.now();
    _authTimer.cancel();
    _authTimer = Timer(Duration.zero, () {});
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    _authTimer.cancel();
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inHours;
    _authTimer = Timer(Duration(hours: timeToExpiry), logout);
  }
}