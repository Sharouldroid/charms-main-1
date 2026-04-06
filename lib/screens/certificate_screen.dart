import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/widgets/certificate/certificate_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/responsive_helper.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({
    super.key,
    required this.isadmin,
    required this.user,
    required this.hostname,
    required this.volorres,
  });

  final bool isadmin;
  final User user;
  final String hostname;
  final int volorres;

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('E-Certificate')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FutureBuilder(
        future: Provider.of<Events>(
          context,
          listen: false,
        ).fetchBookedEvent(hostname, int.parse(user.id).toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.error != null) {
            // SCENARIO 1: An error occurred (likely 404 Not Found or similar)
            // Instead of showing the raw error, we show the friendly message.
            return _buildNoCertificatesState(context);
          } else {
            return Consumer<Events>(
              builder: (ctx, eventData, child) {
                final events = eventData.allbookedevents;

                // SCENARIO 2: No error, but the list is empty
                if (events.isEmpty) {
                  return _buildNoCertificatesState(context);
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (_, i) {
                    final event = events[i];
                    final bookings = event['bookings'] as List;
                    final confirmnum =
                        bookings.isNotEmpty ? bookings[0]['confirmnum'] : null;

                    return CertificateList(
                      hostname: hostname,
                      eventData: Event.fromJson(event),
                      user: user,
                      confirmnum: confirmnum,
                    );
                  },
                );
              },
            );
          }
        },
      ),
        ),
      ),
    );
  }

  // Helper widget to show the friendly message
  Widget _buildNoCertificatesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined, // Certificate icon
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              "No Certificates Found",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              "You have not participated in any volunteer programs yet.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
