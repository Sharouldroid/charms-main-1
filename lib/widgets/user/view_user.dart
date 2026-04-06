import 'package:charms/models/user.dart';
import 'package:charms/providers/users.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

class ViewUser extends StatelessWidget {
  const ViewUser({
    super.key,
    required this.user,
    required this.staffid,
    required this.stafftype,
    required this.hostname,
  });

  final User user;
  final int staffid;
  final int stafftype;
  final String hostname;

  // --- Helper: Get Role Name ---
String _getUserRoleName(User currentUser) {
  switch (currentUser.usertype) {
    case 1: return 'Admin';
    case 2: return 'Volunteer';
    case 3: return 'Researcher';
    case 4: return 'Boat Owner';
    case 5: return 'Manager';
    case 6: return 'Officer';
    case 8: return 'Central Lab Officer';
    case 9: return 'Marine Biologist'; // Add this line
    case 10: return 'internCH';
    case 11: return 'Turtle Ranger';
    default: return 'Undefined';
  }
}

  // --- Helper: Show Password Reset Dialog ---
  void _showResetPasswordDialog(BuildContext context, User currentUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 10),
            const Text('Reset Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will reset ${currentUser.firstname}\'s password to "cms_password".',
              style: TextStyle(color: Colors.grey[800], fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'Only proceed if the user explicitly requested this.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await Provider.of<Users>(context, listen: false).resetPassword(
                  hostname,
                  'cms_password',
                  int.parse(currentUser.id),
                );

                if (ctx.mounted) {
                   await Provider.of<Users>(context, listen: false)
                       .fetchIndividual(hostname, int.parse(currentUser.id));
                }

                showSimpleNotification(
                  Text(
                    'Password reset for ${currentUser.firstname}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  background: Colors.green,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                showSimpleNotification(
                  const Text('Failed to reset password', style: TextStyle(color: Colors.white)),
                  background: Colors.red,
                );
              }
            },
            child: const Text('Confirm Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersData = Provider.of<Users>(context);

    User displayedUser;
    try {
      displayedUser = usersData.userlist.firstWhere((u) => u.id == user.id);
    } catch (e) {
      displayedUser = user;
    }

    final canResetPassword = staffid != int.parse(displayedUser.id) &&
        (stafftype == 1 || stafftype == 5) &&
        displayedUser.usertype != 1;

    // Reuse primary color to avoid repeated lookups
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile Details'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (canResetPassword)
            IconButton(
              tooltip: 'Reset Password',
              onPressed: () => _showResetPasswordDialog(context, displayedUser),
              icon: const Icon(Icons.lock_reset, color: Colors.redAccent),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<Users>(context, listen: false)
              .fetchIndividual(hostname, int.parse(displayedUser.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
              child: Column(
                children: [
                  // HEADER SECTION
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // FIXED: replaced withOpacity(0.05)
                      color: primaryColor.withValues(alpha: 0.05),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.isTablet(context) ? 40 : 30),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: ResponsiveHelper.isTablet(context) ? 60 : 50,
                          backgroundColor: primaryColor,
                          child: Text(
                            '${displayedUser.firstname.isNotEmpty ? displayedUser.firstname[0] : ''}${displayedUser.lastname.isNotEmpty ? displayedUser.lastname[0] : ''}'.toUpperCase(),
                            style: TextStyle(fontSize: ResponsiveHelper.isTablet(context) ? 40 : 32, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.isTablet(context) ? 20 : 16),
                        Text(
                          '${displayedUser.firstname} ${displayedUser.lastname}',
                          style: TextStyle(fontSize: ResponsiveHelper.isTablet(context) ? 28 : 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: ResponsiveHelper.isTablet(context) ? 10 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isTablet(context) ? 16 : 12, vertical: ResponsiveHelper.isTablet(context) ? 6 : 4),
                          decoration: BoxDecoration(
                            // FIXED: replaced withOpacity(0.1)
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              // FIXED: replaced withOpacity(0.2)
                              color: primaryColor.withValues(alpha: 0.2)
                            ),
                          ),
                          child: Text(
                            _getUserRoleName(displayedUser).toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.isTablet(context) ? 14 : 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONTACT INFORMATION
                  SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 20),
                  _buildSectionHeader(context, 'CONTACT INFORMATION'),
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isTablet(context) ? 24 : 16, vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildProfileTile(
                          context,
                          icon: Icons.phone_outlined,
                          title: displayedUser.phone,
                          subtitle: 'Phone Number',
                          color: primaryColor,
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildProfileTile(
                          context,
                          icon: Icons.email_outlined,
                      title: displayedUser.email,
                      subtitle: 'Email Address',
                      color: primaryColor,
                    ),
                  ],
                ),
              ),

              // LOCATION DETAILS
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'LOCATION DETAILS'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildProfileTile(
                      context,
                      icon: Icons.location_city_outlined,
                      title: '${displayedUser.city}, ${displayedUser.state}',
                      subtitle: 'City & State',
                      color: primaryColor,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildProfileTile(
                      context,
                      icon: Icons.home_outlined,
                      title: [
                        displayedUser.address1,
                        displayedUser.address2,
                        displayedUser.postcode.toString(),
                        displayedUser.country
                      ].where((s) => s.toString().isNotEmpty).join(', '),
                      subtitle: 'Full Address',
                      isMultiLine: true,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),

              // // SYSTEM INFO
              //  const SizedBox(height: 16),
              //  _buildSectionHeader(context, 'SYSTEM INFO'),
              //  Card(
              //    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //    elevation: 0,
              //    color: Colors.grey[100],
              //    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //    child: _buildProfileTile(
              //      context,
              //      icon: Icons.numbers,
              //      title: displayedUser.id,
              //      subtitle: 'User ID',
              //      color: Colors.grey[700]!, // System icon color can be grey
              //    ),
              //  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isTablet = ResponsiveHelper.isTablet(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTablet ? 15 : 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isMultiLine = false,
  }) {
    final isTablet = ResponsiveHelper.isTablet(context);
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(isTablet ? 10 : 8),
        decoration: BoxDecoration(
          // FIXED: replaced withOpacity(0.1)
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: isTablet ? 24 : 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: isTablet ? 18 : 16),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: isTablet ? 15 : 13)),
      isThreeLine: isMultiLine,
    );
  }
}
