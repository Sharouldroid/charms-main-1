import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class InternRegistration {
  final int id;         // internRegister.id  → used as intern_id in attendance
  final int userId;     // internRegister.user_id
  final int? scheduleId; // internRegister.schedule_id → used as schedule_id in attendance

  InternRegistration({
    required this.id,
    required this.userId,
    this.scheduleId,
  });

  factory InternRegistration.fromJson(Map<String, dynamic> json) {
    return InternRegistration(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      scheduleId: json['schedule_id'] != null
          ? (json['schedule_id'] as num).toInt()
          : null,
    );
  }
}

class InternHelper {
  /// Returns the intern's registration ID (internRegister.id)
  /// This is what gets stored as intern_id in intern_attendances.
  /// Returns null if user hasn't registered yet.
  static Future<int?> getInternIdByUserId(int userId) async {
    final registrations = await getRegistrationsByUserId(userId);
    if (registrations.isEmpty) return null;
    // Return the latest registration's id
    return registrations.last.id;
  }

  /// Returns all registrations for a user.
  /// Each registration has its own schedule_id.
  static Future<List<InternRegistration>> getRegistrationsByUserId(int userId) async {
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

        List<dynamic> raw = [];
        if (decoded is Map && decoded['data'] != null) {
          final inner = decoded['data'];
          if (inner is List) {
            raw = inner;
          } else if (inner is Map) {
            raw = [inner];
          }
        } else if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map && decoded['id'] != null) {
          raw = [decoded];
        }

        final registrations = raw
            .map((e) => InternRegistration.fromJson(e as Map<String, dynamic>))
            .toList();

        print('✅ Found ${registrations.length} registration(s) for user $userId');
        for (final r in registrations) {
          print('   - internRegister.id=${r.id}, schedule_id=${r.scheduleId}');
        }

        return registrations;

      } else if (response.statusCode == 404) {
        print('⚠️ No registration found for user $userId');
        return [];
      } else {
        print('❌ Unexpected response: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ ERROR: $e');
      return [];
    }
  }

  /// Returns the latest registration that has a valid schedule_id.
  /// Used for clock-in/out to get the correct schedule.
  static Future<InternRegistration?> getActiveRegistration(int userId) async {
    final registrations = await getRegistrationsByUserId(userId);
    if (registrations.isEmpty) return null;

    // Prefer latest registration with a non-null schedule_id
    final withSchedule = registrations
        .where((r) => r.scheduleId != null)
        .toList();

    if (withSchedule.isNotEmpty) return withSchedule.last;

    // Fallback: latest registration even if schedule_id is null
    return registrations.last;
  }
}