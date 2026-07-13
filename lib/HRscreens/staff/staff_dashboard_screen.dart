import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/staff_on_leave_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRscreens/staff/staff_schedule_details_screen.dart';
import 'package:charms/HRutils/attendance_location_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/constants/user_roles.dart';

import 'package:charms/utils/logout_helper.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRscreens/staff/staff_attendance_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffDashboardScreen extends StatefulWidget {
  final String username;
  const StaffDashboardScreen({super.key, required this.username});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  List<Schedule> _staffSchedules = [];
  Staff? _currentStaff;
  bool _isLoading = true;
  String branch = '';
  int workLocation = 0;
  DateTime? lastLoginTime;
  bool _mounted = true;

  // ── Today's attendance (clock in/out available every day) ────────────────
  Schedule? _todaySchedule;
  bool _isCheckingTodayAttendance = true;
  bool _isClockActionLoading = false;
  bool _isClockedInToday = false;
  bool _isClockedOutToday = false;
  String? _todayClockInTimeStr;
  String? _todayClockOutTimeStr;
  String? _todayClockInLocationStr;

  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  // ── Profile completion check ───────────────────────────────────────────────
  bool get _isProfileIncomplete {
    if (_currentStaff == null) return false;
    return _currentStaff!.idNum.isEmpty ||
        _currentStaff!.phone.isEmpty ||
        _currentStaff!.nationality.isEmpty ||
        _currentStaff!.religion.isEmpty ||
        _currentStaff!.address1.isEmpty ||
        _currentStaff!.city.isEmpty ||
        _currentStaff!.state.isEmpty ||
        _currentStaff!.country.isEmpty ||
        _currentStaff!.emergencyName.isEmpty ||
        _currentStaff!.emergencyPhone.isEmpty ||
        _currentStaff!.dob.isEmpty;
  }

  String getBranchName(int workLocation) {
    const branches = {1: 'Chagar Hutang', 2: 'Turtle Lab', 3: 'UMT'};
    return branches[workLocation] ?? 'N/A';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStaffData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && !_isLoading) {
      _loadStaffData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _mounted) {
      _loadStaffData();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadStaffData() async {
    if (!_mounted) return;
    try {
      final staffsProvider    = Provider.of<Staffs>(context, listen: false);
      final schedulesProvider = Provider.of<Schedules>(context, listen: false);
      final leavesProvider    = Provider.of<Leaves>(context, listen: false);
      final claimsProvider    = Provider.of<Claims>(context, listen: false);
      final exchangesProvider = Provider.of<ScheduleExchanges>(context, listen: false);

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

        await exchangesProvider.fetchExchangesByStaff(_currentStaff!.staffId);
        final schedules = await schedulesProvider
            .fetchSchedulesByStaffId(_currentStaff!.staffId);

        final cutoff = DateTime.now().subtract(const Duration(hours: 24));

        if (_mounted) {
          setState(() {
            _staffSchedules = schedules
                .where((s) => s.workDate.isAfter(cutoff))
                .toList()
              ..sort((a, b) => a.workDate.compareTo(b.workDate));

            if (_staffSchedules.isNotEmpty) {
              workLocation = _staffSchedules[0].workLocation;
              branch       = getBranchName(workLocation);
            }
            _todaySchedule = _findTodaySchedule(_staffSchedules);
            lastLoginTime = DateTime.now();
            _isLoading    = false;
          });
        }
        await _checkTodayAttendance();
      } else {
        if (_mounted) {
          setState(() {
            _isLoading                 = false;
            _isCheckingTodayAttendance = false;
            lastLoginTime              = DateTime.now();
          });
        }
      }
    } catch (error) {
      if (_mounted) {
        setState(() {
          _isLoading                 = false;
          _isCheckingTodayAttendance = false;
        });
      }
    }
  }

  Future<void> _openGoogleMaps(String coordinates) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coordinates');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Resolve today's schedule (admin-assigned or previously self-created) ──
  Schedule? _findTodaySchedule(List<Schedule> schedules) {
    final now = DateTime.now();
    for (final s in schedules) {
      if (s.workDate.year == now.year &&
          s.workDate.month == now.month &&
          s.workDate.day == now.day) {
        return s;
      }
    }
    return null;
  }

  // ── Check today's clock in/out state ──────────────────────────────────────
  Future<void> _checkTodayAttendance() async {
    if (!_mounted) return;
    if (_todaySchedule == null || _currentStaff == null) {
      setState(() {
        _isCheckingTodayAttendance = false;
        _isClockedInToday          = false;
        _isClockedOutToday         = false;
      });
      return;
    }
    try {
      final ap = Provider.of<Attendances>(context, listen: false);
      final hasAttendance = await ap.checkAttendance(
        staffId:    _currentStaff!.staffId,
        scheduleId: _todaySchedule!.schedId,
      );
      final clockOutTime = ap.lastCheckedClockOutTime;
      final clockInTime  = ap.lastCheckedClockInTime;
      final clockInLocation = ap.lastCheckedClockInLocation;
      if (!_mounted) return;
      setState(() {
        _isClockedInToday          = hasAttendance;
        _isClockedOutToday         = clockOutTime != null && clockOutTime.isNotEmpty;
        _todayClockInTimeStr       = clockInTime;
        _todayClockOutTimeStr      = clockOutTime;
        _todayClockInLocationStr   = clockInLocation;
        _isCheckingTodayAttendance = false;
      });
    } catch (_) {
      if (_mounted) setState(() => _isCheckingTodayAttendance = false);
    }
  }

  // ── Clock In — resolves today's schedule, self-creating one if HR hasn't
  // assigned a shift, so staff can clock in every day like an intern ───────
  Future<void> _handleDashboardClockIn() async {
    if (_currentStaff == null) return;
    setState(() => _isClockActionLoading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Detecting your location...'),
        ]),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blueGrey,
      ));

      final displayLocation = await resolveDisplayLocation();
      if (displayLocation == null) {
        if (_mounted) setState(() => _isClockActionLoading = false);
        return;
      }

      int scheduleId;
      if (_todaySchedule != null) {
        scheduleId = _todaySchedule!.schedId;
      } else {
        final schedulesProvider = Provider.of<Schedules>(context, listen: false);
        final defaultLocation = workLocation != 0 ? workLocation : 1;
        final created = await schedulesProvider.addSchedule(Schedule(
          schedId:          0,
          staffId:          _currentStaff!.staffId,
          workDate:         DateTime.now(),
          workLocation:     defaultLocation,
          staffType:        1,
          acceptanceStatus: 1,
        ));
        if (created == null) {
          if (_mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Couldn't start today's attendance. Please try again."),
              backgroundColor: Colors.red,
            ));
            setState(() => _isClockActionLoading = false);
          }
          return;
        }
        scheduleId     = created.schedId;
        _todaySchedule = created;
      }

      final ap = Provider.of<Attendances>(context, listen: false);
      final result = await ap.recordAttendance(
        staffId:          _currentStaff!.staffId,
        scheduleId:       scheduleId,
        clockInTime:      DateTime.now().toIso8601String(),
        clockInLocation:  displayLocation,
      );

      if (result['success'] == true && _mounted) {
        setState(() {
          _isClockedInToday        = true;
          _todayClockInTimeStr     = DateFormat('hh:mm a').format(DateTime.now());
          _todayClockInLocationStr = displayLocation;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Successfully clocked in!'), backgroundColor: Colors.green));
      } else if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to clock in.'), backgroundColor: Colors.red));
      }
    } catch (error) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to clock in: $error'), backgroundColor: Colors.red));
      }
    } finally {
      if (_mounted) setState(() => _isClockActionLoading = false);
    }
  }

  // ── Clock Out ──────────────────────────────────────────────────────────────
  Future<void> _handleDashboardClockOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clock Out'),
        content: const Text('Are you sure you want to clock out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clock Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || _todaySchedule == null || _currentStaff == null) return;

    setState(() => _isClockActionLoading = true);
    try {
      final ap  = Provider.of<Attendances>(context, listen: false);
      final now = DateTime.now();
      final result = await ap.clockOutAttendance(
        staffId:      _currentStaff!.staffId,
        scheduleId:   _todaySchedule!.schedId,
        clockOutTime: now.toIso8601String(),
      );
      if (result['success'] == true && _mounted) {
        setState(() {
          _isClockedOutToday    = true;
          _todayClockOutTimeStr = DateFormat('hh:mm a').format(now);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Successfully clocked out!'), backgroundColor: Colors.green));
      }
    } catch (error) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $error'), backgroundColor: Colors.red));
      }
    } finally {
      if (_mounted) setState(() => _isClockActionLoading = false);
    }
  }

  // ✅ NEW — reads dismissed IDs from SharedPreferences
  // Same keys as StaffNotificationScreen so they stay in sync
  Future<Map<String, Set<String>>> _loadDismissedIds(int staffId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'leaves':    (prefs.getStringList('dismissed_leaves_$staffId')    ?? []).toSet(),
        'claims':    (prefs.getStringList('dismissed_claims_$staffId')    ?? []).toSet(),
        'schedules': (prefs.getStringList('dismissed_schedules_$staffId') ?? []).toSet(),
        'exchanges': (prefs.getStringList('dismissed_exchanges_$staffId') ?? []).toSet(),
      };
    } catch (_) {
      return {
        'leaves':    {},
        'claims':    {},
        'schedules': {},
        'exchanges': {},
      };
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    Widget nextScreen;
    switch (index) {
      case 0: return;
      case 1:
        nextScreen = LeaveDashboardScreen(
            username: widget.username,
            staffId:  _currentStaff?.staffId ?? 0);
        break;
      case 2:
        nextScreen = PayrollDashboardScreen(username: widget.username);
        break;
      case 3:
        nextScreen = ClaimDashboardScreen(
            username: widget.username,
            staffId:  _currentStaff?.staffId ?? 0);
        break;
      case 4:
        nextScreen = const StaffMySelfScreen();
        break;
      default: return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  Future<void> _logout() async => LogoutHelper.fullLogout(context);

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatShiftTimes(Schedule schedule) {
    if (schedule.workStartTime == null || schedule.workEndTime == null) {
      return 'Self clock-in';
    }
    return '${schedule.workStartTime} - ${schedule.workEndTime}';
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
      appBar: StaffAppBar(
        title: 'STAFF PORTAL',
        automaticallyImplyLeading: false,
        roundedBottom: false,
        actions: [
          if (_currentStaff != null &&
              UserRoles.hrAdmin.contains(_currentStaff!.usertype))
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Switch to Admin Mode',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminDashboardScreen(
                        username: widget.username)),
              ),
            ),

          // ✅ FIXED bell badge — reads dismissed IDs from SharedPreferences
          Consumer4<Leaves, Claims, Schedules, ScheduleExchanges>(
            builder: (context, leaves, claims, schedules,
                exchanges, child) {
              final staffId = _currentStaff?.staffId ?? 0;
              if (staffId == 0) {
                return const Icon(Icons.notifications_none_rounded);
              }

              return FutureBuilder<Map<String, Set<String>>>(
                future: _loadDismissedIds(staffId),
                builder: (context, snapshot) {
                  final dismissed = snapshot.data ?? {
                    'leaves':    <String>{},
                    'claims':    <String>{},
                    'schedules': <String>{},
                    'exchanges': <String>{},
                  };

                  final dismissedLeaves    = dismissed['leaves']!;
                  final dismissedClaims    = dismissed['claims']!;
                  final dismissedSchedules = dismissed['schedules']!;
                  final dismissedExchanges = dismissed['exchanges']!;

                  final totalNotifications =
                      leaves.leaves.where((l) =>
                          l.staffId == staffId &&
                          l.status != 'Pending' &&
                          !dismissedLeaves.contains(
                              l.leaveId.toString())).length +
                      claims.claims.where((c) =>
                          c.staffId == staffId &&
                          c.status != 'Pending' &&
                          !dismissedClaims.contains(
                              c.claimId.toString())).length +
                      schedules.schedules.where((s) =>
                          s.staffId == staffId &&
                          !dismissedSchedules.contains(
                              s.schedId.toString())).length +
                      exchanges.exchanges.where((e) =>
                          e.targetId == staffId &&
                          e.status == 0 &&
                          !dismissedExchanges.contains(
                              e.exchangeId.toString())).length +
                      exchanges.exchanges.where((e) =>
                          e.requesterId == staffId &&
                          e.status != 0 &&
                          !dismissedExchanges.contains(
                              e.exchangeId.toString())).length;

                  return IconButton(
                    icon: totalNotifications > 0
                        ? Badge(
                            label: Text(
                                totalNotifications.toString()),
                            backgroundColor: Colors.redAccent,
                            child: const Icon(
                                Icons.notifications_active_rounded))
                        : const Icon(
                            Icons.notifications_none_rounded),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StaffNotificationScreen(
                            staffId:     staffId,
                            isPartTimer: false,
                          ),
                        ),
                      );
                      if (result != null &&
                          result['refreshDashboard'] == true) {
                        await _loadStaffData();
                      }
                      // ✅ Force FutureBuilder to re-read
                      // SharedPreferences after returning
                      if (_mounted) setState(() {});
                    },
                  );
                },
              );
            },
          ),

          IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
              onPressed: _logout),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildDashboardContent(),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex:  _selectedIndex,
        onItemTapped:   _onItemTapped,
        showMyselfDot:  _isProfileIncomplete,
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Welcome header ───────────────────────────────────────────── (full-bleed, not width-capped)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
              top: 20, bottom: 28, left: 24, right: 24),
          decoration: BoxDecoration(
            color: staffPrimary,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${widget.username} !',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 16, color: Colors.indigo.shade200),
                const SizedBox(width: 6),
                Text(
                  lastLoginTime != null
                      ? 'Last Login: ${formatDateTime(lastLoginTime!)}'
                      : 'Last Login: Not available',
                  style: TextStyle(
                      color: Colors.indigo.shade100,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ],
          ),
        ),

        // ── Width-capped content below the banner ─────────────────────────
        Expanded(
          child: StaffPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Today's attendance card — clock in/out every day ─────
                _buildTodayAttendanceCard(),

                // ── Attendance history card ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffAttendanceHistoryScreen(
                          staffId:  _currentStaff?.staffId ?? 0,
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
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: staffPrimary.withOpacity(0.1),
                              shape: BoxShape.circle),
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Colors.grey.shade400),
                      ]),
                    ),
                  ),
                ),

                // ── Staff on leave today card ────────────────────────────
                _buildStaffOnLeaveCard(),

                Expanded(child: _buildSchedulesCards()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffOnLeaveCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Consumer<Leaves>(
        builder: (context, leavesProvider, _) {
          final today = DateTime.now();
          final todayOnly = DateTime(today.year, today.month, today.day);
          final onLeaveCount = leavesProvider.leaves.where((leave) {
            if (leave.status.trim().toLowerCase() != 'approved') return false;
            final start = DateTime(
                leave.startDate.year, leave.startDate.month, leave.startDate.day);
            final end = DateTime(
                leave.endDate.year, leave.endDate.month, leave.endDate.day);
            return !todayOnly.isBefore(start) && !todayOnly.isAfter(end);
          }).length;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StaffOnLeaveScreen(isAdmin: false)),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: staffCardBorder),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.beach_access_rounded,
                      color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Staff on Leave Today',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1E293B))),
                      Text(
                        onLeaveCount == 0
                            ? 'No one is on leave today'
                            : '$onLeaveCount staff currently on leave',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey.shade400),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayAttendanceCard() {
    Widget content;

    if (_isCheckingTodayAttendance || _isClockActionLoading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_todaySchedule != null && _todaySchedule!.acceptanceStatus == 2) {
      content = Row(children: [
        const Icon(Icons.block_rounded, color: Colors.redAccent),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Schedule not accepted — contact HR to clock in today.',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ]);
    } else if (_isClockedOutToday) {
      content = Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              'Shift completed! Clocked out at ${_todayClockOutTimeStr ?? "Unknown"}',
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ]);
    } else if (_isClockedInToday) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_todayClockInTimeStr != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Clocked in at $_todayClockInTimeStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
          if (_todayClockInLocationStr != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _openGoogleMaps(_todayClockInLocationStr!),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.location_pin, color: Colors.green, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_todayClockInLocationStr!,
                          style: const TextStyle(fontSize: 12, color: Colors.blue,
                              decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _handleDashboardClockOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Clock Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    } else {
      content = ElevatedButton.icon(
        onPressed: _handleDashboardClockIn,
        icon: const Icon(Icons.login_rounded),
        label: const Text('Clock In',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: staffPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: staffCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.today_rounded, color: staffPrimary, size: 20),
              const SizedBox(width: 8),
              const Text("Today's Attendance",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesCards() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: staffPrimary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 24, right: 24, top: 20, bottom: 4),
          child: Text('Your Assigned Shifts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B))),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 24, right: 24, bottom: 8),
          child: Text(
              'Assigned by HR for outstation trips or schedule swaps .',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadStaffData,
            child: _staffSchedules.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 240,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No assigned shifts',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 100, left: 16, right: 16),
                  itemCount: _staffSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule      = _staffSchedules[index];
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
                              Provider.of<Attendances>(context,
                                  listen: false);
                          final isClockIn = await attendanceProvider
                              .checkAttendance(
                                  staffId:
                                      _currentStaff?.staffId ?? 0,
                                  scheduleId: schedule.schedId);
                          if (!mounted) return;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StaffScheduleDetailsScreen(
                                location:         currentBranch,
                                workDate:         schedule.workDate,
                                assignedStaff:    [_currentStaff?.firstname ?? ''],
                                startTime:        schedule.workStartTime ?? '-',
                                endTime:          schedule.workEndTime ?? '-',
                                startBreak:       schedule.breakStartTime ?? '-',
                                endBreak:         schedule.breakEndTime ?? '-',
                                status:           isClockIn ? 'Clocked In' : 'Not clocked in',
                                scheduleId:       schedule.schedId,
                                staffId:          _currentStaff?.staffId ?? 0,
                                acceptanceStatus: schedule.acceptanceStatus,
                                staffNote:        schedule.staffNote,
                                staffUsertype:    _currentStaff?.usertype ?? 7,
                              ),
                            ),
                          );
                          if (result != null &&
                              result['refreshDashboard'] == true) {
                            await _loadStaffData();
                          }
                        },
                        child: Row(children: [
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                                vertical: 20),
                            decoration: BoxDecoration(
                              color: staffPrimary.withOpacity(0.08),
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16)),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                    _getMonthName(dateObj.month)
                                        .toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: staffPrimary)),
                                Text(dateObj.day.toString(),
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: staffPrimary)),
                              ],
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 60,
                              color: staffCardBorder),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(currentBranch,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color(0xFF1E293B))),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color:
                                            Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                          _formatShiftTimes(schedule),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.grey.shade600,
                                              fontWeight:
                                                  FontWeight.w500)),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: schedule
                                                  .acceptanceStatus ==
                                              1
                                          ? Colors.green
                                              .withOpacity(0.1)
                                          : schedule
                                                      .acceptanceStatus ==
                                                  2
                                              ? Colors.red
                                                  .withOpacity(0.1)
                                              : Colors.orange
                                                  .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      schedule.acceptanceStatus == 1
                                          ? '✅ Accepted'
                                          : schedule
                                                      .acceptanceStatus ==
                                                  2
                                              ? '❌ Not Accepted'
                                              : '⏳ Pending',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: schedule
                                                      .acceptanceStatus ==
                                                  1
                                              ? Colors.green
                                              : schedule.acceptanceStatus ==
                                                      2
                                                  ? Colors.red
                                                  : Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 16.0),
                            child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey.shade400),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }
}