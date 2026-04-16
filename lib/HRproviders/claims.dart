import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../HRmodels/claim.dart';

class Claims with ChangeNotifier {
  // ✅ UPDATED BASE URL
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  List<Claim> _claims = [];

  List<Claim> get claims => [..._claims];

  // 1. GET ALL CLAIMS
  // Route: GET /claim
  Future<void> fetchClaims() async {
    try {
      final response = await http.get(Uri.parse('$_hostname/claim')); 
      print('Raw API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> claimData = json.decode(response.body);
        _claims = claimData.map((data) => Claim.fromJson(data)).toList();
        notifyListeners();
      } else {
        print('Error fetching claims: ${response.body}');
      }
    } catch (error) {
      print('Exception fetching claims: $error');
      throw Exception('Failed to fetch claims: $error');
    }
  }

  // 2. GET CLAIMS BY STAFF ID
  // Route: GET /claim/staff/{staffId}
  Future<void> getClaimByStaffId(int staffId) async {
    try {
      final response = await http.get(Uri.parse('$_hostname/claim/staff/$staffId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> claimData = json.decode(response.body);
        _claims = claimData.map((data) => Claim.fromJson(data)).toList();
        notifyListeners();
      } else {
        print('Error fetching staff claims: ${response.body}');
        throw Exception('Failed to fetch claims for staff');
      }
    } catch (error) {
      throw Exception('Error fetching claims: $error');
    }
  }

  // 3. CREATE CLAIM
  // Route: POST /claim/create
  Future<void> createClaim(Claim claim) async {
    try {
      final payload = {
        'staff_id': claim.staffId,
        'claim_type': claim.claimType,
        'amount': claim.amount,
        'description': claim.description,
        'claim_date': claim.claimDate.toIso8601String(),
        'status': claim.status,
        'proof_file': claim.proofFile, // Ensure this handles base64 string or null
      };

      final response = await http.post(
        Uri.parse('$_hostname/claim/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      // Controller returns 201 on success
      if (response.statusCode == 201) {
        // You might want to parse the response to get the new ID, 
        // but here we just add the local object or refresh
        _claims.add(claim);
        notifyListeners();
      } else {
        throw Exception('Failed to create claim: ${response.body}');
      }
    } catch (error) {
      print('Error creating claim: $error');
      rethrow;
    }
  }

  // 4. UPDATE CLAIM
  // Route: PUT /claim/{id}
  Future<void> updateClaim(int claimId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$_hostname/claim/$claimId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          // 'updated_at': DateTime.now().toIso8601String() // Laravel handles timestamps automatically
        }),
      );

      // Controller returns 200 on success
      if (response.statusCode == 200) {
        final index = _claims.indexWhere((claim) => claim.claimId == claimId);
        if (index != -1) {
          _claims[index] = _claims[index].copyWith(
            status: status,
            updatedAt: DateTime.now()
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

  // 5. DELETE CLAIM
  // Route: DELETE /claim/{id}
  Future<void> deleteClaim(int claimId) async {
    try {
      final response = await http.delete(Uri.parse('$_hostname/claim/$claimId'));

      // Controller returns 204 on success
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