import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:image_picker/image_picker.dart';

class Staffs with ChangeNotifier {
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  List<Staff> _staffList = [];
  List<Staff> get staffList => [..._staffList];

  // ── Convenience getters ────────────────────────────────────────────────────
  List<Staff> get partTimers =>
      _staffList.where((s) => s.isPartTimer).toList();

  List<Staff> get regularStaff =>
      _staffList.where((s) => !s.isPartTimer).toList();

  List<Staff> getStaffByCategory(int category) =>
      _staffList.where((s) => s.category == category).toList();

  List<Staff> getStaffByCategoryAndDepartment(int category, String? department) {
    return _staffList.where((s) {
      final matchesCategory   = s.category == category;
      final matchesDepartment = department == null ||
          department.isEmpty ||
          s.department == department;
      return matchesCategory && matchesDepartment;
    }).toList();
  }

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  String _toStr(dynamic v) => (v ?? '').toString();
  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

  // ── Fetch all staff ────────────────────────────────────────────────────────
  Future<void> fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$_hostname/staff/all'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch staff: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      final List<dynamic> staffData =
          (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List<dynamic>
              : (decoded is List ? decoded : <dynamic>[]);

      _staffList = staffData.map((data) => Staff(
        staffId:           _toInt(data['staff_id'] ?? data['id']),
        userId:            _toInt(data['user_id'] ?? data['userid']),
        username:          _toStr(data['username']),
        email:             _toStr(data['email']),
        usertype:          _toInt(data['usertype']),
        firstname:         _toStr(data['firstname']),
        lastname:          _toStr(data['lastname']),
        occupation:        _toStr(data['occupation']),
        phone:             _toStr(data['phone']),
        category:          _toInt(data['category']),
        nationality:       _toStr(data['nationality']),
        religion:          _toStr(data['religion']),
        maritalStatus:     _toInt(data['marital_status']),
        gender:            _toInt(data['gender']),
        officePhone:       _toStr(data['office_phone']),
        emergencyName:     _toStr(data['emergency_name']),
        emergencyIc:       _toStr(data['emergency_ic']),
        emergencyRelation: _toStr(data['emergency_relation']),
        emergencyGender:   _toInt(data['emergency_gender']),
        emergencyPhone:    _toStr(data['emergency_phone']),
        idNum:             _toStr(data['idnum'] ?? data['id_num']),
        dob:               _toStr(data['dob']),
        address1:          _toStr(data['address1']),
        address2:          _toStr(data['address2']),
        city:              _toStr(data['city']),
        postcode:          _toInt(data['postcode']),
        state:             _toStr(data['state']),
        country:           _toStr(data['country']),
        filepath:          data['filepath'],
        filename:          data['filename'],
        department:        data['department'],
        createdAt:         data['created_at'] != null
            ? DateTime.tryParse(data['created_at'].toString())
            : null,
        dayRate:           _toDouble(data['day_rate']), // ✅
      )).toList();

      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching staff: $error');
      rethrow;
    }
  }

  // ── Upload staff photo ─────────────────────────────────────────────────────
  Future<void> uploadStaffPhoto(int staffId, XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_hostname/staff/$staffId/photo'),
      );
      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        final bytes       = await imageFile.readAsBytes();
        final filename    = imageFile.name;
        final ext         = filename.split('.').last.toLowerCase();
        final contentType = ext == 'png'
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');
        request.files.add(http.MultipartFile.fromBytes(
            'photo', bytes, filename: filename, contentType: contentType));
      } else {
        final filename    = imageFile.name;
        final ext         = filename.split('.').last.toLowerCase();
        final contentType = ext == 'png'
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');
        request.files.add(await http.MultipartFile.fromPath(
            'photo', imageFile.path, contentType: contentType));
      }

      final streamedResponse = await request.send();
      final response         = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to upload photo: ${response.body}');
      }

      final responseData = json.decode(response.body);
      final newFilepath  = responseData['data']?['filepath'];
      final newFilename  = responseData['data']?['filename'];

      final index = _staffList.indexWhere((s) => s.staffId == staffId);
      if (index != -1 && newFilepath != null) {
        final existing = _staffList[index];
        _staffList[index] = Staff(
          staffId:           existing.staffId,
          userId:            existing.userId,
          username:          existing.username,
          email:             existing.email,
          usertype:          existing.usertype,
          firstname:         existing.firstname,
          lastname:          existing.lastname,
          occupation:        existing.occupation,
          phone:             existing.phone,
          category:          existing.category,
          nationality:       existing.nationality,
          religion:          existing.religion,
          maritalStatus:     existing.maritalStatus,
          gender:            existing.gender,
          officePhone:       existing.officePhone,
          emergencyName:     existing.emergencyName,
          emergencyIc:       existing.emergencyIc,
          emergencyRelation: existing.emergencyRelation,
          emergencyGender:   existing.emergencyGender,
          emergencyPhone:    existing.emergencyPhone,
          idNum:             existing.idNum,
          dob:               existing.dob,
          address1:          existing.address1,
          address2:          existing.address2,
          city:              existing.city,
          postcode:          existing.postcode,
          state:             existing.state,
          country:           existing.country,
          filepath:          newFilepath,
          filename:          newFilename,
          department:        existing.department,
          createdAt:         existing.createdAt,
          dayRate:           existing.dayRate, // ✅
        );
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error uploading photo: $error');
      rethrow;
    }
  }

  // ── Update staff details ───────────────────────────────────────────────────
  Future<void> updateStaffDetails(int staffId, Staff updatedStaff) async {
    try {
      final payload = {
        'staff_data': {
          'category':           updatedStaff.category.toString(),
          'nationality':        updatedStaff.nationality,
          'religion':           updatedStaff.religion,
          'marital_status':     updatedStaff.maritalStatus.toString(),
          'office_phone':       updatedStaff.officePhone ?? '',
          'emergency_name':     updatedStaff.emergencyName,
          'emergency_ic':       updatedStaff.emergencyIc,
          'emergency_relation': updatedStaff.emergencyRelation,
          'emergency_gender':   updatedStaff.emergencyGender.toString(),
          'emergency_phone':    updatedStaff.emergencyPhone,
          'day_rate':           updatedStaff.dayRate, // ✅
        },
        'user_data': {
          'username': updatedStaff.username,
          'email':    updatedStaff.email,
        },
        'userdata_data': {
          'firstname':  updatedStaff.firstname,
          'lastname':   updatedStaff.lastname,
          'idnum':      updatedStaff.idNum,
          'dob':        updatedStaff.dob,
          'phone':      updatedStaff.phone,
          'address1':   updatedStaff.address1,
          'address2':   updatedStaff.address2,
          'city':       updatedStaff.city,
          'postcode':   updatedStaff.postcode.toString(),
          'state':      updatedStaff.state,
          'country':    updatedStaff.country,
          'occupation': updatedStaff.occupation,
          'gender':     updatedStaff.gender.toString(),
        },
      };

      final response = await http.put(
        Uri.parse('$_hostname/staff/$staffId'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final index = _staffList.indexWhere((s) => s.staffId == staffId);
        if (index != -1) {
          _staffList[index] = Staff(
            staffId:           updatedStaff.staffId,
            userId:            updatedStaff.userId,
            username:          updatedStaff.username,
            email:             updatedStaff.email,
            usertype:          updatedStaff.usertype,
            firstname:         updatedStaff.firstname,
            lastname:          updatedStaff.lastname,
            occupation:        updatedStaff.occupation,
            phone:             updatedStaff.phone,
            category:          updatedStaff.category,
            nationality:       updatedStaff.nationality,
            religion:          updatedStaff.religion,
            maritalStatus:     updatedStaff.maritalStatus,
            gender:            updatedStaff.gender,
            officePhone:       updatedStaff.officePhone,
            emergencyName:     updatedStaff.emergencyName,
            emergencyIc:       updatedStaff.emergencyIc,
            emergencyRelation: updatedStaff.emergencyRelation,
            emergencyGender:   updatedStaff.emergencyGender,
            emergencyPhone:    updatedStaff.emergencyPhone,
            idNum:             updatedStaff.idNum,
            dob:               updatedStaff.dob,
            address1:          updatedStaff.address1,
            address2:          updatedStaff.address2,
            city:              updatedStaff.city,
            postcode:          updatedStaff.postcode,
            state:             updatedStaff.state,
            country:           updatedStaff.country,
            filepath:          _staffList[index].filepath,
            filename:          _staffList[index].filename,
            department:        updatedStaff.department,
            createdAt:         _staffList[index].createdAt,
            dayRate:           updatedStaff.dayRate, // ✅
          );
          notifyListeners();
        }
      } else {
        throw Exception('Failed to update staff: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error updating staff: $error');
      rethrow;
    }
  }

  // ── Delete staff ───────────────────────────────────────────────────────────
  Future<void> deleteStaff(int staffId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_hostname/staff/$staffId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _staffList.removeWhere((s) => s.staffId == staffId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete staff: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error deleting staff: $error');
      rethrow;
    }
  }
}