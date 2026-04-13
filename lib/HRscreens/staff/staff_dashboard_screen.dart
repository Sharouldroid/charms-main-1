import 'package:charms/HRproviders/attendances.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRscreens/staff/staff_schedule_details_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';

class StaffDashboardScreen extends StatefulWidget {
  final String username;

  const StaffDashboardScreen({Key? key, required this.username})
      : super(key: key);

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

      await staffsProvider.fetchStaff();

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
            lastLoginTime = DateTime.now(); // fast compile fix
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
      if (_mounted) {
        setState(() => _isLoading = false);
      }
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
        nextScreen = StaffMySelfScreen();
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
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
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
      extendBody: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text('CHARMS STAFF', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Dashboard',
            onPressed: _logout,
          ),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "Welcome, ${_currentStaff?.firstname ?? widget.username}!",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            lastLoginTime != null
                ? "Last Login: ${formatDateTime(lastLoginTime!)}"
                : "Last Login: Not available",
          ),
          const SizedBox(height: 20),
          _buildSchedulesCards(),
        ],
      ),
    );
  }

  Widget _buildSchedulesCards() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      height: 800,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "   Your Schedules:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          _staffSchedules.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'No schedules found',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _staffSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = _staffSchedules[index];
                      final currentBranch = getBranchName(schedule.workLocation);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(5.0),
                        child: ListTile(
                          leading: const Icon(Icons.location_on_outlined, size: 30, color: Colors.blue),
                          title: Text(
                            currentBranch,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Date: ${schedule.workDate.toString().split(' ')[0]}\n'
                            'Time: ${schedule.workStartTime} - ${schedule.workEndTime}',
                          ),
                          onTap: () async {
                            final attendanceProvider =
                                Provider.of<Attendances>(context, listen: false);

                            final isClockIn = await attendanceProvider.checkAttendance(
                              staffId: _currentStaff?.staffId ?? 0,
                              scheduleId: schedule.schedId,
                            );

                            if (!mounted) return;

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StaffScheduleDetailsScreen(
                                  location: currentBranch,
                                  workDate: schedule.workDate,
                                  assignedStaff: [_currentStaff?.firstname ?? ''],
                                  startTime: schedule.workStartTime.toString(),
                                  endTime: schedule.workEndTime.toString(),
                                  startBreak: schedule.breakStartTime.toString(),
                                  endBreak: schedule.breakEndTime.toString(),
                                  status: isClockIn ? 'Clocked In' : 'Not clocked in',
                                  scheduleId: schedule.schedId,
                                  staffId: _currentStaff?.staffId ?? 0,
                                ),
                              ),
                            );

                            if (result != null && result['refreshDashboard'] == true) {
                              await _loadStaffData();
                            }
                          },
                          trailing: const Icon(Icons.arrow_forward_ios, size: 30, color: Colors.blue),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}