import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/screens/bookingsetting_screen.dart';
import 'package:charms/widgets/kpp/kpp_create.dart';
import 'package:charms/widgets/kpp/kpp_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:charms/utils/responsive_helper.dart';

class KPPScreen extends StatelessWidget {
  const KPPScreen({
    super.key,
    required this.isstaff,
    // required this.userid,
    required this.user,
    required this.hostname,
  });

  final bool isstaff;
  // final int userid;
  final User user;
  final String hostname;

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
                                hostname: hostname, settingtype: 2)));
                        isDialOpen.value = false;
                      },
                      icon: const Icon(Icons.settings),
                    ),
                    label: 'Settings'),
              ],
            )
          : null,
      appBar: AppBar(
        title: const Text('KPP Events'),
        actions: isstaff
            ? [
                TextButton(
                    onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => KppCreate(
                              hostname: hostname,
                              eventdata: const SpecialEvent(
                                id: 0,
                                startdate: '',
                                enddate: '',
                                pax: 0,
                                needboat: 0,
                              ),
                              user: user,
                              picemail: '',
                            ),
                          ),
                        ),
                    child: const Text('New KPP'))
              ]
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
          child: KPPEvent(
            staff: isstaff,
            user: user,
            hostname: hostname,
          ),
        ),
      ),
    );
  }
}
