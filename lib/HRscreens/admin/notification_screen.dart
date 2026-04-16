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
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: Consumer3<Leaves, Payments, Claims>(
        builder: (context, leaves, payments, claims, child) {
          final pendingLeaves =
              leaves.leaves.where((l) => l.status == 'Pending').toList();
          final pendingPayrolls =
              payments.payments.where((p) => p.status == 'Pending').toList();
          final pendingClaims =
              claims.claims.where((c) => c.status == 'Pending').toList();

          return ListView(
            children: [
              if (pendingLeaves.isEmpty &&
                  pendingPayrolls.isEmpty &&
                  pendingClaims.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('No pending notifications'),
                  ),
                ),
              ...pendingLeaves.map(
                (leave) => NotificationItem(
                  title: 'Leave Request Pending',
                  subtitle:
                      'Staff ID: ${leave.staffId} - Type: ${leave.leaveType}',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageLeaveScreen(),
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
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManagePayrollScreen(),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ),
              ...pendingClaims.map(
                (claim) => NotificationItem(
                  title: 'Claim Request Pending',
                  subtitle:
                      'Staff ID: ${claim.staffId} - Amount: RM${claim.amount}',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageClaimScreen(),
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

class NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const NotificationItem({super.key, 
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}