import 'package:charms/models/user.dart';
import 'package:charms/screens/bookingsetting_screen.dart';
import 'package:charms/widgets/daytrip/daytrip_create.dart';
import 'package:charms/widgets/daytrip/daytrip_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:charms/utils/responsive_helper.dart';

class DaytripScreen extends StatelessWidget {
  const DaytripScreen({
    super.key,
    required this.isstaff,
    required this.user,
    required this.hostname,
    this.companyid = 0,
  });

  final bool isstaff;
  final User user;
  final String hostname;
  final int companyid;

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> isDialOpen = ValueNotifier(false);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: user.usertype == 1 || user.usertype == 5
          ? SpeedDial(
              openCloseDial: isDialOpen,
              animatedIcon: AnimatedIcons.menu_close,
              children: [
                SpeedDialChild(
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => BookingSettingScreen(
                                hostname: hostname, settingtype: 3)));
                        isDialOpen.value = false;
                      },
                      icon: const Icon(Icons.settings),
                    ),
                    label: 'Settings'),
              ],
            )
          : null,
      appBar: AppBar(
        title: const Text('Day Trip'),
        actions: isstaff || user.usertype == 4
            ? [
                TextButton(
                    onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => DaytripCreate(
                              hostname: hostname,
                              user: user,
                              companyid: companyid,
                            ),
                          ),
                        ),
                    child: const Text('Mohon'))
              ]
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
          child: DaytripEvent(
            staff: isstaff,
            user: user,
            hostname: hostname,
          ),
        ),
      ),
    );
  }
}
