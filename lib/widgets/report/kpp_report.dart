import 'package:charms/models/user.dart';
import 'package:charms/providers/reports.dart';
import 'package:charms/widgets/kpp/kpp_event.dart';
import 'package:charms/widgets/report/report_datepick.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KPPReport extends StatefulWidget {
  const KPPReport({
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
  State<KPPReport> createState() => _KPPReportState();
}

class _KPPReportState extends State<KPPReport> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KPP Report'),
          bottom: const TabBar(tabs: [
            Tab(
              child: Text('Events'),
            ),
            Tab(
              child: Text('Monthly'),
            ),
            Tab(
              child: Text('Yearly'),
            ),
          ]),
        ),
        body: TabBarView(
          children: [
            ListView(
              shrinkWrap: true,
              children: [
                const ReportDatepick(),
                KPPEvent(
                  staff: widget.staff,
                  user: widget.user,
                  hostname: widget.hostname,
                ),
              ],
            ),
            FutureBuilder(
              future: Provider.of<Reports>(context, listen: false)
                  .fetchMonthlyReport(widget.hostname, 'kpp'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.error != null) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    return Consumer<Reports>(
                        builder: (ctx, reportdata, child) => ListView.builder(
                              shrinkWrap: true,
                              itemCount: reportdata.datamonth.length,
                              itemBuilder: (_, i) =>
                                  reportdata.datamonth.isNotEmpty
                                      ? ListTile(
                                          title: Text(
                                              '${reportdata.datamonth[i].title}'),
                                          subtitle: Text(
                                              'Total Participants: ${reportdata.datamonth[i].sum}'),
                                          trailing: Text(
                                              'Total Payment: RM ${reportdata.datamonth[i].totalamount}'),
                                          // onTap: () => Navigator.of(context).push(
                                          //     MaterialPageRoute(
                                          //         builder: (ctx) => ViewReport(
                                          //             hostname: widget.hostname,
                                          //             reportdata:
                                          //                 reportdata.data[i]))),
                                        )
                                      : const Text(
                                          'No data available',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                            ));
                  }
                }
              },
            ),
            FutureBuilder(
              future: Provider.of<Reports>(context, listen: false)
                  .fetchYearlyReport(widget.hostname, 'kpp'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.error != null) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    return Consumer<Reports>(
                        builder: (ctx, reportdata, child) => ListView.builder(
                              shrinkWrap: true,
                              itemCount: reportdata.datayear.length,
                              itemBuilder: (_, i) =>
                                  reportdata.datayear.isNotEmpty
                                      ? ListTile(
                                          title: Text(
                                              '${reportdata.datayear[i].title}'),
                                          subtitle: Text(
                                              'Total Participants: ${reportdata.datayear[i].sum}'),
                                          trailing: Text(
                                              'Total Payment: RM ${reportdata.datayear[i].totalamount}'),
                                          // onTap: () => Navigator.of(context).push(
                                          //     MaterialPageRoute(
                                          //         builder: (ctx) => ViewReport(
                                          //             hostname: widget.hostname,
                                          //             reportdata:
                                          //                 reportdata.data[i]))),
                                        )
                                      : const Text(
                                          'No data available',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                            ));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
