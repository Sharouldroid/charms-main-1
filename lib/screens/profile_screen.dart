import 'package:charms/models/user.dart';
import 'package:charms/widgets/user/update_profile.dart';
import 'package:charms/widgets/user/view_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:charms/utils/responsive_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.hostname, required this.user});

  final String hostname;
  final User user;

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> isDialOpen = ValueNotifier(false);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: SpeedDial(
        openCloseDial: isDialOpen,
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => UpdateProfile(
                          userid: int.parse(user.id),
                          hostname: hostname,
                          userdata: user,
                        ),
                  ),
                );
                isDialOpen.value = false;
              },
              icon: const Icon(Icons.edit),
            ),
            label: 'Edit Profile',
          ),
          // SpeedDialChild(
          //     child: IconButton(
          //       onPressed: () {
          //         Navigator.of(context).push(MaterialPageRoute(
          //             builder: (ctx) => UpdateLogin(
          //                   user: user,
          //                   hostname: hostname,
          //                 )));
          //         isDialOpen.value = false;
          //       },
          //       icon: const Icon(Icons.edit),
          //     ),
          //     label: 'Edit Login'),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
          child: ViewUser(
            user: user,
            staffid: int.parse(user.id),
            stafftype: user.usertype,
            hostname: hostname,
          ),
        ),
      ),
    );
  }
}
