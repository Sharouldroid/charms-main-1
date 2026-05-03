import 'package:flutter/material.dart';
import 'package:charms/internshipscreens/assessment_intern.dart';
import 'package:charms/utils/logout_helper.dart';
import 'check_status.dart';
import 'schedule_calendar.dart';
import 'monitor_performance.dart';
import 'intern_list_assesstment.dart';
import 'admin_submissions.dart';
import 'submission_status.dart';

class DashboardScreen extends StatelessWidget {
  final String username;
  final String role;
  final String profilePicture;
  final int userId;

  const DashboardScreen({
    super.key,
    required this.username,
    required this.role,
    required this.profilePicture,
    required this.userId,
  });

  // ✅ Helper method to get the correct ImageProvider
  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      // Network image from server
      debugPrint('🌐 Loading network image: $imagePath');
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      // Local asset image
      debugPrint('📁 Loading asset image: $imagePath');
      return AssetImage(imagePath);
    } else {
      // Fallback to default asset
      debugPrint('⚠️ Unknown image path format, using default: $imagePath');
      return const AssetImage('assets/profilepicture.png');
    }
  }

  // ✅ Logout method
  Future<void> _logout(BuildContext context) async {
    await LogoutHelper.fullLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🖼️ profilePicture received: $profilePicture');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('$role Dashboard'),
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
        color: Colors.white,
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
                        // ✅ Updated CircleAvatar to use _getImageProvider
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _getImageProvider(profilePicture),
                          backgroundColor: Colors.grey[300],
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('❌ Error loading profile image: $exception');
                          },
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            Text(
                              role,
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
                      isAdmin: role == 'Admin', userId: userId),
                ),
              );
              break;
            case 2:
              // Navigate to feedback page
              break;
          }
        },
      ),
    );
  }

  // Helper method to build dashboard buttons
  List<Widget> _buildDashboardButtons(BuildContext context) {
    final buttons = <Widget>[];

    if (role == 'Admin') {
      buttons.addAll([
        _buildDashboardButton(context, 'Create Schedule', Icons.calendar_today,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleCalendar(
                isAdmin: true,
                userId: userId,
              ),
            ),
          );
        }),
        _buildDashboardButton(context, 'Intern List', Icons.person_add, () {
          // Placeholder action for Registration
        }),
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonitorPerformancePage(
                role: role,
                userId: userId,
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
        _buildDashboardButton(context, 'Intern Submissions', Icons.assignment,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminSubmissionsPage(adminId: userId),
            ),
          );
        }),
      ]);
    } else if (role == 'Intern') {
      buttons.addAll([
        _buildDashboardButton(context, 'Register', Icons.calendar_today, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleCalendar(
                isAdmin: false,
                userId: userId,
              ),
            ),
          );
        }),
        _buildDashboardButton(context, 'Monitor Performance', Icons.monitor,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonitorPerformancePage(
                role: role,
                userId: userId,
              ),
            ),
          );
        }),
        _buildDashboardButton(context, 'Assessment', Icons.assessment, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssessmentInternPage(internId: userId),
            ),
          );
        }),
        _buildDashboardButton(context, 'Check Status', Icons.check_circle, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CheckStatusPage(
                  isStatusChecked: false),
            ),
          );
        }),
        _buildDashboardButton(context, 'Submissions', Icons.assignment, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmissionStatusPage(userId: userId),
            ),
          );
        }),
        _buildDashboardButton(context, 'Feedback', Icons.feedback, () {
          // Placeholder action for Feedback
        }),
      ]);
    }

    return buttons;
  }

  // Helper method to build individual buttons
  Widget _buildDashboardButton(BuildContext context, String title,
      IconData icon, VoidCallback onPressed) {
    final buttonWidth =
        (MediaQuery.of(context).size.width / 3) - 32;
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