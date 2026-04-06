import 'package:charms/models/user.dart';
import 'package:charms/providers/events_daytrip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DaytripEvent extends StatelessWidget {
  const DaytripEvent({
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
      future: Provider.of<EventsDaytrip>(context, listen: false)
          .fetchDaytrip(hostname, staff == true ? 1 : 0, int.parse(user.id)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Consumer<EventsDaytrip>(
                builder: (ctx, dtdata, child) => dtdata.dtlist.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: dtdata.dtlist.length,
                        itemBuilder: (_, i) => ExpansionTile(
                              title: Text('Day Trip DT_${dtdata.dtlist[i].id}'),
                              subtitle: Text(
                                  'Applied by: ${dtdata.dtlist[i].company}'),
                              // trailing: Text(
                              // 'Status: ${dtdata.dtlist[i].status == 0 ? 'Pending Approval' : dtdata.dtlist[i].status == 1 ? 'Approved' : dtdata.dtlist[i].status == 11 ? 'Approved & Paid' : 'Rejected'} ',
                              // style: const TextStyle(
                              //     fontWeight: FontWeight.bold),
                              // ),
                              children: [
                                Text(
                                    'Date: ${f.format(DateTime.parse(dtdata.dtlist[i].selecteddate))}'),
                                Text('Time: ${dtdata.dtlist[i].selectedtime}'),
                              ],
                            ))
                    : const Center(
                        child: Text('No Day Trip Event'),
                      ));
          }
        }
      },
    );
  }
}
