import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/claims.dart'; 
import 'package:charms/HRscreens/admin/admin_list_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRscreens/admin/notification_screen.dart';
import 'package:charms/HRscreens/admin/schedule_list_screen.dart';
import 'package:charms/HRscreens/admin/myself_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatelessWidget {
  final String username;
  const AdminDashboard({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return AdminDashboardScreen(username: username);
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final String username;
  const AdminDashboardScreen({super.key, required this.username});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  int totalEmployees = 0;
  int onLeaveCount = 0;
  int todayAttendance = 0;
  int pendingPayroll = 0;
  String lastLoginTime = '';
  bool isLoading = true;

  Map<String, int> locationStaffCounts = {
    'Chagar Hutang': 0,
    'Turtle Lab': 0,
    'UMT': 0,
  };

  @override
  void initState() {
    super.initState();
    _setLastLoginTime();
    _loadDashboardData();
  }

  void _setLastLoginTime() {
    lastLoginTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
  }

  Future<void> _loadDashboardData() async {
    try {
      final staffsProvider = Provider.of<Staffs>(context, listen: false);
      final leavesProvider = Provider.of<Leaves>(context, listen: false);
      final attendancesProvider = Provider.of<Attendances>(context, listen: false);
      final paymentsProvider = Provider.of<Payments>(context, listen: false);
      final schedulesProvider = Provider.of<Schedules>(context, listen: false);
      final claimsProvider = Provider.of<Claims>(context, listen: false); // ✅ Initialize claims

      await Future.wait([
        staffsProvider.fetchStaff(),
        leavesProvider.fetchLeaves(),
        schedulesProvider.fetchSchedules(),
        claimsProvider.fetchClaims(), // ✅ Fetch claims so the badge updates immediately
      ]);

      final currentDate = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
      final attendances = await attendancesProvider.getAllAttendances();
      await paymentsProvider.fetchPaymentsByMonth(currentDate.year, currentDate.month);

      if (!mounted) return;
      setState(() {
        totalEmployees = staffsProvider.staffList.length;

        onLeaveCount = leavesProvider.leaves
            .where((leave) => leave.status == 'Pending')
            .length;

        todayAttendance = attendances
            .where((attendance) =>
                DateTime.parse(attendance['clock_in_time']).day == currentDate.day)
            .length;

        pendingPayroll = totalEmployees -
            paymentsProvider.payments
                .where((payment) =>
                    payment.workDate.month == currentDate.month &&
                    payment.workDate.year == currentDate.year)
                .length;

        final schedules = schedulesProvider.schedules;
        locationStaffCounts = {
          'Chagar Hutang': schedules
              .where((s) =>
                  s.workLocation == 1 &&
                  DateFormat('yyyy-MM-dd').format(s.workDate) == formattedDate)
              .length,
          'Turtle Lab': schedules
              .where((s) =>
                  s.workLocation == 2 &&
                  DateFormat('yyyy-MM-dd').format(s.workDate) == formattedDate)
              .length,
          'UMT': schedules
              .where((s) =>
                  s.workLocation == 3 &&
                  DateFormat('yyyy-MM-dd').format(s.workDate) == formattedDate)
              .length,
        };

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

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
        return;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ManageStaffScreen(username: widget.username)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminListScreen(username: widget.username)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          // ✅ Wrapped in Consumer3 to calculate total pending items
          Consumer3<Leaves, Payments, Claims>(
            builder: (context, leaves, payments, claims, child) {
              int pendingLeaves = leaves.leaves.where((l) => l.status == 'Pending').length;
              int pendingPayrolls = payments.payments.where((p) => p.status == 'Pending').length;
              int pendingClaims = claims.claims.where((c) => c.status == 'Pending').length;

              int totalPending = pendingLeaves + pendingPayrolls + pendingClaims;

              return IconButton(
                icon: totalPending > 0
                    ? Badge(
                        label: Text(totalPending.toString()),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications),
                      )
                    : const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Welcome, ${widget.username}!",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text("Last Login: $lastLoginTime"),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Total Employees',
                      count: totalEmployees,
                      icon: Icons.people,
                      iconColor: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: SummaryCard(
                      title: 'Leave Pending',
                      count: onLeaveCount,
                      icon: Icons.beach_access,
                      iconColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: "Today's Attendance",
                      count: todayAttendance,
                      icon: Icons.access_time,
                      iconColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: SummaryCard(
                      title: 'Payroll Pending',
                      count: pendingPayroll,
                      icon: Icons.receipt,
                      iconColor: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            _buildMovementCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCards() {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Container(
      height: 400,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Today's Schedule ($today)",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...locationStaffCounts.entries.map((entry) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.all(5.0),
              child: ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 30,
                  color: Colors.blue,
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Staff scheduled today: ${entry.value}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 30, color: Colors.blue),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleListScreen(
                        location: entry.key,
                        date: DateTime.now(),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: iconColor),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}