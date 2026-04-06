import 'package:charms/providers/events.dart';
import 'package:charms/widgets/volunteer/view_participant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TripManagement extends StatelessWidget {
  const TripManagement({
    super.key,
    required this.hostname,
    required this.companyid,
    required this.usertype,
    required this.userid,
    required this.confirmnum,
  });

  final String hostname;
  final int companyid;
  final int usertype;
  final int userid;
  final int confirmnum;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return FutureBuilder(
      future: Provider.of<Events>(
        context,
        listen: false,
      ).fetchEventGeneral(hostname, 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Consumer<Events>(
              builder:
                  (ctx, eventData, child) => ListView.builder(
                    itemCount: eventData.eventlist.length,
                    itemBuilder:
                        (_, i) => ListTile(
                          isThreeLine: true,
                          leading: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.library_add_check),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(eventData.eventlist[i].title),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${f.format(DateTime.parse(eventData.eventlist[i].startdate))} - ${f.format(DateTime.parse(eventData.eventlist[i].enddate))}',
                          ),
                          trailing: TextButton.icon(
                            onPressed:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (ctx) => ViewParticipant(
                                          hostname: hostname,
                                          eventid: int.parse(
                                            eventData.eventlist[i].id,
                                          ),
                                          title: eventData.eventlist[i].title,
                                          usertype: usertype,
                                          userid: userid,
                                          confirmnum: confirmnum,
                                          currentuser: 0,
                                          startdate: eventData
                                              .eventlist[i].startdate,
                                          enddate: eventData
                                              .eventlist[i].enddate,
                                          // 7 May 2025
                                        ),
                                  ),
                                ),
                            label: const Text('Senarai Sukarelawan'),
                            icon: const Icon(Icons.list),
                          ),
                        ),

                    // GestureDetector(
                    //       onTap: () {
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (ctx) => ViewEvent(
                    //       title: eventData.eventlist[i].title,
                    //       startdate: f.format(DateTime.parse(
                    //           eventData.eventlist[i].startdate)),
                    //       enddate: f.format(DateTime.parse(
                    //           eventData.eventlist[i].enddate)),
                    //       admin: false,
                    //       user: user,
                    //       eventid: int.parse(eventData.eventlist[i].id),
                    //       hostname: hostname,
                    //       datediff: DateTime.now().difference(
                    //           DateTime.parse(
                    //               eventData.eventlist[i].startdate)),
                    //       datebook: '',
                    //       isgroup: 0,
                    //     ),
                    //   ),
                    // );
                    // },
                    // child:
                    // EventListTile(
                    //   id: eventData.eventlist[i].id,
                    //   title: eventData.eventlist[i].title,
                    //   startdate: eventData.eventlist[i].startdate,
                    //   enddate: eventData.eventlist[i].enddate,
                    //   eventtype: int.parse(
                    //       eventData.eventlist[i].eventtype.toString()),
                    //   hostname: hostname,
                    //   admin: false,
                    //   userid: int.parse(user.id),
                    // ),
                    // )
                  ),
            );
          }
        }
      },
    );

    // FutureBuilder(
    //     future: Provider.of<Boats>(context, listen: false)
    //         .fetchTripData(hostname, companyid),
    //     builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         return const Center(child: CircularProgressIndicator());
    //       } else {
    //         if (snapshot.error != null) {
    //           return Center(
    //             child: Text('Error: ${snapshot.error}'),
    //           );
    //         } else {
    //           return Consumer<Boats>(
    //             builder: (ctx, boatData, child) {
    //               return boatData.tripRecord.isNotEmpty
    //                   ? ListView.builder(
    //                       shrinkWrap: true,
    //                       itemCount: boatData.tripRecord.length,
    //                       itemBuilder: (_, i) => ExpansionTile(
    //                         title: Text(
    //                             '${boatData.tripRecord[i]} (${boatData.tripRecord[i]} pax)'),
    //                         subtitle: Text(boatData.tripRecord[i] == 1
    //                             ? 'Aktif'
    //                             : 'Tidak Aktif'),
    //                         // trailing: IconButton(
    //                         //     onPressed: () => Navigator.of(context)
    //                         //             .push(MaterialPageRoute(
    //                         //           builder: (ctx) => AddBoat(
    //                         //             boatid: boatData.tripRecord[i].id,
    //                         //             hostname: hostname,
    //                         //             boatdata: boatData.tripRecord,
    //                         //             companyid: companyid,
    //                         //           ),
    //                         //         )),
    //                         //     icon: const Icon(Icons.edit)),
    //                         children: [
    //                           ListTile(
    //                               title: Text(
    //                                   'Pemandu: ${boatData.tripRecord[i]}'),
    //                               subtitle: Text(
    //                                   'Telefon: ${boatData.tripRecord[i]}')),
    //                           ListTile(
    //                               title: Text(
    //                                   'Pembantu Pemandu: ${boatData.tripRecord[i]}'),
    //                               subtitle: Text(
    //                                   'Telefon: ${boatData.tripRecord[i]}')),
    //                           // IconButton(
    //                           //     onPressed: () {},
    //                           //     icon: const Icon(Icons.toggle_off))
    //                         ],
    //                       ),
    //                     )
    //                   : const Column(
    //                       mainAxisAlignment: MainAxisAlignment.center,
    //                       children: [
    //                         Text('Tiada Trip'),
    //                       ],
    //                     );
    //             },
    //           );
    //         }
    //       }
    //     });
  }
}
