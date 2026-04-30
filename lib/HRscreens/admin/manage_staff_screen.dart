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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
//import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/utils/logout_helper.dart'; // ← replaces inline logout

class ManageStaffScreen extends StatefulWidget {
  final String username;
  const ManageStaffScreen({super.key, required this.username});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  int _selectedIndex = 1;

  // ── Matches AdminDashboard palette ──────────────────────────────────────────
  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryBlue = const Color(0xFF2563EB);

  // ── Menu items ───────────────────────────────────────────────────────────────
  static const List<_MenuItem> _items = [
    _MenuItem('Staff List',    Icons.people_alt_rounded,     Colors.blue,   null),
    _MenuItem('Plan Schedule', Icons.calendar_today_rounded, Colors.orange, null),
    _MenuItem('Attendance',    Icons.timer_rounded,          Colors.green,  null),
    _MenuItem('Payroll',       Icons.receipt_long_rounded,   Colors.purple, null),
    _MenuItem('Leave',         Icons.beach_access_rounded,   Colors.red,    null),
    _MenuItem('Claim',         Icons.request_page_rounded,   Colors.teal,   null),
  ];

  /// Full logout — clears both app_auth and hr_auth via LogoutHelper.
  Future<void> _logout() async {
    await LogoutHelper.fullLogout(context);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => AdminDashboard(username: widget.username)),
        );
        break;
      case 1:
        break; // current page
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => AdminListScreen(username: widget.username)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MySelfScreen()),
        );
        break;
    }
  }

  Widget _destinationFor(int index) {
    switch (index) {
      case 0:
        return StaffListScreen();
      case 1:
        return PlanScheduleScreen();
      case 2:
        return ManageAttendanceScreen();
      case 3:
        return ManagePayrollScreen();
      case 4:
        return ManageLeaveScreen();
      case 5:
        return ManageClaimScreen();
      default:
        return StaffListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      // ── AppBar — identical style to AdminDashboard ─────────────────────────
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text(
          'CHARMS ADMIN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          // ── Notification badge ─────────────────────────────────────────────
          Consumer3<Leaves, Payments, Claims>(
            builder: (context, leaves, payments, claims, child) {
              int pendingLeaves =
                  leaves.leaves.where((l) => l.status == 'Pending').length;
              int pendingPayrolls =
                  payments.payments.where((p) => p.status == 'Pending').length;
              int pendingClaims =
                  claims.claims.where((c) => c.status == 'Pending').length;
              int totalPending =
                  pendingLeaves + pendingPayrolls + pendingClaims;

              return IconButton(
                icon: totalPending > 0
                    ? Badge(
                        label: Text(totalPending.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(
                            Icons.notifications_none_rounded, size: 26),
                      )
                    : const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Back to Login',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ───────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'Manage Staff 🗂️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a module to manage',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 2-column grid of module cards ─────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _ModuleCard(
                    title: item.title,
                    icon: item.icon,
                    color: item.color,
                    destination: _destinationFor(index),
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// ── Data class for menu items ─────────────────────────────────────────────────
class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? destination;
  const _MenuItem(this.title, this.icon, this.color, this.destination);
}

// ── Module card ───────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;

  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}