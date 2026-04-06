import 'package:charms/models/user.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/widgets/researcher/view_group_participant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewResearcher extends StatelessWidget {
  const ViewResearcher({
    super.key,
    required this.hostname,
    required this.eventid,
    required this.title,
    required this.user,
    required this.confirmnum,
    required this.total,
  });

  final String hostname;
  final int eventid;
  final String title;
  final User user;
  final int confirmnum;
  final double total;

  @override
  Widget build(BuildContext context) {
    String reason = '';
    final GlobalKey<FormState> formKey = GlobalKey();
    void showCancelDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Please input reason', textAlign: TextAlign.center),
          content: Form(
            key: formKey,
            child: TextFormField(
              validator: (value) {
                if (value!.trim().isEmpty) {
                  return 'Please input cancel reason';
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
                  Provider.of<StripeService>(context, listen: false)
                      .processBookingResearcher(hostname, -1,
                          int.parse(user.id), eventid, confirmnum, reason)
                      .then((_) {
                    Provider.of<ResearcherEvents>(context, listen: false)
                        .refundBooking(hostname, confirmnum);
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$title\'s Participants'),
      ),
      body: FutureBuilder(
        future: Provider.of<ResearcherEvents>(context, listen: false)
            .fetchParticipant(hostname, eventid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.error != null) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return Consumer<ResearcherEvents>(
                  builder: (ctx, participantdata, child) => participantdata
                          .participantlist.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: participantdata.participantlist.length,
                          itemBuilder: (_, i) => ExpansionTile(
                            title: Text(
                                'Booked by: ${participantdata.participantlist[i].name}'),
                            subtitle: Text(
                                '${participantdata.participantlist[i].pax} pax'),
                            trailing: (user.usertype == 1 ||
                                        user.usertype == 5) &&
                                    participantdata.participantlist[i].status ==
                                        11
                                ? IconButton(
                                    onPressed: () => showCancelDialog(),
                                    icon: const Icon(Icons.cancel))
                                : participantdata.participantlist[i].status ==
                                        -1
                                    ? const Text(
                                        'Booking Cancelled',
                                        style: TextStyle(color: Colors.red),
                                      )
                                    : participantdata.participantlist[i]
                                                    .status ==
                                                0 &&
                                            participantdata.participantlist[i]
                                                    .userid ==
                                                int.parse(user.id)
                                        ? TextButton.icon(
                                            onPressed: () async {
                                              await Provider.of<StripeService>(
                                                      context,
                                                      listen: false)
                                                  .makePayment(
                                                hostname,
                                                double.parse(participantdata
                                                    .participantlist[i].total
                                                    .toString()),
                                                // widget.pax,
                                                confirmnum,
                                                2,
                                                eventid,
                                                int.parse(user.id),
                                              );

                                              Navigator.of(context).pop();
                                            },
                                            // widget.confirmnum is passed, while confirmnum is a new var created when creating a new booking
                                            icon: const Icon(
                                                Icons.monetization_on_outlined),
                                            label: Text(
                                                'Pay RM ${participantdata.participantlist[i].total}'),
                                          )
                                        : const SizedBox.shrink(),
                            children: [
                              Text(
                                  'Confirmation Number: ${participantdata.participantlist[i].confirmnum}'),
                              const SizedBox(height: 20),
                              Text(
                                  'Phone Number: ${participantdata.participantlist[i].phone}'),
                              const SizedBox(height: 20),
                              Text(
                                  'Email Address: ${participantdata.participantlist[i].email}'),
                              const SizedBox(height: 20),
                              Text(
                                'Status: ${participantdata.participantlist[i].status == 0 ? 'Pending Payment' : participantdata.participantlist[i].status == 11 ? 'Confirmed & Paid' : 'Rejected'} ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              participantdata.participantlist[i].type != 1
                                  ? Column(
                                      children: [
                                        const Text('Group Members'),
                                        ResearcherViewGroupParticipant(
                                          programname: title,
                                          confirmnum: participantdata
                                              .participantlist[i].confirmnum,
                                          hostname: hostname,
                                          booktype: participantdata
                                              .participantlist[i].type,
                                        )
                                      ],
                                    )
                                  : const Text('Individual Booking')
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
    );
  }
}
