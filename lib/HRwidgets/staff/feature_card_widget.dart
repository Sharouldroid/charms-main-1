import 'package:flutter/material.dart';

class FeatureCardWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  FeatureCardWidget({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 93, // Set fixed width
      height: 100, // Adjust the height slightly to avoid overflow
      child: Card(
        color: const Color(0xFFFFE7CB), // Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Same rounded corner design
        ),
        child: InkWell(
          onTap: onTap, // Trigger action when card is tapped
          borderRadius: BorderRadius.circular(10.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, // Use dynamic icon
                  color: Colors.black,
                  size: 36, // Icon size
                ),
                const SizedBox(height: 4), // Space between icon and text
                Flexible(
                  child: Text(
                    text, // Use dynamic text
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center, // Center the text
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
