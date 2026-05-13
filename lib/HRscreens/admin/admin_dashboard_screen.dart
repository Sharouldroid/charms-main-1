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
import 'package:charms/providers/auth.dart' as app_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/utils/logout_helper.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';

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

  int totalEmployees    = 0;
  int onLeaveCount      = 0;
  int todayAttendance   = 0;
  int pendingPayroll    = 0;
  int pendingClaims     = 0;
  int scheduleAlerts    = 0; // ✅ exchanges + rejections combined
  String lastLoginTime  = '';
  bool isLoading        = true;

  Map<String, int> locationStaffCounts = {
    'Chagar Hutang': 0,
    'Turtle Lab': 0,
    'UMT': 0,
  };

  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

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
      final staffsProvider      = Provider.of<Staffs>(context, listen: false);
      final leavesProvider      = Provider.of<Leaves>(context, listen: false);
      final attendancesProvider = Provider.of<Attendances>(context, listen: false);
      final paymentsProvider    = Provider.of<Payments>(context, listen: false);
      final schedulesProvider   = Provider.of<Schedules>(context, listen: false);
      final claimsProvider      = Provider.of<Claims>(context, listen: false);
      final exchangesProvider   = Provider.of<ScheduleExchanges>(context, listen: false);

      await Future.wait([
        staffsProvider.fetchStaff(),
        leavesProvider.fetchLeaves(),
        schedulesProvider.fetchSchedules(),
        claimsProvider.fetchClaims(),
        exchangesProvider.fetchPendingForHR(),
      ]);

      final currentDate    = DateTime.now();
      final formattedDate  = DateFormat('yyyy-MM-dd').format(currentDate);
      final attendances    = await attendancesProvider.getAllAttendances();
      await paymentsProvider.fetchPaymentsByMonth(
          currentDate.year, currentDate.month);

      if (!mounted) return;
      setState(() {
        totalEmployees = staffsProvider.staffList.length;

        onLeaveCount = leavesProvider.leaves
            .where((leave) => leave.status == 'Pending')
            .length;

        todayAttendance = attendances
            .where((attendance) {
              final clockIn = attendance['clock_in_time'];
              if (clockIn == null) return false;
              return DateTime.parse(clockIn.toString()).day == currentDate.day;
            })
            .length;

        pendingPayroll = totalEmployees -
            paymentsProvider.payments
                .where((payment) =>
                    payment.workDate.month == currentDate.month &&
                    payment.workDate.year == currentDate.year)
                .length;

        pendingClaims = claimsProvider.claims
            .where((c) => c.status == 'Pending')
            .length;

        // ✅ Combined: pending exchanges (status=1) + rejected schedules (acceptanceStatus=2)
        final pendingExchanges = exchangesProvider.exchanges
            .where((e) => e.status == 1)
            .length;
        final rejectedSchedules = schedulesProvider.schedules
            .where((s) => s.acceptanceStatus == 2)
            .length;
        scheduleAlerts = pendingExchanges + rejectedSchedules;

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
    await LogoutHelper.fullLogout(context);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => ManageStaffScreen(username: widget.username)));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => AdminListScreen(username: widget.username)));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => const MySelfScreen()));
        break;
    }
  }

  void _showSwitchMenu() {
    final appAuth = Provider.of<app_auth.Auth>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Switch View',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 12),

              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.green.shade50,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.badge_outlined,
                      color: Colors.green, size: 22),
                ),
                title: const Text('Staff Mode',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                subtitle: const Text('View as a staff member'),
                trailing: const Icon(Icons.chevron_right, color: Colors.green),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) =>
                            StaffDashboardScreen(username: widget.username)),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 10),

              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.blue.shade50,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.dashboard_outlined,
                      color: Colors.blue, size: 22),
                ),
                title: const Text('CHARMS Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                subtitle: const Text('Back to main app dashboard'),
                trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                        userid: appAuth.userId ?? 0,
                        usertype: appAuth.usertype,
                        hostname: appAuth.hostname,
                      ),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
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
        backgroundColor: primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Switch View',
            onPressed: _showSwitchMenu,
          ),
          Consumer4<Leaves, Payments, Claims, ScheduleExchanges>(
            builder: (context, leaves, payments, claims, exchanges, child) {
              final schedulesProvider =
                  Provider.of<Schedules>(context, listen: false);

              int pendingLeaves      = leaves.leaves.where((l) => l.status == 'Pending').length;
              int pendingPayrolls    = payments.payments.where((p) => p.status == 'Pending').length;
              int pendingClaimsCount = claims.claims.where((c) => c.status == 'Pending').length;
              int pendingExchanges   = exchanges.exchanges.where((e) => e.status == 1).length;
              int rejectedSchedules  = schedulesProvider.schedules
                  .where((s) => s.acceptanceStatus == 2)
                  .length;
              int totalPending = pendingLeaves + pendingPayrolls +
                  pendingClaimsCount + pendingExchanges + rejectedSchedules;

              return IconButton(
                icon: totalPending > 0
                    ? Badge(
                        label: Text(totalPending.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.notifications_none_rounded,
                            size: 26),
                      )
                    : const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen())),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _buildDashboardContent(),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      "Welcome back,\n${widget.username} 👋",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Last Login: $lastLoginTime",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Row 1 ─────────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Total Employees',
                    count: totalEmployees,
                    icon: Icons.people_alt_rounded,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'Leave Pending',
                    count: onLeaveCount,
                    icon: Icons.beach_access_rounded,
                    iconColor: Colors.red,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Row 2 ─────────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: SummaryCard(
                    title: "Today's Attendance",
                    count: todayAttendance,
                    icon: Icons.timer_rounded,
                    iconColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'Payroll Pending',
                    count: pendingPayroll,
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.teal,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Row 3 ─────────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Claim Pending',
                    count: pendingClaims,
                    icon: Icons.request_page_rounded,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ NEW — combined Schedule Alerts card (tappable → NotificationScreen)
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()),
                    ),
                    child: SummaryCard(
                      title: 'Schedule Alerts',
                      count: scheduleAlerts,
                      icon: Icons.swap_horiz_rounded,
                      iconColor: Colors.purple,
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 32),
              _buildMovementCards(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementCards() {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's Schedule",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            Text(today,
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        ...locationStaffCounts.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03),
                    blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.location_on_rounded,
                    size: 24, color: Colors.blue),
              ),
              title: Text(entry.key,
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Staff scheduled: ${entry.value}',
                    style: TextStyle(color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.blue),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ScheduleListScreen(
                      location: entry.key, date: DateTime.now()),
                ));
              },
            ),
          );
        }),
      ],
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
      aspectRatio: 1.4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(count.toString(),
                  style: const TextStyle(fontSize: 26,
                      fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}