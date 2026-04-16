import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/admin_list_screen.dart';
import 'package:charms/HRscreens/admin/manage_attendance_screen.dart';
import 'package:charms/HRscreens/admin/manage_claim_screen.dart';
import 'package:charms/HRscreens/admin/manage_leave_screen.dart';
import 'package:charms/HRscreens/admin/manage_payroll_screen.dart';
import 'package:charms/HRscreens/admin/myself_screen.dart';
import 'package:charms/HRscreens/admin/notification_screen.dart';
import 'package:charms/HRscreens/admin/plan_schedule_screen.dart';
import 'package:charms/HRscreens/admin/staff_list_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';

class ManageStaffScreen extends StatefulWidget {
  final String username;
  const ManageStaffScreen({super.key, required this.username});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  int _selectedIndex = 1;

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard(username: widget.username)),
        );
        break;
      case 1:
        break; // current page
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminListScreen(username: widget.username)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MySelfScreen(username: widget.username)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Dashboard',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard('Staff List', Icons.people, Colors.blue, StaffListScreen()),
            _buildDashboardCard('Plan Schedule', Icons.calendar_today, Colors.orange, PlanScheduleScreen()),
            _buildDashboardCard('Attendance', Icons.access_time, Colors.green, ManageAttendanceScreen()),
            _buildDashboardCard('Payroll', Icons.monetization_on, Colors.purple, ManagePayrollScreen()),
            _buildDashboardCard('Leave', Icons.beach_access, Colors.red, ManageLeaveScreen()),
            _buildDashboardCard('Claim', Icons.receipt, Colors.teal, ManageClaimScreen()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, Color color, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}