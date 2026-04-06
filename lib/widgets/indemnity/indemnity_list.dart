import 'package:charms/providers/indemnities.dart';
import 'package:charms/widgets/indemnity/create_indemnity.dart';
import 'package:flutter/material.dart';
// import 'package:charms/widgets/view_user.dart';
import 'package:provider/provider.dart';

class IndemnityList extends StatelessWidget {
  const IndemnityList({
    super.key,
    required this.hostname,
    required this.userid,
  });

  final String hostname;
  final int userid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<Indemnitites>(context, listen: false)
          .fetchIndemnitiesbyStatus(hostname, 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Consumer<Indemnitites>(
              builder: (ctx, indemData, child) => ListView.builder(
                itemCount: indemData.indemlist.length,
                itemBuilder: (_, i) => Dismissible(
                  key: ValueKey(indemData.indemlist[i].id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {},
                  child: ExpansionTile(
                    title: Text('Indemnity IDD_${indemData.indemlist[i].id}'),
                    subtitle: Text(indemData.indemlist[i].type == 1
                        ? 'Default'
                        : indemData.indemlist[i].type < 3
                            ? 'With Kids'
                            : 'Day Trip'),
                    trailing: IconButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => CreateIndemnity(
                                      userid: userid,
                                      hostname: hostname,
                                      indemitems: indemData.indemlist,
                                      id: indemData.indemlist[i].id,
                                      index: i,
                                    ))),
                        icon: const Icon(Icons.edit)),
                    children: [
                      Text(indemData.indemlist[i].indemitems,
                          textAlign: TextAlign.justify)
                    ],
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }
}
