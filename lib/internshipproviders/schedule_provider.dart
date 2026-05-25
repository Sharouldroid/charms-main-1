import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'package:charms/internshipservices/schedule_service.dart';
import 'package:charms/main.dart';

class ScheduleProvider with ChangeNotifier {
  List<Schedule> _schedules = [];
  final ScheduleService _scheduleService =
      ScheduleService(baseUrl: AppConfig.hostname);

  List<Schedule> get schedules => _schedules;

  Future<void> loadSchedules() async {
    _schedules = await _scheduleService.fetchSchedules();
    notifyListeners();
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _scheduleService.addSchedule(schedule);
    await loadSchedules(); // reload from backend for consistency
  }

  Future<void> updateSchedule(Schedule updatedSchedule) async {
    await _scheduleService.updateSchedule(
      updatedSchedule.id,
      updatedSchedule.description,
      updatedSchedule.duration, // keep duration as String to match backend
    );

    final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
    if (index != -1) {
      _schedules[index] = updatedSchedule;
      notifyListeners();
    }
  }

  // ✅ ADDED: Method to handle deletion
  Future<void> deleteSchedule(int id) async {
    // 1. Tell the backend to delete it
    await _scheduleService.deleteSchedule(id);
    
    // 2. Remove it from the local list so the UI updates instantly
    _schedules.removeWhere((schedule) => schedule.id == id);
    
    // 3. Notify listeners to rebuild the UI
    notifyListeners();
  }
}