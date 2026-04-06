// secure_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charms/widgets/auth/auth_constants.dart'; // Import this to access keys

class SecureStorageService {
  // Internal storage keys (how it's saved in the phone)
  static const String _usernameKey = 'saved_username';
  static const String _passkeyKey = 'saved_passkey';
  static const String _rememberMeKey = 'remember_me';
  static const String _useBiometricsKey = 'use_biometrics';

  // Save credentials
  static Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passkeyKey, password);
    debugPrint('✅ Credentials SAVED');
  }

  // Get stored credentials
  // CRITICAL: Keys here must match what AuthCard expects
  static Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final passkey = prefs.getString(_passkeyKey);
    
    debugPrint('📖 Credentials LOADED: User=$username, PassFound=${passkey != null}');
    
    return {
      AuthConstants.usernameKey: username, // 'username'
      AuthConstants.passkeyKey: passkey,   // 'passkey'
    };
  }

  // Clear credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_passkeyKey);
    debugPrint('🗑️ Credentials CLEARED');
  }

  // Save remember me preference
  static Future<void> saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
    debugPrint('✅ Remember Me SAVED: $value');
  }

  // Get remember me preference
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_rememberMeKey) ?? false;
    debugPrint('📖 Remember Me LOADED: $value');
    return value;
  }

  // Save biometrics preference
  static Future<void> saveBiometricsPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBiometricsKey, value);
  }

  // Get biometrics preference
  static Future<bool> getBiometricsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useBiometricsKey) ?? false;
  }
  
  // Clear all
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_passkeyKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_useBiometricsKey);
  }
}