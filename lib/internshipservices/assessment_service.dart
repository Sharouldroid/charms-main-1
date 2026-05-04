import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';

class AssessmentService {
  final String baseUrl = '${AppConfig.hostname}/api/internship/assessments';

  // Submit assessment (Admin use)
  Future<void> submitAssessment(int internId, Map<String, int> ratings) async {
    try {
      print('');
      print('========================================');
      print('📤 SUBMITTING ASSESSMENT');
      print('========================================');
      print('Intern ID: $internId');
      print('Ratings: $ratings');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'intern_id': internId,
          'criterion_1': ratings['criterion_1'],
          'criterion_2': ratings['criterion_2'],
          'criterion_3': ratings['criterion_3'],
          'criterion_4': ratings['criterion_4'],
          'criterion_5': ratings['criterion_5'],
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================================');
      print('');

      if (response.statusCode != 200) {
        throw Exception('Failed to submit assessment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting assessment: $e');
    }
  }

  // Get assessment data (Intern use)
  Future<Map<String, int>?> getAssessmentData(int internId) async {
    try {
      print('');
      print('========================================');
      print('📥 FETCHING ASSESSMENT');
      print('========================================');
      print('Intern ID: $internId');

      final response = await http.get(
        Uri.parse('$baseUrl/$internId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================================');
      print('');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'criterion_1': data['criterion_1'] as int,
          'criterion_2': data['criterion_2'] as int,
          'criterion_3': data['criterion_3'] as int,
          'criterion_4': data['criterion_4'] as int,
          'criterion_5': data['criterion_5'] as int,
        };
      } else if (response.statusCode == 404) {
        // No assessment yet
        return null;
      } else {
        throw Exception('Failed to load assessment');
      }
    } catch (e) {
      throw Exception('Error fetching assessment: $e');
    }
  }
}