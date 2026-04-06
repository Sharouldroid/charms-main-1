import 'package:charms/providers/boats.dart';
import 'package:charms/widgets/researcher/view_group_participant.dart';
import 'package:charms/widgets/volunteer/view_group_participant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BoatParticipant extends StatelessWidget {
  const BoatParticipant({
    super.key,
    required this.hostname,
    required this.eventid,
    required this.title,
    required this.usertype,
    required this.confirmnum,
    required this.userid,
  });

  final String hostname;
  final int eventid;
  final String title;
  final int usertype;
  final int confirmnum;
  final int userid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title\'s Participants'),
      ),
      body: ListView(
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        children: [
          const Text('Volunteer'),
          FutureBuilder(
            future: Provider.of<Boats>(context, listen: false)
                .fetchParticipant(hostname, eventid, 1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.error != null) {
                  return Center(
                    child: Text('${snapshot.error}'),
                  );
                } else {
                  return Consumer<Boats>(
                      builder: (ctx, participantdata, child) => participantdata
                              .participantlist.isNotEmpty
                          ? ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: participantdata.participantlist.length,
                              itemBuilder: (_, i) => ExpansionTile(
                                title: Text(
                                    participantdata.participantlist[i].name),
                                subtitle: Text(
                                    '${participantdata.participantlist[i].pax} pax'),
                                trailing:
                                    participantdata.participantlist[i].status ==
                                            -1
                                        ? const Text(
                                            'Booking Cancelled',
                                            style: TextStyle(color: Colors.red),
                                          )
                                        : const SizedBox.shrink(),
                                children: [
                                  Text(
                                      'Confirmation Number: ${participantdata.participantlist[i].confirmnum}'),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                      'Phone Number: ${participantdata.participantlist[i].phone}'),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                      'Email Address: ${participantdata.participantlist[i].email}'),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  participantdata.participantlist[i].type != 1
                                      ? const Text('Group Members')
                                      : const SizedBox.shrink(),
                                  participantdata.participantlist[i].type != 1
                                      ? ViewGroupParticipant(
                                          programname: title,
                                          confirmnum: participantdata
                                              .participantlist[i].confirmnum,
                                          hostname: hostname,
                                          booktype: participantdata
                                              .participantlist[i].type,
                                        )
                                      : const Text('Individual Booking'),
                                ],
                              ),
                            )
                          : const Center(
                              child: Text('No Participation',
                                  style: TextStyle(fontSize: 20))));
                }
              }
            },
          ),
          const Divider(thickness: 5),
          const Text('Researcher'),
          FutureBuilder(
            future: Provider.of<Boats>(context, listen: false)
                .fetchResearcherParticipant(hostname, eventid, 2),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.error != null) {
                  return Center(
                    child: Text('${snapshot.error}'),
                  );
                } else {
                  return Consumer<Boats>(
                      builder: (ctx, researcherdata, child) => researcherdata
                              .researcherlist.isNotEmpty
                          ? ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: researcherdata.researcherlist.length,
                              itemBuilder: (_, i) => ExpansionTile(
                                title:
                                    Text(researcherdata.researcherlist[i].name),
                                subtitle: Text(
                                    '${researcherdata.researcherlist[i].pax} pax'),
                                trailing:
                                    researcherdata.researcherlist[i].status ==
                                            -1
                                        ? const Text(
                                            'Booking Cancelled',
                                            style: TextStyle(color: Colors.red),
                                          )
                                        : const SizedBox.shrink(),
                                children: [
                                  Text(
                                      'Confirmation Number: ${researcherdata.researcherlist[i].confirmnum}'),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                      'Phone Number: ${researcherdata.researcherlist[i].phone}'),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                      'Email Address: ${researcherdata.researcherlist[i].email}'),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  researcherdata.researcherlist[i].type != 1
                                      ? const Text('Group Members')
                                      : const SizedBox.shrink(),
                                  researcherdata.researcherlist[i].type != 1
                                      ? ResearcherViewGroupParticipant(
                                          programname: title,
                                          confirmnum: researcherdata
                                              .researcherlist[i].confirmnum,
                                          hostname: hostname,
                                          booktype: researcherdata
                                              .researcherlist[i].type,
                                        )
                                      : const Text('Individual Booking'),
                                ],
                              ),
                            )
                          : const Center(
                              child: Text('No Participation',
                                  style: TextStyle(fontSize: 20))));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
