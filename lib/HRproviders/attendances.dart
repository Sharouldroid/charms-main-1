import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'dart:typed_data';

class Attendances with ChangeNotifier {
  final String baseUrl = 'https://devcms.com.my/charmsAPI/api';

  // ✅ Store last checked image URL & Clock Out Time
  //String? lastCheckedImageUrl;
  String? lastCheckedClockOutTime;
  String? lastCheckedClockInLocation; 

  // 1. CREATE ATTENDANCE — now returns Map with success + imageUrl
  Future<Map<String, dynamic>> recordAttendance({
    required int staffId,
    required int scheduleId,
    required String clockInTime,
    String? clockOutTime, // Made optional for clocking in
    //Uint8List? image,
     String? clockInLocation,
  }) async {
    final uri = Uri.parse('$baseUrl/attendance/create');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields['staff_id'] = staffId.toString();
      request.fields['schedule_id'] = scheduleId.toString();
      request.fields['clock_in_time'] = clockInTime;
      if (clockOutTime != null) {
        request.fields['clock_out_time'] = clockOutTime;
      }

      if (clockInLocation != null) {
      request.fields['clock_in_location'] = clockInLocation; // ← ADD THIS
    }

      request.fields['attendance_status'] = '2';
  
      

      // if (image != null) {
      //   request.files.add(http.MultipartFile.fromBytes(
      //     'clock_in_image',
      //     image,
      //     filename: 'attendance_$staffId.jpg',
      //   ));
      // }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('recordAttendance status: ${response.statusCode}');
      debugPrint('recordAttendance body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'clockInLocation': data['clock_in_location'], 
        };
      }
      return {'success': false, 'clockInLocation': null};
    } catch (error) {
      debugPrint('Error recording attendance: $error');
      return {'success': false, 'clockInLocation': null};
    }
  }

  // 2. CHECK ATTENDANCE — also stores imageUrl and clockOutTime
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

        // ✅ Store clock in location and Clock Out time for use in screen
        //lastCheckedImageUrl = data['clock_in_image_url'];
        lastCheckedClockOutTime = data['clock_out_time'];
        lastCheckedClockInLocation = data['clock_in_location'];

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

  // ✅ 2.5 CLOCK OUT ATTENDANCE
  Future<Map<String, dynamic>> clockOutAttendance({
    required int staffId,
    required int scheduleId,
    required String clockOutTime,
  }) async {
    // Depending on your Laravel API, this might be a PUT or POST. 
    // Usually, it's a POST to a specific endpoint, or a PUT to update the existing record.
    final uri = Uri.parse('$baseUrl/attendance/clock-out'); // Adjust this URL to match your backend!

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'staff_id': staffId,
          'schedule_id': scheduleId,
          'clock_out_time': clockOutTime,
        }),
      );

      debugPrint('clockOutAttendance status: ${response.statusCode}');
      debugPrint('clockOutAttendance body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return {'success': true};
      }
      return {'success': false};
    } catch (error) {
      debugPrint('Error clocking out: $error');
      return {'success': false};
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