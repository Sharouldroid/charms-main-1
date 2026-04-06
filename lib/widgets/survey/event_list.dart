import 'package:charms/models/event.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/widgets/survey/view_surveyparticipant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventList extends StatefulWidget {
  const EventList({
    super.key,
    required this.admin,
    required this.userid,
    required this.hostname,
    required this.isLabOfficer,
  });

  final bool admin;
  final int userid;
  final String hostname;
  final bool isLabOfficer;

  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DateFormat f = DateFormat('dd-MM-yyyy');
  List<Event> _filteredEvents = [];
  List<Event> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterEvents(_searchController.text);
  }

  void _filterEvents(String query) {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final titleLower = event.title.toLowerCase();
        final startDate = f.format(DateTime.parse(event.startdate));
        final endDate = f.format(DateTime.parse(event.enddate));
        final queryLower = query.toLowerCase();

        return titleLower.contains(queryLower) ||
            startDate.contains(queryLower) ||
            endDate.contains(queryLower);
      }).toList();
    });
  }

  List<TextSpan> _highlightOccurrences(String source, String query) {
    if (query.isEmpty || !source.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: source)];
    }

    final matches = query.toLowerCase().allMatches(source.toLowerCase());
    final result = <TextSpan>[];
    var lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        result.add(TextSpan(
          text: source.substring(lastMatchEnd, match.start),
        ));
      }

      result.add(TextSpan(
        text: source.substring(match.start, match.end),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < source.length) {
      result.add(TextSpan(text: source.substring(lastMatchEnd)));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<Events>(context, listen: false)
          .fetchEventAdmin(widget.hostname, 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.error != null) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        return Consumer<Events>(
          builder: (ctx, eventData, child) {
            // Initialize data only once
            if (_allEvents.isEmpty) {
              _allEvents = eventData.eventlist;
              _filteredEvents = _allEvents;
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Search by title or date',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filteredEvents = _allEvents;
                                setState(() {});
                                _searchFocusNode.requestFocus();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredEvents.isEmpty
                      ? const Center(child: Text('No matching events found'))
                      : ListView.builder(
                          itemCount: _filteredEvents.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) => ViewSurveyparticipant(
                                          hostname: widget.hostname,
                                          eventid: int.parse(
                                              eventData.eventlist[i].id),
                                        ))),
                            child: ListTile(
                              title: Text.rich(
                                TextSpan(
                                  children: _highlightOccurrences(
                                    _filteredEvents[i].title,
                                    _searchController.text,
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                '${f.format(DateTime.parse(_filteredEvents[i].startdate))} - '
                                '${f.format(DateTime.parse(_filteredEvents[i].enddate))}',
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
