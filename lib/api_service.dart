import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// Staff model to ensure type safety
class Staff {
  final int id;
  final String name;
  final String email;

  Staff({required this.id, required this.name, required this.email});

  // Factory constructor to create Staff from JSON
  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }

  // Method to serialize Staff object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class ApiService {
  static final String baseUrl = 'https://devcms.com.my/charmsAPI/api'; // Update for your API URL
  static const _timeoutDuration = Duration(seconds: 10);

  // Generic GET method
  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(_timeoutDuration);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        log(
            'GET request to $endpoint failed with status code ${response.statusCode} and body: ${response.body}');
        throw Exception('GET request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error during GET request to $endpoint: $e');
      rethrow;
    }
  }

  // Generic POST method
  Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeoutDuration);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        log(
            'POST request to $endpoint failed with status code ${response.statusCode} and body: ${response.body}');
        throw Exception(
            'POST request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error during POST request to $endpoint: $e');
      rethrow;
    }
  }

  // Generic PUT method
  Future<void> _put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(_timeoutDuration);
      if (response.statusCode != 200) {
        log(
            'PUT request to $endpoint failed with status code ${response.statusCode} and body: ${response.body}');
        throw Exception('PUT request failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Error during PUT request to $endpoint: $e');
      rethrow;
    }
  }

  // Fetch staff list
  Future<List<Staff>> fetchStaffList() async {
    final response = await _get('/user/staff');
    if (response['success'] == true && response['data'] != null) {
      List<Staff> staffList =
          (response['data'] as List).map((data) => Staff.fromJson(data)).toList();
      log('Fetched ${staffList.length} staff members');
      return staffList;
    } else {
      log('Failed to fetch staff list. Response data: $response');
      throw Exception('Failed to fetch staff list');
    }
  }

  // Fetch staff details
  Future<Staff> fetchStaffDetails(int id) async {
    final response = await _get('/user/staff/$id');
    if (response['success'] == true && response['data'] != null) {
      return Staff.fromJson(response['data'][0]);
    } else {
      log('Failed to fetch staff details. Response data: $response');
      throw Exception('Staff details not found');
    }
  }

  // Register new staff
  Future<void> registerStaff(Map<String, String> staffData) async {
    await _post('/staff', staffData);
    log('Staff registered successfully');
  }

  // Update existing staff
  Future<void> updateStaff(int id, Map<String, String> staffData) async {
    await _put('/staff/$id', staffData);
    log('Staff with ID $id updated successfully');
  }
}