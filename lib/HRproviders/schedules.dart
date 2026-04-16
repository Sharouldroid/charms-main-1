import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/HRmodels/schedule.dart';

class Schedules with ChangeNotifier {
  // Base URL for the CHARMS API
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  List<Schedule> _schedules = [];

  List<Schedule> get schedules => [..._schedules];

  // Fetch all schedules
  Future<void> fetchSchedules() async {
    try {
      final response = await http.get(
        Uri.parse('$_hostname/staff-schedule'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20)); // Timeout after 20 seconds

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch schedules: ${response.statusCode} ${response.body}');
      }

      final decoded = json.decode(response.body);

      // Check for different response structures
      List<dynamic> scheduleData;
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          scheduleData = decoded['data'] as List<dynamic>;
        } else if (decoded['schedules'] is List) {
          scheduleData = decoded['schedules'] as List<dynamic>;
        } else {
          scheduleData = [];
        }
      } else if (decoded is List) {
        scheduleData = decoded;
      } else {
        scheduleData = [];
      }

      // Map data to Schedule model
      _schedules = scheduleData.map((data) => Schedule.fromJson(data)).toList();
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching schedules: $error');
      rethrow;
    }
  }

  // Fetch schedules by staff ID
  Future<List<Schedule>> fetchSchedulesByStaffId(int staffId) async {
    try {
      final response = await http.get(
        Uri.parse('$_hostname/staff-schedule/$staffId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> scheduleData = json.decode(response.body);
        return scheduleData.map((data) => Schedule.fromJson(data)).toList();
      } else if (response.statusCode == 404) {
        debugPrint('No schedule found for staff ID: $staffId');
        return [];
      } else {
        throw Exception('Failed to fetch schedules for staff ID: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching schedules by staff ID: $error');
      rethrow;
    }
  }

  // Add a new schedule
  Future<void> addSchedule(Schedule schedule) async {
    final url = Uri.parse('$_hostname/staff-schedule/create');
    final body = schedule.toJson();
    body['work_date'] = schedule.workDate.toIso8601String().split('T')[0]; // Format date to YYYY-MM-DD

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        await fetchSchedules();
        notifyListeners();
      } else {
        throw Exception('Failed to add schedule: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error adding schedule: $error');
      rethrow;
    }
  }

  // Update an existing schedule
  Future<void> updateSchedule(Schedule schedule) async {
    final url = Uri.parse('$_hostname/staff-schedule/${schedule.schedId}');
    final updateData = {
      'staff_id': schedule.staffId,
      'work_date': schedule.workDate.toIso8601String().split('T')[0], // Ensure date format
      'work_location': schedule.workLocation,
      'staff_type': schedule.staffType,
      'intern_slot': schedule.internSlot,
      'work_start_time': schedule.workStartTime,
      'work_end_time': schedule.workEndTime,
      'break_start_time': schedule.breakStartTime,
      'break_end_time': schedule.breakEndTime,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        await fetchSchedules();
        notifyListeners();
      } else if (response.statusCode == 404) {
        debugPrint('Schedule not found for ID: ${schedule.schedId}');
      } else {
        throw Exception('Failed to update schedule: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error updating schedule: $error');
      rethrow;
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(int schedId) async {
    final url = Uri.parse('$_hostname/staff-schedule/$schedId');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _schedules.removeWhere((schedule) => schedule.schedId == schedId);
        notifyListeners();
      } else if (response.statusCode == 404) {
        debugPrint('Schedule not found to delete with ID: $schedId');
      } else {
        throw Exception('Failed to delete schedule');
      }
    } catch (error) {
      debugPrint('Error deleting schedule: $error');
      rethrow;
    }
  }
}