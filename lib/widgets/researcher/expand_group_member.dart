// import 'package:charms/providers/events_researcher.dart';
import 'package:charms/providers/event_groups.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:provider/provider.dart';

class ResearcherExpandGroupMember extends StatelessWidget {
  final String name;
  final String idnum;
  final String email;
  final int booktype;
  final String hostname;
  final int confirmnum;

  const ResearcherExpandGroupMember({
    super.key,
    required this.name,
    required this.idnum,
    required this.email,
    required this.booktype,
    required this.hostname,
    required this.confirmnum,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: $name'),
          Text('ID: $idnum'),
          Text('Email: $email'),
          FutureBuilder(
            future: Provider.of<EventGroups>(context, listen: false)
                .fetchMemberIndemnities(hostname, email, confirmnum),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.error != null) {
                return const Text(
                  'Error: User is not registered to CHARMS',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return Text(
                  snapshot.data == true
                      ? 'Indemnity Accepted'
                      : 'Indemnity Incomplete',
                  style: TextStyle(
                    color: snapshot.data == true ? Colors.green : Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
