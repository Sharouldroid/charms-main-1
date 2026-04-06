import 'package:charms/widgets/survey/list_researcher.dart';
import 'package:charms/widgets/survey/list_volunteer.dart';
import 'package:flutter/material.dart';

class ViewSurveyparticipant extends StatelessWidget {
  const ViewSurveyparticipant({
    super.key,
    required this.hostname,
    required this.eventid,
  });

  final String hostname;
  final int eventid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Survey Data'),
          // actions: [
          //     IconButton(
          //       onPressed: () => _printAllQuestions(context),
          //       icon: const Icon(Icons.print),
          //       tooltip: 'Print All Questions',
          //     ),
          // ],
          bottom: const TabBar(
            tabs: [
              Tab(child: Text('Volunteer')),
              Tab(child: Text('Researcher')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListVolunteer(eventid: eventid, hostname: hostname),
            ListResearcher(eventid: eventid, hostname: hostname)
          ],
        ),
      ),
    );
  }
}
