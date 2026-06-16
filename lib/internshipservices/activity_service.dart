import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import '../internshipmodels/activity.dart';

class ActivityService {
  final String baseUrl;
  final String? token;

  ActivityService({String? baseUrl, this.token})
      : baseUrl = (baseUrl ?? AppConfig.hostname).replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // POST /api/internship/activities
  Future<Activity> addActivity(int internId, String activityDescription) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/activities'),
      headers: _headers(),
      body: jsonEncode({
        'intern_id': internId,
        'activity_description': activityDescription,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Supports both:
      // { "activity": {...} } OR direct object {...}
      if (data is Map<String, dynamic> && data.containsKey('activity')) {
        return Activity.fromJson(data['activity']);
      }

      return Activity.fromJson(data as Map<String, dynamic>);
    }

    throw Exception(
      'Failed to add activity: ${response.statusCode} ${response.body}',
    );
  }

  // GET /api/internship/activities/{internId}
  Future<List<Activity>> getActivitiesByIntern(int internId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/activities/$internId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    }

    throw Exception(
      'Failed to fetch activities: ${response.statusCode} ${response.body}',
    );
  }

  // GET /api/internship/activities
  Future<List<Activity>> getAllActivities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/activities'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    }

    throw Exception(
      'Failed to fetch all activities: ${response.statusCode} ${response.body}',
    );
  }

  // DELETE /api/internship/activities/{activityId}
  Future<void> deleteActivity(int activityId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/internship/activities/$activityId'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete activity: ${response.statusCode} ${response.body}',
      );
    }
  }

  // PUT /api/internship/activities/{activityId}
  Future<void> updateActivity(int activityId, String activityDescription) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/internship/activities/$activityId'),
      headers: _headers(),
      body: jsonEncode({
        'activity_description': activityDescription,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update activity: ${response.statusCode} ${response.body}',
      );
    }
  }
}