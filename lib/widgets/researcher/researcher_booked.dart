import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:charms/widgets/researcher/researcher_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResearcherBooked extends StatelessWidget {
  const ResearcherBooked({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
    required this.eventtype,
  });

  final bool staff;
  final User user;
  final String hostname;
  final int eventtype;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<ResearcherEvents>(
        context,
        listen: false,
      ).fetchBookedEvent(
        hostname,
        user.usertype == 1 || user.usertype == 5 ? 1 : 0,
        int.parse(user.id),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(child: Text('Error: No booking record'));
            // return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Consumer<ResearcherEvents>(
              builder:
                  (ctx, eventData, child) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: eventData.bookedeventslist.length,
                    itemBuilder:
                        (_, i) =>
                            eventData.bookedeventslist.isNotEmpty
                                ? Column(
                                  children: [
                                    Card(
                                      child: ResearcherTile(
                                        id: eventData.bookedeventslist[i]['id'],
                                        eventdata: Event.fromJson(
                                          eventData.bookedeventslist[i],
                                        ),
                                        hostname: hostname,
                                        booked: true,
                                        user: user,
                                      ),
                                    ),
                                  ],
                                )
                                // )
                                : null,
                  ),
            );
          }
        }
      },
    );
  }
}
