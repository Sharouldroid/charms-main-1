import 'package:charms/models/user.dart';
import 'package:charms/widgets/volunteer/event_list_booked.dart';
import 'package:flutter/material.dart';

class VolunteerBookingHistory extends StatelessWidget {
  const VolunteerBookingHistory({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
  });

  final bool staff;
  final User user;
  final String hostname;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: EventListBooked(
        staff: staff,
        user: user,
        hostname: hostname,
        eventtype: 1,
      ),
    );
  }
}
