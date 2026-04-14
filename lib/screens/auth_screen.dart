import 'package:charms/widgets/auth/auth_card.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF567FD7), // Charms blue
              Color(0xFFDA291C), // Charms red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Branding
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo/seatrulogo1.png', // replace with your logo asset
                        height: isMobile ? 100 : 150,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Welcome to Charms',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Auth Card (login form)
                Card(
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: AuthCard(), // existing login form
                  ),
                ),

                const SizedBox(height: 20),

                // Footer / Extra options
                TextButton(
                  onPressed: () {
                    // Add forgot password navigation here
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
