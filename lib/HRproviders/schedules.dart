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

  // Add a new schedule. Returns the created Schedule (with its real schedId)
  // when it can be resolved, so callers (e.g. self clock-in) can use it right away.
  Future<Schedule?> addSchedule(Schedule schedule) async {
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
        Schedule? created;
        try {
          final decoded = json.decode(response.body);
          final data = decoded is Map<String, dynamic> && decoded['data'] is Map
              ? decoded['data'] as Map<String, dynamic>
              : decoded as Map<String, dynamic>;
          created = Schedule.fromJson(data);
        } catch (_) {
          created = null;
        }

        await fetchSchedules();
        notifyListeners();

        created ??= await _findCreatedSchedule(schedule.staffId, schedule.workDate);
        return created;
      } else {
        throw Exception('Failed to add schedule: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error adding schedule: $error');
      rethrow;
    }
  }

  // Fallback when the create response doesn't carry a usable schedule payload:
  // re-fetch and match on staffId + calendar day, picking the newest match.
  Future<Schedule?> _findCreatedSchedule(int staffId, DateTime workDate) async {
    try {
      final schedules = await fetchSchedulesByStaffId(staffId);
      final sameDay = schedules.where((s) =>
          s.workDate.year == workDate.year &&
          s.workDate.month == workDate.month &&
          s.workDate.day == workDate.day);
      if (sameDay.isEmpty) return null;
      return sameDay.reduce((a, b) => a.schedId >= b.schedId ? a : b);
    } catch (_) {
      return null;
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

  // Accept a schedule assignment
  Future<bool> acceptSchedule(int schedId) async {
    try {
      final response = await http.put(
        Uri.parse('$_hostname/staff-schedule/$schedId/accept'),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('acceptSchedule: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Update local list
        final idx = _schedules.indexWhere((s) => s.schedId == schedId);
        if (idx != -1) {
          final old = _schedules[idx];
          _schedules[idx] = Schedule(
            schedId:          old.schedId,
            staffId:          old.staffId,
            workDate:         old.workDate,
            workLocation:     old.workLocation,
            staffType:        old.staffType,
            internSlot:       old.internSlot,
            workStartTime:    old.workStartTime,
            workEndTime:      old.workEndTime,
            breakStartTime:   old.breakStartTime,
            breakEndTime:     old.breakEndTime,
            acceptanceStatus: 1,
            staffNote:        old.staffNote,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error accepting schedule: $e');
      return false;
    }
  }

  // Reject a schedule assignment with a reason
  Future<bool> rejectSchedule(int schedId, String reason) async {
    try {
      final response = await http.put(
        Uri.parse('$_hostname/staff-schedule/$schedId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'staff_note': reason}),
      );
      debugPrint('rejectSchedule: ${response.statusCode}');
      if (response.statusCode == 200) {
        final idx = _schedules.indexWhere((s) => s.schedId == schedId);
        if (idx != -1) {
          final old = _schedules[idx];
          _schedules[idx] = Schedule(
            schedId:          old.schedId,
            staffId:          old.staffId,
            workDate:         old.workDate,
            workLocation:     old.workLocation,
            staffType:        old.staffType,
            internSlot:       old.internSlot,
            workStartTime:    old.workStartTime,
            workEndTime:      old.workEndTime,
            breakStartTime:   old.breakStartTime,
            breakEndTime:     old.breakEndTime,
            acceptanceStatus: 2,
            staffNote:        reason,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting schedule: $e');
      return false;
    }
  }

  // Dismiss a rejected schedule (HR side — sets hr_dismissed = true, does NOT delete)
  Future<void> dismissSchedule(int schedId) async {
    try {
      final url = Uri.parse('$_hostname/staff-schedule/$schedId/dismiss');

      debugPrint('DISMISS SCHEDULE URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'hr_dismissed': true}),
      );

      debugPrint('DISMISS SCHEDULE STATUS: ${response.statusCode}');
      debugPrint('DISMISS SCHEDULE RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to dismiss schedule: ${response.body}');
      }

      // Optimistically update local list so UI refreshes immediately
      final index = _schedules.indexWhere((s) => s.schedId == schedId);
      if (index != -1) {
        final old = _schedules[index];
        _schedules[index] = Schedule(
          schedId:          old.schedId,
          staffId:          old.staffId,
          workDate:         old.workDate,
          workLocation:     old.workLocation,
          staffType:        old.staffType,
          internSlot:       old.internSlot,
          workStartTime:    old.workStartTime,
          workEndTime:      old.workEndTime,
          breakStartTime:   old.breakStartTime,
          breakEndTime:     old.breakEndTime,
          acceptanceStatus: old.acceptanceStatus,
          staffNote:        old.staffNote,
          hrDismissed:      true,
        );
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error dismissing schedule: $error');
      rethrow;
    }
  }
}