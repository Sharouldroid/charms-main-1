import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/HRmodels/staff.dart';

class Staffs with ChangeNotifier {
  // Updated hostname to match your CHARMS API production URL
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';
  
  List<Staff> _staffList = [];

  // Getter for staff
  List<Staff> get staffList => [..._staffList];

  List<Staff> getStaffByCategory(int category) {
    return _staffList.where((staff) => staff.category == category).toList();
  }

  // Fetch Staff Data
  Future<void> fetchStaff() async {
  try {
    // no trailing slash
    final response = await http
        .get(Uri.parse('$_hostname/staff'), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch staff: ${response.statusCode} ${response.body}');
    }

    final decoded = json.decode(response.body);

    // supports: {success:true,data:[...]} OR {staff:[...]} OR [...]
    List<dynamic> staffData;
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) {
        staffData = decoded['data'] as List<dynamic>;
      } else if (decoded['staff'] is List) {
        staffData = decoded['staff'] as List<dynamic>;
      } else {
        staffData = [];
      }
    } else if (decoded is List) {
      staffData = decoded;
    } else {
      staffData = [];
    }

    _staffList = staffData
        .map((data) => Staff(
              staffId: data['id'] ?? 0,
              userId: data['userid'] ?? 0,
              username: data['username'] ?? '',
              email: data['email'] ?? '',
              usertype: data['usertype'] ?? 0,
              firstname: data['firstname'] ?? '',
              lastname: data['lastname'] ?? '',
              occupation: data['occupation'] ?? '',
              phone: data['phone'] ?? '',
              category: data['category'] ?? 0,
              nationality: data['nationality'] ?? '',
              religion: data['religion'] ?? '',
              maritalStatus: data['marital_status'] ?? 0,
              officePhone: data['office_phone'],
              emergencyName: data['emergency_name'] ?? '',
              emergencyIc: data['emergency_ic'] ?? '',
              emergencyRelation: data['emergency_relation'] ?? '',
              emergencyGender: data['emergency_gender'] ?? 0,
              emergencyPhone: data['emergency_phone'] ?? '',
              idNum: data['id_num'] ?? '',
              dob: data['dob'] ?? '',
              address1: data['address1'] ?? '',
              address2: data['address2'] ?? '',
              city: data['city'] ?? '',
              postcode: data['postcode'] ?? 0,
              state: data['state'] ?? '',
              country: data['country'] ?? '',
            ))
        .toList();

    notifyListeners();
  } catch (error) {
    debugPrint('Error fetching staff: $error');
    rethrow;
  }
}

  // Update Staff Details
  Future<void> updateStaffDetails(int staffId, Staff updatedStaff) async {
    try {
      // Aligned with Route::put('/{id}', [HRStaffController::class, 'updateStaff'])
      // Controller expects 'staff_data' and 'user_data'
      final payload = {
        'staff_data': {
          'firstname': updatedStaff.firstname,
          'lastname': updatedStaff.lastname,
          'occupation': updatedStaff.occupation,
          'category': updatedStaff.category,
          'nationality': updatedStaff.nationality,
          'religion': updatedStaff.religion,
          'marital_status': updatedStaff.maritalStatus,
          'office_phone': updatedStaff.officePhone,
          'id_num': updatedStaff.idNum,
          'dob': updatedStaff.dob,
          'emergency_name': updatedStaff.emergencyName,
          'emergency_ic': updatedStaff.emergencyIc,
          'emergency_relation': updatedStaff.emergencyRelation,
          'emergency_gender': updatedStaff.emergencyGender,
          'emergency_phone': updatedStaff.emergencyPhone
        },
        'user_data': {
          'email': updatedStaff.email, // Combined email into user_data as per typical User model
          'phone': updatedStaff.phone,
          'address1': updatedStaff.address1,
          'address2': updatedStaff.address2,
          'city': updatedStaff.city,
          'postcode': updatedStaff.postcode,
          'state': updatedStaff.state,
          'country': updatedStaff.country
        },
      };

      final response = await http.put(
        Uri.parse('$_hostname/staff/$staffId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final index = _staffList.indexWhere((staff) => staff.staffId == staffId);
        if (index != -1) {
          _staffList[index] = updatedStaff;
        }
        notifyListeners();
      } else {
        throw Exception('Failed to update staff details: ${response.body}');
      }
    } catch (error) {
      print('Error updating staff: $error');
      rethrow;
    }
  }

  // Delete Staff
  Future<void> deleteStaff(int staffId) async {
    try {
      // Aligned with Route::delete('/{id}', [HRStaffController::class, 'deleteStaff'])
      final response = await http.delete(Uri.parse('$_hostname/staff/$staffId'));
      
      if (response.statusCode == 200) {
        _staffList.removeWhere((staff) => staff.staffId == staffId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete staff: ${response.body}');
      }
    } catch (error) {
      print('Error deleting staff: $error');
      rethrow;
    }
  }
}