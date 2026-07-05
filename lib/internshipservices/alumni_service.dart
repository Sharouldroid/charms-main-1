import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import 'package:charms/internshipmodels/alumni_update.dart';

class AlumniService {
  final String baseUrl;

  AlumniService() : baseUrl = AppConfig.hostname.replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  // GET /api/internship/alumni/{userId}
  Future<List<AlumniUpdate>> fetchUpdates(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/alumni/$userId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];
      return data.map((e) => AlumniUpdate.fromJson(e)).toList();
    }
    // 404 = no updates submitted yet
    if (response.statusCode == 404) return [];
    throw Exception('Failed to fetch alumni updates: ${response.statusCode}');
  }

  // POST /api/internship/alumni
  Future<AlumniUpdate> createUpdate({
    required int userId,
    required String status,
    required String organisation,
    required String roleOrProgramme,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/alumni'),
      headers: _headers(),
      body: jsonEncode({
        'user_id': userId,
        'status': status,
        'organisation': organisation,
        'role_or_programme': roleOrProgramme,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return AlumniUpdate.fromJson(decoded['data']);
    }
    throw Exception('Failed to submit alumni update: ${response.statusCode}');
  }
}
