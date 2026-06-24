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

  // GET /api/internship/assessments/interns/list
  Future<List<Map<String, dynamic>>> getInterns() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/assessments/interns/list'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception('Failed to load interns: ${response.statusCode} ${response.body}');
  }

  // POST /api/internship/assessments/submit
  Future<void> submitAssessment(
    int internId,
    Map<String, int> ratings,
    Map<String, String> labels,
  ) async {
    final items = ratings.keys.map((key) {
      return {
        'key': key,
        'label': labels[key] ?? key,
        'score': ratings[key],
      };
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/assessments/submit'),
      headers: _headers(),
      body: jsonEncode({
        'intern_id': internId,
        'items': items,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit assessment: ${response.statusCode} ${response.body}');
    }
  }

  // GET /api/internship/assessments/{internId}
  // Returns { 'ratings': Map<String,int>, 'labels': Map<String,String> } or null
  Future<Map<String, dynamic>?> getAssessmentData(int internId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/assessments/$internId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];

      final Map<String, int> ratings = {};
      final Map<String, String> labels = {};

      for (final item in items) {
        final key = item['criterion_key'].toString();
        ratings[key] = int.parse(item['score'].toString());
        labels[key] = item['label'].toString();
      }

      if (ratings.isEmpty) return null;

      return {'ratings': ratings, 'labels': labels};
    }

    if (response.statusCode == 404) return null;

    throw Exception('Failed to load assessment data: ${response.statusCode} ${response.body}');
  }
}