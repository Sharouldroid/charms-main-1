import 'package:flutter/material.dart';

class StaffProfileWidget extends StatelessWidget {
  final String imagePath;
  final String name;
  final String staffId;
  final String position;

  StaffProfileWidget({
    required this.imagePath,
    required this.name,
    required this.staffId,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0, // Adds shadow to the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: Colors.blue[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically in the center
          children: [
            // Picture
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(imagePath), // Use the dynamic image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 20.0), // Space between the image and the text
            // Text on the right side of the picture
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start of the container
                children: [
                  Text(
                    name, // Use the dynamic name
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    staffId, // Use the dynamic position
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    position, // Use the dynamic position
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.white ,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
