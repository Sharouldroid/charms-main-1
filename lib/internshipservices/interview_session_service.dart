import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import '../internshipmodels/interview_session.dart';

class InterviewSessionService {
  final String baseUrl;
  final String? token;

  InterviewSessionService({String? baseUrl, this.token})
      : baseUrl =
            (baseUrl ?? AppConfig.hostname).replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  List<InterviewSession> _parseList(http.Response response, String label) {
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((e) => InterviewSession.fromJson(e)).toList();
    }
    throw Exception(
      'Unexpected response format ($label): expected List, got ${decoded.runtimeType}',
    );
  }

  // GET /api/internship/interview-sessions?status=available
  Future<List<InterviewSession>> fetchAvailableSessions() async {
    final url = '$baseUrl/api/internship/interview-sessions?status=available';
    final response = await http.get(Uri.parse(url), headers: _headers());
    if (response.statusCode == 200) {
      return _parseList(response, 'fetchAvailableSessions');
    }
    throw Exception(
      'Failed to load available interview sessions: ${response.statusCode} ${response.body}',
    );
  }

  // GET /api/internship/interview-sessions/admin
  Future<List<InterviewSession>> fetchAllSessions() async {
    final url = '$baseUrl/api/internship/interview-sessions/admin';
    final response = await http.get(Uri.parse(url), headers: _headers());
    if (response.statusCode == 200) {
      return _parseList(response, 'fetchAllSessions');
    }
    throw Exception(
      'Failed to load interview sessions: ${response.statusCode} ${response.body}',
    );
  }

  // GET /api/internship/interview-sessions/user/{userId}
  Future<InterviewSession?> fetchMySession(int userId) async {
    final url = '$baseUrl/api/internship/interview-sessions/user/$userId';
    final response = await http.get(Uri.parse(url), headers: _headers());
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null || (decoded is Map && decoded.isEmpty)) return null;
      return InterviewSession.fromJson(decoded);
    }
    if (response.statusCode == 404) return null;
    throw Exception(
      'Failed to load your interview session: ${response.statusCode} ${response.body}',
    );
  }

  // POST /api/internship/interview-sessions
  Future<void> createSession(
      DateTime date, String startTime, String endTime) async {
    final url = '$baseUrl/api/internship/interview-sessions';
    final payload = {
      'date':
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'start_time': startTime,
      'end_time': endTime,
    };
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to create interview session: ${response.statusCode} ${response.body}',
      );
    }
  }

  // POST /api/internship/interview-sessions/{id}/book
  Future<void> bookSession(int id, int userId) async {
    final url = '$baseUrl/api/internship/interview-sessions/$id/book';
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to book interview session: ${response.statusCode} ${response.body}',
      );
    }
  }

  // PUT /api/internship/interview-sessions/{id} { meeting_link }
  Future<void> updateMeetingLink(int id, String meetingLink) async {
    final url = '$baseUrl/api/internship/interview-sessions/$id';
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode({'meeting_link': meetingLink}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update meeting link: ${response.statusCode} ${response.body}',
      );
    }
  }

  // PUT /api/internship/interview-sessions/{id}/complete
  Future<void> completeSession(int id) async {
    final url = '$baseUrl/api/internship/interview-sessions/$id/complete';
    final response = await http.put(Uri.parse(url), headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark interview session as completed: ${response.statusCode} ${response.body}',
      );
    }
  }

  // PUT /api/internship/interview-sessions/{id}/cancel
  Future<void> cancelBooking(int id) async {
    final url = '$baseUrl/api/internship/interview-sessions/$id/cancel';
    final response = await http.put(Uri.parse(url), headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to cancel interview session: ${response.statusCode} ${response.body}',
      );
    }
  }

  // DELETE /api/internship/interview-sessions/{id}
  Future<void> deleteSession(int id) async {
    final url = '$baseUrl/api/internship/interview-sessions/$id';
    final response = await http.delete(Uri.parse(url), headers: _headers());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete interview session: ${response.statusCode} ${response.body}',
      );
    }
  }
}
