import 'package:charms/widgets/auth/auth_card.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final maxWidth = isTablet ? 500.0 : double.infinity;
    final titleFontSize = isTablet ? 40.0 : 32.0;
    final padding = ResponsiveHelper.getResponsivePadding(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/logo/seatrulogo2.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(color: Colors.blueGrey.withOpacity(0.7)),
          // Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: padding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CHARMS',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isTablet ? 40 : 32),
                        const AuthCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
