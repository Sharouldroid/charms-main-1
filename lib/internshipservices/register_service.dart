import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charms/main.dart';
import '../internshipmodels/register.dart';
import 'package:image_picker/image_picker.dart';

class RegisterService {
  final String baseUrl;
  final String? token;

  RegisterService({String? baseUrl, this.token})
      : baseUrl = (baseUrl ?? AppConfig.hostname).replaceAll(RegExp(r'\/+$'), '');

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // POST /api/internship/registers
  Future<int> addRegister(Register register) async {
    final url = '$baseUrl/api/internship/registers';
    
    print('');
    print('========================================');
    print('📤 INTERN REGISTRATION REQUEST');
    print('========================================');
    print('URL: $url');
    print('BODY: ${jsonEncode(register.toJson())}');
    
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(register.toJson()),
    );

    print('📥 RESPONSE STATUS: ${response.statusCode}');
    print('📥 RESPONSE BODY: ${response.body}');
    print('========================================');
    print('');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // ✅ Grab the ID from the nested 'data' object returned by Laravel
      return jsonResponse['data']['id'] as int; 
    } 
    // ✅ Catch the duplicate registration conflict!
    else if (response.statusCode == 409) {
      throw Exception('DUPLICATE_REGISTRATION'); 
    } 
    // Handle other errors gracefully
    else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to register: ${response.statusCode}');
    }
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

  // Fetch interns
Future<List<Map<String, dynamic>>> fetchInterns() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/internship/registers'),
    headers: _headers(),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] ?? []; // ✅ unwrap the 'data' key
    return List<Map<String, dynamic>>.from(data);
  }

  throw Exception('Failed to load interns: ${response.statusCode} ${response.body}');
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

  // PUT /api/internship/registers/{id}/contact
  Future<Register> updateMyDetails(int userId, Map<String, dynamic> payload) async {
    final url = '$baseUrl/api/internship/registers/$userId/contact';

    final response = await http.put(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Register.fromJson(body['data']);
    }

    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Failed to update profile: ${response.statusCode}');
  }

  // POST /api/internship/registers/{id}/photo  (multipart)
  // POST /api/internship/registers/{id}/photo  (multipart) — PWA-safe
  Future<String> uploadInternPhoto(int userId, XFile photo) async {
    final url = '$baseUrl/api/internship/registers/$userId/photo';
    final request = http.MultipartRequest('POST', Uri.parse(url));

    request.headers['Accept'] = 'application/json';
    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final bytes = await photo.readAsBytes(); // works on web + mobile + desktop
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: photo.name, // XFile.name works cross-platform too
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data']['filepath'] as String;
    }

    throw Exception('Failed to upload photo: ${response.statusCode} ${response.body}');
  }

  // GET /api/internship/registers/{id}/with-photo
  Future<String?> getInternPhotoPath(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/internship/registers/$userId/with-photo'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['filepath'] as String?;
    }
    return null;
  }

  // GET /api/user/by-userid/{userid}
  // Looks up HR_userlogin by HR_userdata.id (userid) — used to auto-fill
  // the Email field on the intern registration form.
  Future<String?> fetchEmailByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/by-userid/$userId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return body['data']['email'] as String?;
      }
    }
    return null;
  }

}