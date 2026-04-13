import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/HRmodels/schedule.dart';

class Schedules with ChangeNotifier {
  // Updated hostname to match your CHARMS API production URL
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';
  
  List<Schedule> _schedules = [];

  List<Schedule> get schedules => [..._schedules];

  Future<void> fetchSchedules() async {
  try {
    final response = await http
        .get(Uri.parse('$_hostname/staff-schedule'), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch schedules: ${response.statusCode} ${response.body}');
    }

    final decoded = json.decode(response.body);

    // supports: {data:[...]} OR {schedules:[...]} OR [...]
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

    _schedules = scheduleData.map((data) => Schedule.fromJson(data)).toList();
    notifyListeners();
  } catch (error) {
    debugPrint('Error fetching schedules: $error');
    rethrow;
  }
}

  Future<List<Schedule>> fetchSchedulesByStaffId(int staffId) async {
    try {
      // Aligned with Route::get('/{staff_id}', [HRScheduleController::class, 'getScheduleByStaff'])
      final response =
          await http.get(Uri.parse('$_hostname/staff-schedule/$staffId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> scheduleData = json.decode(response.body);
        return scheduleData.map((data) => Schedule.fromJson(data)).toList();
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching staff schedules: $error');
      rethrow;
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    // Aligned with Route::post('/create', [HRScheduleController::class, 'addSchedule'])
    // Using MultipartRequest as per your CHARMS API example
    final url = Uri.parse('$_hostname/staff-schedule/create');
    var request = http.MultipartRequest('POST', url);

    request.fields['staff_id'] = schedule.staffId.toString();
    request.fields['work_date'] = schedule.workDate.toIso8601String().split('T')[0];
    request.fields['work_location'] = schedule.workLocation.toString();
    request.fields['staff_type'] = schedule.staffType.toString();
    
    if (schedule.internSlot != null) {
      request.fields['intern_slot'] = schedule.internSlot.toString();
    }
    if (schedule.workStartTime != null) {
      request.fields['work_start_time'] = schedule.workStartTime!;
    }
    if (schedule.workEndTime != null) {
      request.fields['work_end_time'] = schedule.workEndTime!;
    }
    if (schedule.breakStartTime != null) {
      request.fields['break_start_time'] = schedule.breakStartTime!;
    }
    if (schedule.breakEndTime != null) {
      request.fields['break_end_time'] = schedule.breakEndTime!;
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        await fetchSchedules();
        notifyListeners();
      } else {
        throw Exception('Failed to add schedule: ${response.body}');
      }
    } catch (error) {
      print('Error adding schedule: $error');
      rethrow;
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      // Aligned with Route::put('/{id}', [HRScheduleController::class, 'updateSchedule'])
      final updateData = {
        'staff_id': schedule.staffId,
        'work_date': schedule.workDate.toIso8601String().split('T')[0],
        'work_location': schedule.workLocation,
        'staff_type': schedule.staffType,
        'intern_slot': schedule.internSlot,
        'work_start_time': schedule.workStartTime,
        'work_end_time': schedule.workEndTime,
        'break_start_time': schedule.breakStartTime,
        'break_end_time': schedule.breakEndTime,
      };

      final response = await http.put(
        Uri.parse('$_hostname/staff-schedule/${schedule.schedId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        await fetchSchedules();
        notifyListeners();
      } else {
        throw Exception('Failed to update schedule: ${response.body}');
      }
    } catch (error) {
      print('Error updating schedule: $error');
      rethrow;
    }
  }

  Future<void> deleteSchedule(int schedId) async {
    try {
      // Aligned with Route::delete('/{id}', [HRScheduleController::class, 'deleteSchedule'])
      final response = await http.delete(
        Uri.parse('$_hostname/staff-schedule/$schedId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _schedules.removeWhere((schedule) => schedule.schedId == schedId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete schedule');
      }
    } catch (error) {
      print('Error deleting schedule: $error');
      rethrow;
    }
  }
}