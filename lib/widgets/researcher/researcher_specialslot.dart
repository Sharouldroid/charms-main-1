import 'package:charms/models/user.dart';
import 'package:charms/providers/event_groups.dart';
import 'package:charms/providers/events_special.dart';
import 'package:charms/providers/users.dart';
import 'package:charms/widgets/researcher/researcherspecial_affiliation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ResearcherSpecialSlot extends StatefulWidget {
  const ResearcherSpecialSlot({
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
  State<ResearcherSpecialSlot> createState() => _ResearcherSpecialSlotState();
}

class _ResearcherSpecialSlotState extends State<ResearcherSpecialSlot> {
  late Future<void> _loadDataFuture;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _loadDataFuture = Provider.of<EventsSpecial>(
      context,
      listen: false,
    ).fetchRSS(
      widget.hostname,
      widget.user.usertype == 1 || widget.user.usertype == 5 ? 1 : 0,
      int.parse(widget.user.id),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Pending Approval';
      case 1:
        return 'Approved';
      case 11:
        return 'Approved & Paid';
      case -1:
        return 'Rejected';
      default:
        return 'Unknown Status';
    }
  }

  void _showRejectDialog(BuildContext context, int specialId) {
    String reason = '';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Please input reject reason',
              textAlign: TextAlign.center,
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please input reject reason'
                            : null,
                onSaved: (value) => reason = value ?? '',
              ),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  child: const Text('Proceed'),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();

                    Provider.of<EventsSpecial>(
                      context,
                      listen: false,
                    ).processRSS(
                      widget.hostname,
                      specialId,
                      reason,
                      int.parse(widget.user.id),
                      -1,
                    );

                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildUserInfo(BuildContext context, int applicantId) {
    return FutureBuilder<User?>(
      future: Provider.of<Users>(
        context,
        listen: false,
      ).fetchIndividual(widget.hostname, applicantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading user info',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('User not found'));
        }
        return Text(
          'Applied by: ${snapshot.data!.firstname} ${snapshot.data!.lastname}',
        );
      },
    );
  }

  Widget _buildGroupMembers(BuildContext context, int specialId) {
    return FutureBuilder(
      future: Provider.of<EventGroups>(
        context,
        listen: false,
      ).fetchRSSGroup(widget.hostname, specialId),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle error state
        if (snapshot.hasError) {
          String errorMessage = "Error loading group members";

          // Try to extract the message from different error formats
          try {
            if (snapshot.error is Map<String, dynamic>) {
              final errorData = snapshot.error as Map<String, dynamic>;
              if (errorData.containsKey('message')) {
                errorMessage = errorData['message'];
              }
            } else if (snapshot.error is String) {
              errorMessage = snapshot.error as String;
            } else {
              errorMessage = snapshot.error.toString();
            }
          } catch (e) {
            errorMessage = "Error loading group members";
          }

          return Center(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Handle success state
        return Consumer<EventGroups>(
          builder: (ctx, groupData, child) {
            if (groupData.rssmemberlist.isEmpty) {
              return const Center(
                child: Text(
                  "No group members found",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupData.rssmemberlist.length,
              itemBuilder:
                  (_, index) => ListTile(
                    title: Text(
                      '${index + 1}. ${groupData.rssmemberlist[index].name}',
                    ),
                  ),
            );
          },
        );
      },
    );
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

        // Handle error state
        if (snapshot.hasError) {
          String errorMessage = "Failed to load special slots";

          if (snapshot.error is String) {
            errorMessage = snapshot.error as String;
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
        return Consumer<EventsSpecial>(
          builder: (ctx, rssData, child) {
            // Check if data is empty
            if (rssData.rsslist.isEmpty) {
              return const Center(
                child: Text(
                  "No special slot requests found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            // Display the list
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rssData.rsslist.length,
              itemBuilder: (_, index) {
                final item = rssData.rsslist[index];
                final isAdmin =
                    widget.user.usertype == 1 || widget.user.usertype == 5;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: ExpansionTile(
                    title: const Text('Researcher Special Slot'),
                    subtitle: _buildUserInfo(context, item.applicantid),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${_dateFormat.format(DateTime.parse(item.startdate))} '
                              '- ${_dateFormat.format(DateTime.parse(item.enddate))}',
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Status: ${_getStatusText(item.status)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.status == -1) ...[
                              const SizedBox(height: 10),
                              Text('Reason: ${item.rejectreason}'),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'Boat Arrangement: '
                              '${item.needboat == 0 ? 'Self Arrangement' : 'Needs boat arrangement'}',
                            ),
                            const SizedBox(height: 10),
                            Text('Pax: ${item.pax}'),
                            if (item.pax > 1) ...[
                              const SizedBox(height: 10),
                              const Text('Group Members:'),
                              _buildGroupMembers(context, item.id),
                            ],
                            TextButton(
                              onPressed:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (ctx) => ResearcherspecialAffiliation(
                                            hostname: widget.hostname,
                                            specialid: item.id,
                                          ),
                                    ),
                                  ),
                              child: const Text('View Affiliation'),
                            ),
                            if (isAdmin && item.status == 0) ...[
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Provider.of<EventsSpecial>(
                                        context,
                                        listen: false,
                                      ).processRSS(
                                        widget.hostname,
                                        item.id,
                                        '',
                                        int.parse(widget.user.id),
                                        1,
                                      );
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () =>
                                            _showRejectDialog(context, item.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ],
                            if (item.status == 1 &&
                                item.applicantid == int.parse(widget.user.id))
                              ElevatedButton(
                                onPressed: () async {
                                  await Provider.of<EventsSpecial>(
                                    context,
                                    listen: false,
                                  ).paymentRSS(
                                    widget.hostname,
                                    item.amount,
                                    item.id,
                                    int.parse(widget.user.id),
                                  );
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Make Payment'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
