import 'package:charms/widgets/boat/add_boat.dart';
import 'package:charms/widgets/boat/boat_management.dart';
import 'package:flutter/material.dart';
import 'package:charms/utils/responsive_helper.dart';

class ManageBoatScreen extends StatelessWidget {
  const ManageBoatScreen({
    super.key,
    required this.hostname,
    required this.userid,
    required this.companyid,
  });

  final String hostname;
  final int userid;
  final int companyid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengurusan Bot'),
        actions: [
          IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => AddBoat(
                      boatid: 0,
                      hostname: hostname,
                      boatdata: const [],
                      companyid: companyid,
                    ),
                  )),
              icon: const Icon(Icons.add)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
          child: BoatManagement(
              hostname: hostname, companyid: companyid, userid: userid),
        ),
      ),
    );
  }
}
