import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
class AssessmentService {
  final String baseUrl;

AssessmentService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.hostname;

  Future<void> submitAssessment(int internId, Map<String, int> ratings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/submit-assessment'),
        body: json.encode({
          'intern_id': internId,
          'criterion_1': ratings['criterion_1'],
          'criterion_2': ratings['criterion_2'],
          'criterion_3': ratings['criterion_3'],
          'criterion_4': ratings['criterion_4'],
          'criterion_5': ratings['criterion_5'],
        }),
        headers: {'Content-Type': 'application/json'},
      );

      // Check if the response status is not successful
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to submit assessment. Status code: ${response.statusCode}');
      }

      print('Assessment submitted successfully');
    } catch (e) {
      print('Error submitting assessment: $e');
      rethrow; // Rethrow the exception to be handled in the caller
    }
  }

  Future<Map<String, int>?> getAssessmentData(int internId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get-assessment/$internId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'criterion_1': data['criterion_1'] ?? 1,
          'criterion_2': data['criterion_2'] ?? 1,
          'criterion_3': data['criterion_3'] ?? 1,
          'criterion_4': data['criterion_4'] ?? 1,
          'criterion_5': data['criterion_5'] ?? 1,
        };
      } else {
        throw Exception('Failed to load assessment data');
      }
    } catch (e) {
      print('Error fetching assessment data: $e');
      return null;
    }
  }
}
