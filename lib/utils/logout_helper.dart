import 'package:flutter/material.dart';

class LogoutHelper {
  /// For module-level logout (HR/Intern) -> go back to main dashboard
  static Future<void> backToMainDashboard(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  /// Full app logout (clear auth) -> go login
  static Future<void> fullLogoutToLogin(BuildContext context, Future<void> Function() logoutAction) async {
    final navigator = Navigator.of(context);
    await logoutAction();
    navigator.pushNamedAndRemoveUntil('/', (route) => false);
  }
}