import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../HRmodels/leave.dart';

class Leaves with ChangeNotifier {
  // Updated hostname to match your CHARMS API example
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';
  
  List<Leave> _leaves = [];

  List<Leave> get leaves => [..._leaves];

  Future<void> fetchLeaves() async {
    try {
      // Aligned with Laravel: Route::get('/', [HRLeaveController::class, 'getAllLeaves'])
      final response = await http.get(Uri.parse('$_hostname/leave/'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Aligned with Laravel response: return response()->json(['leaves' => $leaves], 200);
        if (responseData.containsKey('leaves')) {
          final List<dynamic> leaveData = responseData['leaves'];
          _leaves = leaveData.map((data) => Leave.fromJson(data)).toList();
          notifyListeners();
        }
      } else {
        print('Error fetching leaves: ${response.body}');
      }
    } catch (error) {
      print('Exception fetching leaves: $error');
      throw Exception('Failed to fetch leaves: $error');
    }
  }

  Future<Leave> getLeaveById(int leaveId) async {
    try {
      // Aligned with Laravel: Route::get('/{id}', [HRLeaveController::class, 'getLeaveById'])
      final response = await http.get(Uri.parse('$_hostname/leave/$leaveId'));

      if (response.statusCode == 200) {
        return Leave.fromJson(json.decode(response.body));
      }
      throw Exception('Leave not found');
    } catch (error) {
      throw Exception('Failed to fetch leave: $error');
    }
  }

  Future<void> getLeaveByStaffId({int? staffId}) async {
    try {
      final url = staffId != null 
          ? Uri.parse('$_hostname/leave/staff/$staffId')
          : Uri.parse('$_hostname/leave/');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> && responseData.containsKey('leaves')) {
          final List<dynamic> leavesData = responseData['leaves'];
          _leaves = leavesData.map((item) => Leave.fromJson(item)).toList();
        } else if (responseData is List) {
          _leaves = responseData.map((item) => Leave.fromJson(item)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
        notifyListeners();
      } else {
        throw Exception('Failed to fetch leaves: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching leaves: $error');
      throw Exception('Failed to fetch leaves: $error');
    }
  }

  Future<void> createLeave(Leave leave) async {
    // Aligned with your example: using MultipartRequest for POST
    final url = Uri.parse('$_hostname/leave/create');
    var request = http.MultipartRequest('POST', url);

    // Adding fields to the request
    request.fields['staff_id'] = leave.staffId.toString();
    request.fields['leave_type'] = leave.leaveType;
    request.fields['start_date'] = leave.startDate.toIso8601String();
    request.fields['end_date'] = leave.endDate.toIso8601String();
    request.fields['reason'] = leave.reason;
    request.fields['status'] = leave.status;

    // Handling the file upload if proofFile exists
    if (leave.proofFile != null) {
      request.fields['proof_file_name'] = leave.proofFileName ?? 'file';
      request.fields['proof_file_type'] = leave.proofFileType ?? '';
      
      request.files.add(http.MultipartFile.fromBytes(
        'proof_file', 
        leave.proofFile!,
        filename: leave.proofFileName,
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        print('Server error: ${response.body}');
        throw Exception('Server error: ${response.body}');
      }
    } catch (error) {
      print('Exception creating leave: $error');
      rethrow;
    }
  }

  Future<void> updateLeave(Leave leave) async {
    try {
      // Aligned with Laravel: Route::put('/{id}', [HRLeaveController::class, 'updateLeave'])
      final Map<String, dynamic> updateData = {
        'status': leave.status,
      };

      final response = await http.put(
        Uri.parse('$_hostname/leave/${leave.leaveId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        await fetchLeaves();
      } else {
        throw Exception('Failed to update leave: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating leave: $error');
      throw Exception('Error updating leave: $error');
    }
  }

  Future<void> deleteLeave(int leaveId) async {
    try {
      // Aligned with Laravel: Route::delete('/{id}', [HRLeaveController::class, 'deleteLeave'])
      final response = await http.delete(
        Uri.parse('$_hostname/leave/$leaveId'),
      );

      if (response.statusCode == 204) {
        _leaves.removeWhere((leave) => leave.leaveId == leaveId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete leave');
      }
    } catch (error) {
      throw Exception('Error deleting leave: $error');
    }
  }
}