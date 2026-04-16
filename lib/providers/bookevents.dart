import 'dart:convert';

import 'package:charms/models/bookgroup.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookEvents with ChangeNotifier {
  List<BookGroup> _groupMember = [];
  List<BookGroup> _researcherMember = [];

  List<BookGroup> get groupMember {
    return [..._groupMember];
  }

  List<BookGroup> get researcherMember {
    return [..._researcherMember];
  }
// all checked 23 Mar 2025

  Future<void> createBooking(
    String hostname,
    int userid,
    int pax,
    int eventid,
    int confirmnum,
    int isgroup,
    int booktype,
    String size,
    double amount,
    String diet,
    String health,
  ) async {
    final url = '${hostname}booking/create';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'userid': userid,
          'pax': pax,
          'eventid': eventid,
          'confirmationno': confirmnum,
          // 'isgroup': isgroup,
          'booktype': booktype,
          'shirtsize': size,
          'amount': amount,
          'diet_restriction': diet,
          'health_condition' : health,
          'status': 0, // <--- FIX: Added missing status field (0 = New/Pending)
        }),
      );

      // Check for Server Errors
      if (response.statusCode >= 400) {
        print('Server Error: ${response.body}');
        throw Exception('Failed to create booking: ${response.body}');
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addBookingGroup(String hostname, String name, String idnum,
      String email, int eventid, int confirmnum, String size, String diet, String health) async {
    final url = '${hostname}booking/group';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'name': name,
        'idnum': idnum,
        'email': email,
        'eventid': eventid,
        'confirmationno': confirmnum,
        'shirtsize': size,
        'diet_restriction': diet,
        'health_condition' : health,
      }),
    );

    if (response.statusCode >= 400) {
       throw Exception('Failed to add group member: ${response.body}');
    }

    notifyListeners();
  }

  Future<void> fetchGroupMembers(String hostname, int confirmnum) async {
    final url = '${hostname}booking/group/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode >= 400) {
         throw Exception('Failed to load members');
      }

      final extractedEvent = jsonDecode(response.body);
      final List<BookGroup> loadedMembers = [];
      
      if (extractedEvent is List) {
        for (var groupdata in extractedEvent) {
          loadedMembers.add(BookGroup(
            id: groupdata['id'],
            name: groupdata['name'],
            idnum: groupdata['idnum'],
            email: groupdata['email'],
            confirmnum: groupdata['confirmationno'],
            shirtsize: groupdata['shirtsize'],
          ));
        }
      }
      _groupMember = loadedMembers;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchResearcherGroup(String hostname, int confirmnum) async {
    final url = '${hostname}researcher/group/researcher/$confirmnum';
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode >= 400) {
         throw Exception('Failed to load researcher group');
      }

      final extractedEvent = jsonDecode(response.body);
      final List<BookGroup> loadedMembers = [];
      if (extractedEvent is List) {
        for (var groupdata in extractedEvent) {
          loadedMembers.add(BookGroup(
            id: groupdata['id'],
            name: groupdata['name'],
            idnum: groupdata['idnum'],
            email: groupdata['email'],
            confirmnum: groupdata['confirmationno'],
          ));
        }
      }
      _researcherMember = loadedMembers;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
// all checked 23 Mar 2025

  Future<void> processBooking(String hostname, int status, int userid,
      int eventid, int confirmnum, String reason) async {
    final url = '${hostname}booking/process';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'status': status,
        'reason': reason,
        'userid': userid,
        'eventid': eventid,
        'confirmnum': confirmnum,
      }),
    );

    if (response.statusCode >= 400) {
        throw Exception('Failed to process booking');
    }

    notifyListeners();
  }

  Future<void> refundBooking(String hostname, int confirmnum) async {
    final url = '${hostname}booking/refund';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'confirmnum': confirmnum,
      }),
    );

    if (response.statusCode >= 400) {
        throw Exception('Failed to refund');
    }

    notifyListeners();
  }

  // ... inside BookEvents class ...

  // Fetch Emergency Contact (No change needed here, logic is same)
  Future<Map<String, dynamic>?> fetchEmergencyContact(String hostname, int userid) async {
    final url = '${hostname}emergency-contact/$userid';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return data['data']; 
        }
      }
      return null; 
    } catch (e) {
      print('Error fetching emergency contact: $e');
      return null;
    }
  }

  // Save Emergency Contact (Updated key)
  Future<void> saveEmergencyContact(
      String hostname, int userid, String name, String phone, String relationship) async {
    final url = '${hostname}emergency-contact/save';
    try {
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'userid': userid, // <--- CHANGED from 'user_id' to 'userid'
          'name': name,
          'phone': phone,
          'relationship': relationship,
        }),
      );
    } catch (e) {
      print('Error saving emergency contact: $e');
    }
  }
}