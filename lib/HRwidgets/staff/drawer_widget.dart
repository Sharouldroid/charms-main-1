import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRscreens/staff/change_pass_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrawerWidget extends StatelessWidget {
  final ImageProvider profileImage;
  final String staffName;
  final String email;
  final String userRole;

  const DrawerWidget({super.key, 
    required this.profileImage,
    required this.staffName,
    required this.email,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      child: Container(
        color: Colors.white, // Set the background of the column area to green
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Increased height of UserAccountsDrawerHeader
            SizedBox(
              height: 230.0, // Increase height to provide more space
              child: UserAccountsDrawerHeader(
                accountName: Text(
                  staffName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2, // Allows the text to wrap to the next line
                  overflow: TextOverflow.visible, // Makes sure the name wraps
                ),
                accountEmail: Text(
                  '$email | $userRole',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2, // Allows email and role to wrap if needed
                  overflow: TextOverflow.visible, // Prevents text from being cut
                ),
                // Reduced size of the profile picture
                currentAccountPicture: CircleAvatar(
                  radius: 30, // Reduced size
                  backgroundImage: profileImage,
                ),
                decoration: const BoxDecoration(color: Colors.blue),
              ),
            ),

            // List of drawer items
           
            // Divider between list items
            Divider(
              height: 1,
              color: Colors.blue, // You can change the color if needed
            ),

            ListTile(
              leading: Icon(Icons.password, color: Colors.black), // White icon
              title: Text(
                'Change Password',
                style: TextStyle(color: Colors.black), // White text
              ),
              tileColor: Colors.white, // Blue background for ListTile
              dense: false,
              contentPadding: EdgeInsetsDirectional.fromSTEB(40, 0, 0, 0),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePassScreen()));
              },
            ),

            // Divider between list items
            Divider(
              height: 1,
              color: Colors.blue, // You can change the color if needed
            ),

            ListTile(
              leading: Icon(Icons.edit_document, color: Colors.black), // White icon
              title: Text(
                'Documents',
                style: TextStyle(color: Colors.black), // White text
              ),
              tileColor: Colors.white, // Blue background for ListTile
              dense: false,
              contentPadding: EdgeInsetsDirectional.fromSTEB(40, 0, 0, 0),
            ),

            // Divider between list items
            Divider(
              height: 1,
              color: Colors.blue, // You can change the color if needed
            ),

            ListTile(
              leading: Icon(Icons.tips_and_updates, color: Colors.black), // White icon
              title: Text(
                'Tips',
                style: TextStyle(color: Colors.black), // White text
              ),
              tileColor: Colors.white, // Blue background for ListTile
              dense: false,
              contentPadding: EdgeInsetsDirectional.fromSTEB(40, 0, 0, 0),
            ),

            // Divider between list items
            Divider(
              height: 1,
              color: Colors.blue, // You can change the color if needed
            ),

            ListTile(
              leading: Icon(Icons.privacy_tip_sharp, color: Colors.black), // White icon
              title: Text(
                'About',
                style: TextStyle(color: Colors.black), // White text
              ),
              tileColor: Colors.white, // Blue background for ListTile
              dense: false,
              contentPadding: EdgeInsetsDirectional.fromSTEB(40, 0, 0, 0),
            ),
            //Spacer(), // Pushes the logout button to the bottom

            // Divider between list items
            Divider(
              height: 1,
              color: Colors.blue, // You can change the color if needed
            ),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.black), // White icon
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.black), // White text
              ),
              tileColor: Colors.white, // Blue background for ListTile
              dense: false,
              contentPadding: EdgeInsetsDirectional.fromSTEB(40, 0, 0, 0),
              onTap: () async {
                // Trigger the logout in the Auth provider
                await Provider.of<Auth>(context, listen: false).logout();

                // Navigate to the AuthScreen after logout
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),

            // Divider between list items
            Divider(
              height: 1,
              color: Colors.blue, // You can change the color if needed
            ),
            
          ],
        ),
      ),
    );
  }
}
