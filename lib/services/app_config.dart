// app_config.dart
// Centralized configuration using environment variables
import 'package:flutter/foundation.dart';

class AppConfig {
  static bool _initialized = false;
  static String _hostname = 'https://devcms.com.my/charmsAPI/api/';
  
  // API Configuration - use hardcoded default that works
  static String get hostname => _hostname;

  // Alternative hostnames for different environments
  static String get devHostname => 'http://10.0.2.2:8000/api/';
  static String get stagingHostname => 'https://staging.devcms.com.my/charmsAPI/api/';
  static String get productionHostname => 'https://devcms.com.my/charmsAPI/api/';

  // Stripe Configuration
  static String get stripePublishableKey {
    return 'pk_test_51QSKKDJXyl2rrn60kQRXyH1HhpjHARd4nSfbRVhGiUUPbYiF1KnLR4MTxCA9BxOPhfL0sLGbCey4e7VhVYuzFA2h00lvURfwoU';
  }

  // App Configuration
  static const String appName = 'CHARMS';
  static const String appVersion = '2.1.2';
  static const int sessionTimeoutMinutes = 30;

  // Feature Flags
  static bool get enableBiometrics => true;
  static bool get enableGoogleSignIn => true;

  // Rate Limiting Configuration
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int loginDelayMultiplierSeconds = 2;

  // Age Restriction
  static const int minimumAge = 16;

  // Initialize environment
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    // Try to load from environment, but use defaults if not available
    try {
      // For now, just use production URL
      _hostname = productionHostname;
      debugPrint('AppConfig initialized with hostname: $_hostname');
    } catch (e) {
      debugPrint('AppConfig initialization warning: $e');
      // Use default values - already set
    }
  }
}
