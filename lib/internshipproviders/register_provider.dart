import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/register.dart';
import 'package:charms/internshipservices/register_service.dart';
import 'package:charms/main.dart';

class RegisterProvider with ChangeNotifier {
  final RegisterService _registerService =
      RegisterService(baseUrl: AppConfig.hostname);

  List<Map<String, dynamic>> _internList = [];
  List<Map<String, dynamic>> get internList => _internList;

  Future<int> registerUser(Register register) async {
    
    print('');
    print('========================================');
    print('📤 SENDING REGISTRATION REQUEST');
    print('========================================');
    print('User ID: ${register.userId}');
    print('Schedule ID: ${register.scheduleId}');  // ✅ Check this!
    print('Name: ${register.firstName} ${register.lastName}');
    print('========================================');
    
    final userId = await _registerService.addRegister(register);
    notifyListeners();
    return userId;
  }

  Future<void> loadInterns() async {
    try {
      _internList = await _registerService.fetchInterns();
    } catch (e) {
      _internList = [];
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<Register> getInternDetails(int internId) {
    return _registerService.getInternDetails(internId);
  }
}