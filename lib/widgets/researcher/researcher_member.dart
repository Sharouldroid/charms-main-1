import 'package:charms/models/user.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ResearcherMember extends StatelessWidget {
  const ResearcherMember({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
  });

  final bool staff;
  final User user;
  final String hostname;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return FutureBuilder(
      future: Provider.of<ResearcherEvents>(context, listen: false)
          .fetchMemberEvent(hostname, user.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            // Display API error message if available
            final errorData = snapshot.error;
            String errorMessage = "No data";

            if (errorData is Map<String, dynamic> &&
                errorData.containsKey('message')) {
              errorMessage = errorData['message']; // API error message
            }

            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return Consumer<ResearcherEvents>(
                builder: (ctx, eventData, child) => ListView.builder(
                      shrinkWrap: true,
                      itemCount: eventData.bookedmemberevents.length,
                      itemBuilder: (_, i) => eventData
                              .bookedmemberevents.isNotEmpty
                          ? ListTile(
                              isThreeLine: true,
                              title: Row(children: [
                                Expanded(
                                    child: Text(
                                        eventData.bookedmemberevents[i].title)),
                              ]),
                              subtitle: Text(
                                  '${f.format(DateTime.parse(eventData.bookedmemberevents[i].startdate))} - ${f.format(DateTime.parse(eventData.bookedmemberevents[i].enddate))}'),
                              trailing: DateTime.parse(eventData
                                          .bookedmemberevents[i].startdate)
                                      .isAfter(DateTime.now())
                                  ? const Text('Upcoming',
                                      style: TextStyle(color: Colors.amber))
                                  : const Text('Passed',
                                      style: TextStyle(color: Colors.grey)),
                            )
                          : const Text('No Associated Event'),
                    ));
          }
        }
      },
    );
  }
}
