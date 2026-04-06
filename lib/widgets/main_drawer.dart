import 'package:charms/models/user.dart';
import 'package:charms/providers/auth.dart';
import 'package:charms/providers/boats.dart';
import 'package:charms/screens/auth_screen.dart';
import 'package:charms/screens/companyprofile_screen.dart';
import 'package:charms/screens/daytrip_screen.dart';
import 'package:charms/screens/manage_boat_screen.dart';
import 'package:charms/screens/profile_screen.dart';
import 'package:charms/screens/terms_of_service_screen.dart';
import 'package:charms/widgets/boat/boat_driver.dart';
import 'package:charms/widgets/boat/edit_profile.dart';
import 'package:charms/widgets/boat/history.dart';
import 'package:charms/widgets/researcher/booking_history.dart';
import 'package:charms/widgets/volunteer/booking_history.dart';
import 'package:charms/services/secure_storage_service.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    required this.userid,
    required this.hostname,
    required this.usertype,
    // required this.onSelectScreen,
    required this.user,
    required this.isAdmin,
  });

  final int userid;
  final String hostname;
  final int usertype;
  // final void Function(String identifier) onSelectScreen;
  final User user;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final iconSize = isTablet ? 32.0 : 26.0;
    final headerIconSize = isTablet ? 56.0 : 48.0;
    final headerPadding = isTablet ? 24.0 : 20.0;
    
    return Drawer(
      width: isTablet ? 350 : null,
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.all(headerPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.anchor_outlined,
                  size: headerIconSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: isTablet ? 22 : 18),
                Text(
                  'CHARMS',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: isTablet ? 28 : null,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.person_pin_rounded,
              size: iconSize,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'Profile',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            onTap: () {
              // onSelectScreen('profile');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (ctx) => ProfileScreen(hostname: hostname, user: user),
                ),
              );
            },
          ),
          usertype == 4
              ? FutureBuilder(
                future: Provider.of<Boats>(
                  context,
                  listen: false,
                ).fetchCompanyDatabyUserid(hostname, userid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.error != null) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return Consumer<Boats>(
                        builder: (ctx, boatData, child) {
                          return boatData.companyRecord.isNotEmpty
                              ? ListView.builder(
                                shrinkWrap: true,
                                itemCount: boatData.companyRecord.length,
                                itemBuilder:
                                    (_, i) => Column(
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            Icons.info,
                                            size: 26,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                          title: Text(
                                            'Maklumat Syarikat',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall!.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onTap:
                                              () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        ctx,
                                                      ) => CompanyProfileScreen(
                                                        userid: userid,
                                                        hostname: hostname,
                                                        companydata:
                                                            boatData
                                                                .companyRecord,
                                                      ),
                                                ),
                                              ),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.info,
                                            size: 26,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                          title: Text(
                                            'Maklumat Bot',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall!.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onTap:
                                              () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (ctx) => ManageBoatScreen(
                                                        hostname: hostname,
                                                        userid: userid,
                                                        companyid:
                                                            boatData
                                                                .companyRecord[i]
                                                                .id,
                                                      ),
                                                ),
                                              ),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.info,
                                            size: 26,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                          title: Text(
                                            'Maklumat Pemandu Bot',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall!.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onTap:
                                              () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (ctx) => BoatDriver(
                                                        // userid: userid,
                                                        hostname: hostname,
                                                        companyid:
                                                            boatData
                                                                .companyRecord[i]
                                                                .id,
                                                        // companydata:
                                                        //     boatData.companyRecord,
                                                      ),
                                                ),
                                              ),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.info,
                                            size: 26,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                          title: Text(
                                            'Sejarah Perjalanan',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall!.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onTap:
                                              () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (ctx) => History(
                                                        hostname: hostname,
                                                        isAdmin: isAdmin,
                                                      ),
                                                ),
                                              ),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.share_location_outlined,
                                            size: 26,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                          title: Text(
                                            'Day Trip',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall!.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              fontSize: 24,
                                            ),
                                          ),
                                          onTap:
                                              () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (ctx) => DaytripScreen(
                                                        isstaff: false,
                                                        hostname: hostname,
                                                        user: user,
                                                        companyid:
                                                            boatData
                                                                .companyRecord[i]
                                                                .id,
                                                      ),
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Center(
                                    child: Text(
                                      'Maklumat Syarikat Tidak Lengkap',
                                    ),
                                  ),
                                  TextButton.icon(
                                    label: const Text('Lengkapkan'),
                                    onPressed:
                                        () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (ctx) => EditProfile(
                                                  userid: userid,
                                                  hostname: hostname,
                                                  companydata: const [],
                                                ),
                                          ),
                                        ),
                                    icon: const Icon(Icons.check_box),
                                  ),
                                ],
                              );
                        },
                      );
                    }
                  }
                },
              )
              : (usertype == 1 || usertype == 6 || usertype == 2) // Removed manager (5)
              ? ListTile(
                leading: Icon(
                  Icons.history,
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Booking History',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (ctx) => VolunteerBookingHistory(
                            staff:
                                usertype == 1 || usertype == 5 || usertype == 6
                                    ? true
                                    : false,
                            user: user,
                            hostname: hostname,
                          ),
                    ),
                  );
                },
              )
              : const SizedBox(height: 0),
          (usertype == 1 || usertype == 6 || usertype == 3) // Removed manager (5)
              ? ListTile(
                leading: Icon(
                  Icons.history,
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Researcher History',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (ctx) => ResearcherBookingHistory(
                            staff:
                                usertype == 1 || usertype == 5 || usertype == 6
                                    ? true
                                    : false,
                            user: user,
                            hostname: hostname,
                          ),
                    ),
                  );
                },
              )
              : const SizedBox.shrink(),
          const Spacer(),
          // Settings Section with Account Deletion
          ListTile(
            leading: Icon(
              Icons.settings,
              size: 26,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => _SettingsPage(
                    hostname: hostname,
                    userid: userid,
                    user: user,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(
              Icons.logout,
              size: 26,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'Logout',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              try {
                // Perform logout
                await Provider.of<Auth>(context, listen: false).logout();

                // Close the drawer
                Navigator.of(context).pop();

                // Close loading indicator
                Navigator.of(context).pop();

                // DON'T clear secure storage - it wipes Remember Me credentials!
                // await SecureStorageService.clearAll();

                // Navigate to auth screen and clear all routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (Route<dynamic> route) => false,
                );
              } catch (error) {
                // Close loading indicator if still showing
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: ${error.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// Settings Page with Account Deletion prominently displayed
class _SettingsPage extends StatelessWidget {
  final String hostname;
  final int userid;
  final User user;

  const _SettingsPage({
    required this.hostname,
    required this.userid,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info Section
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '2.1.2',
            onTap: null,
          ),
          
          // Legal Section
          _buildSectionHeader(context, 'Legal'),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openUrl('http://conservems.my/PrivacyPolicyCHARMs/PrivacyPolicy.html'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const TermsOfServiceScreen(),
              ),
            ),
          ),
          
          // Data Section
          // _buildSectionHeader(context, 'Your Data'),
          // _buildSettingsTile(
          //   context,
          //   icon: Icons.download_outlined,
          //   title: 'Export My Data',
          //   subtitle: 'Download a copy of your personal data',
          //   onTap: () => _requestDataExport(context),
          // ),
          
          // Account Section
          _buildSectionHeader(context, 'Account'),
          const SizedBox(height: 8),
          Semantics(
            label: 'Delete Account Button - This will permanently delete your account',
            child: Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28),
                title: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Permanently delete your account and all data',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.red.shade400),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Support Contact
          Center(
            child: TextButton.icon(
              onPressed: () => _openUrl('mailto:info@conservems.my', context),
              icon: const Icon(Icons.help_outline),
              label: const Text('Contact Support'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: '$title ${subtitle ?? ''}',
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _openUrl(String urlString, [BuildContext? context]) async {
    final url = Uri.parse(urlString);
    try {
      // For mailto, try to launch directly without canLaunchUrl check
      // as canLaunchUrl can return false even when launch works
      if (url.scheme == 'mailto') {
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched && context != null && context.mounted) {
          // Show email address so user can copy it manually
          final email = url.path;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No email app found. Contact: $email'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: email));
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (context != null && context.mounted) {
        final email = url.scheme == 'mailto' ? url.path : urlString;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open. Contact: $email'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red.shade700),
        title: const Text(
          'Delete Account?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action will permanently delete your account and all associated data including:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Your profile information'),
                  Text('• Booking history'),
                  Text('• Payment records'),
                  Text('• Survey responses'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteAccount(context);
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Call soft delete API
      final response = await http.put(
        Uri.parse('${hostname}users/soft-delete/$userid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Clear all stored data
        await SecureStorageService.clearAll();
        await Provider.of<Auth>(context, listen: false).logout();

        if (context.mounted) {
          // Close loading dialog
          Navigator.of(context).pop();
          
          // Navigate to auth screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const AuthScreen()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deleted.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again or contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}