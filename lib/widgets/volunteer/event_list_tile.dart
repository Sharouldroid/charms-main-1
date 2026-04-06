import 'dart:async';
import 'dart:convert';
import 'package:charms/models/event.dart';
import 'package:charms/widgets/volunteer/create_event.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EventListTile extends StatefulWidget {
  const EventListTile({
    super.key,
    required this.id,
    required this.eventdata,
    required this.hostname,
    this.booked = false,
    required this.userid,
    required this.usertype,
    this.highlight = false, // default to false
  });

  final String id;
  final Event eventdata;
  final String hostname;
  final bool booked;
  final int userid;
  final int usertype;
  final bool highlight; // NEW

  @override
  State<EventListTile> createState() => _EventListTileState();
}

class _EventListTileState extends State<EventListTile> {
  late StreamController _streamController;
  Timer? _timer;
  late num slotcount;
  int initValue = 0;

  @override
  void initState() {
    super.initState();
    slotcount = widget.eventdata.slotvolunteer;
    _streamController = StreamController();
    getData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        getData();
      }
    });
  }

  Future<void> getData() async {
    if (!_streamController.isClosed) {
      try {
        var url = '${widget.hostname}event/count/${widget.id}';
        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          var apicount = data['slotcount'] ?? 0;

          if (initValue == apicount) {
            slotcount = slotcount;
          } else if (initValue > apicount) {
            slotcount += apicount;
          } else if (initValue < apicount) {
            slotcount -= apicount;
          }
          initValue = apicount;
          _streamController.add(slotcount);
        } else {
          throw Exception('Failed to fetch data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    super.dispose();
  }

  final f = DateFormat('dd-MM-yyyy');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _streamController.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Card(
            color:
                widget.highlight
                    ? Colors.amber[100]
                    : null, // Highlight if true
            child: ListTile(
              isThreeLine: true,
              title: Row(
                children: [
                  Expanded(child: Text(widget.eventdata.title)),
                  // if (widget.booked) ...[
                  //   IconButton(
                  //     icon: const Icon(Icons.receipt),
                  //     tooltip: 'View Receipt',
                  //     onPressed:
                  //         () => Navigator.of(context).push(
                  //           MaterialPageRoute(
                  //             builder:
                  //                 (ctx) => ViewReceipt(
                  //                   hostname: widget.hostname,
                  //                   event: widget.eventdata,
                  //                   volres: 1,
                  //                 ),
                  //           ),
                  //         ),
                  //   ),
                  // ],
                  if (!widget.booked &&
                      (widget.usertype == 1 || widget.usertype == 5))
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Event',
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => CreateEvent(
                                    userid: widget.userid,
                                    hostname: widget.hostname,
                                    eventdata: widget.eventdata,
                                  ),
                            ),
                          ),
                    ),
                ],
              ),
              subtitle: Text(
                '${f.format(DateTime.parse(widget.eventdata.startdate))} - '
                '${f.format(DateTime.parse(widget.eventdata.enddate))}',
              ),
              trailing:
                  !widget.booked
                      ? slotcount > 0
                          ? Text('$slotcount available')
                          : const Text('FULLY BOOKED')
                      : null,
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
