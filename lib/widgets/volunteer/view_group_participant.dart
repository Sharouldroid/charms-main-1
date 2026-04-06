import 'package:charms/providers/bookevents.dart';
import 'package:charms/widgets/volunteer/expand_group_member.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewGroupParticipant extends StatelessWidget {
  const ViewGroupParticipant({
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
          .fetchGroupMembers(hostname, confirmnum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Consumer<BookEvents>(
                builder: (ctx, memberdata, child) => ListView.builder(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: memberdata.groupMember.length,
                      itemBuilder: (_, i) => ExpandGroupMember(
                        name: memberdata.groupMember[i].name,
                        idnum: memberdata.groupMember[i].idnum,
                        email: memberdata.groupMember[i].email,
                        booktype: booktype,
                        hostname: hostname,
                        confirmnum: confirmnum,
                        shirtsize: memberdata.groupMember[i].shirtsize,
                      ),
                    ));
          }
        }
      },
    );
  }
}
