import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class InternHelper {
  /// Get intern registration ID from user ID
  /// Returns null if user hasn't registered yet
  static Future<int?> getInternIdByUserId(int userId) async {
    try {
      print('');
      print('========================================');
      print('🔍 CHECKING INTERN REGISTRATION');
      print('========================================');
      print('User ID: $userId');
      
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/registers/by-user/$userId'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('========================================');
      print('');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final internId = data['id'] as int;
        
        print('✅ Found registration! Intern ID: $internId');
        return internId;
      } else if (response.statusCode == 404) {
        print('⚠️ No registration found for user $userId');
        return null;
      } else {
        print('❌ Unexpected response: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('');
      print('========================================');
      print('❌ ERROR CHECKING REGISTRATION');
      print('========================================');
      print('Error: $e');
      print('========================================');
      print('');
      return null;
    }
  }
}