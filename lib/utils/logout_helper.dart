import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart' as app_auth;  // ← keep only this
import 'package:charms/screens/auth_screen.dart';

class LogoutHelper {
  static Future<void> fullLogout(BuildContext context) async {
    // One logout clears everything — HR users are stored in app_auth too
    await Provider.of<app_auth.Auth>(context, listen: false).logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  static Future<void> backToMainDashboard(BuildContext context) async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
    );
  }
}