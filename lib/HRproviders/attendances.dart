import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class Attendances with ChangeNotifier {
  final String baseUrl = 'https://devcms.com.my/charmsAPI/api';

  // ✅ Store last checked image URL for use after checkAttendance
  String? lastCheckedImageUrl;

  // 1. CREATE ATTENDANCE — now returns Map with success + imageUrl
  Future<Map<String, dynamic>> recordAttendance({
    required int staffId,
    required int scheduleId,
    required String clockInTime,
    Uint8List? image,
  }) async {
    final uri = Uri.parse('$baseUrl/attendance/create');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields['staff_id'] = staffId.toString();
      request.fields['schedule_id'] = scheduleId.toString();
      request.fields['clock_in_time'] = clockInTime;
      request.fields['attendance_status'] = '2';

      if (image != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'clock_in_image',
          image,
          filename: 'attendance_$staffId.jpg',
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('recordAttendance status: ${response.statusCode}');
      debugPrint('recordAttendance body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'imageUrl': data['clock_in_image_url'], // ✅ return URL
        };
      }
      return {'success': false, 'imageUrl': null};
    } catch (error) {
      debugPrint('Error recording attendance: $error');
      return {'success': false, 'imageUrl': null};
    }
  }

  // 2. CHECK ATTENDANCE — also stores imageUrl
  Future<bool> checkAttendance({
    required int staffId,
    required int scheduleId,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/attendance/check?staff_id=$staffId&schedule_id=$scheduleId');

    try {
      final response = await http.get(uri);
      debugPrint('checkAttendance: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ Store image URL for use in screen
        lastCheckedImageUrl = data['clock_in_image_url'];

        if (data['exists'] == true && data['attendance_status'] == 2) {
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('Error checking attendance: $error');
      return false;
    }
  }

  // 3. GET ALL ATTENDANCE
  Future<List<Map<String, dynamic>>> getAllAttendances() async {
    final uri = Uri.parse('$baseUrl/attendance');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        throw Exception(
            'Failed to load attendances: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching attendances: $error');
      rethrow;
    }
  }

  // 4. GET ATTENDANCE BY ID
  Future<Map<String, dynamic>> getAttendanceById(int id) async {
    final uri = Uri.parse('$baseUrl/attendance/$id');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Attendance not found');
      }
    } catch (error) {
      debugPrint('Error fetching attendance by ID: $error');
      rethrow;
    }
  }

  // 5. UPDATE ATTENDANCE
  Future<bool> updateAttendance(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/attendance/$id');

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      debugPrint('updateAttendance: ${response.statusCode}');

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      debugPrint('Error updating attendance: $error');
      rethrow;
    }
  }

  // 6. DELETE ATTENDANCE
  Future<bool> deleteAttendance(int id) async {
    final uri = Uri.parse('$baseUrl/attendance/$id');

    try {
      final response = await http.delete(uri);
      debugPrint('deleteAttendance: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      debugPrint('Error deleting attendance: $error');
      rethrow;
    }
  }
}