import 'dart:convert';
import 'package:http/http.dart' as http;
import '../internshipmodels/schedule.dart';
import 'package:charms/main.dart';

class ScheduleService {
  final String baseUrl;

ScheduleService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.hostname;

  Future<List<Schedule>> fetchSchedules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/internship/schedules'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((schedule) => Schedule.fromJson(schedule))
            .toList();
      } else {
        throw Exception('Failed to load schedules: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error loading schedules: $e');
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/schedules'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(schedule.toJson()),
      );

      // Debug log to check response
      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to add schedule: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error adding schedule: $e');
    }
  }

  Future<void> updateSchedule(
      int id, String newDescription, int newDuration) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/schedules/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            {'description': newDescription, 'duration': newDuration}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update schedule: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }
}
