// schedule_button_screen.dart
import 'package:flutter/material.dart';
import 'schedule_calendar.dart';

class ScheduleButtonScreen extends StatelessWidget {
  final bool isAdmin;

  const ScheduleButtonScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'User Dashboard'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ScheduleCalendar(isAdmin: isAdmin, userId: 1),
              ),
            );
          },
          child: const Text('Go to Schedule'),
        ),
      ),
    );
  }
}
