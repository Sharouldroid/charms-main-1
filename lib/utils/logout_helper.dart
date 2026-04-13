import 'package:charms/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogoutHelper {
  static Future<void> logoutAndGoLogin(BuildContext context) async {
    final navigator = Navigator.of(context); // capture before await
    await Provider.of<Auth>(context, listen: false).logout();
    navigator.pushNamedAndRemoveUntil('/', (route) => false);
  }
}