import 'package:charms/models/user.dart';
import 'package:charms/widgets/report/report_datepick.dart';
import 'package:flutter/material.dart';

class BoatReport extends StatefulWidget {
  const BoatReport({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
    required this.eventtype,
  });

  final bool staff;
  final User user;
  final String hostname;
  final int eventtype;

  @override
  State<BoatReport> createState() => _BoatReportState();
}

class _BoatReportState extends State<BoatReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boat Report'),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          const ReportDatepick(),
          const Text('In development')
          // FutureBuilder(
          //   future: Provider.of<Events>(context, listen: false)
          //       .fetchEventAdmin(widget.hostname, widget.eventtype),
          //   builder: (context, snapshot) {
          //     if (snapshot.connectionState == ConnectionState.waiting) {
          //       return const Center(child: CircularProgressIndicator());
          //     } else {
          //       if (snapshot.error != null) {
          //         return Center(
          //           child: Text('Error: ${snapshot.error}'),
          //         );
          //       } else {
          //         return Consumer<Events>(
          //             builder: (ctx, eventData, child) => ListView.builder(
          //                   shrinkWrap: true,
          //                   itemCount: eventData.eventlist.length,
          //                   itemBuilder: (_, i) => ListTile(
          //                     title: Text(eventData.eventlist[i].title),
          //                     subtitle: Text(
          //                         '${f.format(DateTime.parse(eventData.eventlist[i].startdate))} - ${f.format(DateTime.parse(eventData.eventlist[i].enddate))}'),
          //                     onTap: () => Navigator.of(context).push(
          //                         MaterialPageRoute(
          //                             builder: (ctx) => ViewReport(
          //                                 hostname: widget.hostname,
          //                                 eventdata: eventData.eventlist[i]))),
          //                   ),
          //                 ));
          //       }
          //     }
          //   },
          // ),
        ],
      ),
    );
  }
}
