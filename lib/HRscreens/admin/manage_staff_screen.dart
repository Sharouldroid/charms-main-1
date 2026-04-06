import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/admin_list_screen.dart';
import 'package:charms/HRscreens/admin/notification_screen.dart';
import 'package:charms/HRscreens/admin/staff_list_screen.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRscreens/admin/myself_screen.dart';
import 'package:charms/HRwidgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:charms/HRscreens/admin/manage_attendance_screen.dart';
import 'package:charms/HRscreens/admin/manage_claim_screen.dart';
import 'package:charms/HRscreens/admin/manage_leave_screen.dart';
import 'package:charms/HRscreens/admin/manage_payroll_screen.dart';
import 'package:charms/HRscreens/admin/plan_schedule_screen.dart';
import 'package:provider/provider.dart';

class ManageStaffScreen extends StatefulWidget {
  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  late String username;
  int _selectedIndex = 1;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];

  Future<void> _logout() async {
// Logout logic
    await Provider.of<Auth>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    username = Provider.of<Auth>(context, listen: false).username;
  }

  // Handle navigation between sections
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AdminDashboard(username: username)));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ManageStaffScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => AdminListScreen()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MySelfScreen()));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title:
            const Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
          }),
        ],
      ),
      drawer: CustomDrawer(
        selectedLanguage: _selectedLanguage,
        languages: _languages,
        onLanguageChanged: (String? newValue) {
          setState(() {
            _selectedLanguage = newValue!;
          });
        },
        onLogOut: _logout,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(context, 'Staff List', Icons.people,
                Colors.blue, StaffListScreen()),
            _buildDashboardCard(context, 'Plan Schedule', Icons.calendar_today,
                Colors.orange,PlanScheduleScreen()),
            _buildDashboardCard(context, 'Attendance', Icons.access_time,
                Colors.green, ManageAttendanceScreen()),
            _buildDashboardCard(context, 'Payroll', Icons.monetization_on,
                Colors.purple, ManagePayrollScreen()),
            _buildDashboardCard(context, 'Leave', Icons.beach_access,
                Colors.red, ManageLeaveScreen()),
            _buildDashboardCard(context, 'Claim', Icons.receipt, Colors.teal,
                ManageClaimScreen()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon,
      Color color, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
