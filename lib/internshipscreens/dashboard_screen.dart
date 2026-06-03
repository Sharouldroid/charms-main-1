import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    // ✅ Fetch unread notification count on dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternshipNotificationProvider>().fetchUnreadCount(
        widget.userId,
        widget.role == 'Admin',
      );
    });
  }

  Future<void> _loadStaffData() async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🚀 LOADING STAFF DATA FOR INTERNSHIP');
    debugPrint('========================================');
    debugPrint('📋 Username: ${widget.username}');
    debugPrint('🔑 UserId: ${widget.userId}');
    debugPrint('');

    try {
      final staffsProvider = context.read<Staffs>();

      debugPrint('🔍 Step 1: Fetching all staff from database...');
      await staffsProvider.fetchStaff();

      debugPrint('✅ Step 2: Staff data fetched');
      debugPrint('📊 Total staff: ${staffsProvider.staffList.length}');

      for (var staff in staffsProvider.staffList) {
        debugPrint('   - ${staff.firstname} ${staff.lastname} (userId: ${staff.userId})');
      }

      debugPrint('');
      debugPrint('🔎 Step 3: Looking for userId: ${widget.userId}');

      final matches = staffsProvider.staffList
          .where((s) => s.userId == widget.userId)
          .toList();

      if (matches.isEmpty) {
        debugPrint('❌ No matching staff found for userId=${widget.userId}');
        setState(() { _isLoading = false; });
        return;
      }

      _currentStaff = matches.first;

      debugPrint('✅ Step 4: Found staff!');
      debugPrint('   👤 Name: ${_currentStaff!.firstname} ${_currentStaff!.lastname}');
      debugPrint('   📧 Email: ${_currentStaff!.email}');
      debugPrint('   🖼️ Filepath: ${_currentStaff!.filepath}');
      debugPrint('   📁 Filename: ${_currentStaff!.filename}');
      debugPrint('');

      if (_currentStaff!.filepath != null && _currentStaff!.filepath!.isNotEmpty) {
        _profilePicture = 'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}';
        debugPrint('✅ Step 5: Profile picture URL built');
        debugPrint('   🌐 URL: $_profilePicture');
      } else {
        debugPrint('⚠️ Step 5: No filepath, using default');
        _profilePicture = 'assets/profilepicture.png';
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('✅ LOADING COMPLETE');
      debugPrint('========================================');
      debugPrint('');

    } catch (error) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('❌ ERROR LOADING STAFF DATA');
      debugPrint('========================================');
      debugPrint('Error: $error');
      debugPrint('========================================');
      debugPrint('');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await LogoutHelper.fullLogout(context);
  }

  Future<void> _navigateToDocumentUpload() async {
    if (widget.role == 'Intern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        if (mounted) Navigator.pop(context);

        if (internId != null) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => DocsUpload(userId: internId, scheduleId: null),
            ));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('⚠️ Please complete your registration first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ));
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ScheduleCalendar(isAdmin: false, userId: widget.userId),
            ));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _navigateToMonitorPerformance() async {
    if (widget.role == 'Intern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        if (mounted) Navigator.pop(context);

        if (internId != null) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MonitorPerformancePage(role: widget.role, userId: internId),
            ));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('⚠️ Please complete your registration first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ));
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ScheduleCalendar(isAdmin: false, userId: widget.userId),
            ));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => MonitorPerformancePage(role: widget.role, userId: widget.userId),
      ));
    }
  }

  Future<void> _navigateToAssessment() async {
    if (widget.role == 'Intern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        if (mounted) Navigator.pop(context);

        if (internId != null) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => AssessmentInternPage(internId: internId),
            ));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('⚠️ Please complete your registration first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ));
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ScheduleCalendar(isAdmin: false, userId: widget.userId),
            ));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => AssessmentInternPage(internId: widget.userId),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: Colors.blueAccent,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 20),
              Text('Loading Dashboard...', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
          // ✅ Notification bell with unread badge
          Consumer<InternshipNotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.white),
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
                      // ✅ Refresh count after returning
                      if (mounted) {
                        context.read<InternshipNotificationProvider>().fetchUnreadCount(
                          widget.userId,
                          widget.role == 'Admin',
                        );
                      }
                    },
                  ),
                  // ✅ Red badge
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
              // Profile section
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        (_currentStaff?.filepath != null && _currentStaff!.filepath!.isNotEmpty)
                            ? CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blueAccent.withOpacity(0.12),
                                backgroundImage: NetworkImage(
                                    'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}'),
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blueAccent.withOpacity(0.12),
                                child: const Icon(Icons.person_rounded, size: 52, color: Colors.blueAccent),
                              ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.role,
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Buttons section
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chat'),
              content: const Text('This will be your chat interface.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        tooltip: 'Chat with Support',
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
        ],
        selectedItemColor: Colors.blueAccent,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ScheduleCalendar(
                  isAdmin: widget.role == 'Admin',
                  userId: widget.userId,
                ),
              ));
              break;
            case 2:
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
        _buildDashboardButton(context, 'Create Schedule', Icons.calendar_today, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ScheduleCalendar(isAdmin: true, userId: widget.userId),
          ));
        }),
       _buildDashboardButton(context, 'Intern List', Icons.person_add, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const InternListPage(),
          ));
        }),
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => MonitorPerformancePage(role: widget.role, userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const AssessmentListPage(), // ← changed
          ));
        }),
        _buildDashboardButton(context, 'Intern Submissions', Icons.assignment, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => AdminSubmissionsPage(adminId: widget.userId),
          ));
        }),
      ]);
    } else if (widget.role == 'Intern') {
      buttons.addAll([
        _buildDashboardButton(context, 'Register', Icons.calendar_today, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ScheduleCalendar(isAdmin: false, userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor, () {
          _navigateToMonitorPerformance();
        }),
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          _navigateToAssessment();
        }),
        _buildDashboardButton(context, 'Check Status', Icons.check_circle, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => RegistrationStatusPage(userId: widget.userId),
          ));
        }),
        _buildDashboardButton(context, 'Upload Documents', Icons.upload_file, () {
          _navigateToDocumentUpload();
        }),
        _buildDashboardButton(context, 'My Profile', Icons.account_circle, () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => InternMySelfScreen(
              userId: widget.userId,
              username: widget.username,
            ),
          ));
        }),
      ]);
    }

    return buttons;
  }

  Widget _buildDashboardButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}