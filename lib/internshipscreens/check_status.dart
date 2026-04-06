import 'package:flutter/material.dart';

class CheckStatusPage extends StatelessWidget {
  final bool
      isStatusChecked; // Indicates if the task is checked (green) or not (red)

  const CheckStatusPage({super.key, required this.isStatusChecked});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Status'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display status (Green check or Red cross)
            Icon(
              isStatusChecked ? Icons.check_circle : Icons.cancel,
              color: isStatusChecked ? Colors.green : Colors.red,
              size: 100.0,
            ),
            const SizedBox(height: 20),
            Text(
              isStatusChecked
                  ? 'Your submission is approved!'
                  : 'Your submission is not approved.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isStatusChecked ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Resubmit'),
            ),
          ],
        ),
      ),
    );
  }
}
