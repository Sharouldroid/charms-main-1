import 'package:charms/models/user.dart';
import 'package:charms/providers/events_kpp.dart';
import 'package:charms/widgets/kpp/kpp_upload.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KPPEvent extends StatelessWidget {
  const KPPEvent({
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
    String reason = '';
    final GlobalKey<FormState> formKey = GlobalKey();

    void rejectDialog(int specialid) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Please input reject reason',
              textAlign: TextAlign.center),
          content: Form(
            key: formKey,
            child: TextFormField(
              validator: (value) {
                if (value!.trim().isEmpty) {
                  return 'Please input reject reason';
                }
                return null;
              },
              onSaved: (value) {
                reason = value!;
              },
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                child: const Text('Proceed'),
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    // Invalid!
                    return;
                  }
                  formKey.currentState!.save();
                  Provider.of<EventsKPP>(context, listen: false).processKPP(
                      hostname, specialid, reason, int.parse(user.id), -1);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder(
      future: Provider.of<EventsKPP>(context, listen: false)
          .fetchKPP(hostname, staff == true ? 1 : 0, user.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Consumer<EventsKPP>(
                builder: (ctx, kppdata, child) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: kppdata.kpplist.length,
                    itemBuilder: (_, i) => ExpansionTile(
                          title: Text(
                              'Kem Prihatin Penyu KPP_${kppdata.kpplist[i].id}'),
                          trailing: Text(
                            'Status: ${kppdata.kpplist[i].status == 0 ? 'Pending Approval' : kppdata.kpplist[i].status == 1 ? 'Approved' : kppdata.kpplist[i].status == 11 ? 'Approved & Paid' : 'Rejected'} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Text(
                                'Applied Date: ${f.format(DateTime.parse(kppdata.kpplist[i].startdate))} - ${f.format(DateTime.parse(kppdata.kpplist[i].enddate))}'),
                            Text(
                                'Person In Charge Email: ${kppdata.kpplist[i].picemail}'),
                            Text('Pax: ${kppdata.kpplist[i].pax} participants'),
                            user.usertype == 1 || user.usertype == 5
                                ? kppdata.kpplist[i].status == 0
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                Provider.of<EventsKPP>(context,
                                                        listen: false)
                                                    .processKPP(
                                                        hostname,
                                                        kppdata.kpplist[i].id,
                                                        '',
                                                        int.parse(user.id),
                                                        1);
                                                Navigator.of(context).pop();
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.white, // Text color
                                                backgroundColor: Colors
                                                    .blue, // Button background color
                                                disabledForegroundColor: Colors
                                                    .grey, // Disabled text color
                                              ),
                                              child: const Text('Approve'),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () => rejectDialog(
                                                  kppdata.kpplist[i].id),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.white, // Text color
                                                backgroundColor: Colors
                                                    .red, // Button background color
                                                disabledForegroundColor: Colors
                                                    .grey, // Disabled text color
                                              ),
                                              child: const Text('Reject'),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink()
                                : kppdata.kpplist[i].status == 1
                                    ? user.email == kppdata.kpplist[i].picemail
                                        ? TextButton(
                                            onPressed: () async {
                                              await Provider.of<EventsKPP>(
                                                      context,
                                                      listen: false)
                                                  .paymentKPP(
                                                      hostname,
                                                      kppdata.kpplist[i].amount,
                                                      kppdata.kpplist[i].id,
                                                      int.parse(user.id))
                                                  .then((_) =>
                                                      Navigator.of(context)
                                                          .pop());
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.white, // Text color
                                              backgroundColor: Colors
                                                  .blue, // Button background color
                                              disabledForegroundColor: Colors
                                                  .grey, // Disabled text color
                                            ),
                                            child: const Text('Make Payment'),
                                          )
                                        : const SizedBox.shrink()
                                    : const SizedBox.shrink(),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (ctx) => KPPUpload(
                                                  hostname: hostname,
                                                  type: 'Participants',
                                                  kppid: kppdata.kpplist[i].id,
                                                ))),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white, // Text color
                                      backgroundColor: Colors
                                          .blue, // Button background color
                                      disabledForegroundColor:
                                          Colors.grey, // Disabled text color
                                    ),
                                    child: const Text('Participants'),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (ctx) => KPPUpload(
                                                  hostname: hostname,
                                                  type: 'Indemnity',
                                                  kppid: kppdata.kpplist[i].id,
                                                ))),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white, // Text color
                                      backgroundColor: Colors
                                          .blue, // Button background color
                                      disabledForegroundColor:
                                          Colors.grey, // Disabled text color
                                    ),
                                    child: const Text('Indemnity'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        )));
          }
        }
      },
    );
  }
}
