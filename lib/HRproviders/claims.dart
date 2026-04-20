import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../HRmodels/claim.dart';

class Claims with ChangeNotifier {
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  List<Claim> _claims = [];
  List<Claim> get claims => [..._claims];

  /// 1) GET ALL CLAIMS
  Future<void> fetchClaims() async {
    try {
      final response = await http.get(Uri.parse('$_hostname/claim'));

      if (response.statusCode == 200) {
        final List<dynamic> claimData = json.decode(response.body);
        _claims = claimData.map((data) => Claim.fromJson(data)).toList();
        notifyListeners();
      } else {
        throw Exception('Error fetching claims: ${response.body}');
      }
    } catch (error) {
      throw Exception('Failed to fetch claims: $error');
    }
  }

  /// 2) GET CLAIMS BY STAFF ID
  Future<void> getClaimByStaffId(int staffId) async {
    try {
      final response = await http.get(
        Uri.parse('$_hostname/claim/staff/$staffId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> claimData = json.decode(response.body);
        _claims = claimData.map((data) => Claim.fromJson(data)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to fetch claims for staff: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error fetching claims: $error');
    }
  }

  /// 3) CREATE CLAIM (MULTIPART)
  /// - Supports image/pdf upload
  /// - Works for Flutter Web/PWA and mobile
  Future<void> createClaim(Claim claim) async {
  try {
    final uri = Uri.parse('$_hostname/claim/create');
    final request = http.MultipartRequest('POST', uri);

    // Required text fields
    request.fields['staff_id'] = claim.staffId.toString();
    request.fields['claim_type'] = claim.claimType;
    request.fields['amount'] = claim.amount.toString();
    request.fields['description'] = claim.description;
    request.fields['claim_date'] = claim.claimDate.toIso8601String();
    request.fields['status'] = claim.status;

    // Optional metadata
    if (claim.proofFileName != null && claim.proofFileName!.isNotEmpty) {
      request.fields['proof_file_name'] = claim.proofFileName!;
    }
    if (claim.proofFileType != null && claim.proofFileType!.isNotEmpty) {
      request.fields['proof_file_type'] = claim.proofFileType!;
    }

    // Actual file upload (IMPORTANT)
    if (claim.proofFile != null && claim.proofFile!.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'proof_file', // must match Laravel input name
          claim.proofFile!,
          filename: claim.proofFileName ?? 'proof_file',
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    // Debug log (remove later)
    print('createClaim status: ${response.statusCode}');
    print('createClaim body: ${response.body}');

    if (response.statusCode == 201) {
      // refresh list to get saved proof_file/proof_file_url
      await getClaimByStaffId(claim.staffId);
    } else {
      throw Exception('Failed to create claim: ${response.body}');
    }
  } catch (error) {
    throw Exception('Error creating claim: $error');
  }
}

  /// 4) UPDATE CLAIM STATUS (JSON)
  /// If only status update is needed, keep this.
  Future<void> updateClaim(int claimId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$_hostname/claim/$claimId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final index = _claims.indexWhere((claim) => claim.claimId == claimId);
        if (index != -1) {
          _claims[index] = _claims[index].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      } else {
        throw Exception('Failed to update claim: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error updating claim: $error');
    }
  }

  /// 5) OPTIONAL: UPDATE CLAIM WITH FILE (MULTIPART PUT via _method)
  Future<void> updateClaimWithFile(
    int claimId, {
    String? status,
    String? claimType,
    double? amount,
    String? description,
    DateTime? claimDate,
    List<int>? proofBytes,
    String? proofFileName,
    String? proofFileType,
  }) async {
    try {
      final uri = Uri.parse('$_hostname/claim/$claimId');
      final request = http.MultipartRequest('POST', uri);

      // Laravel method spoofing for PUT
      request.fields['_method'] = 'PUT';

      if (status != null) request.fields['status'] = status;
      if (claimType != null) request.fields['claim_type'] = claimType;
      if (amount != null) request.fields['amount'] = amount.toString();
      if (description != null) request.fields['description'] = description;
      if (claimDate != null) request.fields['claim_date'] = claimDate.toIso8601String();
      if (proofFileName != null) request.fields['proof_file_name'] = proofFileName;
      if (proofFileType != null) request.fields['proof_file_type'] = proofFileType;

      if (proofBytes != null && proofBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'proof_file',
            proofBytes,
            filename: proofFileName ?? 'proof_file',
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        await fetchClaims();
      } else {
        throw Exception('Failed to update claim with file: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error updating claim with file: $error');
    }
  }

  /// 6) DELETE CLAIM
  Future<void> deleteClaim(int claimId) async {
    try {
      final response = await http.delete(Uri.parse('$_hostname/claim/$claimId'));

      if (response.statusCode == 204 || response.statusCode == 200) {
        _claims.removeWhere((claim) => claim.claimId == claimId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete claim: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error deleting claim: $error');
    }
  }
}