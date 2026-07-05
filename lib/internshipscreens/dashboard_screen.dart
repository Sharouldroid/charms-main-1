import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/internshipscreens/assessment_intern.dart';
import 'package:charms/internshipservices/intern_helper.dart';
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
import 'package:charms/internshipproviders/schedule_provider.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'package:charms/internshipservices/schedule_service.dart';
import 'package:charms/internshipscreens/offer_letter_screen.dart';
import 'package:charms/internshipscreens/intern_history_screen.dart';
import 'package:charms/main.dart';
import 'package:charms/internshipproviders/interview_session_provider.dart';
import 'package:charms/internshipmodels/interview_session.dart';
import 'package:charms/internshipscreens/interview_session_picker_screen.dart';
import 'package:charms/internshipscreens/interview_session_admin_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int? _activeScheduleId;
  bool _needsScheduleRegistration = false;

  // ── Available Schedules card state (Intern only) ────────────────────────
  List<Schedule> _availableSchedules = [];
  Map<int, Map<String, dynamic>> _scheduleRegCounts = {};
  bool _schedulesLoading = true;

  // ── Interview session state (Intern only) ───────────────────────────────
  InterviewSession? _mySession;
  bool _needsInterviewBooking = false;
  bool _interviewLoading = true;

  // ── Interview session overview (Admin/Supervisor only) ──────────────────
  int _upcomingInterviewCount = 0;
  int _awaitingLinkCount = 0;
  bool _interviewOverviewLoading = true;

  // ── Design tokens ───────────────────────────────────────────────────────
  static const Color _gradientStart = Colors.blueAccent;
  static const Color _gradientEnd = Color(0xFF7B40FB);

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternshipNotificationProvider>().fetchUnreadCount(
        widget.userId,
        widget.role == 'Admin' || widget.role == 'Supervisor',
      );
      if (widget.role == 'Intern') {
        _checkAttendanceState();
        _loadAvailableSchedules();
        _loadMyInterviewSession();
      }
      if (widget.role == 'Admin' || widget.role == 'Supervisor') {
        _loadInterviewOverview();
      }
    });
  }

  // ── Load the intern's own interview session (Intern only) ──────────────
  Future<void> _loadMyInterviewSession() async {
    try {
      final provider = context.read<InterviewSessionProvider>();
      await provider.loadMySession(widget.userId);
      if (mounted) {
        setState(() {
          _mySession = provider.mySession;
          _needsInterviewBooking = _mySession == null;
          _interviewLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading interview session: $e');
      if (mounted) setState(() => _interviewLoading = false);
    }
  }

  // ── Load interview session overview counts (Admin/Supervisor only) ─────
  Future<void> _loadInterviewOverview() async {
    try {
      final provider = context.read<InterviewSessionProvider>();
      await provider.loadAllSessions();
      final booked = provider.allSessions.where((s) => s.isBooked).toList();
      if (mounted) {
        setState(() {
          _upcomingInterviewCount = booked.length;
          _awaitingLinkCount = booked
              .where((s) => s.meetingLink == null || s.meetingLink!.isEmpty)
              .length;
          _interviewOverviewLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading interview overview: $e');
      if (mounted) setState(() => _interviewOverviewLoading = false);
    }
  }

  // ── Check existing attendance state from backend ───────────────────────
  Future<void> _checkAttendanceState() async {
    try {
      final reg = await InternHelper.getActiveRegistration(widget.userId);
      if (mounted) {
        setState(() {
          _needsScheduleRegistration = reg == null || reg.scheduleId == null;
        });
      }
      if (reg == null || reg.scheduleId == null) return;

      final provider = context.read<InternAttendanceProvider>();
      final result = await provider.checkAttendance(
        userId: widget.userId,
        scheduleId: reg.scheduleId!,
      );

      if (mounted) {
        setState(() {
          _isClockIn  = result['has_clocked_in']  == true;
          _isClockOut = result['has_clocked_out'] == true;
          _clockInLocationStr = result['clock_in_location']?.toString();
          _activeScheduleId   = reg.scheduleId;

          if (_isClockOut && result['clock_out_time'] != null) {
            final t = DateTime.tryParse(result['clock_out_time'].toString());
            if (t != null) {
              _clockOutTimeStr = DateFormat('hh:mm a').format(t.toLocal());
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking attendance state: $e');
    }
  }

  // ── Load available schedules (Intern only) ──────────────────────────────
  Future<void> _loadAvailableSchedules() async {
    try {
      final provider = context.read<ScheduleProvider>();
      await provider.loadSchedules();

      final now = DateTime.now();
      final upcoming = provider.schedules
          .where((s) =>
              s.endDate.isAfter(now.subtract(const Duration(days: 1))))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      final shortlist = upcoming.take(4).toList();
      final counts = <int, Map<String, dynamic>>{};
      final service = ScheduleService(baseUrl: AppConfig.hostname);
      for (final s in shortlist) {
        counts[s.id] = await service.checkRegistrationLimit(s.id);
      }

      if (mounted) {
        setState(() {
          _availableSchedules = shortlist;
          _scheduleRegCounts = counts;
          _schedulesLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading available schedules: $e');
      if (mounted) setState(() => _schedulesLoading = false);
    }
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

  // ── GPS helpers ────────────────────────────────────────────────────────
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

  // ── FAB: Clock In / Out bottom sheet ───────────────────────────────────
  void _showAttendanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_isAttendanceLoading,
      enableDrag: !_isAttendanceLoading,
      builder: (ctx) => _AttendanceBottomSheet(
        userId: widget.userId,
        isClockIn: _isClockIn,
        isClockOut: _isClockOut,
        clockInLocationStr: _clockInLocationStr,
        clockOutTimeStr: _clockOutTimeStr,
        onClockIn: () => _handleClockIn(ctx),
        onClockOut: () => _handleClockOut(ctx),
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

  Future<void> _handleClockIn(BuildContext sheetCtx) async {
    setState(() => _isAttendanceLoading = true);

    try {
      final reg = await InternHelper.getActiveRegistration(widget.userId);
      if (reg == null || reg.scheduleId == null) {
        _showSnack('⚠️ Please complete your registration first.', Colors.orange);
        return;
      }

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

      final locationStr = await _buildDisplayLocation();

      final provider = context.read<InternAttendanceProvider>();
      final result = await provider.clockIn(
        userId: widget.userId,
        scheduleId: reg.scheduleId!,
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
        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      } else {
        _showSnack('❌ ${result['message'] ?? 'Failed to clock in.'}', Colors.red);
      }
    } catch (e) {
      _showSnack('❌ Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }

  Future<void> _handleClockOut(BuildContext sheetCtx) async {
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
        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
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

  // ── Navigation helpers ─────────────────────────────────────────────────
  Future<void> _navigateToDocumentUpload() async {
    if (widget.role != 'Intern') return;
    _showLoading();
    try {
      final internId = await InternHelper.getInternIdByUserId(widget.userId);
      if (mounted) Navigator.pop(context);
      if (internId != null) {
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DocsUpload(userId: widget.userId, scheduleId: null),
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
          _showSnack('⚠️ Please complete your registration first.', Colors.orange);
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
                  internId: widget.userId, canAssess: false),
            ));
          }
        } else {
          _showSnack('⚠️ Please complete your registration first.', Colors.orange);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          _showSnack('❌ Error: $e', Colors.red);
        }
      }
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AssessmentInternPage(
          internId: widget.userId,
          canAssess: widget.role == 'Supervisor',
        ),
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

    if (widget.role == 'Supervisor') return _buildSupervisorScaffold();
    if (widget.role == 'Admin') return _buildAdminScaffold();
    if (widget.role == 'Intern') return _buildInternScaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text('${widget.role} Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
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
                            isAdmin: widget.role == 'Admin' || widget.role == 'Supervisor',
                          ),
                        ),
                      );
                      if (mounted) {
                        context
                            .read<InternshipNotificationProvider>()
                            .fetchUnreadCount(
                                widget.userId, widget.role == 'Admin' || widget.role == 'Supervisor');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Profile card ─────────────────────────────────────────────
            _buildProfileCard(),
            const SizedBox(height: 20),

            // ── Dashboard buttons ────────────────────────────────────────
            _buildDashboardButtonsCard(),

            // ── Available Schedules card (Intern only) ───────────────────
            if (widget.role == 'Intern') ...[
              const SizedBox(height: 20),
              _buildAvailableSchedulesCard(),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: widget.role == 'Intern'
            ? <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                    icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(
                    _isClockOut
                        ? Icons.check_circle_rounded
                        : _isClockIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                  ),
                  label: _isClockOut
                      ? 'Completed'
                      : _isClockIn
                          ? 'Clock Out'
                          : 'Clock In',
                ),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.timeline), label: 'Timeline'),
              ]
            : <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                    icon: Icon(Icons.home), label: 'Home'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.schedule), label: 'Schedule'),
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
              if (widget.role == 'Intern') {
                _showAttendanceSheet();
              } else {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ScheduleCalendar(
                    isAdmin: widget.role != 'Intern',
                    userId: widget.userId,
                  ),
                ));
              }
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

  // ── Profile card ───────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            (_currentStaff?.filepath != null &&
                    _currentStaff!.filepath!.isNotEmpty)
                ? CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}'),
                  )
                : CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person_rounded,
                        size: 38, color: Colors.white),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(widget.role,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dashboard buttons card ─────────────────────────────────────────────
  Widget _buildDashboardButtonsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: _buildDashboardButtons(context),
        ),
      ),
    );
  }

  List<Widget> _buildDashboardButtons(BuildContext context) {
    final buttons = <Widget>[];

    if (widget.role == 'Supervisor') {
      buttons.addAll([
        _buildDashboardButton(context, 'Intern List', Icons.people_rounded, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const InternListPage(canAssess: true),
          ));
        }),
        _buildDashboardButton(context, 'Intern History', Icons.history_rounded, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => InternHistoryScreen(
              role: widget.role,
              userId: widget.userId,
            ),
          ));
        }),
        // _buildDashboardButton(context, 'Activity Logs', Icons.monitor_rounded, () {
        //   Navigator.push(context, MaterialPageRoute(
        //     builder: (_) => MonitorPerformancePage(
        //       role: 'Admin',
        //       userId: widget.userId,
        //     ),
        //   ));
        // }),
        // _buildDashboardButton(context, 'Assessment', Icons.assignment_rounded, () {
        //   Navigator.push(context, MaterialPageRoute(
        //     builder: (_) => AssessmentInternPage(
        //       internId: widget.userId,
        //       canAssess: true,
        //     ),
        //   ));
        // }),
        _buildDashboardButton(context, 'Attendance', Icons.fingerprint_rounded, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AdminInternAttendanceScreen(),
          ));
        }),
        _buildDashboardButton(context, 'Submissions', Icons.assignment_turned_in_rounded, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AdminSubmissionsPage(adminId: widget.userId),
          ));
        }),
      ]);
    } else if (widget.role == 'Admin') {
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
            builder: (_) => const InternListPage(canAssess: false),
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
        _buildDashboardButton(context, 'Intern History', Icons.history_rounded,
            () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => InternHistoryScreen(
              role: widget.role,
              userId: widget.userId,
            ),
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
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => MonitorPerformancePage(
              role: widget.role,
              userId: widget.userId,
            ),
          ));
        }),
        _buildDashboardButton(context, 'Check Status', Icons.check_circle, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => RegistrationStatusPage(userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Upload Resume', Icons.upload_file, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => DocsUpload(
              userId: widget.userId,
              scheduleId: null,
            ),
          ));
        }),
        _buildDashboardButton(context, 'My Profile', Icons.account_circle, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => InternMySelfScreen(
              userId: widget.userId,
              username: widget.username,
            ),
          ));
        }),
        _buildDashboardButton(context, 'Offer Letter', Icons.description_rounded, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => OfferLetterScreen(
              userId: widget.userId,
              role: widget.role,
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
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

  // ── Available Schedules card (Intern only) ──────────────────────────────
  Widget _buildAvailableSchedulesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_gradientStart, _gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Available Schedules',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) =>
                      ScheduleCalendar(isAdmin: false, userId: widget.userId),
                )),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View All',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ]),
              ),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 20, thickness: 0.8),
          ),

          // ── Card body ──────────────────────────────────────────────────
          if (_schedulesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          else if (_availableSchedules.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(children: [
                Icon(Icons.calendar_month_outlined,
                    size: 44, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(
                  'No schedules available right now.',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back later or tap View All.',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                  children: _availableSchedules
                      .map(_buildScheduleRow)
                      .toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(Schedule s) {
    final countData = _scheduleRegCounts[s.id];
    final current =
        (countData?['currentRegistrations'] as num?)?.toInt() ?? 0;
    final max = (countData?['maxRegistrations'] as num?)?.toInt() ?? 5;
    final spotsLeft = max - current;
    final isFull = spotsLeft <= 0;

    // ── Status label logic ─────────────────────────────────────────────
    // Show "Available" / "Almost Full" / "Full" — never raw slot count
    final String statusLabel;
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;

    if (isFull) {
      statusLabel = 'Full';
      statusColor = const Color(0xFFE53935);
      statusBg    = const Color(0xFFFFEBEE);
      statusIcon  = Icons.block_rounded;
    } else if (spotsLeft <= 3) {
      statusLabel = 'Almost Full';
      statusColor = const Color(0xFFF57C00);
      statusBg    = const Color(0xFFFFF3E0);
      statusIcon  = Icons.warning_amber_rounded;
    } else {
      statusLabel = 'Available';
      statusColor = const Color(0xFF2E7D32);
      statusBg    = const Color(0xFFE8F5E9);
      statusIcon  = Icons.check_circle_rounded;
    }

    final startFmt =
        DateFormat('EEE, dd MMM yyyy').format(s.startDate.toLocal());
    final endFmt = DateFormat('dd MMM yyyy').format(s.endDate.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) =>
              ScheduleCalendar(isAdmin: false, userId: widget.userId),
        )),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.blueAccent.withOpacity(0.1), width: 1),
          ),
          child: Row(children: [
            // ── Date badge ───────────────────────────────────────────────
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Text(
                  DateFormat('dd').format(s.startDate.toLocal()),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.1),
                ),
                Text(
                  DateFormat('MMM').format(s.startDate.toLocal()),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.2),
                ),
              ]),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.date_range_rounded,
                        size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '$startFmt – $endFmt',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Status chip ──────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Interview Session info card (Intern only) ───────────────────────────
  Future<void> _openInterviewLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open link', Colors.red);
    }
  }

  Widget _buildInterviewInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_gradientStart, _gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Interview Session',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) =>
                        InterviewSessionPickerScreen(userId: widget.userId),
                  ));
                  _loadMyInterviewSession();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_mySession == null ? 'Book Now' : 'View',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ]),
              ),
            ]),
            const Divider(height: 20, thickness: 0.8),
            if (_interviewLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (_mySession == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(children: [
                  Icon(Icons.event_busy_rounded, size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t booked an interview session yet.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This is required before your resume can be approved.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ]),
              )
            else
              Builder(builder: (context) {
                final session = _mySession!;
                final hasLink =
                    session.meetingLink != null && session.meetingLink!.isNotEmpty;
                final statusColor =
                    session.isCompleted ? Colors.green : Colors.blueAccent;
                final dateFmt =
                    DateFormat('EEE, dd MMM yyyy').format(session.date.toLocal());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.calendar_month, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(dateFmt, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text('${session.startTime}–${session.endTime}',
                          style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          session.isCompleted ? 'COMPLETED' : 'BOOKED',
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    if (hasLink)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openInterviewLink(session.meetingLink!),
                          icon: const Icon(Icons.videocam_rounded, size: 16),
                          label: const Text('Join Interview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Meeting link will appear here once your interviewer adds it.',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                            ),
                          ),
                        ]),
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Interview Session overview card (Admin/Supervisor only) ─────────────
  Widget _buildInterviewOverviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Interview Sessions',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const InterviewSessionAdminScreen(),
                  ));
                  _loadInterviewOverview();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Manage',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ]),
              ),
            ]),
            const Divider(height: 20, thickness: 0.8),
            if (_interviewOverviewLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else
              Row(children: [
                Expanded(
                  child: _overviewStat(
                    'Booked',
                    _upcomingInterviewCount.toString(),
                    Icons.event_available_rounded,
                    Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _overviewStat(
                    'Awaiting Link',
                    _awaitingLinkCount.toString(),
                    Icons.link_off_rounded,
                    Colors.orange,
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _overviewStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ]),
    );
  }

  // ── Supervisor Dashboard ───────────────────────────────────────────────

  Widget _buildSupervisorScaffold() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1E3A8A),
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Dashboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            actions: [
              _buildSupervisorNotifBell(),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white70, size: 22),
                tooltip: 'Logout',
                onPressed: () => _logout(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildSupervisorHero(greeting, dateStr),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSupervisorBody(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _buildInterviewOverviewCard(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSupervisorBottomNav(),
    );
  }

  Widget _buildSupervisorNotifBell() {
    return Consumer<InternshipNotificationProvider>(
      builder: (context, notifProvider, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: 'Notifications',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InternshipNotificationScreen(
                      userId: widget.userId,
                      isAdmin: true,
                    ),
                  ),
                );
                if (mounted) {
                  context
                      .read<InternshipNotificationProvider>()
                      .fetchUnreadCount(widget.userId, true);
                }
              },
            ),
            if (notifProvider.unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    notifProvider.unreadCount > 99
                        ? '99+'
                        : '${notifProvider.unreadCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSupervisorHero(String greeting, String dateStr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (_currentStaff?.filepath != null &&
                    _currentStaff!.filepath!.isNotEmpty)
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}'),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 30),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(widget.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Text('Supervisor',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(dateStr,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Management Tools',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text('Tap a card to get started',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          const SizedBox(height: 20),
          _buildSupervisorCard(
            title: 'Intern List',
            subtitle: 'View, manage and assess your intern roster',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            tag: 'Roster',
            tagColor: const Color(0xFF2563EB),
            tagBg: const Color(0xFFEFF6FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const InternListPage(canAssess: true),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Attendance',
            subtitle: 'Track and monitor daily intern attendance records',
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            tag: 'Records',
            tagColor: const Color(0xFF059669),
            tagBg: const Color(0xFFECFDF5),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AdminInternAttendanceScreen(),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Submissions',
            subtitle: 'Review and evaluate intern document submissions',
            icon: Icons.assignment_turned_in_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            tag: 'Resumes',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFF5F3FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AdminSubmissionsPage(adminId: widget.userId),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Interview Sessions',
            subtitle: 'Create interview slots and manage bookings',
            icon: Icons.event_note_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            tag: 'Interview',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFF5F3FF),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => const InterviewSessionAdminScreen(),
              ));
              _loadInterviewOverview();
            },
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Intern History',
            subtitle: 'View past batches and historical document submissions',
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF0891B2),
            iconBg: const Color(0xFFCFFAFE),
            tag: 'History',
            tagColor: const Color(0xFF0891B2),
            tagBg: const Color(0xFFECFEFF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => InternHistoryScreen(
                role: widget.role,
                userId: widget.userId,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required VoidCallback onTap,
    bool showAlert = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: showAlert
            ? Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  if (showAlert)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.priority_high_rounded,
                            color: Colors.white, size: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  color: tagColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1), size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Admin Dashboard ───────────────────────────────────────────────────

  Widget _buildAdminScaffold() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1E3A8A),
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Dashboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            actions: [
              _buildSupervisorNotifBell(),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white70, size: 22),
                tooltip: 'Logout',
                onPressed: () => _logout(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildAdminHero(greeting, dateStr),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildAdminBody(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _buildInterviewOverviewCard(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSupervisorBottomNav(),
    );
  }

  Widget _buildAdminHero(String greeting, String dateStr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (_currentStaff?.filepath != null &&
                    _currentStaff!.filepath!.isNotEmpty)
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}'),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 30),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(widget.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text('Admin',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(dateStr,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Management Tools',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text('Tap a card to get started',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          const SizedBox(height: 20),
          _buildSupervisorCard(
            title: 'Create Schedule',
            subtitle: 'Set up and manage internship schedules',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            tag: 'Calendar',
            tagColor: const Color(0xFF2563EB),
            tagBg: const Color(0xFFEFF6FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) =>
                  ScheduleCalendar(isAdmin: true, userId: widget.userId),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Intern List',
            subtitle: 'View and manage all registered interns',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            tag: 'Roster',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFF5F3FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const InternListPage(canAssess: false),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Intern Resume Submissions',
            subtitle: 'Review and evaluate intern resume submissions',
            icon: Icons.assignment_turned_in_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            tag: 'Resumes',
            tagColor: const Color(0xFFD97706),
            tagBg: const Color(0xFFFFFBEB),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AdminSubmissionsPage(adminId: widget.userId),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Interview Sessions',
            subtitle: 'Create interview slots and manage bookings',
            icon: Icons.event_note_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            tag: 'Interview',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFF5F3FF),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => const InterviewSessionAdminScreen(),
              ));
              _loadInterviewOverview();
            },
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Attendance',
            subtitle: 'Track and monitor daily intern attendance records',
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            tag: 'Records',
            tagColor: const Color(0xFF059669),
            tagBg: const Color(0xFFECFDF5),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AdminInternAttendanceScreen(),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Intern History',
            subtitle: 'View past batches and historical document submissions',
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF0891B2),
            iconBg: const Color(0xFFCFFAFE),
            tag: 'History',
            tagColor: const Color(0xFF0891B2),
            tagBg: const Color(0xFFECFEFF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => InternHistoryScreen(
                role: widget.role,
                userId: widget.userId,
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ── Intern Dashboard ───────────────────────────────────────────────────

  Widget _buildInternScaffold() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0F766E),
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Dashboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            actions: [
              _buildInternNotifBell(),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white70, size: 22),
                tooltip: 'Logout',
                onPressed: () => _logout(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildInternHero(greeting, dateStr),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildInternBody(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _buildInterviewInfoCard(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _buildAvailableSchedulesCard(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildInternBottomNav(),
    );
  }

  Widget _buildInternNotifBell() {
    return Consumer<InternshipNotificationProvider>(
      builder: (context, notifProvider, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white),
              tooltip: 'Notifications',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InternshipNotificationScreen(
                      userId: widget.userId,
                      isAdmin: false,
                    ),
                  ),
                );
                if (mounted) {
                  context
                      .read<InternshipNotificationProvider>()
                      .fetchUnreadCount(widget.userId, false);
                }
              },
            ),
            if (notifProvider.unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    notifProvider.unreadCount > 99
                        ? '99+'
                        : '${notifProvider.unreadCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInternHero(String greeting, String dateStr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (_currentStaff?.filepath != null &&
                    _currentStaff!.filepath!.isNotEmpty)
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}'),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 30),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(widget.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text('Intern',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(dateStr,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text('Tap a card to get started',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          const SizedBox(height: 20),
          _buildSupervisorCard(
            title: 'Register',
            subtitle: 'Register for an available internship schedule',
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF0891B2),
            iconBg: const Color(0xFFE0F2FE),
            tag: 'Schedule',
            tagColor: const Color(0xFF0891B2),
            tagBg: const Color(0xFFF0F9FF),
            showAlert: _needsScheduleRegistration,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) =>
                  ScheduleCalendar(isAdmin: false, userId: widget.userId),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Book Interview',
            subtitle: _mySession == null
                ? 'Select an interview session set up by admin'
                : 'View your booked interview session',
            icon: Icons.event_available_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            tag: 'Interview',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFF5F3FF),
            showAlert: _needsInterviewBooking,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) =>
                    InterviewSessionPickerScreen(userId: widget.userId),
              ));
              _loadMyInterviewSession();
            },
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Activity Logs',
            subtitle: 'View your daily internship activity records',
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            tag: 'Logs',
            tagColor: const Color(0xFF2563EB),
            tagBg: const Color(0xFFEFF6FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MonitorPerformancePage(
                  role: widget.role, userId: widget.userId),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Check Status',
            subtitle: 'View your current internship registration status',
            icon: Icons.verified_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            tag: 'Status',
            tagColor: const Color(0xFF059669),
            tagBg: const Color(0xFFECFDF5),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RegistrationStatusPage(userId: widget.userId),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Upload Resume',
            subtitle: 'Submit your resume for consideration',
            icon: Icons.cloud_upload_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            tag: 'Upload',
            tagColor: const Color(0xFF7C3AED),
            tagBg: const Color(0xFFF5F3FF),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) =>
                  DocsUpload(userId: widget.userId, scheduleId: null),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'My Profile',
            subtitle: 'View and update your personal information',
            icon: Icons.manage_accounts_rounded,
            iconColor: const Color(0xFFDB2777),
            iconBg: const Color(0xFFFCE7F3),
            tag: 'Profile',
            tagColor: const Color(0xFFDB2777),
            tagBg: const Color(0xFFFDF2F8),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => InternMySelfScreen(
                userId: widget.userId,
                username: widget.username,
              ),
            )),
          ),
          const SizedBox(height: 12),
          _buildSupervisorCard(
            title: 'Offer Letter',
            subtitle: 'View and download your internship offer letter',
            icon: Icons.description_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            tag: 'Letter',
            tagColor: const Color(0xFFD97706),
            tagBg: const Color(0xFFFFFBEB),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) =>
                  OfferLetterScreen(userId: widget.userId, role: widget.role),
            )),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInternBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F766E),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(
              _isClockOut
                  ? Icons.check_circle_rounded
                  : _isClockIn
                      ? Icons.logout_rounded
                      : Icons.login_rounded,
            ),
            label: _isClockOut
                ? 'Completed'
                : _isClockIn
                    ? 'Clock Out'
                    : 'Clock In',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.timeline_rounded), label: 'Timeline'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              _showAttendanceSheet();
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(
                builder: (_) =>
                    InternTimelineScreen(userId: widget.userId),
              ));
              break;
          }
        },
      ),
    );
  }

  Widget _buildSupervisorBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Slot Details'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(
                builder: (_) =>
                    ScheduleCalendar(isAdmin: true, userId: widget.userId),
              ));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SlotDetailsScreen(),
              ));
              break;
          }
        },
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
                border: Border.all(color: Colors.green.withOpacity(0.2)),
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

          // View History button
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