import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';

class AssessmentService {
  final String baseUrl;
  final String? token;

  AssessmentService({String? baseUrl, this.token})
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

  // POST /api/internship/assessments/submit
  Future<void> submitAssessment(int internId, Map<String, int> ratings) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/assessments/submit'),
      headers: _headers(),
      body: jsonEncode({
        'intern_id': internId,
        'criterion_1': ratings['criterion_1'],
        'criterion_2': ratings['criterion_2'],
        'criterion_3': ratings['criterion_3'],
        'criterion_4': ratings['criterion_4'],
        'criterion_5': ratings['criterion_5'],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to submit assessment: ${response.statusCode} ${response.body}',
      );
    }
  }

  // GET /api/internship/assessments/{internId}
  Future<Map<String, int>?> getAssessmentData(int internId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/assessments/$internId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'criterion_1': (data['criterion_1'] ?? 1) as int,
        'criterion_2': (data['criterion_2'] ?? 1) as int,
        'criterion_3': (data['criterion_3'] ?? 1) as int,
        'criterion_4': (data['criterion_4'] ?? 1) as int,
        'criterion_5': (data['criterion_5'] ?? 1) as int,
      };
    }

    if (response.statusCode == 404) {
      return null; // assessment not found
    }

    throw Exception(
      'Failed to load assessment data: ${response.statusCode} ${response.body}',
    );
  }
}