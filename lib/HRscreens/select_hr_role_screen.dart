import 'package:flutter/material.dart';
import 'login_screen.dart';

class SelectHRRoleScreen extends StatelessWidget {
  const SelectHRRoleScreen({super.key});
  
  void navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select HR Role'),
        leading: const Icon(Icons.arrow_back),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HR Module Login',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => navigateToLogin(context, 'HR Admin'),
              icon: const Icon(Icons.security),
              label: const Text('Login as HR Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => navigateToLogin(context, 'Staff'),
              icon: const Icon(Icons.group),
              label: const Text('Login as Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}