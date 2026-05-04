import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';

class SubmissionService {
  final String baseUrl = '${AppConfig.hostname}/api/internship/submissions';

  // Add new submission
  Future<void> addSubmission(int internId, String details) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'intern_id': internId,
          'details': details,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add submission: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding submission: $e');
    }
  }

  // Get submissions for a specific intern
  Future<List<Map<String, dynamic>>> getSubmissionsByIntern(int internId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/intern/$internId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      throw Exception('Error fetching submissions: $e');
    }
  }

  // Get all submissions (admin view)
  Future<List<Map<String, dynamic>>> getAllSubmissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['data'];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load all submissions');
      }
    } catch (e) {
      throw Exception('Error fetching all submissions: $e');
    }
  }

  // Update submission status
  Future<void> updateSubmissionStatus(int submissionId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$submissionId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
}