import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class Attendances with ChangeNotifier {
  // ✅ UPDATED BASE URL matching your "charmsAPI" structure
  final String baseUrl = 'https://devcms.com.my/charmsAPI/api';

  // 1. CREATE ATTENDANCE (Using MultipartRequest as requested)
  // Route: POST /attendance/create
  Future<bool> recordAttendance({
  required int staffId,
  required int scheduleId,
  required String clockInTime,
  Uint8List? image, // Change String? imagePath to Uint8List? image
}) async {
  final uri = Uri.parse('$baseUrl/attendance/create');
  
  try {
    final request = http.MultipartRequest('POST', uri);

    request.fields['staff_id'] = staffId.toString();
    request.fields['schedule_id'] = scheduleId.toString();
    request.fields['clock_in_time'] = clockInTime;
    request.fields['attendance_status'] = '2';

    // 2. Update to handle raw bytes instead of a file path
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'clock_in_image', // Ensure this key matches your Laravel $request->file('clock_in_image')
        image,
        filename: 'attendance_$staffId.jpg',
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return response.statusCode == 201 || response.statusCode == 200;
  } catch (error) {
    print('Error recording attendance: $error');
    return false;
  }
}

  // 2. CHECK ATTENDANCE STATUS
  // Route: GET /attendance/check?staff_id=X&schedule_id=Y
  Future<bool> checkAttendance({
    required int staffId,
    required int scheduleId,
  }) async {
    final uri = Uri.parse('$baseUrl/attendance/check?staff_id=$staffId&schedule_id=$scheduleId');

    try {
      final response = await http.get(uri);
      
      print('Check Attendance Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // PHP Controller returns: { "exists": bool, "attendance_status": int }
        if (data['exists'] == true && data['attendance_status'] == 2) {
          return true;
        }
      }
      return false;
    } catch (error) {
      print('Error checking attendance: $error');
      return false;
    }
  }

  // 3. GET ALL ATTENDANCE
  // Route: GET /attendance
  Future<List<Map<String, dynamic>>> getAllAttendances() async {
    final uri = Uri.parse('$baseUrl/attendance');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to load attendances: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching attendances: $error');
      rethrow;
    }
  }

  // 4. GET ATTENDANCE BY ID
  // Route: GET /attendance/{id}
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
      print('Error fetching attendance by ID: $error');
      rethrow;
    }
  }

  // 5. UPDATE ATTENDANCE
  // Route: PUT /attendance/{id}
  // Note: Using JSON for updates is usually cleaner, but PHP handles PUT best with JSON or x-www-form-urlencoded
  Future<bool> updateAttendance(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/attendance/$id');

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print('Update Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      print('Error updating attendance: $error');
      rethrow;
    }
  }

  // 6. DELETE ATTENDANCE
  // Route: DELETE /attendance/{id}
  Future<bool> deleteAttendance(int id) async {
    final uri = Uri.parse('$baseUrl/attendance/$id');

    try {
      final response = await http.delete(uri);

      print('Delete Response: ${response.statusCode}');

      // Controller returns 204 on success
      if (response.statusCode == 204 || response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      print('Error deleting attendance: $error');
      rethrow;
    }
  }
}