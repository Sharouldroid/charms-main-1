import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/providers/reports.dart';
import 'package:charms/widgets/report/report_datepick.dart';
import 'package:charms/widgets/report/view_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ResearcherReport extends StatefulWidget {
  const ResearcherReport({
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
  State<ResearcherReport> createState() => _ResearcherReportState();
}

class _ResearcherReportState extends State<ResearcherReport> {
  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Researcher Report'),
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
                FutureBuilder(
                  future: Provider.of<Events>(context, listen: false)
                      .fetchEventAdmin(widget.hostname, widget.eventtype),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      if (snapshot.error != null) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      } else {
                        return Consumer<Events>(
                            builder: (ctx, eventData, child) =>
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: eventData.eventlist.length,
                                  itemBuilder: (_, i) => ListTile(
                                    title: Text(eventData.eventlist[i].title),
                                    subtitle: Text(
                                        '${f.format(DateTime.parse(eventData.eventlist[i].startdate))} - ${f.format(DateTime.parse(eventData.eventlist[i].enddate))}'),
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (ctx) => ViewReport(
                                                hostname: widget.hostname,
                                                eventdata:
                                                    eventData.eventlist[i]))),
                                  ),
                                ));
                      }
                    }
                  },
                ),
              ],
            ),
            FutureBuilder(
              future: Provider.of<Reports>(context, listen: false)
                  .fetchMonthlyReport(widget.hostname, 'researcher'),
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
                                              'Total Researchers: ${reportdata.datamonth[i].sum}'),
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
                  .fetchYearlyReport(widget.hostname, 'researcher'),
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
                                              'Total Researchers: ${reportdata.datayear[i].sum}'),
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
