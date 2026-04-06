import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/providers/reports.dart';
import 'package:charms/widgets/report/view_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VolunteerReport extends StatefulWidget {
  const VolunteerReport({
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
  State<VolunteerReport> createState() => _VolunteerReportState();
}

DateTime? _startDate;
DateTime? _endDate;

class _VolunteerReportState extends State<VolunteerReport> {
  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Volunteer Report'),
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
                ExpansionTile(
                  title: const Text('Search'),
                  children: [
                    Row(
                      children: [
                        Text(_startDate != null
                            ? '${_startDate!.day}-${_startDate!.month}-${_startDate!.year}'
                            : 'Select first date'),
                        // Text(
                        //   '${_startDate!.day}-${_startDate!.month}-${_startDate!.year}',
                        // ),

                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            _startDate = await pickDate();

                            if (_startDate == null) return;

                            // setState(() => _startDate = _startDate!);
                            setState(() {
                              _startDate = _startDate!;
                            });
                          },
                          icon: const Icon(Icons.calendar_month),
                        ),
                        // const Spacer(),
                        // Text(
                        //   '${_endDate!.day}-${_endDate!.month}-${_endDate!.year}',
                        // ),

                        Text(_endDate != null
                            ? '${_endDate!.day}-${_endDate!.month}-${_endDate!.year}'
                            : 'Select last date'),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            _endDate = await pickDate();

                            if (_endDate == null) return;

                            // setState(() => _endDate = _endDate!);
                            setState(() {
                              _endDate = _endDate!;
                            });
                          },
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => FutureBuilder(
                        future: Provider.of<Reports>(context, listen: false)
                            .fetchrangereport(widget.hostname,
                                _startDate.toString(), _endDate.toString()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
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
                                          title: Text(
                                              eventData.eventlist[i].title),
                                          subtitle: Text(
                                              '${f.format(DateTime.parse(eventData.eventlist[i].startdate))} - ${f.format(DateTime.parse(eventData.eventlist[i].enddate))}'),
                                          onTap: () => Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                  builder: (ctx) => ViewReport(
                                                      hostname: widget.hostname,
                                                      eventdata: eventData
                                                          .eventlist[i]))),
                                        ),
                                      ));
                            }
                          }
                        },
                      ),
                      label: const Text('Search'),
                      icon: const Icon(Icons.search),
                    )
                  ],
                ),
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
                  .fetchMonthlyReport(widget.hostname, 'volunteer'),
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
                                              'Total Volunteers: ${reportdata.datamonth[i].sum}'),
                                          trailing: Text(
                                              'Total Payment: RM ${reportdata.datamonth[i].totalamount.toStringAsFixed(2)}'),
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
                  .fetchYearlyReport(widget.hostname, 'volunteer'),
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
                                              'Total Volunteers: ${reportdata.datayear[i].sum}'),
                                          trailing: Text(
                                              'Total Payment: RM ${reportdata.datayear[i].totalamount.toStringAsFixed(2)}'),
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

  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now());
}
