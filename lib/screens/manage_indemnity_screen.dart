import 'package:charms/widgets/indemnity/create_indemnity.dart';
import 'package:charms/widgets/indemnity/indemnity_list.dart';
import 'package:flutter/material.dart';
import 'package:charms/utils/responsive_helper.dart';

class ManageIndemnityScreen extends StatelessWidget {
  const ManageIndemnityScreen(
      {super.key, required this.userid, required this.hostname});

  final int userid;
  final String hostname;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Liability'),
          actions: [
            IconButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => CreateIndemnity(
                          userid: userid,
                          hostname: hostname,
                          indemitems: const [],
                          id: 0,
                        ))),
                icon: const Icon(Icons.add))
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
            child: IndemnityList(hostname: hostname, userid: userid),
          ),
        ));
  }
}
