import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/InternAttendanceRecord.dart';
import 'package:charms/internshipservices/InternAttendanceService.dart';

class InternAttendanceProvider with ChangeNotifier {
  final InternAttendanceService _service = InternAttendanceService();

  List<InternAttendanceRecord> _history = [];
  bool _isLoadingHistory = false;

  // Per-schedule cached check result (keyed by scheduleId)
  final Map<int, Map<String, dynamic>> _checkCache = {};

  List<InternAttendanceRecord> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;

  // ── Clock In ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> clockIn({
    required int userId,
    required int scheduleId,
    required String clockInTime,
    String? clockInLocation,
  }) async {
    final result = await _service.clockIn(
      userId: userId,
      scheduleId: scheduleId,
      clockInTime: clockInTime,
      clockInLocation: clockInLocation,
    );
    // Invalidate cache for this schedule so next check re-fetches
    _checkCache.remove(scheduleId);
    return result;
  }

  // ── Clock Out ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> clockOut({
    required int userId,
    required int scheduleId,
    required String clockOutTime,
  }) async {
    final result = await _service.clockOut(
      userId: userId,
      scheduleId: scheduleId,
      clockOutTime: clockOutTime,
    );
    _checkCache.remove(scheduleId);
    // Update history list locally if we already have it loaded
    if (_history.isNotEmpty) {
      final idx = _history.indexWhere((r) => r.scheduleId == scheduleId);
      if (idx != -1) {
        await fetchHistory(userId); // reload for accuracy
      }
    }
    return result;
  }

  // ── Check attendance ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkAttendance({
    required int userId,
    required int scheduleId,
  }) async {
    if (_checkCache.containsKey(scheduleId)) {
      return _checkCache[scheduleId]!;
    }
    final result = await _service.checkAttendance(
      userId: userId,
      scheduleId: scheduleId,
    );
    _checkCache[scheduleId] = result;
    return result;
  }

  // ── Load History ───────────────────────────────────────────────────────
  Future<void> fetchHistory(int userId) async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _history = await _service.fetchHistory(userId);
    } catch (e) {
      debugPrint('InternAttendanceProvider.fetchHistory error: $e');
      _history = [];
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _checkCache.clear();
    _history = [];
  }
}