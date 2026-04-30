import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart' as app_auth;
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/screens/auth_screen.dart';

class LogoutHelper {
  /// Full app logout — clears BOTH auth providers then navigates to login.
  /// Always call this from StaffDashboard, AdminDashboard, and any screen
  /// that should fully sign the user out of the app.
  /// Clears both providers first before navigating so `home:` in main.dart
  /// never sees a briefly-still-true `isAuth` during the route transition.
  static Future<void> fullLogout(BuildContext context) async {
    // Clear main CHARMS session
    await Provider.of<app_auth.Auth>(context, listen: false).logout();
    // Clear HR session (removes only 'hrUserData' key, not main 'userData')
    await Provider.of<hr_auth.Auth>(context, listen: false).logout();

    if (!context.mounted) return;

    // Push AuthScreen directly and remove all routes from the stack.
    // Using MaterialPageRoute instead of pushNamedAndRemoveUntil('/') avoids
    // the race where home: briefly resolves to a dashboard because
    // notifyListeners() hasn't propagated yet.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  /// Module-level navigation only — goes back to CHARMS Dashboard without
  /// logging the user out. Use this for HR/Internship module back buttons.
  static Future<void> backToMainDashboard(BuildContext context) async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
    );
  }
}