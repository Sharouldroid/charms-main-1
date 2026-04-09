import 'package:flutter/material.dart';
import 'package:charms/internshipscreens/assessment_intern.dart';
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
    required this.userId, // Add userId parameter
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('$role Dashboard'),
        backgroundColor: Colors.blueAccent, // Customize the app bar color
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(username),
              accountEmail: Text(role),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(profilePicture),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.purple
                  ], // Gradient for drawer header
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedule'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleCalendar(
                        isAdmin: role == 'Admin', userId: userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () {
                // Navigate to Feedback page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Implement logout functionality
              },
            ),
          ],
        ),
      ),
      body: Container(
        // Apply solid white background here
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
                    ], // Matching the gradient of the main page
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                      15), // Match the card's border radius
                ),
                child: Card(
                  elevation:
                      0, // Remove card shadow to let gradient show through
                  color: Colors
                      .transparent, // Make the card transparent to show gradient
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(profilePicture),
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
                                color: Color.fromARGB(255, 255, 255,
                                    255), // Change text color to black for better visibility on white background
                              ),
                            ),
                            Text(
                              role,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 255, 255,
                                    255), // Change text color to black for better visibility on white background
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
                    ], // Matching the gradient of the profile section
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                      15), // Match the card's border radius
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 16.0, // Horizontal space between buttons
                        runSpacing:
                            16.0, // Vertical space between rows of buttons
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
          // Navigate to chat box page or open chat feature
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
        child: Icon(Icons.chat, color: Colors.white),
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
          // Implement navigation based on tapped index
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
            MaterialPageRoute(builder: (context) => InternListPage()),
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
                userId: userId, // Pass userId here
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
          // Navigate to CheckStatusPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CheckStatusPage(
                  isStatusChecked:
                      false), // Pass the status as false or true based on the logic you have
            ),
          );
        }),
        _buildDashboardButton(context, 'Submissions', Icons.assignment, () {
          // Navigate to SubmissionStatusPage
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
    // Define a fixed size for the button boxes
    final buttonWidth =
        (MediaQuery.of(context).size.width / 3) - 32; // Adjust as needed
    const buttonHeight = 120.0; // Fixed height for the buttons

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // Remove default padding
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor:
                Colors.blueAccent, // Blue accent color for button background
            elevation: 3, // Slight shadow effect for depth
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: Colors.white, size: 24), // Adjust icon size as needed
              const SizedBox(height: 8), // Spacing between icon and text
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16, // Adjust font size for smaller buttons
                  fontWeight: FontWeight.w600, // Bolder font weight
                  color: Colors.white, // White font color for visibility
                ),
                textAlign: TextAlign.center, // Center text alignment
              ),
            ],
          ),
        ),
      ),
    );
  }
}
