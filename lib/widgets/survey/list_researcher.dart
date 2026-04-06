import 'package:charms/providers/surveys.dart';
import 'package:charms/widgets/survey/view_answer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ListResearcher extends StatefulWidget {
  const ListResearcher({
    super.key,
    required this.eventid,
    required this.hostname,
  });

  final int eventid;
  final String hostname;

  @override
  State<ListResearcher> createState() => _ListResearcherState();
}

class _ListResearcherState extends State<ListResearcher> {
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = Provider.of<Surveys>(context, listen: false)
        .fetchBookedResbyId(widget.hostname, widget.eventid);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat f = DateFormat('dd-MM-yyyy');

    return FutureBuilder(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle error state
        if (snapshot.hasError) {
          String errorMessage = "Failed to load volunteer data";

          // Try to get detailed error message
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
        return Consumer<Surveys>(
          builder: (context, surveyData, child) {
            // Check if data is empty
            if (surveyData.reslist.isEmpty) {
              return const Center(
                child: Text(
                  "No researchers found for this event",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            // Display the list
            return ListView.builder(
              shrinkWrap: true,
              itemCount: surveyData.reslist.length,
              itemBuilder: (context, index) {
                final volunteer = surveyData.reslist[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => ViewAnswer(
                              hostname: widget.hostname,
                              userid: int.parse(volunteer['userid']),
                              confirmnum: int.parse(volunteer['confirmnum']),
                            ))),
                    title: Text(volunteer['name']?.toString() ?? 'No Title'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Confirmation Number: ${volunteer['confirmnum'] ?? 'N/A'}'),
                        Text(
                            'Book Date: ${f.format(DateTime.parse(volunteer['datebook']))}'),
                      ],
                    ),
                    // Add more fields as needed
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
