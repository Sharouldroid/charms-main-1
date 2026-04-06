import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:charms/models/user.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/widgets/researcher/book_slot.dart';
import 'package:charms/widgets/researcher/view_researcher.dart';

class ResearcherViewEvent extends StatefulWidget {
  const ResearcherViewEvent({
    super.key,
    required this.title,
    required this.startdate,
    required this.enddate,
    required this.eventid,
    required this.datebook,
    required this.price,
    this.confirmnum = 0,
    required this.staff,
    required this.user,
    required this.hostname,
    required this.datediff,
    this.booktype = 0,
    this.ischild = false,
    this.pax = 1,
    this.paid = 0,
    required this.total,
    required this.status,
    required this.cancelreason,
    required this.slotresearcher,
  });

  final String title;
  final String startdate;
  final String enddate;
  final int eventid;
  final String datebook;
  final double price;
  final int confirmnum;
  final bool staff;
  final User user;
  final String hostname;
  final Duration datediff;
  final int booktype;
  final bool ischild;
  final int pax;
  final int paid;
  final double total;
  final int status;
  final String cancelreason;
  final int slotresearcher;

  @override
  State<ResearcherViewEvent> createState() => _ResearcherViewEventState();
}

class _ResearcherViewEventState extends State<ResearcherViewEvent> {
  final StreamController<int> _slotStreamController = StreamController<int>();
  final GlobalKey<FormState> _formKey = GlobalKey();
  int pax = 1;
  int confirmnum = 0;
  int initValue = 0;
  late int slotcount;
  String? _currentPosterUrl;
  bool _posterLoading = false;
  bool _posterError = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPoster();
    slotcount = widget.slotresearcher;
    _startSlotUpdates();
  }

  @override
  void dispose() {
    _slotStreamController.close();
    super.dispose();
  }

  Future<void> _loadCurrentPoster() async {
    setState(() {
      _posterLoading = true;
      _posterError = false;
    });

    try {
      final response = await http
          .get(Uri.parse('${widget.hostname}fileupload/getcurrentposter'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentPosterUrl = data['url'];
          _posterLoading = false;
        });
      } else {
        setState(() {
          _posterLoading = false;
          _posterError = true;
        });
      }
    } catch (e) {
      setState(() {
        _posterLoading = false;
        _posterError = true;
      });
      debugPrint('Error loading poster: $e');
    }
  }

  Future<void> _startSlotUpdates() async {
    // Initial fetch
    Provider.of<ResearcherEvents>(context, listen: false).fetchSlot;

    // Set up periodic updates (every 30 seconds)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_slotStreamController.isClosed) {
        Provider.of<ResearcherEvents>(context, listen: false).fetchSlot;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _proceed(int pax, int type) async {
    if (type != 1 && !_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState?.save();

    // Generate confirmation number
    final rnd = math.Random();
    confirmnum = 100000 + rnd.nextInt(900000);

    try {
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (ctx) => ResearcherBookSlot(
                booktype: type,
                pax: pax,
                user: widget.user,
                eventid: widget.eventid,
                confirmnum: confirmnum,
                startdate: widget.startdate,
                enddate: widget.enddate,
                hostname: widget.hostname,
                price: widget.price,
                title: widget.title,
                staff: widget.staff,
                boatprice: 0,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString()}')),
        );
      }
    }
  }

  void _showBookingTypeDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Choose your booking type',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Individual'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _proceed(1, 1);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.groups_2),
                  label: const Text('Group'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showGroupSizeDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showGroupSizeDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Enter total volunteers',
              textAlign: TextAlign.center,
            ),
            content: Form(
              key: _formKey,
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of participants',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  final numValue = int.tryParse(value) ?? 0;
                  if (numValue <= 1 || numValue > slotcount) {
                    return 'Must be between 2 and $slotcount';
                  }
                  return null;
                },
                onSaved: (value) => pax = int.parse(value!),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(ctx);
                    _proceed(pax, 2);
                  }
                },
                child: const Text('Proceed'),
              ),
            ],
          ),
    );
  }

  Widget _buildBookingButton() {
    if (widget.staff) return const SizedBox.shrink();
    if (widget.datediff.inDays >= 0) return const Text('This slot has passed');
    if (widget.datebook.isNotEmpty) {
      return Text('You have booked this program on ${widget.datebook}');
    }

    return FutureBuilder<bool>(
      future: _checkIfAlreadyBooked(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.data == true) {
          return const Text(
            'You have already booked this event',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          );
        }

        return slotcount <= 0
            ? const Text('Fully Booked')
            : TextButton.icon(
              onPressed: _showBookingTypeDialog,
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Book'),
            );
      },
    );
  }

  Future<bool> _checkIfAlreadyBooked() async {
    try {
      final eventsProvider = Provider.of<ResearcherEvents>(
        context,
        listen: false,
      );

      // Check direct booking
      final isBooked = await eventsProvider.checkBooked(
        widget.hostname,
        widget.eventid,
        int.parse(widget.user.id),
        2,
      );

      if (isBooked) return true;

      // Check as member
      return await eventsProvider.checkBookedMembers(
        widget.hostname,
        widget.eventid,
        widget.user.email,
      );
    } catch (e) {
      debugPrint('Error checking booking status: $e');
      return false;
    }
  }

  Widget _buildPosterWidget() {
    if (_posterLoading) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_posterError || _currentPosterUrl == null) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No poster available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: AspectRatio(
            aspectRatio:
                16 / 9, // Common poster aspect ratio (adjust as needed)
            child: Image.network(
              _currentPosterUrl!,
              fit:
                  BoxFit.contain, // Changed from BoxFit.cover to BoxFit.contain
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load poster',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Scaffold(
                          appBar: AppBar(),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(_currentPosterUrl!),
                            ),
                          ),
                        ),
                  ),
                );
              },
              child: _buildPosterWidget(), // Your existing widget
            ),
            const SizedBox(height: 20),
            _buildEventDates(),
            const SizedBox(height: 20),
            _buildBookingButton(),
            if (widget.staff) _buildStaffButton(),
            if (widget.confirmnum != 0) _buildBookingDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDates() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.startdate,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          ' - ',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          widget.enddate,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStaffButton() {
    return TextButton.icon(
      onPressed:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (ctx) => ViewResearcher(
                    hostname: widget.hostname,
                    eventid: widget.eventid,
                    title: widget.title,
                    user: widget.user,
                    confirmnum: widget.confirmnum,
                    total: widget.total,
                  ),
            ),
          ),
      icon: const Icon(Icons.list),
      label: const Text('Participants List'),
    );
  }

  Widget _buildBookingDetails() {
    return ExpansionTile(
      title: Text(
        widget.booktype == 1 ? 'Individual Booking' : 'Group Booking',
      ),
      children: [
        Text('Booking Confirmation Number: ${widget.confirmnum}'),
        FutureBuilder(
          future: Provider.of<ResearcherEvents>(
            context,
            listen: false,
          ).fetchPaymentRecord(widget.hostname, widget.confirmnum),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            return Consumer<ResearcherEvents>(
              builder: (ctx, eventData, _) {
                if (eventData.paymentrecord.isEmpty) {
                  return ElevatedButton.icon(
                    onPressed: () => _handlePayment(),
                    icon: const Icon(Icons.payment),
                    label: Text('Pay RM ${widget.total}'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventData.paymentrecord.length,
                  itemBuilder:
                      (_, i) => Column(
                        children: [
                          Text(
                            'Paid on: ${eventData.paymentrecord[i].date}',
                            style: const TextStyle(color: Colors.green),
                          ),
                          Text(
                            'Payment ID: ${eventData.paymentrecord[i].paymentid}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    try {
      await Provider.of<StripeService>(context, listen: false).makePayment(
        widget.hostname,
        widget.total,
        widget.confirmnum,
        2,
        widget.eventid,
        int.parse(widget.user.id),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    }
  }
}
