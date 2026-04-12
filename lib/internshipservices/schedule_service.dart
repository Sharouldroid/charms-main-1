import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import '../internshipmodels/schedule.dart';

class ScheduleService {
  final String baseUrl;
  final String? token;

  ScheduleService({String? baseUrl, this.token})
      : baseUrl =
            (baseUrl ?? AppConfig.hostname).replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // GET /api/internship/schedules
  Future<List<Schedule>> fetchSchedules() async {
    final url = '$baseUrl/api/internship/schedules';
    print('REQUEST URL (fetchSchedules): $url');

    try {
      final response = await http.get(Uri.parse(url), headers: _headers());

      print('STATUS (fetchSchedules): ${response.statusCode}');
      print('BODY (fetchSchedules): ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded.map((e) => Schedule.fromJson(e)).toList();
        } else {
          throw Exception(
            'Unexpected response format: expected List, got ${decoded.runtimeType}',
          );
        }
      }

      throw Exception(
        'Failed to load schedules: ${response.statusCode} ${response.body}',
      );
    } catch (e, st) {
      print('ERROR (fetchSchedules): $e');
      print('STACK (fetchSchedules): $st');
      rethrow;
    }
  }

  // GET /api/internship/schedules/date/{date}
  Future<List<Schedule>> fetchSchedulesByDate(String date) async {
    final url = '$baseUrl/api/internship/schedules/date/$date';
    print('REQUEST URL (fetchSchedulesByDate): $url');

    try {
      final response = await http.get(Uri.parse(url), headers: _headers());

      print('STATUS (fetchSchedulesByDate): ${response.statusCode}');
      print('BODY (fetchSchedulesByDate): ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded.map((e) => Schedule.fromJson(e)).toList();
        } else {
          throw Exception(
            'Unexpected response format: expected List, got ${decoded.runtimeType}',
          );
        }
      }

      throw Exception(
        'Failed to load schedules by date: ${response.statusCode} ${response.body}',
      );
    } catch (e, st) {
      print('ERROR (fetchSchedulesByDate): $e');
      print('STACK (fetchSchedulesByDate): $st');
      rethrow;
    }
  }

  // POST /api/internship/schedules
  Future<void> addSchedule(Schedule schedule) async {
    final url = '$baseUrl/api/internship/schedules';
    print('REQUEST URL (addSchedule): $url');
    print('REQUEST BODY (addSchedule): ${jsonEncode(schedule.toJson())}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode(schedule.toJson()),
      );

      print('STATUS (addSchedule): ${response.statusCode}');
      print('BODY (addSchedule): ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Failed to add schedule: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, st) {
      print('ERROR (addSchedule): $e');
      print('STACK (addSchedule): $st');
      rethrow;
    }
  }

  // PUT /api/internship/schedules/{id}
  Future<void> updateSchedule(
      int id, String newDescription, String newDuration) async {
    final url = '$baseUrl/api/internship/schedules/$id';
    final payload = {
      'description': newDescription,
      'duration': newDuration,
    };

    print('REQUEST URL (updateSchedule): $url');
    print('REQUEST BODY (updateSchedule): ${jsonEncode(payload)}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode(payload),
      );

      print('STATUS (updateSchedule): ${response.statusCode}');
      print('BODY (updateSchedule): ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update schedule: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, st) {
      print('ERROR (updateSchedule): $e');
      print('STACK (updateSchedule): $st');
      rethrow;
    }
  }

  // GET /api/internship/schedules/{scheduleId}/check-limit
  Future<Map<String, dynamic>> checkRegistrationLimit(int scheduleId) async {
    final url = '$baseUrl/api/internship/schedules/$scheduleId/check-limit';
    print('REQUEST URL (checkRegistrationLimit): $url');

    try {
      final response = await http.get(Uri.parse(url), headers: _headers());

      print('STATUS (checkRegistrationLimit): ${response.statusCode}');
      print('BODY (checkRegistrationLimit): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 400) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw Exception(
          'Unexpected response format: expected Map, got ${decoded.runtimeType}',
        );
      }

      throw Exception(
        'Failed to check registration limit: ${response.statusCode} ${response.body}',
      );
    } catch (e, st) {
      print('ERROR (checkRegistrationLimit): $e');
      print('STACK (checkRegistrationLimit): $st');
      rethrow;
    }
  }
}