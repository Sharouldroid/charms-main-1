import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/services/app_config.dart';

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  String _currentVersion = '';
  String _latestVersion = '';
  bool _forceUpdate = false;

  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  bool get forceUpdate => _forceUpdate;

  // Initialize and get current app version
  Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    } catch (e) {
      debugPrint('Error getting package info: $e');
      _currentVersion = '1.0.0';
    }
  }

  // Check for updates from server
 Future<bool> checkForUpdate() async {
  try {
    final base = AppConfig.hostname.replaceAll(RegExp(r'\/+$'), '');
    final url = Uri.parse('$base/api/app-version'); // if backend route is /api/app-version

    debugPrint('VERSION URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _latestVersion = data['latest_version'] ?? _currentVersion;
      _forceUpdate = data['force_update'] ?? false;
      return _isNewerVersion(_latestVersion, _currentVersion);
    } else {
      debugPrint('Version endpoint status: ${response.statusCode}');
      debugPrint('Version endpoint body: ${response.body}');
    }
  } catch (e) {
    debugPrint('Version check error: $e');
  }
  return false;
}

  // Compare version strings
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (e) {
      debugPrint('Version comparison error: $e');
    }
    return false;
  }

  // Show update dialog
  static Future<void> showUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String latestVersion,
    required bool forceUpdate,
    String? message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            forceUpdate ? Icons.system_update : Icons.update,
            size: 48,
            color: forceUpdate ? Colors.red : Colors.blue,
          ),
          title: Text(
            forceUpdate ? 'Update Required' : 'Update Available',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message ?? 'A new version of CHARMS is available.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Current', style: TextStyle(fontSize: 12)),
                        Text(
                          currentVersion,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    Column(
                      children: [
                        const Text('Latest', style: TextStyle(fontSize: 12)),
                        Text(
                          latestVersion,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (forceUpdate) ...[
                const SizedBox(height: 12),
                const Text(
                  'This update is required to continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () => _openStore(),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  // Open app store
  static Future<void> _openStore() async {
    // Replace with your actual app store URLs
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.charms.app';
    const appStoreUrl = 'https://apps.apple.com/app/charms/id123456789';
    
    final Uri url;
    if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS) {
      url = Uri.parse(appStoreUrl);
    } else {
      url = Uri.parse(playStoreUrl);
    }
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
