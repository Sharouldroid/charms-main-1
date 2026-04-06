import 'package:charms/models/user.dart';
import 'package:charms/providers/users.dart';
import 'package:charms/screens/profile_screen.dart';
import 'package:charms/widgets/user/view_user.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

class UserList extends StatelessWidget {
  const UserList({
    super.key,
    required this.hostname,
    required this.user,
  });

  final String hostname;
  final User user;

  @override
  Widget build(BuildContext context) {
String getRoleName(int userType) {
  switch (userType) {
    case 1: return 'Admin';
    case 5: return 'Manager'; // Already exists, ensure it's here
    case 3: return 'Researcher';
    case 2: return 'Volunteer';
    case 4: return 'Boat Owner';
    case 7: return 'KPP Participant';
    case 8: return 'Central Lab Officer';
    case 9: return 'Marine Biologist'; // Add this line
    case 10: return 'internCH';
    case 11: return 'Turtle Ranger';
    default: return 'Unknown Role';
  }
}

    return FutureBuilder(
      future: Provider.of<Users>(context, listen: false).fetchUser(hostname),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else {
          return Consumer<Users>(
            builder: (ctx, userData, child) {
              return ListView.builder(
                itemCount: userData.userlist.length,
                itemBuilder: (_, i) => Dismissible(
                  key: ValueKey(userData.userlist[i].id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {},
                  child: ExpansionTile(
                    title: Text(
                        '${userData.userlist[i].firstname} ${userData.userlist[i].lastname}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${userData.userlist[i].username}'),
                        Text(
                          'Role: ${getRoleName(userData.userlist[i].usertype)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => int.parse(user.id) !=
                                  int.parse(userData.userlist[i].id)
                              ? ViewUser(
                                  user: userData.userlist[i],
                                  staffid: int.parse(user.id),
                                  stafftype: user.usertype,
                                  hostname: hostname,
                                )
                              : ProfileScreen(
                                  hostname: hostname,
                                  user: user,
                                ),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_rounded),
                    ),
                    children:
                        int.parse(user.id) != int.parse(userData.userlist[i].id)
                            ? _buildRoleChangeButtons(
                                context, user, userData.userlist[i], hostname)
                            : [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Cannot change your own role.'),
                                ),
                              ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  List<Widget> _buildRoleChangeButtons(
    BuildContext context,
    User currentUser,
    User targetUser,
    String hostname,
  ) {
    List<Widget> buttons = [];

    final List<Map<String, dynamic>> roleOptions = [
  {'role': 1, 'label': 'Admin', 'icon': Icons.admin_panel_settings},
  {'role': 5, 'label': 'Manager (full)', 'icon': Icons.work_outline},
  {'role': 3, 'label': 'Researcher', 'icon': Icons.search},
  {'role': 2, 'label': 'Volunteer', 'icon': Icons.volunteer_activism},
  {'role': 4, 'label': 'Boat Owner', 'icon': Icons.directions_boat},
  {'role': 7, 'label': 'KPP Participant', 'icon': Icons.auto_fix_normal},
  {'role': 8, 'label': 'Central Lab Officer', 'icon': Icons.local_library_rounded},

];
    for (var option in roleOptions) {
      if (currentUser.usertype <= option['role'] &&
          targetUser.usertype != option['role'] &&
          targetUser.usertype != 1) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Provider.of<Users>(context, listen: false).updateUserRole(
                  hostname,
                  option['role'] as int,
                  int.parse(targetUser.id),
                );
                showSimpleNotification(
                  Text(
                    '${targetUser.firstname} ${targetUser.lastname} is now a ${option['label'].toString()}!',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  duration: const Duration(seconds: 4),
                  background: Colors.green,
                );
              },
              label: Text(option['label'] as String),
              icon: Icon(option['icon'] as IconData),
            ),
          ),
        );
      }
    }
    return buttons;
  }
}
