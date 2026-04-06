import 'package:charms/models/event.dart';
import 'package:charms/providers/surveys.dart';
import 'package:charms/widgets/survey/exit_survey.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExitSurveyList extends StatelessWidget {
  const ExitSurveyList({
    super.key,
    required this.hostname,
    required this.eventData,
    required this.userid,
    required this.confirmnum,
  });

  final String hostname;
  final Event eventData;
  final int userid;
  final int confirmnum;

  @override
  Widget build(BuildContext context) {
    final enddate = DateTime.parse(eventData.enddate);
    final currentdate = DateTime.now();
    return FutureBuilder(
      future: Provider.of<Surveys>(
        context,
        listen: false,
      ).fetchExitSurvey(hostname, userid, confirmnum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data == false
                ? currentdate.isAfter(enddate)
                    ? GestureDetector(
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => ExitSurvey(
                                    hostname: hostname,
                                    eventname: eventData.title,
                                    userid: userid,
                                    eventid: int.parse(eventData.id),
                                    confirmnum: confirmnum,
                                  ),
                            ),
                          ),
                      child: ListTile(
                        title: Text(eventData.title),
                        subtitle: Text('Confirmation Number: $confirmnum'),
                      ),
                    )
                    : ListTile(
                      title: Text(eventData.title),
                      subtitle: Text(
                        'Available once end date has passed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                : snapshot.data == null
                ? Text(
                  'You have no booking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                )
                : ListTile(
                  title: Text(eventData.title),
                  subtitle: Text('Confirmation Number: $confirmnum'),
                  trailing: Text(
                    'Survey Completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
          }
        }
      },
    );
  }
}
