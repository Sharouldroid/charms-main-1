import 'package:charms/models/user.dart';
import 'package:charms/providers/events_daytrip.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/responsive_helper.dart';

class DaytripIndemnityScreen extends StatelessWidget {
  const DaytripIndemnityScreen({
    super.key,
    required this.title,
    required this.total,
    required this.selecteddate,
    required this.selectedtime,
    required this.hostname,
    required this.user,
    required this.pax,
    required this.companyid,
  });

  final String title;
  final int total;
  final DateTime selecteddate;
  final String selectedtime;
  final String hostname;
  final User user;
  final int pax;
  final int companyid;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Indemnity')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: Column(children: [
        const SizedBox(height: 20),
        Text(
          'Sebagai pertimbangan SEATRU (UMT) menerima permohonan saya dengan penyertaan seramai $pax orang dalam program $title di Chagar Hutang, Pulau Redang, Terengganu, Malaysia pada tarikh ${f.format(selecteddate)} dan masa $selectedtime, saya bersetuju dengan pelepasan tuntutan, pengecualian tanggungjawab, dan penerimaan risiko ini',
          textAlign: TextAlign.justify,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.yellow[200]),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FutureBuilder(
            future: Provider.of<Indemnitites>(context, listen: false)
                .fetchIndemnitiesbyType(hostname, 4),
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
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              child: Text(
                                '${i + 1}.  ${indemData.indemlist[i].indemitems}',
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                    fontSize: 18,
                                    wordSpacing: 1.5,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }));
                }
              }
            },
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            await Provider.of<EventsDaytrip>(context, listen: false)
                .applyDaytrip(
              hostname,
              int.parse(user.id),
              companyid,
              pax,
              selecteddate.toString(),
              selectedtime,
              total,
            );
            await Provider.of<EventsDaytrip>(context, listen: false)
                .storeIndemnity(hostname, 'Agree to all', int.parse(user.id));
            await Provider.of<EventsDaytrip>(context, listen: false)
                .paymentDT(hostname, total, int.parse(user.id));
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check_box),
          label: const Text('Setuju dan Bayar'),
        ),
      ]),
          ),
        ),
      ),
    );
  }
}
