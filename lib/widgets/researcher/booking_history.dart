import 'package:charms/models/user.dart';
import 'package:charms/widgets/researcher/researcher_booked.dart';
import 'package:charms/widgets/researcher/researcher_specialslot.dart';
import 'package:flutter/material.dart';

class ResearcherBookingHistory extends StatelessWidget {
  const ResearcherBookingHistory({
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
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: Column(
        children: [
          ResearcherBooked(
            staff: staff,
            user: user,
            hostname: hostname,
            eventtype: 1,
          ),
          const Divider(thickness: 5),
          const Text('Special Slot'),
          ResearcherSpecialSlot(
            staff: staff,
            user: user,
            hostname: hostname,
            eventtype: 1,
          ),
        ],
      ),
    );
  }
}
