import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import 'package:charms/internshipmodels/InternAttendanceRecord.dart';

class InternAttendanceService {
  final String baseUrl;

  InternAttendanceService({String? baseUrl})
      : baseUrl = (baseUrl ?? AppConfig.hostname).replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  // ── Clock In ───────────────────────────────────────────────────────────
  // POST /api/internship/attendance/clock-in
  Future<Map<String, dynamic>> clockIn({
    required int userId,
    required int scheduleId,
    required String clockInTime,
    String? clockInLocation,
  }) async {
    final url = '$baseUrl/api/internship/attendance/clock-in';
    final body = jsonEncode({
      'user_id': userId,
      'schedule_id': scheduleId,
      'clock_in_time': clockInTime,
      'clock_in_location': clockInLocation,
    });

    print('REQUEST (clockIn): $url');
    print('BODY (clockIn): $body');

    final response = await http.post(Uri.parse(url), headers: _headers(), body: body);

    print('STATUS (clockIn): ${response.statusCode}');
    print('BODY (clockIn): ${response.body}');

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'success': false};
  }

  // ── Clock Out ──────────────────────────────────────────────────────────
  // PUT /api/internship/attendance/clock-out
  Future<Map<String, dynamic>> clockOut({
    required int userId,
    required int scheduleId,
    required String clockOutTime,
  }) async {
    final url = '$baseUrl/api/internship/attendance/clock-out';
    final body = jsonEncode({
      'user_id': userId,
      'schedule_id': scheduleId,
      'clock_out_time': clockOutTime,
    });

    print('REQUEST (clockOut): $url');

    final response = await http.put(Uri.parse(url), headers: _headers(), body: body);

    print('STATUS (clockOut): ${response.statusCode}');
    print('BODY (clockOut): ${response.body}');

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'success': false};
  }

  // ── Check attendance for a specific schedule ───────────────────────────
  // GET /api/internship/attendance/check?user_id=X&schedule_id=Y
  Future<Map<String, dynamic>> checkAttendance({
    required int userId,
    required int scheduleId,
  }) async {
    final url = '$baseUrl/api/internship/attendance/check?user_id=$userId&schedule_id=$scheduleId';
    print('REQUEST (checkAttendance): $url');

    final response = await http.get(Uri.parse(url), headers: _headers());

    print('STATUS (checkAttendance): ${response.statusCode}');
    print('BODY (checkAttendance): ${response.body}');

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  // ── Attendance History ─────────────────────────────────────────────────
  // GET /api/internship/attendance/history?user_id=X
  Future<List<InternAttendanceRecord>> fetchHistory(int userId) async {
    final url = '$baseUrl/api/internship/attendance/history?user_id=$userId';
    print('REQUEST (fetchHistory): $url');

    final response = await http.get(Uri.parse(url), headers: _headers());

    print('STATUS (fetchHistory): ${response.statusCode}');
    print('BODY (fetchHistory): ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((e) => InternAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}