import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://10.0.2.2:5002/cms/api/v1';

  Future<List<Map<String, dynamic>>> fetchStaffList() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/user/staff'));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final staffList = List<Map<String, dynamic>>.from(responseData['data']);
        print('Fetched ${staffList.length} staff members');
        return staffList;
      } else {
        print('Data format issue: $responseData');
        throw Exception('Data format error');
      }
    } else {
      throw Exception('Failed to load staff list: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in fetchStaffList: $e');
    rethrow;
  }
}


  Future<Map<String, dynamic>> fetchStaffDetails(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/user/staff/$id'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true && responseData['data'] != null) {
        return Map<String, dynamic>.from(responseData['data'][0]);
      } else {
        throw Exception('Staff details not found');
      }
    } else {
      throw Exception('Failed to load staff details');
    }
  }

  Future<void> registerStaff(Map<String, String> staffData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/staff'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(staffData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to register staff');
    }
  }

  Future<void> updateStaff(int id, Map<String, String> staffData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/staff/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(staffData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update staff');
    }
  }
}
