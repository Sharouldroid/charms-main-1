import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/surveys.dart';
import 'package:charms/widgets/certificate/view_certificate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CertificateList extends StatelessWidget {
  const CertificateList({
    super.key,
    required this.hostname,
    required this.eventData,
    required this.user,
    required this.confirmnum,
  });

  final String hostname;
  final Event eventData;
  final User user;
  final int confirmnum;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<Surveys>(
        context,
        listen: false,
      ).fetchExitSurvey(hostname, int.parse(user.id), confirmnum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(child: Text('Error: Error retrieving data'));
            // return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data == true
                ? GestureDetector(
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (ctx) =>
                                  ViewCertificate(event: eventData, user: user),
                        ),
                      ),
                  child: ListTile(
                    title: Text(eventData.title),
                    subtitle: Text('Confirmation Number: $confirmnum'),
                  ),
                )
                : ListTile(
                  title: Text(eventData.title),
                  // subtitle: Text('Confirmation Number: $confirmnum'),
                  subtitle: Text(
                    'Available once exit survey is completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 15,
                    ),
                  ),
                );
          }
        }
      },
    );
  }
}
