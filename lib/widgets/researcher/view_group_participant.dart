import 'package:charms/providers/bookevents.dart';
import 'package:charms/widgets/researcher/expand_group_member.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResearcherViewGroupParticipant extends StatelessWidget {
  const ResearcherViewGroupParticipant({
    super.key,
    required this.programname,
    required this.confirmnum,
    required this.hostname,
    required this.booktype,
  });

  final String programname;
  final int confirmnum;
  final String hostname;
  final int booktype;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<BookEvents>(context, listen: false)
          .fetchResearcherGroup(hostname, confirmnum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.error != null) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Consumer<BookEvents>(
            builder: (ctx, memberdata, child) => ListView.builder(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: memberdata.researcherMember.length,
              itemBuilder: (_, i) {
                final member = memberdata.researcherMember[i];
                return ResearcherExpandGroupMember(
                  name: member.name,
                  idnum: member.idnum,
                  email: member.email,
                  booktype: booktype,
                  hostname: hostname,
                  confirmnum: confirmnum,
                );
              },
            ),
          );
        }
      },
    );
  }
}
