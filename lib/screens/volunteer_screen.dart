import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/screens/eventsetting_screen.dart';
import 'package:charms/widgets/volunteer/create_event.dart';
import 'package:charms/widgets/volunteer/event_list.dart';
import 'package:charms/widgets/volunteer/event_list_booked.dart';
import 'package:charms/widgets/volunteer/event_list_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class VolunteerScreen extends StatelessWidget {
  const VolunteerScreen({
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton:
            user.usertype == 1 || user.usertype == 5
                ? SpeedDial(
                  openCloseDial: isDialOpen,
                  animatedIcon: AnimatedIcons.menu_close,
                  children: [
                    SpeedDialChild(
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => EventsettingScreen(
                                    hostname: hostname,
                                    settingtype: 1,
                                  ),
                            ),
                          );
                          isDialOpen.value = false;
                        },
                        icon: const Icon(Icons.settings),
                      ),
                      label: 'Settings',
                    ),
                  ],
                )
                : null,
        appBar: AppBar(
          title: const Text('Events'),
          actions:
              isstaff
                  ? [
                    IconButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => CreateEvent(
                                    userid: int.parse(user.id),
                                    hostname: hostname,
                                    eventdata: Event(
                                      title: '',
                                      startdate: '',
                                      enddate: '',
                                      slotresearcher: 0,
                                      slotvolunteer: 0,
                                      eventtype: 1,
                                      id: '0',
                                      price: 0,
                                      priceresearcher: 0,
                                      // status: 0,
                                    ),
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.add),
                    ),
                  ]
                  : null,
          bottom: const TabBar(
            tabs: [
              Tab(child: Text('All Events')),
              Tab(child: Text('Booked Events')),
              Tab(child: Text('Associated Events')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Available event tab
            VolunteerEventList(staff: isstaff, user: user, hostname: hostname),

            // booked event tab
            EventListBooked(
              staff: isstaff,
              user: user,
              hostname: hostname,
              eventtype: 1,
            ),
            // group member of another booked event tab
            EventListMember(
              staff: isstaff,
              user: user,
              hostname: hostname,
              volorres: 1,
            ),
          ],
        ),
      ),
    );
  }
}
