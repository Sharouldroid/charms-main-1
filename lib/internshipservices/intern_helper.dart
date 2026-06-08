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
        final decoded = jsonDecode(response.body);

        // ✅ New response format: { "success": true, "data": [...] }
        List<dynamic> registrations = [];

        if (decoded is Map && decoded['data'] != null) {
          final inner = decoded['data'];
          if (inner is List) {
            registrations = inner;
          } else if (inner is Map) {
            registrations = [inner]; // single registration
          }
        } else if (decoded is List) {
          registrations = decoded; // fallback: bare list
        } else if (decoded is Map && decoded['id'] != null) {
          // fallback: old single-object format
          registrations = [decoded];
        }

        if (registrations.isEmpty) {
          print('⚠️ No registrations found for user $userId');
          return null;
        }

        // ✅ Return the ID of the FIRST registration
        final internId = (registrations.first['user_id'] as num).toInt();
        print('✅ Found registration! Intern ID: $internId');
        print('   Total registrations: ${registrations.length}');
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