import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:charms/HRmodels/staff_document.dart';

class StaffDocuments with ChangeNotifier {
  static const String _base = 'https://devcms.com.my/charmsAPI/api';

  static const List<String> documentTypes = [
    'Resume',
    'Identity Card',
    'Bank Statement',
  ];

  List<StaffDocument> _documents = [];
  List<StaffDocument> _adminSubmissions = [];
  bool _isLoading = false;
  String? _error;

  List<StaffDocument> get documents => [..._documents];
  List<StaffDocument> get adminSubmissions => [..._adminSubmissions];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Defers notification to after the current build completes — avoids
  // "setState()/markNeedsBuild() called during build" when a fetch is
  // kicked off synchronously from a widget's initState().
  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  StaffDocument? forType(String documentType) {
    try {
      return _documents.firstWhere((d) => d.documentType == documentType);
    } catch (_) {
      return null;
    }
  }

  // ── Distinct staff IDs that have at least one document HR hasn't seen ────
  List<int> get unviewedStaffIds => _adminSubmissions
      .where((d) => d.adminViewedAt == null)
      .map((d) => d.staffId)
      .toSet()
      .toList();

  List<String> unviewedDocumentTypesForStaff(int staffId) => _adminSubmissions
      .where((d) => d.staffId == staffId && d.adminViewedAt == null)
      .map((d) => d.documentType)
      .toList();

  MediaType _contentTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // ── Fetch this staff member's own document slots ────────────────────────
  Future<void> fetchSubmissions(int staffId) async {
    _isLoading = true;
    _notify();

    try {
      final res = await http.get(
        Uri.parse('$_base/staff/documents/submissions/$staffId'),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data'] ?? json;
        _documents = data.map((e) => StaffDocument.fromJson(e)).toList();
        _error = null;
      } else {
        _error = 'Failed to fetch documents';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ── Upload/replace a document for a given type ───────────────────────────
  Future<Map<String, dynamic>> uploadDocument({
    required int staffId,
    required String documentType,
    required PlatformFile file,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/staff/documents/upload'),
      );

      request.fields['staffId'] = staffId.toString();
      request.fields['documentType'] = documentType;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) throw Exception('Failed to read file bytes');
        request.files.add(http.MultipartFile.fromBytes(
          'document',
          bytes,
          filename: file.name,
          contentType: _contentTypeFor(file.name),
        ));
      } else {
        final path = file.path;
        if (path == null) throw Exception('File path is null');
        request.files.add(await http.MultipartFile.fromPath(
          'document',
          path,
          contentType: _contentTypeFor(file.name),
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchSubmissions(staffId);
        return {'success': true, 'message': 'Uploaded successfully'};
      }

      String message = 'Failed to upload document';
      try {
        final json = jsonDecode(res.body);
        message = json['message'] ?? json['error'] ?? message;
      } catch (_) {}
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Delete a submitted document ──────────────────────────────────────────
  Future<bool> deleteSubmission(int id, int staffId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/staff/documents/submissions/$id'),
      );

      if (res.statusCode == 200) {
        await fetchSubmissions(staffId);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ── ADMIN: fetch all part timers' document submissions ───────────────────
  Future<List<StaffDocument>> fetchAdminSubmissions({int? staffId}) async {
    try {
      final uri = Uri.parse(staffId != null
          ? '$_base/staff/documents/admin/submissions?staffId=$staffId'
          : '$_base/staff/documents/admin/submissions');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data'] ?? json;
        final result = data.map((e) => StaffDocument.fromJson(e)).toList();
        _adminSubmissions = result;
        _notify();
        return result;
      }
      return [];
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // ── ADMIN: mark a staff member's documents as viewed (clears the
  //    "document uploaded" notification for them) ───────────────────────────
  Future<bool> markViewed(int staffId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/staff/documents/admin/mark-viewed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staffId': staffId}),
      );

      if (res.statusCode == 200) {
        final now = DateTime.now();
        _adminSubmissions = _adminSubmissions
            .map((d) => d.staffId == staffId ? d.copyWith(adminViewedAt: now) : d)
            .toList();
        _notify();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
