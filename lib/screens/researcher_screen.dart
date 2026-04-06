import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/screens/bookingsetting_screen.dart';
import 'package:charms/widgets/researcher/custom_event.dart';
import 'package:charms/widgets/researcher/event_list.dart';
import 'package:charms/widgets/researcher/researcher_booked.dart';
import 'package:charms/widgets/researcher/researcher_member.dart';
import 'package:charms/widgets/researcher/researcher_specialslot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ResearcherScreen extends StatefulWidget {
  const ResearcherScreen({
    super.key,
    required this.isstaff,
    this.eventid = 0,
    required this.user,
    required this.hostname,
    this.highlightedEventId,
  });

  final bool isstaff;
  final int eventid;
  final User user;
  final String hostname;
  final int? highlightedEventId;

  @override
  State<ResearcherScreen> createState() => _ResearcherScreenState();
}

class _ResearcherScreenState extends State<ResearcherScreen> {
  int? _highlightedEventId;

  @override
  void initState() {
    super.initState();
    _highlightedEventId = widget.highlightedEventId;
    if (_highlightedEventId != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedEventId = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> isDialOpen = ValueNotifier(false);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton:
            widget.user.usertype == 1 || widget.user.usertype == 5
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
                                  (ctx) => BookingSettingScreen(
                                    hostname: widget.hostname,
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
          title: const Text('Researcher Events'),
          actions:
              widget.isstaff || widget.user.usertype == 3
                  ? [
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => CustomEvent(
                                    hostname: widget.hostname,
                                    eventdata: const SpecialEvent(
                                      id: 0,
                                      startdate: '',
                                      enddate: '',
                                      pax: 0,
                                      needboat: 0,
                                    ),
                                    user: widget.user,
                                  ),
                            ),
                          ),
                      child: const Text('Special Slot'),
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
            ResearchereventList(
              staff: widget.isstaff,
              user: widget.user,
              hostname: widget.hostname,
              highlight: _highlightedEventId == widget.eventid,
            ), // compare IDs),
            // booked event tab
            ListView(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              children: [
                ResearcherBooked(
                  staff: widget.isstaff,
                  user: widget.user,
                  hostname: widget.hostname,
                  eventtype: 1,
                ),
                const Divider(thickness: 5),
                const Text('Researcher Special Slot'),
                ResearcherSpecialSlot(
                  staff: widget.isstaff,
                  user: widget.user,
                  hostname: widget.hostname,
                  eventtype: 1,
                ),
              ],
            ),
            // group member of another booked event tab
            ResearcherMember(
              staff: widget.isstaff,
              user: widget.user,
              hostname: widget.hostname,
            ),
          ],
        ),
      ),
    );
  }
}
