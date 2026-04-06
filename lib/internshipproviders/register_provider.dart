import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/register.dart';
import 'package:charms/internshipservices/register_service.dart';
import 'package:charms/main.dart';

class RegisterProvider with ChangeNotifier {
 final RegisterService _registerService =
      RegisterService(baseUrl: AppConfig.hostname);

  Future<int> registerUser(Register register) async {
    try {
      // Ensure your Service parses the { "id": 1 } JSON from PHP 
      // and returns just the integer 1.
      final userId = await _registerService.addRegister(register);
      notifyListeners(); // Good practice to notify on state change
      return userId;
    } catch (e) {
      // This catches the 400 or 500 errors from the PHP controller
      print('Error during registration: $e'); 
      rethrow; 
    }
  }

  List<Map<String, dynamic>> _internList = [];

  List<Map<String, dynamic>> get internList => _internList;

  Future<void> loadInterns() async {
    try {
      _internList = await _registerService.fetchInterns();
      notifyListeners();
    } catch (e) {
      print('Error loading interns: $e');
      _internList = [];
      notifyListeners();
    }
  }

  Future<Register> getInternDetails(int internId) async {
    try {
      return await _registerService.getInternDetails(internId);
    } catch (e) {
      print('Error fetching intern details: $e');
      rethrow;
    }
  }
}
