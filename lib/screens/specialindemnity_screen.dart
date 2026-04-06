import 'package:charms/models/specialbooking_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/screens/specialcheckout_screen.dart';
import 'package:charms/widgets/optional/add_on.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SpecialIndemnityScreen extends StatelessWidget {
  const SpecialIndemnityScreen({
    super.key,
    required this.eventid,
    required this.title,
    required this.startdate,
    required this.enddate,
    required this.type,
    required this.hostname,
    required this.user,
    required this.answers,
    this.pax = 1,
    required this.boatprice,
    required this.eventprice,
    required this.affiliatetitle,
    required this.department,
    required this.institution,
    required this.location,
    required this.filename,
  });

  final int eventid;
  final String title;
  final String startdate;
  final String enddate;
  final int type;
  final String hostname;
  final User user;
  final String answers;
  final int pax;
  final int boatprice;
  final int eventprice;
  final String affiliatetitle;
  final String department;
  final String institution;
  final String location;
  final String filename;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    void showBookDialog(String answer) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text(
                'Would you like to purchase some add ons?',
                textAlign: TextAlign.center,
              ),
              // content:
              actions: <Widget>[
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (ctx) => AddOn(
                                hostname: hostname,
                                confirmnum: 0,
                                pax: pax,
                                ischecked: 'Agreed',
                                user: user,
                                eventid: eventid,
                                booktype: type,
                                shirtsize: '',
                                staff: false,
                                volres: 0,
                                isRSS: 1,
                                startdate: startdate,
                                enddate: enddate,
                                needboat: boatprice > 0 ? 1 : 0,
                                affiliatetitle: affiliatetitle,
                                department: department,
                                institution: institution,
                                location: location,
                                filename: filename,
                              ),
                        ),
                      ),
                  child: const Text('Yes Please'),
                ),
                ElevatedButton(
                  child: const Text('No Thanks'),
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (ctx) => SpecialCheckoutScreen(
                                hostname: hostname,
                                pax: pax,
                                ischecked: 'Agreed',
                                user: user,
                                startdate: startdate,
                                enddate: enddate,
                                needboat: boatprice > 0 ? 1 : 0,
                                affiliatetitle: affiliatetitle,
                                department: department,
                                institution: institution,
                                location: location,
                                filename: filename,
                              ),
                        ),
                      ),
                ),
              ],
            ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Indemnity')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'In consideration of SEATRU (UMT) accepting my participation in the volunteer program at Chagar Hutang, Pulau Redang, Terengganu, Malaysia to be held between ${f.format(DateTime.parse(startdate))} to ${f.format(DateTime.parse(enddate))} , I agree to this release of claims, waiver of liability and assumption of risk.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: Provider.of<Indemnitites>(
                context,
                listen: false,
              ).fetchIndemnitiesbyType(hostname, 1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.error != null) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Consumer<Indemnitites>(
                      builder:
                          (ctx, indemData, child) => ListView.builder(
                            itemCount: indemData.indemlist.length,
                            itemBuilder: (_, i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                child: Text(
                                  '${i + 1}.  ${indemData.indemlist[i].indemitems}',
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    wordSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                    );
                  }
                }
              },
            ),
          ),
          Consumer2<Indemnitites, StripeService>(
            builder: (context, providerA, providerB, child) {
              return TextButton.icon(
                onPressed: () {
                  Provider.of<SpecialBookingCartOut>(
                    context,
                    listen: false,
                  ).addItem(
                    '$eventid-${user.id}',
                    title,
                    int.parse(user.id),
                    pax,
                    'Agreed',
                    boatprice,
                    eventprice,
                    startdate,
                    enddate,
                    // affiliatetitle,
                    // department,
                    // institution,
                    // location,
                    // filename,
                  );
                  showBookDialog('Agreed');
                  // }
                },
                icon: const Icon(Icons.check_box),
                label: const Text('Agree & Proceed'),
              );
            },
          ),
        ],
      ),
    );
  }
}
