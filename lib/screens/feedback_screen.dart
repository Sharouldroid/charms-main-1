import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/widgets/survey/entrysurvey_list.dart';
import 'package:charms/widgets/survey/exitsurvey_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({
    super.key,
    required this.isadmin,
    required this.user,
    required this.hostname,
    required this.volorres,
  });

  final bool isadmin;
  final User user;
  final String hostname;
  final int volorres;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: FutureBuilder(
        future: Provider.of<Events>(
          context,
          listen: false,
        ).fetchBookedEvent(hostname, user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.error != null) {
            // SCENARIO 1: An error occurred (likely 404 because no events found)
            return Scaffold(
              appBar: AppBar(title: const Text('Surveys')),
              body: _buildNoSurveysState(context),
            );
          } else {
            return Consumer<Events>(
              builder: (ctx, eventData, child) {
                // SCENARIO 2: Success, but list is empty
                if (eventData.allbookedevents.isEmpty) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Surveys')),
                    body: _buildNoSurveysState(context),
                  );
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Surveys'),
                    bottom: const TabBar(
                      tabs: [
                        Tab(text: 'Entry Survey'),
                        Tab(text: 'Exit Survey'),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      // --- Entry Survey List ---
                      ListView.builder(
                        itemCount: eventData.allbookedevents.length,
                        itemBuilder: (_, i) {
                          final event = eventData.allbookedevents[i];
                          return EntrySurveyList(
                            hostname: hostname,
                            eventData: Event.fromJson(event),
                            userid: int.parse(user.id),
                            confirmnum: event['bookings'][0]['confirmnum'],
                          );
                        },
                      ),
                      // --- Exit Survey List ---
                      ListView.builder(
                        itemCount: eventData.allbookedevents.length,
                        itemBuilder: (_, i) {
                          final event = eventData.allbookedevents[i];
                          return ExitSurveyList(
                            hostname: hostname,
                            eventData: Event.fromJson(event),
                            userid: int.parse(user.id),
                            confirmnum: event['bookings'][0]['confirmnum'],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Helper widget for the "No Surveys" state
  Widget _buildNoSurveysState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined, // Survey/Clipboard icon
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              "No Surveys Found",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              "You have no pending entry or exit surveys at this time.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}