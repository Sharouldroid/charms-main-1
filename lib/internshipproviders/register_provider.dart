import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/register.dart';
import 'package:charms/internshipservices/register_service.dart';
import 'package:charms/main.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<Register> updateMyDetails(int userId, Map<String, dynamic> payload) async {
    final updated = await _registerService.updateMyDetails(userId, payload);
    notifyListeners();
    return updated;
  }

  Future<String> uploadInternPhoto(int userId, XFile photo) async {
    final filepath = await _registerService.uploadInternPhoto(userId, photo);
    notifyListeners();
    return filepath;
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

  Future<String?> getInternPhotoPath(int userId) {
    return _registerService.getInternPhotoPath(userId);
  }

  Future<Register> getInternDetails(int internId) {
    return _registerService.getInternDetails(internId);
  }

  // ✅ NEW: Used by the intern registration form to auto-fill Email
  // from HR_userlogin (looked up via HR_userdata.id / userid).
  Future<String?> fetchEmailByUserId(int userId) {
    return _registerService.fetchEmailByUserId(userId);
  }
}