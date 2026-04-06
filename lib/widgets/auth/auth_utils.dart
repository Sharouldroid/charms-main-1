// auth_utils.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AuthUtils {
  static Future<bool> authenticateWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) return false;

      return await auth.authenticate(
        localizedReason: 'Authenticate to login to CHARMS',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String message,
    bool isSuccess = false,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isSuccess ? 'Success' : 'Error'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDismiss?.call();
                },
              ),
            ],
          ),
    );
  }

  static Future<void> showPendingApprovalDialog(
  BuildContext context, {
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Registration Submitted'),
      content: const Text(
        'Your registration has been submitted for approval. '
        'You will be notified once your account is approved by an admin or manager.\n\n'
        'Please check back later.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

}
