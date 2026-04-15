import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/HRmodels/staff.dart';

class Staffs with ChangeNotifier {
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  List<Staff> _staffList = [];

  List<Staff> get staffList => [..._staffList];

  List<Staff> getStaffByCategory(int category) {
    return _staffList.where((staff) => staff.category == category).toList();
  }

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  String _toStr(dynamic v) => (v ?? '').toString();

  // Fetch Staff Data
  Future<void> fetchStaff() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_hostname/staff/all'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch staff: ${response.statusCode} ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      // Expected format: { success: true, data: [...] }
      final List<dynamic> staffData =
          (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List<dynamic>
              : (decoded is List ? decoded : <dynamic>[]);

      _staffList = staffData.map((data) {
        return Staff(
          // prefer staff_id if API provides it, fallback to id
          staffId: _toInt(data['staff_id'] ?? data['id']),
          // prefer user_id, fallback userid
          userId: _toInt(data['user_id'] ?? data['userid']),
          username: _toStr(data['username']),
          email: _toStr(data['email']),
          usertype: _toInt(data['usertype']),
          firstname: _toStr(data['firstname']),
          lastname: _toStr(data['lastname']),
          occupation: _toStr(data['occupation']),
          phone: _toStr(data['phone']),
          category: _toInt(data['category']),
          nationality: _toStr(data['nationality']),
          religion: _toStr(data['religion']),
          maritalStatus: _toInt(data['marital_status']),
          officePhone: _toStr(data['office_phone']),
          emergencyName: _toStr(data['emergency_name']),
          emergencyIc: _toStr(data['emergency_ic']),
          emergencyRelation: _toStr(data['emergency_relation']),
          emergencyGender: _toInt(data['emergency_gender']),
          emergencyPhone: _toStr(data['emergency_phone']),
          idNum: _toStr(data['idnum'] ?? data['id_num']),
          dob: _toStr(data['dob']),
          address1: _toStr(data['address1']),
          address2: _toStr(data['address2']),
          city: _toStr(data['city']),
          postcode: _toInt(data['postcode']),
          state: _toStr(data['state']),
          country: _toStr(data['country']),
        );
      }).toList();

      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching staff: $error');
      rethrow;
    }
  }

  // Update Staff Details
  Future<void> updateStaffDetails(int staffId, Staff updatedStaff) async {
  try {
    final payload = {
      // HR_staff table fields
      'staff_data': {
        'category': updatedStaff.category.toString(),
        'nationality': updatedStaff.nationality,
        'religion': updatedStaff.religion,
        'marital_status': updatedStaff.maritalStatus.toString(),
        'office_phone': updatedStaff.officePhone,
        'emergency_name': updatedStaff.emergencyName,
        'emergency_ic': updatedStaff.emergencyIc,
        'emergency_relation': updatedStaff.emergencyRelation,
        'emergency_gender': updatedStaff.emergencyGender.toString(),
        'emergency_phone': updatedStaff.emergencyPhone,
      },

      // HR_userlogin table fields
      'user_data': {
        'username': updatedStaff.username,
        'email': updatedStaff.email,
      },

      // HR_userdata table fields
      'userdata_data': {
        'firstname': updatedStaff.firstname,
        'lastname': updatedStaff.lastname,
        'idnum': updatedStaff.idNum, // column is idnum
        'dob': updatedStaff.dob,
        'phone': updatedStaff.phone,
        'address1': updatedStaff.address1,
        'address2': updatedStaff.address2,
        'city': updatedStaff.city,
        'postcode': updatedStaff.postcode.toString(),
        'state': updatedStaff.state,
        'country': updatedStaff.country,
        'occupation': updatedStaff.occupation,
      },
    };

    debugPrint('UPDATE STAFF URL: $_hostname/staff/$staffId');
    debugPrint('UPDATE STAFF PAYLOAD: ${json.encode(payload)}');

    final response = await http.put(
      Uri.parse('$_hostname/staff/$staffId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(payload),
    );

    debugPrint('UPDATE STAFF STATUS: ${response.statusCode}');
    debugPrint('UPDATE STAFF RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final index = _staffList.indexWhere((staff) => staff.staffId == staffId);
      if (index != -1) {
        _staffList[index] = updatedStaff;
        notifyListeners();
      }
    } else {
      throw Exception('Failed to update staff details: ${response.body}');
    }
  } catch (error) {
    debugPrint('Error updating staff: $error');
    rethrow;
  }
}

  // Delete Staff
  Future<void> deleteStaff(int staffId) async {
  try {
    debugPrint('DELETE URL: $_hostname/staff/$staffId');

    final response = await http.delete(
      Uri.parse('$_hostname/staff/$staffId'),
      headers: {'Accept': 'application/json'},
    );

    debugPrint('DELETE STATUS: ${response.statusCode}');
    debugPrint('DELETE RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      _staffList.removeWhere((staff) => staff.staffId == staffId);
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