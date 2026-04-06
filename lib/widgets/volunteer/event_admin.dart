import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/widgets/volunteer/event_list_tile.dart';
import 'package:charms/widgets/volunteer/view_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventAdmin extends StatelessWidget {
  const EventAdmin({
    super.key,
    required this.id,
    required this.user,
    required this.eventdata,
    required this.hostname,
  });

  final String id;
  final User user;
  final Event eventdata;
  final String hostname;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return Dismissible(
      key: ValueKey(id),
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
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ViewEvent(
              title: eventdata.title,
              startdate: f.format(DateTime.parse(eventdata.startdate)),
              enddate: f.format(DateTime.parse(eventdata.enddate)),
              staff: true,
              user: user,
              eventid: int.parse(id),
              hostname: hostname,
              datediff: DateTime.now()
                  .difference(DateTime.parse(eventdata.startdate)),
              datebook: '',
              // isgroup: 0,
              price: eventdata.price,
              total: 0,
              status: eventdata.status,
              cancelreason: eventdata.cancelreason.toString(),
              slotvolunteer: eventdata.slotvolunteer,
            ),
          ),
        ),
        child: EventListTile(
          id: id,
          eventdata: eventdata,
          hostname: hostname,
          userid: int.parse(user.id),
          // price: price,
          usertype: user.usertype,
        ),
      ),
    );
  }
}
