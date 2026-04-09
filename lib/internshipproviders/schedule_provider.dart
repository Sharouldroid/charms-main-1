import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'package:charms/internshipservices/schedule_service.dart';
import 'package:charms/services/app_config.dart';

class ScheduleProvider with ChangeNotifier {
  List<Schedule> _schedules = [];
  final ScheduleService _scheduleService =
      ScheduleService(baseUrl: AppConfig.hostname);

  List<Schedule> get schedules => _schedules;

  Future<void> loadSchedules() async {
    try {
      _schedules = await _scheduleService.fetchSchedules();
      notifyListeners();
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      // Debug log to verify schedule data
      print('Adding schedule: ${schedule.toJson()}');

      await _scheduleService.addSchedule(schedule);
      _schedules.add(schedule);
      notifyListeners();
    } catch (e) {
      print('Error adding schedule: $e');
    }
  }

  Future<void> updateSchedule(Schedule updatedSchedule) async {
    try {
      await _scheduleService.updateSchedule(
        updatedSchedule.id,
        updatedSchedule.description,
        updatedSchedule.duration ?? 0, // Add duration
      );
      final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
      if (index != -1) {
        _schedules[index] = updatedSchedule;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating schedule: $e');
    }
  }
}
