import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemChrome
import 'package:flutter_stripe/flutter_stripe.dart'; // Needed for Stripe
import 'package:charms/consts.dart'; // Needed for stripePublishableKey
import 'package:charms/providers/auth.dart';
import 'package:charms/services/connectivity_service.dart';
import 'package:charms/services/version_service.dart';
import 'package:charms/services/app_config.dart';
import 'app_startup.dart';

class AppStartup {
  static Future<void> initialize(Auth auth) async {
    // Initialize connectivity monitoring
    ConnectivityService().initialize();

    await Future.wait([
      _initConfig(),
      _initStripe(),
      _initOrientation(),
      _initVersionService(),
      auth.tryAutoLogin(),
    ]);
  }

  static Future<void> _initConfig() async {
    await AppConfig.initialize();
  }

  static Future<void> _initStripe() async {
    try {
      // This uses the key from consts.dart
      Stripe.publishableKey = stripePublishableKey; 
      await Stripe.instance.applySettings();
      debugPrint('🚀 Stripe initialized in background.');
    } catch (e) {
      debugPrint('⚠️ Stripe initialization warning: $e');
    }
  }

  static Future<void> _initOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static Future<void> _initVersionService() async {
    try {
      await VersionService().initialize();
    } catch (e) {
      debugPrint('⚠️ Version service initialization warning: $e');
    }
  }

  // Check for updates and show dialog if needed
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final versionService = VersionService();
      final hasUpdate = await versionService.checkForUpdate();
      
      if (hasUpdate && context.mounted) {
        await VersionService.showUpdateDialog(
          context,
          currentVersion: versionService.currentVersion,
          latestVersion: versionService.latestVersion,
          forceUpdate: versionService.forceUpdate,
        );
      }
    } catch (e) {
      debugPrint('Version check error: $e');
    }
  }
}