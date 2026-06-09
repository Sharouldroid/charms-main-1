import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/internshipscreens/assessment_intern.dart';
import 'package:charms/internshipservices/intern_helper.dart'; // InternHelper + InternRegistration
import 'package:charms/utils/logout_helper.dart';
import 'schedule_calendar.dart';
import 'monitor_performance.dart';
import 'intern_list_assesstment.dart';
import 'admin_submissions.dart';
import 'docs_upload.dart';
import 'registration_status.dart';
import 'intern_myself_screen.dart';
import 'package:charms/internshipproviders/internship_notification_provider.dart';
import 'package:charms/internshipscreens/internship_notification_screen.dart';
import 'intern_timeline_screen.dart';
import 'package:charms/internshipscreens/slot_details_screen.dart';
import 'package:charms/internshipproviders/InternAttendanceProvider.dart';
import 'package:charms/internshipscreens/InternAttendanceHistoryScreen.dart';
import 'package:charms/internshipscreens/admin_intern_attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final String role;
  final int userId;
 
  const DashboardScreen({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
  });
 
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
 
class _DashboardScreenState extends State<DashboardScreen> {
  Staff? _currentStaff;
  bool _isLoading = true;
  String _profilePicture = 'assets/profilepicture.png';
 
  // ── Attendance state (Intern only) ─────────────────────────────────────
  bool _isClockIn = false;
  bool _isClockOut = false;
  bool _isAttendanceLoading = false;
  String? _clockInLocationStr;
  String? _clockOutTimeStr;
  // The schedule the intern is currently registered for (today's schedule)
  // We resolve this lazily when the FAB sheet opens.
  int? _activeScheduleId;
 
  @override
  void initState() {
    super.initState();
    _loadStaffData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternshipNotificationProvider>().fetchUnreadCount(
        widget.userId,
        widget.role == 'Admin',
      );
    });
  }
 
  // ── Load staff / profile picture ───────────────────────────────────────
  Future<void> _loadStaffData() async {
    try {
      final staffsProvider = context.read<Staffs>();
      await staffsProvider.fetchStaff();
 
      final matches = staffsProvider.staffList
          .where((s) => s.userId == widget.userId)
          .toList();
 
      if (matches.isNotEmpty) {
        _currentStaff = matches.first;
        if (_currentStaff!.filepath != null &&
            _currentStaff!.filepath!.isNotEmpty) {
          _profilePicture =
              'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}';
        }
      }
    } catch (error) {
      debugPrint('Error loading staff data: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  Future<void> _logout(BuildContext context) async {
    await LogoutHelper.fullLogout(context);
  }
 
  // ── GPS helpers (same pattern as StaffScheduleDetailsScreen) ───────────
  Future<String?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
 
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
 
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('GPS error: $e');
      return null;
    }
  }
 
  Future<String?> _getPlaceName(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final response =
          await http.get(url, headers: {'User-Agent': 'charms-app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name']?.toString();
      }
    } catch (_) {}
    return null;
  }
 
  Future<String?> _buildDisplayLocation() async {
    final coords = await _getCurrentLocation();
    if (coords == null) return null;
 
    String display = coords;
    final parts = coords.split(', ');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        final place = await _getPlaceName(lat, lng);
        if (place != null) display = '$place\n($coords)';
      }
    }
    return display;
  }
 
  // ── Resolve today's active schedule for the intern ─────────────────────
  Future<int?> _resolveActiveScheduleId() async {
    // We call InternHelper to get intern_id, then check today's registrations.
    // Resolved lazily in _handleClockIn via InternHelper.getActiveRegistration
    return null;
  }
 
  // ── FAB: Clock In / Out bottom sheet ───────────────────────────────────
  void _showAttendanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AttendanceBottomSheet(
        userId: widget.userId,
        isClockIn: _isClockIn,
        isClockOut: _isClockOut,
        clockInLocationStr: _clockInLocationStr,
        clockOutTimeStr: _clockOutTimeStr,
        onClockIn: _handleClockIn,
        onClockOut: _handleClockOut,
        onViewHistory: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  InternAttendanceHistoryScreen(userId: widget.userId),
            ),
          );
        },
        isLoading: _isAttendanceLoading,
      ),
    );
  }
 
  Future<void> _handleClockIn() async {
    setState(() => _isAttendanceLoading = true);
 
    try {
      // 1. Resolve the active registration → gets both intern_id and schedule_id
      final reg = await InternHelper.getActiveRegistration(widget.userId);
      if (reg == null || reg.scheduleId == null) {
        _showSnack('⚠️ Please complete your registration first.', Colors.orange);
        return;
      }
 
      // 2. Show location snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Detecting your location...'),
          ]),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blueGrey,
        ));
      }
 
      // 3. Get GPS + reverse geocode
      final locationStr = await _buildDisplayLocation();
 
      // 4. Clock in with correct intern_id (internRegister.id) and schedule_id
      final provider = context.read<InternAttendanceProvider>();
      final result = await provider.clockIn(
        userId: widget.userId,
        scheduleId: reg.scheduleId!, // internRegister.schedule_id → internship_schedules.id
        clockInTime: DateTime.now().toIso8601String(),
        clockInLocation: locationStr,
      );
 
      if (result['success'] == true) {
        setState(() {
          _isClockIn = true;
          _clockInLocationStr = locationStr;
          _activeScheduleId = reg.scheduleId;
        });
        _showSnack('✅ Clocked in successfully!', Colors.green);
        if (mounted) Navigator.pop(context); // close sheet
      } else {
        _showSnack('❌ ${result['message'] ?? 'Failed to clock in.'}', Colors.red);
      }
    } catch (e) {
      _showSnack('❌ Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }
 
  Future<void> _handleClockOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clock Out'),
        content: const Text('Are you sure you want to clock out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clock Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
 
    setState(() => _isAttendanceLoading = true);
    try {
      // Use cached schedule_id if available, otherwise re-resolve
      int? scheduleId = _activeScheduleId;
      if (scheduleId == null) {
        final reg = await InternHelper.getActiveRegistration(widget.userId);
        if (reg == null || reg.scheduleId == null) {
          _showSnack('⚠️ No active registration found.', Colors.orange);
          return;
        }
        scheduleId = reg.scheduleId!;
      }
 
      final now = DateTime.now();
      final provider = context.read<InternAttendanceProvider>();
      final result = await provider.clockOut(
        userId: widget.userId,
        scheduleId: scheduleId,
        clockOutTime: now.toIso8601String(),
      );
 
      if (result['success'] == true) {
        setState(() {
          _isClockOut = true;
          _clockOutTimeStr = DateFormat('hh:mm a').format(now.toLocal());
        });
        _showSnack('✅ Clocked out successfully!', Colors.green);
        if (mounted) Navigator.pop(context); // close sheet
      } else {
        _showSnack('❌ ${result['message'] ?? 'Failed to clock out.'}', Colors.red);
      }
    } catch (e) {
      _showSnack('❌ Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }
 
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }
 
  // ── Navigation helpers (unchanged from original) ───────────────────────
  Future<void> _navigateToDocumentUpload() async {
    if (widget.role != 'Intern') return;
    _showLoading();
    try {
      final internId = await InternHelper.getInternIdByUserId(widget.userId);
      if (mounted) Navigator.pop(context);
      if (internId != null) {
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) =>
                DocsUpload(userId: internId, scheduleId: null),
          ));
        }
      } else {
        _showSnack('⚠️ Please complete your registration first.', Colors.orange);
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) =>
                ScheduleCalendar(isAdmin: false, userId: widget.userId),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('❌ Error: $e', Colors.red);
      }
    }
  }
 
  Future<void> _navigateToMonitorPerformance() async {
    if (widget.role == 'Intern') {
      _showLoading();
      try {
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        if (mounted) Navigator.pop(context);
        if (internId != null) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => MonitorPerformancePage(
                  role: widget.role, userId: widget.userId),
            ));
          }
        } else {
          _showSnack(
              '⚠️ Please complete your registration first.', Colors.orange);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          _showSnack('❌ Error: $e', Colors.red);
        }
      }
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) =>
            MonitorPerformancePage(role: widget.role, userId: widget.userId),
      ));
    }
  }
 
  Future<void> _navigateToAssessment() async {
    if (widget.role == 'Intern') {
      _showLoading();
      try {
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        if (mounted) Navigator.pop(context);
        if (internId != null) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AssessmentInternPage(
                  internId: widget.userId, isAdmin: false),
            ));
          }
        } else {
          _showSnack(
              '⚠️ Please complete your registration first.', Colors.orange);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          _showSnack('❌ Error: $e', Colors.red);
        }
      }
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) =>
            AssessmentInternPage(internId: widget.userId, isAdmin: true),
      ));
    }
  }
 
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
 
  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: const Text('Loading...'),
            backgroundColor: Colors.blueAccent),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 20),
              Text('Loading Dashboard...',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
 
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.role} Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Notification bell
          Consumer<InternshipNotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded,
                        color: Colors.white),
                    tooltip: 'Notifications',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InternshipNotificationScreen(
                            userId: widget.userId,
                            isAdmin: widget.role == 'Admin',
                          ),
                        ),
                      );
                      if (mounted) {
                        context
                            .read<InternshipNotificationProvider>()
                            .fetchUnreadCount(
                                widget.userId, widget.role == 'Admin');
                      }
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        child: Text(
                          notifProvider.unreadCount > 99
                              ? '99+'
                              : '${notifProvider.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 254, 251, 251),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blueAccent,
                      Color.fromARGB(255, 123, 64, 251)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        (_currentStaff?.filepath != null &&
                                _currentStaff!.filepath!.isNotEmpty)
                            ? CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    Colors.blueAccent.withOpacity(0.12),
                                backgroundImage: NetworkImage(
                                    'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}'),
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    Colors.blueAccent.withOpacity(0.12),
                                child: const Icon(Icons.person_rounded,
                                    size: 52, color: Colors.blueAccent),
                              ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.username,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text(widget.role,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
 
              // Dashboard buttons
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blueAccent,
                      Color.fromARGB(255, 123, 64, 251)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        children: _buildDashboardButtons(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
 
      // ── FAB: Attendance (Intern only) ────────────────────────────────
      floatingActionButton: widget.role == 'Intern'
          ? FloatingActionButton.extended(
              onPressed: _showAttendanceSheet,
              backgroundColor: Colors.blueAccent,
              icon: Icon(
                _isClockOut
                    ? Icons.check_circle_rounded
                    : _isClockIn
                        ? Icons.logout_rounded
                        : Icons.login_rounded,
                color: Colors.white,
              ),
              label: Text(
                _isClockOut
                    ? 'Completed'
                    : _isClockIn
                        ? 'Clock Out'
                        : 'Clock In',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
 
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Schedule'),
          if (widget.role == 'Intern')
            const BottomNavigationBarItem(
                icon: Icon(Icons.timeline), label: 'Timeline')
          else
            const BottomNavigationBarItem(
                icon: Icon(Icons.feedback), label: 'Slot Details'),
        ],
        selectedItemColor: Colors.blueAccent,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ScheduleCalendar(
                  isAdmin: widget.role == 'Admin',
                  userId: widget.userId,
                ),
              ));
              break;
            case 2:
              if (widget.role == 'Intern') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) =>
                      InternTimelineScreen(userId: widget.userId),
                ));
              } else {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SlotDetailsScreen(),
                ));
              }
              break;
          }
        },
      ),
    );
  }
 
  List<Widget> _buildDashboardButtons(BuildContext context) {
    final buttons = <Widget>[];
 
    if (widget.role == 'Admin') {
      buttons.addAll([
        _buildDashboardButton(context, 'Create Schedule', Icons.calendar_today,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) =>
                ScheduleCalendar(isAdmin: true, userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Intern List', Icons.person_add, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const InternListPage(),
          ));
        }),
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MonitorPerformancePage(
                role: widget.role, userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AssessmentListPage(),
          ));
        }),
        _buildDashboardButton(context, 'Intern Submissions', Icons.assignment,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AdminSubmissionsPage(adminId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Attendance', Icons.fingerprint_rounded,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AdminInternAttendanceScreen(),
          ));
        }),
      ]);
    } else if (widget.role == 'Intern') {
      buttons.addAll([
        _buildDashboardButton(context, 'Register', Icons.calendar_today, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) =>
                ScheduleCalendar(isAdmin: false, userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Activity Logs', Icons.monitor, () {
          _navigateToMonitorPerformance();
        }),
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          _navigateToAssessment();
        }),
        _buildDashboardButton(context, 'Check Status', Icons.check_circle,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => RegistrationStatusPage(userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Upload Documents', Icons.upload_file,
            () {
          _navigateToDocumentUpload();
        }),
        _buildDashboardButton(context, 'My Profile', Icons.account_circle,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => InternMySelfScreen(
              userId: widget.userId,
              username: widget.username,
            ),
          ));
        }),
      ]);
    }
 
    return buttons;
  }
 
  Widget _buildDashboardButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    final buttonWidth = (MediaQuery.of(context).size.width / 3) - 32;
    const buttonHeight = 120.0;
 
    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.blueAccent,
            elevation: 3,
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
// ── Attendance Bottom Sheet ────────────────────────────────────────────────
class _AttendanceBottomSheet extends StatelessWidget {
  final int userId;
  final bool isClockIn;
  final bool isClockOut;
  final String? clockInLocationStr;
  final String? clockOutTimeStr;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onViewHistory;
  final bool isLoading;
 
  const _AttendanceBottomSheet({
    required this.userId,
    required this.isClockIn,
    required this.isClockOut,
    required this.clockInLocationStr,
    required this.clockOutTimeStr,
    required this.onClockIn,
    required this.onClockOut,
    required this.onViewHistory,
    required this.isLoading,
  });
 
  static const Color _primaryBlue = Color(0xFF2563EB);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
 
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: _primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Attendance',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
 
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(_statusIcon, color: _statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusText,
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ]),
          ),
 
          // Clock-in location display
          if (isClockIn && clockInLocationStr != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clockInLocationStr!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black87),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
 
          const SizedBox(height: 20),
 
          // Action button
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!isClockIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onClockIn,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Clock In',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else if (!isClockOut)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onClockOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Clock Out',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    'Shift complete! Clocked out at ${clockOutTimeStr ?? "—"}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
 
          const SizedBox(height: 12),
 
          // View History button (always visible)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: BorderSide(color: _primaryBlue.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onViewHistory,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('View Attendance History',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
 
  Color get _statusColor {
    if (isClockOut) return Colors.green;
    if (isClockIn) return Colors.orange;
    return Colors.blueGrey;
  }
 
  IconData get _statusIcon {
    if (isClockOut) return Icons.check_circle_rounded;
    if (isClockIn) return Icons.radio_button_checked_rounded;
    return Icons.access_time_rounded;
  }
 
  String get _statusText {
    if (isClockOut) return 'Shift completed — you have clocked out.';
    if (isClockIn) return 'Currently clocked in — remember to clock out!';
    return 'Not yet clocked in today.';
  }
}