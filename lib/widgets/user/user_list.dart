import 'package:charms/models/user.dart';
import 'package:charms/providers/users.dart';
import 'package:charms/screens/profile_screen.dart';
import 'package:charms/widgets/user/view_user.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:charms/constants/user_roles.dart';

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
                      '${userData.userlist[i].firstname} ${userData.userlist[i].lastname}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${userData.userlist[i].username}'),
                        Text(
                          'Role: ${UserRoles.getRoleName(userData.userlist[i].usertype)}',
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
                        int.parse(user.id) !=
                                int.parse(userData.userlist[i].id)
                            ? _buildRoleChangeButtons(
                                context,
                                user,
                                userData.userlist[i],
                                hostname,
                              )
                            : [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child:
                                      Text('Cannot change your own role.'),
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
      {
        'role': UserRoles.superID,
        'label': 'Super ID',
        'icon': Icons.admin_panel_settings
      },
      {
        'role': UserRoles.manager,
        'label': 'Manager',
        'icon': Icons.work_outline
      },
      {
        'role': UserRoles.staffAdmin,
        'label': 'Staff Admin',
        'icon': Icons.manage_accounts
      },
      {
        'role': UserRoles.staff,
        'label': 'Staff',
        'icon': Icons.badge
      },
      {
        'role': UserRoles.centralLabOfficer,
        'label': 'Central Lab Officer',
        'icon': Icons.local_library_rounded
      },
      {
        'role': UserRoles.marineBiologist,
        'label': 'Marine Biologist',
        'icon': Icons.water
      },
      {
        'role': UserRoles.trainee,
        'label': 'Intern / Trainee',
        'icon': Icons.school
      },
      {
        'role': UserRoles.researcher,
        'label': 'Researcher',
        'icon': Icons.search
      },
      {
        'role': UserRoles.volunteer,
        'label': 'Volunteer',
        'icon': Icons.volunteer_activism
      },
      {
        'role': UserRoles.boatOwner,
        'label': 'Boat Owner',
        'icon': Icons.directions_boat
      },
      {
        'role': UserRoles.turtleRanger,
        'label': 'Turtle Ranger',
        'icon': Icons.nature
      },
    ];

    for (var option in roleOptions) {
      if (currentUser.usertype <= option['role'] &&
          targetUser.usertype != option['role'] &&
          targetUser.usertype != UserRoles.superID) {
        buttons.add(
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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
                    '${targetUser.firstname} ${targetUser.lastname} is now a ${option['label']}!',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
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