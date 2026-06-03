import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/HRmodels/payment_claim.dart';
import 'package:flutter/widgets.dart';

class PaymentClaims with ChangeNotifier {
  static const String _base = 'https://devcms.com.my/charmsAPI/api';

  // ── State ─────────────────────────────────────────────────────────────────
  List<PaymentClaim> _claims = [];
  Map<String, dynamic> _dashboard = {};
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<PaymentClaim> get claims => [..._claims];

  List<PaymentClaim> get pendingClaims =>
      _claims.where((c) => c.status == 'Pending').toList();

  List<PaymentClaim> get approvedClaims =>
      _claims.where((c) => c.status == 'Approved').toList();

  List<PaymentClaim> get rejectedClaims =>
      _claims.where((c) => c.status == 'Rejected').toList();

  Map<String, dynamic> get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ NEW — defers notification to after build is complete
void _setLoading(bool val) {
    _isLoading = val;
    WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
    });
}

  // ── ADMIN: Fetch all payment claims ───────────────────────────────────────
  Future<void> fetchAllClaims({String? status}) async {
    _setLoading(true);
    try {
      final uri = Uri.parse(
        status != null
            ? '$_base/payment-claims?status=$status'
            : '$_base/payment-claims',
      );

       debugPrint('=== fetchAllClaims URL: $uri ==='); // ← ADD

      final res = await http.get(uri);

      debugPrint('=== fetchAllClaims status: ${res.statusCode} ==='); // ← ADD
      debugPrint('=== fetchAllClaims body: ${res.body} ===');     

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data'] ?? [];
        _claims = data.map((e) => PaymentClaim.fromJson(e)).toList();
        _error = null;
      } else {
        _error = 'Failed to fetch payment claims';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── PART TIMER: Fetch dashboard data ──────────────────────────────────────
  Future<Map<String, dynamic>> fetchDashboard(int staffId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/payment-claims/dashboard/$staffId'),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        _dashboard = json['data'] ?? {};

        // Also populate claim history into _claims for this staff
        final List history = _dashboard['claim_history'] ?? [];
        _claims = history.map((e) => PaymentClaim.fromJson(e)).toList();

        notifyListeners();
        return _dashboard;
      } else {
        _error = 'Failed to fetch dashboard';
        return {};
      }
    } catch (e) {
      _error = e.toString();
      return {};
    }
  }

  // ── PART TIMER: Submit monthly claim ─────────────────────────────────────
  Future<Map<String, dynamic>> submitClaim({
    required int staffId,
    required int month,
    required int year,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/payment-claims/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': staffId,
          'month':    month,
          'year':     year,
        }),
      );

      final json = jsonDecode(res.body);

      if (res.statusCode == 201) {
        // Refresh dashboard after submit
        await fetchDashboard(staffId);
        return {'success': true, 'message': json['message']};
      } else {
        return {
          'success': false,
          'message': json['message'] ?? 'Failed to submit claim',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── ADMIN: Approve a claim ────────────────────────────────────────────────
  Future<bool> approveClaim(int claimId, int reviewedBy) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/payment-claims/$claimId/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reviewed_by': reviewedBy}),
      );

      if (res.statusCode == 200) {
        // Update local state immediately
        final idx = _claims.indexWhere((c) => c.claimId == claimId);
        if (idx != -1) {
          _claims[idx] = _claims[idx].copyWith(
            status:     'Approved',
            reviewedAt: DateTime.now(),
            reviewedBy: reviewedBy,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ── ADMIN: Reject a claim ─────────────────────────────────────────────────
  Future<bool> rejectClaim(
      int claimId, int reviewedBy, String rejectionReason) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/payment-claims/$claimId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reviewed_by':      reviewedBy,
          'rejection_reason': rejectionReason,
        }),
      );

      if (res.statusCode == 200) {
        // Update local state immediately
        final idx = _claims.indexWhere((c) => c.claimId == claimId);
        if (idx != -1) {
          _claims[idx] = _claims[idx].copyWith(
            status:          'Rejected',
            rejectionReason: rejectionReason,
            reviewedAt:      DateTime.now(),
            reviewedBy:      reviewedBy,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}