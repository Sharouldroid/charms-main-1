import 'package:flutter/material.dart';

class ProgressTrackingPage extends StatelessWidget {
  const ProgressTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Progress"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            Text(
              "Progress Summary",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            // Progress bar section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Current Progress:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: 0.6, // 60% progress for demo
                    color: Colors.green,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  const Text("60% complete", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Goals section
            Text(
              "Current Goals",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Goal 1: Complete project documentation"),
                  SizedBox(height: 5),
                  Text("Goal 2: Improve code quality by refactoring"),
                  SizedBox(height: 5),
                  Text("Goal 3: Submit weekly progress reports"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Log Progress Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Action when the button is pressed (navigate to log progress page)
                  // You can create a separate page for logging progress and navigate to it
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Log Progress"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProgressTrackingPage(),
  ));
}
