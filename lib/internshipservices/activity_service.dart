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

  // ── Activities ────────────────────────────────────────────────────────────

  // POST /api/internship/activities
  Future<Activity> addActivity(int internId, String activityDescription, {String? title}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/activities'),
      headers: _headers(),
      body: jsonEncode({
        'intern_id': internId,
        'activity_description': activityDescription,
        if (title != null && title.isNotEmpty) 'title': title,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
  Future<void> updateActivity(int activityId, String activityDescription, {String? title}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/internship/activities/$activityId'),
      headers: _headers(),
      body: jsonEncode({
        'activity_description': activityDescription,
        if (title != null && title.isNotEmpty) 'title': title,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update activity: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ── Milestones ────────────────────────────────────────────────────────────

  // GET /api/internship/milestones/{userId}
  Future<List<dynamic>> getMilestones(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/milestones/$userId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Supports: [...] OR { "milestones": [...] }
      if (data is List) return data;
      if (data is Map<String, dynamic> && data.containsKey('milestones')) {
        return data['milestones'] as List<dynamic>;
      }
      return [];
    }

    if (response.statusCode == 404) return []; // no milestones yet

    throw Exception(
      'Failed to fetch milestones: ${response.statusCode} ${response.body}',
    );
  }

  // POST /api/internship/milestones
  Future<void> addMilestone(int userId, String title, String? notes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/milestones'),
      headers: _headers(),
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to add milestone: ${response.statusCode} ${response.body}',
      );
    }
  }

  // PUT /api/internship/milestones/{milestoneId}
  Future<void> updateMilestone(int milestoneId, String title, String? notes) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/internship/milestones/$milestoneId'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'notes': notes ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update milestone: ${response.statusCode} ${response.body}',
      );
    }
  }
}