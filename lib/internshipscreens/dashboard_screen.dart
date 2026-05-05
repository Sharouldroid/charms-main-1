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
        setState(() {
          _isLoading = false;
        });
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await LogoutHelper.fullLogout(context);
  }

  // ✅ Navigate to document upload with intern ID lookup
  Future<void> _navigateToDocumentUpload() async {
    if (widget.role == 'Intern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        debugPrint('🔍 Looking up intern ID for userId: ${widget.userId}');
        
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        
        debugPrint('📋 Intern ID result: $internId');
        
        if (mounted) Navigator.pop(context);

        if (internId != null) {
          debugPrint('✅ Found intern ID: $internId, navigating to upload');
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocsUpload(
                  userId: internId,
                  scheduleId: null,
                ),
              ),
            );
          }
        } else {
          debugPrint('⚠️ No registration found, redirecting to registration');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Please complete your registration first'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduleCalendar(
                  isAdmin: false,
                  userId: widget.userId,
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error looking up intern ID: $e');
        
        if (mounted) {
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ✅ NEW: Navigate to monitor performance with intern ID lookup
  Future<void> _navigateToMonitorPerformance() async {
    if (widget.role == 'Intern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        debugPrint('🔍 Looking up intern ID for Monitor Performance: ${widget.userId}');
        
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        
        debugPrint('📋 Intern ID for performance: $internId');
        
        if (mounted) Navigator.pop(context);

        if (internId != null) {
          debugPrint('✅ Found intern ID: $internId, navigating to monitor performance');
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MonitorPerformancePage(
                  role: widget.role,
                  userId: internId, // ✅ Use internId!
                ),
              ),
            );
          }
        } else {
          debugPrint('⚠️ No registration found for performance monitoring');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Please complete your registration first'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduleCalendar(
                  isAdmin: false,
                  userId: widget.userId,
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error looking up intern ID for performance: $e');
        
        if (mounted) {
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Admin view - no lookup needed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonitorPerformancePage(
            role: widget.role,
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  // ✅ NEW: Navigate to assessment with intern ID lookup
  Future<void> _navigateToAssessment() async {
    if (widget.role == 'Intern') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        debugPrint('🔍 Looking up intern ID for Assessment: ${widget.userId}');
        
        final internId = await InternHelper.getInternIdByUserId(widget.userId);
        
        debugPrint('📋 Intern ID for assessment: $internId');
        
        if (mounted) Navigator.pop(context);

        if (internId != null) {
          debugPrint('✅ Found intern ID: $internId, navigating to assessment');
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssessmentInternPage(
                  internId: internId, // ✅ Use internId!
                ),
              ),
            );
          }
        } else {
          debugPrint('⚠️ No registration found for assessment');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Please complete your registration first'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduleCalendar(
                  isAdmin: false,
                  userId: widget.userId,
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error looking up intern ID for assessment: $e');
        
        if (mounted) {
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // This shouldn't happen for interns, but kept for safety
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentInternPage(internId: widget.userId),
        ),
      );
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
              CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Text(
                'Loading Dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
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
                    borderRadius: BorderRadius.circular(15),
                  ),
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
                                child: const Icon(Icons.person_rounded,
                                    size: 52, color: Colors.blueAccent),
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
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            Text(
                              widget.role,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chat'),
              content: const Text('This will be your chat interface.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleCalendar(
                      isAdmin: widget.role == 'Admin', userId: widget.userId),
                ),
              );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleCalendar(
                isAdmin: true,
                userId: widget.userId,
              ),
            ),
          );
        }),
        _buildDashboardButton(context, 'Intern List', Icons.person_add, () {
          // Placeholder action for Registration
        }),
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonitorPerformancePage(
                role: widget.role,
                userId: widget.userId,
              ),
            ),
          );
        }),
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InternListPage()),
          );
        }),
        _buildDashboardButton(context, 'Intern Submissions', Icons.assignment, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminSubmissionsPage(adminId: widget.userId),
            ),
          );
        }),
      ]);
    } else if (widget.role == 'Intern') {
      buttons.addAll([
        _buildDashboardButton(context, 'Register', Icons.calendar_today, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleCalendar(
                isAdmin: false,
                userId: widget.userId,
              ),
            ),
          );
        }),
        // ✅ FIXED: Monitor Performance with intern ID lookup
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor, () {
          _navigateToMonitorPerformance();
        }),
        // ✅ FIXED: Assessment with intern ID lookup
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          _navigateToAssessment();
        }),
        // ✅ FIXED: Check Status with real API
        _buildDashboardButton(context, 'Check Status', Icons.check_circle, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationStatusPage(userId: widget.userId),
            ),
          );
        }),
        // ✅ FIXED: Upload Documents with intern ID lookup
        _buildDashboardButton(context, 'Upload Documents', Icons.upload_file, () {
          _navigateToDocumentUpload();
        }),
        // ❌ REMOVED: Submissions button (functionality merged into Upload Documents)
      ]);
    }

    return buttons;
  }

  Widget _buildDashboardButton(BuildContext context, String title,
      IconData icon, VoidCallback onPressed) {
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