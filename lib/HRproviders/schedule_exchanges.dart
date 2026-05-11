import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/HRmodels/schedule_exchange.dart';

class ScheduleExchanges with ChangeNotifier {
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  List<ScheduleExchange> _exchanges = [];
  List<ScheduleExchange> get exchanges => [..._exchanges];

  // Staff: request exchange
  Future<bool> requestExchange({
    required int requesterId,
    required int targetId,
    required int requesterSched,
    required int targetSched,
    String? note,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_hostname/schedule-exchange/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requester_id':    requesterId,
          'target_id':       targetId,
          'requester_sched': requesterSched,
          'target_sched':    targetSched,
          'requester_note':  note,
        }),
      );
      debugPrint('requestExchange: ${response.statusCode} ${response.body}');
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error requesting exchange: $e');
      return false;
    }
  }

  // Fetch exchanges for a staff (both as requester + target)
  Future<void> fetchExchangesByStaff(int staffId) async {
    try {
      final response = await http.get(
        Uri.parse('$_hostname/schedule-exchange/staff/$staffId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _exchanges = data.map((e) => ScheduleExchange.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching exchanges: $e');
    }
  }

  // Fetch all pending for HR
  Future<List<ScheduleExchange>> fetchPendingForHR() async {
    try {
      final response = await http.get(
        Uri.parse('$_hostname/schedule-exchange/pending-hr'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => ScheduleExchange.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching HR pending: $e');
      return [];
    }
  }

  // Target staff: accept or reject
  Future<bool> targetRespond(int exchangeId, bool accept, {String? note}) async {
    try {
      final response = await http.put(
        Uri.parse('$_hostname/schedule-exchange/$exchangeId/target-respond'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'accept': accept, 'target_note': note}),
      );
      if (response.statusCode == 200) { notifyListeners(); return true; }
      return false;
    } catch (e) {
      debugPrint('Error target respond: $e');
      return false;
    }
  }

 // HR: approve or reject
Future<bool> hrRespond(int exchangeId, bool approve, {String? note}) async {
  try {
    final response = await http.put(
      Uri.parse('$_hostname/schedule-exchange/$exchangeId/hr-respond'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'approve': approve, 'hr_note': note}),
    );
    if (response.statusCode == 200) {
      notifyListeners();
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('Error HR respond: $e');
    return false;
  }
}
}