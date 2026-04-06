// register_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../internshipmodels/register.dart';
import 'package:charms/main.dart';

class RegisterService {
  final String baseUrl;

RegisterService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.hostname;

  Future<int> addRegister(Register register) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(register.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // Assuming the response includes the user ID
      } else {
        throw Exception('Failed to register: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }

  Future<List<Register>> getAllRegisters() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/internship/registers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Register.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch users: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<void> deleteRegister(int userId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/api/registers/$userId'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchInterns() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/registers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load interns');
      }
    } catch (e) {
      throw Exception('Failed to load interns: $e');
    }
  }

  Future<void> updateInternApprovalStatus(
      int internId, String status, String comments) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/internApproval'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'intern_id': internId,
          'status': status,
          'comments': comments,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update approval status: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error updating approval status: $e');
    }
  }

  Future<Register> getInternDetails(int internId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/registers/$internId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Register.fromJson(
            data); // Convert JSON response to Register object
      } else {
        throw Exception('Failed to load intern details');
      }
    } catch (e) {
      throw Exception('Error fetching intern details: $e');
    }
  }

  Future<Register> fetchInternDetails(int internId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/registers'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Register.fromJson(data);
      } else {
        throw Exception('Failed to fetch intern details');
      }
    } catch (e) {
      throw Exception('Error fetching intern details: $e');
    }
  }
}
