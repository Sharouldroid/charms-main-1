import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/widgets/receipt/view_receipt.dart';
import 'package:charms/widgets/volunteer/view_participant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventListBooked extends StatefulWidget {
  const EventListBooked({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
    required this.eventtype,
  });

  final bool staff;
  final User user;
  final String hostname;
  final int eventtype;

  @override
  State<EventListBooked> createState() => _EventListBookedState();
}

class _EventListBookedState extends State<EventListBooked> {
  late Future<void> _loadDataFuture;

 @override
  void initState() {
    super.initState();
    // Initial data load
    _loadDataFuture = _fetchData();
  }

  // ✅ 1. SEPARATE FETCH FUNCTION (So we can call it again later)
  Future<void> _fetchData() {
    if (!widget.staff) {
      return Provider.of<Events>(context, listen: false)
          .fetchBookedEvent(widget.hostname, widget.user.id);
    } else {
      return Provider.of<Events>(context, listen: false)
          .fetchAllBookedEvent(widget.hostname);
    }
  }

  // ✅ 2. REFRESH METHOD
  void _refreshList() {
    setState(() {
      _loadDataFuture = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle error state (e.g., 404 if no events found)
        if (snapshot.hasError) {
          // If not staff (meaning a volunteer/user), showing "No history" is friendlier than an error
          if (!widget.staff) {
            return _buildNoBookingHistoryState(context);
          }

          // For staff/admin, we might still want to see the actual error for debugging
          String errorMessage = "Failed to load booked events";
          if (snapshot.error is Map<String, dynamic> &&
              (snapshot.error as Map<String, dynamic>).containsKey('message')) {
            errorMessage = (snapshot.error as Map<String, dynamic>)['message'];
          } else if (snapshot.error.toString().isNotEmpty) {
            errorMessage = snapshot.error.toString();
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Success state
        return Consumer<Events>(
          builder: (ctx, eventData, child) {
            // Handle empty list case
            if (eventData.allbookedevents.isEmpty) {
              return _buildNoBookingHistoryState(context);
            }

            return _buildEventList(eventData);
          },
        );
      },
    );
  }

  // Helper widget for "No Booking History" state
  Widget _buildNoBookingHistoryState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_outlined, // History/Paper icon
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "No Booking History Yet",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "You haven't participated in any events yet.",
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(Events eventData) {
    return ListView.builder(
      itemCount: eventData.allbookedevents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(eventData.allbookedevents[index]);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bookings = event['bookings'] as List;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ExpansionTile(
        title: Text(
          event['title'] ?? 'Untitled Event',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "${event['startdate']} → ${event['enddate']}",
          style: const TextStyle(fontSize: 14),
        ),
        children:
            bookings.isNotEmpty
                ? [
                  ...bookings.map(
                    (booking) => _buildBookingTile(event, booking),
                  ),
                ]
                : [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No bookings found',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                ],
      ),
    );
  }

  Widget _buildBookingTile(
    Map<String, dynamic> event,
    Map<String, dynamic> booking,
  ) {
    // --- STATUS LOGIC FIX ---
    // 1 = Paid, 2 = Unpaid
    int status = 2; // Default to 2 (Unpaid)
    
    // Check booking level status first, then event level
    if (booking['paymentstatus'] != null) {
      status = int.tryParse(booking['paymentstatus'].toString()) ?? 2;
    } else if (event['paymentstatus'] != null) {
      status = int.tryParse(event['paymentstatus'].toString()) ?? 2;
    }
    
    // Define logic based on your values
    bool isPaid = (status == 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        title: Text(
          booking['name'] ?? 'No Name',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        // --- STATUS CHIP UI ---
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPaid ? Colors.green : Colors.orange,
                    width: 0.5
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.pending,
                      size: 12,
                      color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaid ? 'Paid' : 'Unpaid', // 1 shows Paid, 2 shows Unpaid
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Row(
            mainAxisSize: MainAxisSize.min,
           children: [
              // ✅ FIX: Disable Receipt Button if NOT Paid
              IconButton(
                icon: Icon(
                  Icons.receipt, 
                  size: 20, 
                  color: isPaid ? Colors.green : Colors.grey.shade300
                ),
                tooltip: isPaid ? 'View Receipt' : 'No Receipt (Unpaid)',
                onPressed: isPaid ? () => _navigateToReceipt(event, booking) : null,
              ),
              IconButton(
                icon: const Icon(Icons.view_list, size: 20),
                tooltip: 'View Participants',
                onPressed: () => _navigateToParticipants(event, booking),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReceipt(
    Map<String, dynamic> event,
    Map<String, dynamic> booking,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (ctx) => ViewReceipt(
              hostname: widget.hostname,
              event: Event.fromJson({
                ...event,
                'confirmnum': booking['confirmnum'],
                'total': booking['total'],
                'pax': booking['pax'],
              }),
              volres: 1,
            ),
      ),
    );
  }

 // Changed to async to wait for the result
  Future<void> _navigateToParticipants(
    Map<String, dynamic> event,
    Map<String, dynamic> booking,
  ) async {
    // Wait for the ViewParticipant page to close
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ViewParticipant(
          hostname: widget.hostname,
          eventid: int.parse(event['id']),
          title: event['title'],
          usertype: widget.user.usertype,
          userid: booking['userid'],
          confirmnum: booking['confirmnum'],
          currentuser: int.parse(widget.user.id),
          startdate: event['startdate'],
          enddate: event['enddate'],
        ),
      ),
    );

    // ✅ When we come back, refresh the data to check for new payments
    _refreshList();
  }
}
