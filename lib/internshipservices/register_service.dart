import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import '../internshipmodels/register.dart';

class RegisterService {
  final String baseUrl;
  final String? token;

  RegisterService({String? baseUrl, this.token})
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

  // POST /api/internship/registers
  Future<int> addRegister(Register register) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/registers'),
      headers: _headers(),
      body: jsonEncode(register.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as int;
    }

    throw Exception('Failed to register: ${response.statusCode} ${response.body}');
  }

  // GET /api/internship/registers
  Future<List<Register>> getAllRegisters() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/registers'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Register.fromJson(json)).toList();
    }

    throw Exception('Failed to fetch users: ${response.statusCode} ${response.body}');
  }

  // DELETE /api/internship/registers/{id}
  Future<void> deleteRegister(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/internship/registers/$userId'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.statusCode} ${response.body}');
    }
  }

  // alias for list interns (same endpoint)
  Future<List<Map<String, dynamic>>> fetchInterns() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/registers'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }

    throw Exception('Failed to load interns: ${response.statusCode} ${response.body}');
  }

  // PUT /api/internship/internApproval
  // Keep only if this endpoint exists in your Laravel routes/controller
  Future<void> updateInternApprovalStatus(
      int internId, String status, String comments) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/internship/internApproval'),
      headers: _headers(),
      body: jsonEncode({
        'intern_id': internId,
        'status': status,
        'comments': comments,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update approval status: ${response.statusCode} ${response.body}');
    }
  }

  // GET /api/internship/registers/{id}
  Future<Register> getInternDetails(int internId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/registers/$internId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Register.fromJson(data);
    }

    throw Exception('Failed to load intern details: ${response.statusCode} ${response.body}');
  }
}