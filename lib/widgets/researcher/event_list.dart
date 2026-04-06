import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/widgets/researcher/researcher_tile.dart';
import 'package:charms/widgets/researcher/view_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ResearchereventList extends StatefulWidget {
  const ResearchereventList({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
    this.highlight = false, // default to false
  });

  final bool staff;
  final User user;
  final String hostname;
  final bool highlight; // NEW

  @override
  State<ResearchereventList> createState() => _ResearchereventListState();
}

class _ResearchereventListState extends State<ResearchereventList>
    with AutomaticKeepAliveClientMixin {
  late Future<void> _fetchEvents;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchEvents = _loadEvents();
  }

  Future<void> _loadEvents() async {
    await Provider.of<Events>(
      context,
      listen: false,
    ).fetchEventGeneral(widget.hostname, 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final f = DateFormat('dd-MM-yyyy');

    return FutureBuilder(
      future: _fetchEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        return Consumer<Events>(
          builder: (ctx, eventData, child) {
            if (eventData.eventlist.isEmpty) {
              return const Center(child: Text('No available events'));
            }

            return ListView.builder(
              key: const PageStorageKey<String>('researcher-events-list'),
              cacheExtent: 500,
              itemCount: eventData.eventlist.length,
              itemBuilder: (_, i) {
                final event = eventData.eventlist[i];

                return GestureDetector(
                  key: ValueKey(event.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (ctx) => ResearcherViewEvent(
                              title: event.title,
                              startdate: f.format(
                                DateTime.parse(event.startdate),
                              ),
                              enddate: f.format(DateTime.parse(event.enddate)),
                              staff: widget.staff,
                              user: widget.user,
                              eventid: int.parse(event.id),
                              hostname: widget.hostname,
                              datediff: DateTime.now().difference(
                                DateTime.parse(event.startdate),
                              ),
                              datebook: '',
                              price: event.priceresearcher,
                              total: 0,
                              status: event.status,
                              cancelreason: event.cancelreason.toString(),
                              slotresearcher: event.slotresearcher,
                            ),
                      ),
                    );
                  },
                  child: ResearcherTile(
                    id: event.id,
                    eventdata: event,
                    hostname: widget.hostname,
                    user: widget.user,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
