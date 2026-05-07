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

      final List<dynamic> staffData =
          (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List<dynamic>
              : (decoded is List ? decoded : <dynamic>[]);

      _staffList = staffData.map((data) {
        return Staff(
          staffId: _toInt(data['staff_id'] ?? data['id']),
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
          gender: _toInt(data['gender']),   
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
          filepath: data['filepath'],   // ✅ nullable
          filename: data['filename'],   // ✅ nullable
        );
      }).toList();

      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching staff: $error');
      rethrow;
    }
  }

  // Upload Staff Photo
  Future<void> uploadStaffPhoto(int staffId, XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_hostname/staff/$staffId/photo'),
      );

      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        // ✅ Web — read as bytes and use XFile.name
        final bytes = await imageFile.readAsBytes();
        final filename = imageFile.name; // Fixed: Use .name instead of parsing .path on web
        final ext = filename.split('.').last.toLowerCase();
        final contentType =
            ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      } else {
        // ✅ Mobile — use fromPath (dart:io available)
        final filename = imageFile.name;
        final ext = filename.split('.').last.toLowerCase();
        final contentType =
            ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imageFile.path,
            contentType: contentType,
          ),
        );
      }

      debugPrint('UPLOAD PHOTO URL: $_hostname/staff/$staffId/photo');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('UPLOAD PHOTO STATUS: ${response.statusCode}');
      debugPrint('UPLOAD PHOTO RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to upload photo: ${response.body}');
      }

      final responseData = json.decode(response.body);
      final newFilepath = responseData['data']?['filepath'];
      final newFilename = responseData['data']?['filename'];

      final index = _staffList.indexWhere((s) => s.staffId == staffId);
      if (index != -1 && newFilepath != null) {
        final existing = _staffList[index];
        _staffList[index] = Staff(
          staffId: existing.staffId,
          userId: existing.userId,
          username: existing.username,
          email: existing.email,
          usertype: existing.usertype,
          firstname: existing.firstname,
          lastname: existing.lastname,
          occupation: existing.occupation,
          phone: existing.phone,
          category: existing.category,
          nationality: existing.nationality,
          religion: existing.religion,
          maritalStatus: existing.maritalStatus,
          gender: existing.gender,   
          officePhone: existing.officePhone,
          emergencyName: existing.emergencyName,
          emergencyIc: existing.emergencyIc,
          emergencyRelation: existing.emergencyRelation,
          emergencyGender: existing.emergencyGender,
          emergencyPhone: existing.emergencyPhone,
          idNum: existing.idNum,
          dob: existing.dob,
          address1: existing.address1,
          address2: existing.address2,
          city: existing.city,
          postcode: existing.postcode,
          state: existing.state,
          country: existing.country,
          filepath: newFilepath,
          filename: newFilename,
        );
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error uploading photo: $error');
      rethrow;
    }
  }

  // Update Staff Details
  Future<void> updateStaffDetails(int staffId, Staff updatedStaff) async {
    try {
      final payload = {
    'staff_data': {
      'category':           updatedStaff.category.toString(),
      'nationality':        updatedStaff.nationality,        // String ✅
      'religion':           updatedStaff.religion,           // String ✅
      'marital_status':     updatedStaff.maritalStatus.toString(),
      'office_phone':       updatedStaff.officePhone ?? '',  // String? ✅ keep
      'emergency_name':     updatedStaff.emergencyName,      // String ✅
      'emergency_ic':       updatedStaff.emergencyIc,        // String ✅
      'emergency_relation': updatedStaff.emergencyRelation,  // String ✅
      'emergency_gender':   updatedStaff.emergencyGender.toString(),
      'emergency_phone':    updatedStaff.emergencyPhone,     // String ✅
    },
    'user_data': {
      'username': updatedStaff.username,  // String ✅
      'email':    updatedStaff.email,     // String ✅
    },
    'userdata_data': {
      'firstname':  updatedStaff.firstname,   // String ✅
      'lastname':   updatedStaff.lastname,    // String ✅
      'idnum':      updatedStaff.idNum,       // String ✅
      'dob':        updatedStaff.dob,         // String ✅
      'phone':      updatedStaff.phone,       // String ✅
      'address1':   updatedStaff.address1,    // String ✅
      'address2':   updatedStaff.address2,    // String ✅
      'city':       updatedStaff.city,        // String ✅
      'postcode':   updatedStaff.postcode.toString(),
      'state':      updatedStaff.state,       // String ✅
      'country':    updatedStaff.country,     // String ✅
      'occupation': updatedStaff.occupation,  // String ✅
      'gender': updatedStaff.gender.toString(), // int ✅
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
        final index =
            _staffList.indexWhere((staff) => staff.staffId == staffId);
        if (index != -1) {
          // Preserve existing filepath/filename since update doesn't change photo
          _staffList[index] = Staff(
            staffId: updatedStaff.staffId,
            userId: updatedStaff.userId,
            username: updatedStaff.username,
            email: updatedStaff.email,
            usertype: updatedStaff.usertype,
            firstname: updatedStaff.firstname,
            lastname: updatedStaff.lastname,
            occupation: updatedStaff.occupation,
            phone: updatedStaff.phone,
            category: updatedStaff.category,
            nationality: updatedStaff.nationality,
            religion: updatedStaff.religion,
            maritalStatus: updatedStaff.maritalStatus,
            gender: updatedStaff.gender,     
            officePhone: updatedStaff.officePhone,
            emergencyName: updatedStaff.emergencyName,
            emergencyIc: updatedStaff.emergencyIc,
            emergencyRelation: updatedStaff.emergencyRelation,
            emergencyGender: updatedStaff.emergencyGender,
            emergencyPhone: updatedStaff.emergencyPhone,
            idNum: updatedStaff.idNum,
            dob: updatedStaff.dob,
            address1: updatedStaff.address1,
            address2: updatedStaff.address2,
            city: updatedStaff.city,
            postcode: updatedStaff.postcode,
            state: updatedStaff.state,
            country: updatedStaff.country,
            filepath: _staffList[index].filepath, // ✅ preserve photo
            filename: _staffList[index].filename, // ✅ preserve photo
          );
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