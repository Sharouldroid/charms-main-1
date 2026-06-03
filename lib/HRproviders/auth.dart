import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../HRmodels/user.dart';

class Auth with ChangeNotifier {
  DateTime? lastLoginTime;
  String? _token;
  String? _userId;
  DateTime _expiryDate = DateTime.now();
  int _usertype = 2;
  Timer _authTimer = Timer(const Duration(hours: 0), () {});
  String _username = '';
  String _profilePicture = '';

  static const String _hostname = 'https://devcms.com.my/charmsAPI/api/';
  static const String _prefsKey = 'hrUserData';

  String get username => _username;
  String get hostname => _hostname;
  String get profilePicture => _profilePicture;
  bool get isAuth => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  String? get userId => _userId;
  int get usertype => _usertype;

  // ── Login ─────────────────────────────────────────────────────────
  Future<int> authenticate(String username, String passkey,
      {bool saveSession = true}) async {
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

      debugPrint('LOGIN DATA FULL: ${jsonEncode(responseData)}');

      _token    = responseData['token'] ?? '';
      _userId   = (data['id'] ?? data['userid']).toString();
      _username = data['username'] ?? username;
      _usertype = data['usertype'] != null
          ? int.parse(data['usertype'].toString())
          : 2;

      _expiryDate  = DateTime.now().add(const Duration(hours: 3));
      lastLoginTime = DateTime.now();

      _profilePicture = data['staff_image_url']?.toString() ?? '';

      if (saveSession) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _prefsKey,
          json.encode({
            'token':          _token,
            'userId':         _userId,
            'usertype':       _usertype,
            'username':       _username,
            'profilePicture': _profilePicture,
            'expiryDate':     _expiryDate.toIso8601String(),
            'lastLoginTime':  lastLoginTime?.toIso8601String(),
          }),
        );
      }

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
        'firstname':      newUser.firstname,
        'lastname':       newUser.lastname,
        'phone':          newUser.phone,
        'dob':            newUser.dob,
        'address1':       newUser.address1,
        'address2':       newUser.address2,
        'city':           newUser.city,
        'postcode':       newUser.postcode,
        'state':          newUser.state,
        'country':        newUser.country,
        'occupation':     newUser.occupation,
        'email':          newUser.email,
        'username':       newUser.username,
        'password':       newUser.password,
        'passkey':        newUser.password,
        'usertype':       newUser.usertype,
        'gender':         newUser.gender,
        'staff_id':       newUser.staff_id,
        'nationality':    newUser.nationality,
        'religion':       newUser.religion,
        'marital_status': newUser.marital_status,
        'office_phone':   newUser.office_phone,
      }),
    );
    notifyListeners();
  }

  // ── Register staff (3-step) ───────────────────────────────────────
  Future<int> registerStaff(Map<String, String> staffData) async {
    const staffDataUrl    = '${_hostname}staff/create';
    const userUrl         = '${_hostname}user/create';
    const staffProfileUrl = '${_hostname}staff/profile/create';

    try {
      // STEP 1: create HR_userdata
      final staffRes = await http.post(
        Uri.parse(staffDataUrl),
        headers: {'Content-type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'firstname':  staffData['firstname'],
          'lastname':   staffData['lastname'],
          'id_num':     staffData['id_num'],
          'phone':      staffData['phone'],
          'email':      staffData['email'],
          'dob':        staffData['dob'],
          'address1':   staffData['address1'],
          'address2':   staffData['address2'],
          'city':       staffData['city'],
          'postcode':   staffData['postcode'],
          'state':      staffData['state'],
          'country':    staffData['country'],
          'occupation': staffData['occupation'],
          'gender':     staffData['gender'],
          'filename':   staffData['filename'],
        }),
      );

      debugPrint('STAFF CREATE STATUS: ${staffRes.statusCode}');
      if (staffRes.statusCode != 200 && staffRes.statusCode != 201) {
        throw Exception('Staff data creation failed: ${staffRes.body}');
      }

      final staffJson       = jsonDecode(staffRes.body);
      final dynamic rawId   = staffJson['data']?['id'] ?? staffJson['id'];
      final int? userdataId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      if (userdataId == null) throw Exception('Staff id not returned: ${staffRes.body}');

      // STEP 2: create HR_userlogin
      final cleanPass = (staffData['passkey'] ?? staffData['password'] ?? '').trim();

      final userRes = await http.post(
        Uri.parse(userUrl),
        headers: {'Content-type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'userid':   userdataId,
          'username': staffData['username'],
          'email':    staffData['email'],
          'usertype': staffData['usertype'],
          'password': cleanPass,
          'passkey':  cleanPass,
        }),
      );

      debugPrint('USER CREATE STATUS: ${userRes.statusCode}');
      if (userRes.statusCode != 200 && userRes.statusCode != 201) {
        throw Exception('User creation failed: ${userRes.body}');
      }

      // ✅ DEBUG — check exactly what is being sent to Step 3
      debugPrint('=== STEP 3 PAYLOAD DEBUG ===');
      debugPrint('user_id: $userdataId');
      debugPrint('usertype: ${staffData['usertype']}');
      debugPrint('day_rate: ${staffData['day_rate']}');
      debugPrint('category: ${staffData['category']}');
      debugPrint('full staffData map: $staffData');

      // STEP 3: create HR_staff profile
      final profileRes = await http.post(
        Uri.parse(staffProfileUrl),
        headers: {'Content-type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id':            userdataId,
          'category':           staffData['category'],
          'nationality':        staffData['nationality'],
          'religion':           staffData['religion'],
          'marital_status':     staffData['marital_status'],
          'office_phone':       staffData['office_phone'],
          'emergency_name':     staffData['emergency_name'],
          'emergency_ic':       staffData['emergency_ic'],
          'emergency_relation': staffData['emergency_relation'],
          'emergency_gender':   staffData['emergency_gender'],
          'emergency_phone':    staffData['emergency_phone'],
          'department':         staffData['department'],
          'day_rate':           staffData['day_rate'] ?? '0',
          'plain_password':     cleanPass,
        }),
      );

      debugPrint('PROFILE CREATE STATUS: ${profileRes.statusCode}');
      debugPrint('PROFILE RESPONSE BODY: ${profileRes.body}'); // ✅ see full response
      if (profileRes.statusCode != 200 && profileRes.statusCode != 201) {
        throw Exception('Staff profile creation failed: ${profileRes.body}');
      }

      final profileJson      = jsonDecode(profileRes.body);
      final dynamic rawSid   = profileJson['data']?['id'] ?? profileJson['id'];
      final int? staffId     = rawSid is int ? rawSid : int.tryParse(rawSid?.toString() ?? '');
      if (staffId == null) throw Exception('Staff profile id not returned: ${profileRes.body}');

      notifyListeners();
      return staffId;
    } catch (error) {
      debugPrint('registerStaff error: $error');
      rethrow;
    }
  }

  // ── tryAutoLogin ──────────────────────────────────────────────────
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsKey)) return false;

    final extractedData = json.decode(prefs.getString(_prefsKey)!) as Map<String, dynamic>;
    final expiryDate    = DateTime.parse(extractedData['expiryDate'].toString());
    if (expiryDate.isBefore(DateTime.now())) return false;

    _token    = extractedData['token']?.toString();
    _userId   = extractedData['userId']?.toString();
    _usertype = int.tryParse(extractedData['usertype'].toString()) ?? 2;
    _username = extractedData['username']?.toString() ?? '';
    _profilePicture = extractedData['profilePicture']?.toString() ?? '';
    lastLoginTime = DateTime.now();

    notifyListeners();
    _autoLogout();
    return true;
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    _token    = '';
    _userId   = '';
    _usertype = 0;
    _username = '';
    _expiryDate = DateTime.now();
    _authTimer.cancel();
    _authTimer = Timer(Duration.zero, () {});
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void _autoLogout() {
    _authTimer.cancel();
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inHours;
    _authTimer = Timer(Duration(hours: timeToExpiry), logout);
  }
}