import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> loginUser(BuildContext context, String username, String password, String role) async {
  final url = Uri.parse('https://your-backend-api.com/login');

  try {
    // Send login request to API
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password, 'role': role}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Check user type from response to navigate accordingly
      if (responseData['usertype'] == 6) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(username: username),
          ),
        );
      } else if ([7, 8, 9, 10].contains(responseData['usertype'])) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StaffDashboardScreen(username: username),
          ),
        );
      } else {
        // Handle unknown roles or failed login attempts
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user role')),
        );
      }
    } else {
      // On error, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  } catch (error) {
    // Handle network error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred. Please try again later.')),
    );
  }
}