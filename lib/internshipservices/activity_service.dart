import 'dart:convert';
import 'package:http/http.dart' as http;
import '../internshipmodels/activity.dart';
import 'package:charms/services/app_config.dart';
class ActivityService {
  final String baseUrl;

 ActivityService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.hostname;

  // Create a new activity log
  Future<Activity> addActivity(int internId, String activityDescription) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}activities'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'intern_id': internId,
          'activity_description': activityDescription,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Activity.fromJson(data['activity']);
      } else {
        throw Exception('Failed to add activity: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error adding activity: $e');
    }
  }

  // Get activities for a specific intern
  Future<List<Activity>> getActivitiesByIntern(int internId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}activities/$internId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch activities: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  // Get all activities (admin view)
  Future<List<Activity>> getAllActivities() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}activities'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch all activities: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching all activities: $e');
    }
  }

  // Delete an activity (optional)
  Future<void> deleteActivity(int activityId) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}activities/$activityId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete activity: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }
}
