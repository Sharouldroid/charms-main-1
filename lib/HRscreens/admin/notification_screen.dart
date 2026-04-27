import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRscreens/admin/manage_claim_screen.dart';
import 'package:charms/HRscreens/admin/manage_leave_screen.dart';
import 'package:charms/HRscreens/admin/manage_payroll_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadNotifications();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadNotifications() async {
    final leavesProvider = Provider.of<Leaves>(context, listen: false);
    final paymentsProvider = Provider.of<Payments>(context, listen: false);
    final claimsProvider = Provider.of<Claims>(context, listen: false);

    await Future.wait([
      leavesProvider.fetchLeaves(),
      paymentsProvider.fetchPayments(),
      claimsProvider.fetchClaims(),
    ]);

    // Show system notifications for pending items
    showSystemNotifications(
      leavesProvider.leaves.where((l) => l.status == 'Pending').length,
      paymentsProvider.payments.where((p) => p.status == 'Pending').length,
      claimsProvider.claims.where((c) => c.status == 'Pending').length,
    );
  }

  Future<void> showSystemNotifications(
      int leaves, int payrolls, int claims) async {
    if (leaves > 0) {
      await _showNotification(
          'Pending Leaves', 'You have $leaves pending leave requests');
    }
    if (payrolls > 0) {
      await _showNotification(
          'Pending Payrolls', 'You have $payrolls pending payroll items');
    }
    if (claims > 0) {
      await _showNotification(
          'Pending Claims', 'You have $claims pending claim requests');
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'charms_hr_channel',
      'CHARMS HR Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // Modern Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('NOTIFICATIONS', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2
          )
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Consumer3<Leaves, Payments, Claims>(
        builder: (context, leaves, payments, claims, child) {
          final pendingLeaves =
              leaves.leaves.where((l) => l.status == 'Pending').toList();
          final pendingPayrolls =
              payments.payments.where((p) => p.status == 'Pending').toList();
          final pendingClaims =
              claims.claims.where((c) => c.status == 'Pending').toList();

          if (pendingLeaves.isEmpty &&
              pendingPayrolls.isEmpty &&
              pendingClaims.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No pending notifications',
                    style: TextStyle(
                      color: Colors.grey.shade500, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 16.0, top: 8.0),
                child: Text(
                  'Action Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              ...pendingLeaves.map(
                (leave) => NotificationItem(
                  title: 'Leave Request Pending',
                  subtitle: 'Staff ID: ${leave.staffId} • Type: ${leave.leaveType}',
                  iconData: Icons.beach_access_rounded,
                  iconColor: Colors.redAccent,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageLeaveScreen(),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ),
              ...pendingPayrolls.map(
                (payroll) => NotificationItem(
                  title: 'Payroll Pending',
                  subtitle: 'Staff ID: ${payroll.staffId}',
                  iconData: Icons.receipt_long_rounded,
                  iconColor: Colors.teal,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManagePayrollScreen(),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ),
              ...pendingClaims.map(
                (claim) => NotificationItem(
                  title: 'Claim Request Pending',
                  subtitle: 'Staff ID: ${claim.staffId} • Amount: RM${claim.amount}',
                  iconData: Icons.request_page_rounded,
                  iconColor: Colors.orange,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageClaimScreen(),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Modernized Notification Item
class NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}