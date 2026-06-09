import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';

class InternMilestone {
  final int id;
  final int userId;
  final String title;
  final DateTime milestoneDate;
  final bool isAuto;

  InternMilestone({
    required this.id,
    required this.userId,
    required this.title,
    required this.milestoneDate,
    required this.isAuto,
  });

  factory InternMilestone.fromJson(Map<String, dynamic> json) {
    return InternMilestone(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      milestoneDate: DateTime.parse(json['milestone_date']),
      isAuto: (json['is_auto'] == true || json['is_auto'] == 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'milestone_date':
            '${milestoneDate.year}-${milestoneDate.month.toString().padLeft(2, '0')}-${milestoneDate.day.toString().padLeft(2, '0')}',
        'is_auto': isAuto,
      };
}

class MilestoneService {
  final String baseUrl;

  MilestoneService()
      : baseUrl = AppConfig.hostname.replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  // GET /api/internship/milestones/{userId}
  Future<List<InternMilestone>> fetchMilestones(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/milestones/$userId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];
      return data.map((e) => InternMilestone.fromJson(e)).toList();
    }
    // 404 = no milestones yet, return empty
    if (response.statusCode == 404) return [];
    throw Exception('Failed to fetch milestones: ${response.statusCode}');
  }

  // POST /api/internship/milestones
  Future<InternMilestone> createMilestone({
    required int userId,
    required String title,
    required DateTime date,
    bool isAuto = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/internship/milestones'),
      headers: _headers(),
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'milestone_date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'is_auto': isAuto,
      }),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return InternMilestone.fromJson(decoded['data']);
    }
    throw Exception('Failed to create milestone: ${response.statusCode}');
  }

  // PUT /api/internship/milestones/{id}
  Future<InternMilestone> updateMilestone({
    required int id,
    required String title,
    required DateTime date,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/internship/milestones/$id'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'milestone_date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return InternMilestone.fromJson(decoded['data']);
    }
    throw Exception('Failed to update milestone: ${response.statusCode}');
  }

  // DELETE /api/internship/milestones/{id}
  Future<void> deleteMilestone(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/internship/milestones/$id'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete milestone: ${response.statusCode}');
    }
  }
}