// login_rate_limiter.dart
// Rate limiting for login attempts to prevent brute force attacks
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginRateLimiter {
  static const String _attemptsKey = 'login_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const String _lastAttemptTimeKey = 'last_attempt_time';

  static const int maxAttempts = 5;
  static const int lockoutDurationMinutes = 5;
  static const int delayMultiplierSeconds = 2;

  // Check if user is currently locked out
  static Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTimeString = prefs.getString(_lockoutTimeKey);
    
    if (lockoutTimeString == null) return false;
    
    final lockoutTime = DateTime.parse(lockoutTimeString);
    final now = DateTime.now();
    
    if (now.isBefore(lockoutTime)) {
      return true;
    } else {
      // Lockout expired, reset attempts
      await resetAttempts();
      return false;
    }
  }

  // Get remaining lockout time in minutes
  static Future<int> getRemainingLockoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTimeString = prefs.getString(_lockoutTimeKey);
    
    if (lockoutTimeString == null) return 0;
    
    final lockoutTime = DateTime.parse(lockoutTimeString);
    final now = DateTime.now();
    
    if (now.isBefore(lockoutTime)) {
      return lockoutTime.difference(now).inMinutes + 1;
    }
    return 0;
  }

  // Record a failed login attempt
  static Future<LoginAttemptResult> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if already locked out
    if (await isLockedOut()) {
      final remainingMinutes = await getRemainingLockoutMinutes();
      return LoginAttemptResult(
        isLockedOut: true,
        remainingMinutes: remainingMinutes,
        attemptsRemaining: 0,
      );
    }
    
    int attempts = prefs.getInt(_attemptsKey) ?? 0;
    attempts++;
    await prefs.setInt(_attemptsKey, attempts);
    await prefs.setString(_lastAttemptTimeKey, DateTime.now().toIso8601String());
    
    if (attempts >= maxAttempts) {
      // Lock out the user
      final lockoutTime = DateTime.now().add(Duration(minutes: lockoutDurationMinutes));
      await prefs.setString(_lockoutTimeKey, lockoutTime.toIso8601String());
      
      return LoginAttemptResult(
        isLockedOut: true,
        remainingMinutes: lockoutDurationMinutes,
        attemptsRemaining: 0,
      );
    }
    
    return LoginAttemptResult(
      isLockedOut: false,
      remainingMinutes: 0,
      attemptsRemaining: maxAttempts - attempts,
      delaySeconds: attempts * delayMultiplierSeconds,
    );
  }

  // Reset attempts after successful login
  static Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockoutTimeKey);
    await prefs.remove(_lastAttemptTimeKey);
  }

  // Get current attempt count
  static Future<int> getCurrentAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_attemptsKey) ?? 0;
  }

  // Calculate progressive delay based on attempts
  static Future<int> getProgressiveDelay() async {
    final attempts = await getCurrentAttempts();
    return attempts * delayMultiplierSeconds;
  }

  // Show lockout dialog
  static void showLockoutDialog(BuildContext context, int remainingMinutes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.lock_clock,
          size: 48,
          color: Colors.red,
        ),
        title: const Text(
          'Account Temporarily Locked',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Too many failed login attempts.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Try again in $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If you forgot your password, please contact support.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show attempts remaining warning
  static void showAttemptsWarning(BuildContext context, int attemptsRemaining) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Invalid credentials. $attemptsRemaining attempt${attemptsRemaining > 1 ? 's' : ''} remaining.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class LoginAttemptResult {
  final bool isLockedOut;
  final int remainingMinutes;
  final int attemptsRemaining;
  final int delaySeconds;

  LoginAttemptResult({
    required this.isLockedOut,
    required this.remainingMinutes,
    required this.attemptsRemaining,
    this.delaySeconds = 0,
  });
}
