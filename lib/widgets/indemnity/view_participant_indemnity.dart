import 'package:charms/models/user.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

class ViewParticipantIndemnity extends StatelessWidget {
  const ViewParticipantIndemnity({
    super.key,
    required this.user,
    required this.hostname,
    required this.confirmnum,
    required this.type,
    required this.startdate,
    required this.enddate,
    required this.eventid,
    required this.title,
    required this.price,
    required this.shirtsize,
    required this.staff,
    required this.volres,
  });

  final User user;
  final String hostname;
  final int confirmnum;
  final int type;
  final String startdate;
  final String enddate;
  final int eventid;
  final String title;
  final int price;
  final String shirtsize;
  final bool staff;
  final int volres;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Indemnity'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: Provider.of<Indemnitites>(context, listen: false)
                  .fetchIndemnitiesbyType(hostname, type == 3 ? type : 1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.error != null) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    return Consumer<Indemnitites>(
                        builder: (ctx, indemData, child) => ListView.builder(
                              itemCount: indemData.indemlist.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.all(10),
                                child: ListTile(
                                  title: Text(
                                    '${i + 1}. ${indemData.indemlist[i].indemitems}',
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ),
                            ));
                  }
                }
              },
            ),
          ),
          SizedBox(
            height: 80,
            child: FutureBuilder(
              future: volres == 1
                  ? Provider.of<Indemnitites>(context, listen: false)
                      .fetchUserIndemnities(
                          hostname, int.parse(user.id), confirmnum)
                  : Provider.of<ResearcherEvents>(context, listen: false)
                      .fetchUserIndemnities(
                          hostname, int.parse(user.id), confirmnum),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.error != null) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Consumer<Indemnitites>(
                        builder: (ctx, indemdata, child) => ListView.builder(
                              itemCount: indemdata.indemAnswer.length,
                              itemBuilder: (context, i) => Column(
                                children: [
                                  indemdata.indemAnswer[i].answers.isNotEmpty
                                      ? const Text('Indemnity Completed',
                                          style: TextStyle(
                                              fontSize: 25,
                                              color: Colors.green))
                                      : const Text('Indemnity Incomplete',
                                          style: TextStyle(
                                              fontSize: 25, color: Colors.red)),
                                  Visibility(
                                      visible: indemdata
                                              .indemAnswer[i].answers.isNotEmpty
                                          ? false
                                          : true,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Provider.of<Indemnitites>(context,
                                                  listen: false)
                                              .updateUserIndemnity(
                                                  hostname,
                                                  int.parse(user.id),
                                                  'Agreed edit',
                                                  confirmnum)
                                              .then((_) {
                                            showSimpleNotification(
                                              const Text(
                                                'Indemnity Completed',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20),
                                              ),
                                              duration:
                                                  const Duration(seconds: 2),
                                              background: Colors.green,
                                            );
                                            Navigator.of(context).pop();
                                          });
                                        },
                                        label: const Text('Update Indemnity'),
                                      )

                                      // TextButton.icon(
                                      //     onPressed: () => Navigator.of(context)
                                      //             .push(MaterialPageRoute(
                                      //           builder: (ctx) =>
                                      //           IndemnityScreen(
                                      //             eventid: eventid,
                                      //             title: title,
                                      //             price: price,
                                      //             startdate: startdate,
                                      //             enddate: enddate,
                                      //             type:
                                      //                 type, // 1 & 2 =individual, group 3 = individual w child
                                      //             hostname: hostname,
                                      //             confirmnum: confirmnum,
                                      //             user: user,
                                      //             edit: true,
                                      //             answers: 'Agreed',
                                      //             shirtsize: shirtsize,
                                      //             admin: admin,
                                      //           )
                                      //         )),
                                      //     label: const Text('Complete Indemnity'),
                                      //     icon: const Icon(Icons.exit_to_app)),
                                      ),
                                ],
                              ),
                            ));
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
