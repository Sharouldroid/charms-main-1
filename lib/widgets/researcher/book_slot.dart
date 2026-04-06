import 'package:charms/models/booking_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/screens/checkout_screen.dart';
import 'package:charms/widgets/researcher/group_booking.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:charms/widgets/optional/add_on.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResearcherBookSlot extends StatelessWidget {
  const ResearcherBookSlot({
    super.key,
    required this.booktype,
    required this.pax,
    required this.user,
    required this.eventid,
    required this.confirmnum,
    required this.startdate,
    required this.enddate,
    required this.hostname,
    required this.price,
    required this.title,
    required this.staff,
    required this.boatprice,
    this.affiliatetitle = '',
    this.department = '',
    this.institution = '',
    this.location = '',
    this.filename = '',
  });

  // 1 = individual, 2 = group
  final int booktype;
  final int pax;
  final User user;
  final int eventid;
  final int confirmnum;
  final String startdate;
  final String enddate;
  final String hostname;
  final double price;
  final String title;
  final bool staff;
  final int boatprice;
  final String affiliatetitle;
  final String department;
  final String institution;
  final String location;
  final String filename;

  @override
  Widget build(BuildContext context) {
    void showBookDialog(List<int> ischecked) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Would you like to purchase some add ons?',
            textAlign: TextAlign.center,
          ),
          // content:
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => AddOn(
                    hostname: hostname,
                    confirmnum: confirmnum,
                    pax: pax,
                    ischecked: 'Agreed',
                    user: user,
                    eventid: eventid,
                    booktype: booktype,
                    staff: staff,
                    volres: 2,
                    isRSS: 0,
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => CheckoutScreen(
                    confirmnum: confirmnum,
                    hostname: hostname,
                    pax: pax,
                    ischecked: 'Agreed',
                    user: user,
                    eventid: eventid,
                    booktype: booktype,
                    staff: staff,
                    volres: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // List selectedData = [];
    List<int> ischecked = [];
    final indemItems = Provider.of<Indemnitites>(
      context,
      listen: false,
    ).fetchIndemnitiesbyType(hostname, booktype == 1 ? 1 : 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          booktype == 1
              ? 'Individual Booking'
              : booktype == 2
                  ? 'Group Booking'
                  : 'Individual with Children',
        ),
      ),
      body: booktype == 1
          ? Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Name: ${user.firstname} ${user.lastname}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'IC / Passport: ${user.idnum}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Email: ${user.email}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 25),
                Text(
                  'In consideration of SEATRU (UMT) accepting my participation in the volunteer program at Chagar Hutang, Pulau Redang, Terengganu, Malaysia to be held between $startdate to $enddate , I agree to this release of claims, waiver of liability and assumption of risk.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder(
                    future: indemItems,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        if (snapshot.error != null) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else {
                          return Consumer<Indemnitites>(
                            builder: (ctx, indemData, child) =>
                                ListView.builder(
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
                        Provider.of<BookingCartOut>(
                          context,
                          listen: false,
                        ).addItem(
                          '$eventid-${user.id}',
                          title,
                          price,
                          confirmnum,
                          int.parse(user.id),
                          pax,
                          booktype,
                          'Agreed',
                          '', // Shirt size (empty for researcher if not needed)
                          'None',
                          'No health issue', // <--- FIXED: Added 10th Argument (Diet)
                        );

                        showBookDialog(ischecked);
                      },
                      icon: const Icon(Icons.check_box),
                      label: const Text('Agree & Proceed'),
                    );
                  },
                ),
              ],
            )
          : ResearcherGroupBooking(
              pax: pax,
              user: user,
              eventid: eventid,
              title: title,
              price: price,
              confirmnum: confirmnum,
              startdate: startdate,
              enddate: enddate,
              hostname: hostname,
              booktype: booktype,
              staff: staff,
            ),
    );
  }
}
