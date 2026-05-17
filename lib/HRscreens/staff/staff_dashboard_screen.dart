import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRscreens/staff/staff_schedule_details_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/constants/user_roles.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/utils/logout_helper.dart';
import 'dart:async';
import 'package:charms/HRscreens/staff/staff_attendance_history_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  final String username;

  const StaffDashboardScreen({super.key, required this.username});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedIndex = 0;
  List<Schedule> _staffSchedules = [];
  Staff? _currentStaff;
  bool _isLoading = true;
  String branch = '';
  int workLocation = 0;
  DateTime? lastLoginTime;
  bool _mounted = true;

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5);
  final Color staffBg = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  String getBranchName(int workLocation) {
    const branches = {
      1: 'Chagar Hutang',
      2: 'Turtle Lab',
      3: 'UMT',
    };
    return branches[workLocation] ?? 'N/A';
  }

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  // ✅ Fix 4 — auto-refresh every time the dashboard becomes the active route
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && !_isLoading) {
      _loadStaffData();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadStaffData() async {
    if (!_mounted) return;

    try {
      final staffsProvider = Provider.of<Staffs>(context, listen: false);
      final schedulesProvider = Provider.of<Schedules>(context, listen: false);
      final leavesProvider = Provider.of<Leaves>(context, listen: false);
      final claimsProvider = Provider.of<Claims>(context, listen: false);
      final hrAuth = Provider.of<hr_auth.Auth>(context, listen: false);
      debugPrint('HR Auth token: ${hrAuth.token}');
      debugPrint('HR Auth username: ${hrAuth.username}');

      await Future.wait([
        staffsProvider.fetchStaff(),
        leavesProvider.fetchLeaves(),
        claimsProvider.fetchClaims(),
      ]);

      if (!_mounted) return;

      final staffList = staffsProvider.staffList;
      if (staffList.isNotEmpty) {
        _currentStaff = staffList.firstWhere(
          (staff) => staff.username == widget.username,
          orElse: () => throw Exception('Staff not found'),
        );

        final schedules = await schedulesProvider
            .fetchSchedulesByStaffId(_currentStaff!.staffId);

        if (_mounted) {
          setState(() {
            _staffSchedules = schedules;
            if (_staffSchedules.isNotEmpty) {
              workLocation = _staffSchedules[0].workLocation;
              branch = getBranchName(workLocation);
            }
            lastLoginTime = DateTime.now();
            _isLoading = false;
          });
        }
      } else {
        if (_mounted) {
          setState(() {
            _isLoading = false;
            lastLoginTime = DateTime.now();
          });
        }
      }
    } catch (error) {
      if (_mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    Widget nextScreen;
    switch (index) {
      case 0:
        return;
      case 1:
        nextScreen = LeaveDashboardScreen(
          username: widget.username,
          staffId: _currentStaff?.staffId ?? 0,
        );
        break;
      case 2:
        nextScreen = PayrollDashboardScreen(username: widget.username);
        break;
      case 3:
        nextScreen = ClaimDashboardScreen(
          username: widget.username,
          staffId: _currentStaff?.staffId ?? 0,
        );
        break;
      case 4:
        nextScreen = const StaffMySelfScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  Future<void> _logout() async {
    await LogoutHelper.fullLogout(context);
  }

  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}, "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')} "
        "${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text(
          'STAFF PORTAL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: staffPrimary,
        actions: [
          if (_currentStaff != null &&
              UserRoles.hrAdmin.contains(_currentStaff!.usertype))
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Switch to Admin Mode',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminDashboardScreen(username: widget.username),
                  ),
                );
              },
            ),
          Consumer3<Leaves, Claims, Schedules>(
            builder: (context, leaves, claims, schedules, child) {
              int staffId = _currentStaff?.staffId ?? 0;

              if (staffId == 0) {
                return const Icon(Icons.notifications_none_rounded);
              }

              int resolvedLeaves = leaves.leaves
                  .where(
                      (l) => l.staffId == staffId && l.status != 'Pending')
                  .length;

              int resolvedClaims = claims.claims
                  .where(
                      (c) => c.staffId == staffId && c.status != 'Pending')
                  .length;

              int assignedSchedules = schedules.schedules
                  .where((s) => s.staffId == staffId)
                  .length;

              int totalNotifications =
                  resolvedLeaves + resolvedClaims + assignedSchedules;

              return IconButton(
                icon: totalNotifications > 0
                    ? Badge(
                        label: Text(totalNotifications.toString()),
                        backgroundColor: Colors.redAccent,
                        child:
                            const Icon(Icons.notifications_active_rounded),
                      )
                    : const Icon(Icons.notifications_none_rounded),
                // ✅ Fix 3 — await result and refresh if notified
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StaffNotificationScreen(
                        staffId: _currentStaff?.staffId ?? 0,
                      ),
                    ),
                  );
                  // ✅ Refresh dashboard if notification screen signals so
                  if (result != null && result['refreshDashboard'] == true) {
                    await _loadStaffData();
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildDashboardContent(),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Welcome Header (indigo banner) ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
              top: 20, bottom: 28, left: 24, right: 24),
          decoration: BoxDecoration(
            color: staffPrimary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${widget.username} !",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 16, color: Colors.indigo.shade200),
                  const SizedBox(width: 6),
                  Text(
                    lastLoginTime != null
                        ? "Last Login: ${formatDateTime(lastLoginTime!)}"
                        : "Last Login: Not available",
                    style: TextStyle(
                      color: Colors.indigo.shade100,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Attendance History Card ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffAttendanceHistoryScreen(
                  staffId: _currentStaff?.staffId ?? 0,
                  username: widget.username,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: staffCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: staffPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history_rounded,
                        color: staffPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance History',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1E293B))),
                        Text('View your clock in/out records',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),

        // ── Schedules section ────────────────────────────────────────────
        Expanded(child: _buildSchedulesCards()),
      ],
    );
  }

  Widget _buildSchedulesCards() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: staffPrimary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section label ─────────────────────────────────────────────────
        Padding(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
          child: Text(
            "Your Upcoming Shifts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        Expanded(
          child: _staffSchedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming schedules',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 100, left: 16, right: 16),
                  itemCount: _staffSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _staffSchedules[index];
                    final currentBranch =
                        getBranchName(schedule.workLocation);
                    final dateObj = schedule.workDate;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: staffCardBorder),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final attendanceProvider =
                              Provider.of<Attendances>(context, listen: false);

                          final isClockIn =
                              await attendanceProvider.checkAttendance(
                            staffId: _currentStaff?.staffId ?? 0,
                            scheduleId: schedule.schedId,
                          );

                          if (!mounted) return;

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StaffScheduleDetailsScreen(
                                location: currentBranch,
                                workDate: schedule.workDate,
                                assignedStaff: [
                                  _currentStaff?.firstname ?? ''
                                ],
                                startTime:
                                    schedule.workStartTime.toString(),
                                endTime: schedule.workEndTime.toString(),
                                startBreak:
                                    schedule.breakStartTime.toString(),
                                endBreak:
                                    schedule.breakEndTime.toString(),
                                status: isClockIn
                                    ? 'Clocked In'
                                    : 'Not clocked in',
                                scheduleId: schedule.schedId,
                                staffId: _currentStaff?.staffId ?? 0,
                                acceptanceStatus: schedule.acceptanceStatus, // ✅ NEW
                                staffNote: schedule.staffNote,               // ✅ NEW
                              ),
                            ),
                          );

                          if (result != null &&
                              result['refreshDashboard'] == true) {
                            await _loadStaffData();
                          }
                        },
                        child: Row(
                          children: [
                            // ── Left date block (ticket style) ───────────
                            Container(
                              width: 80,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: staffPrimary.withOpacity(0.08),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getMonthName(dateObj.month)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: staffPrimary,
                                    ),
                                  ),
                                  Text(
                                    dateObj.day.toString(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: staffPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Vertical divider
                            Container(
                              width: 1,
                              height: 60,
                              color: staffCardBorder,
                            ),

                            // ── Right content block ───────────────────────
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentBranch,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded,
                                            size: 14,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${schedule.workStartTime} - ${schedule.workEndTime}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ── Acceptance status badge ───────────
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: schedule.acceptanceStatus == 1
                                                ? Colors.green.withOpacity(0.1)
                                                : schedule.acceptanceStatus == 2
                                                    ? Colors.red.withOpacity(0.1)
                                                    : Colors.orange.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            schedule.acceptanceStatus == 1
                                                ? '✅ Accepted'
                                                : schedule.acceptanceStatus == 2
                                                    ? '❌ Not Accepted'
                                                    : '⏳ Pending',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: schedule.acceptanceStatus == 1
                                                  ? Colors.green
                                                  : schedule.acceptanceStatus == 2
                                                      ? Colors.red
                                                      : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // ── End acceptance status badge ───────
                                  ],
                                ),
                              ),
                            ),

                            // ── Trailing arrow ────────────────────────────
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}