import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/widgets/volunteer/event_admin.dart';
import 'package:charms/widgets/volunteer/event_list_tile.dart';
import 'package:charms/widgets/volunteer/view_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VolunteerEventList extends StatefulWidget {
  const VolunteerEventList({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
    this.highlightedEventId,
  });

  final bool staff;
  final User user;
  final String hostname;
  final int? highlightedEventId;

  @override
  State<VolunteerEventList> createState() => _VolunteerEventListState();
}

class _VolunteerEventListState extends State<VolunteerEventList>
    with AutomaticKeepAliveClientMixin {
  
  // --- Pagination Variables ---
  int _page = 1;
  final int _itemsPerPage = 6; 
  bool _isLoading = true;
  // ----------------------------

  int? _highlightedEventId;

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    _highlightedEventId = widget.highlightedEventId;

    // Load ALL data once
    _loadAllData();

    if (_highlightedEventId != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedEventId = null;
          });
        }
      });
    }
  }

  Future<void> _loadAllData() async {
    try {
      final eventsProvider = Provider.of<Events>(context, listen: false);
      if (widget.staff) {
        await eventsProvider.fetchEventAdmin(widget.hostname, 1);
      } else {
        await eventsProvider.fetchEventGeneral(widget.hostname, 1);
      }
    } catch (e) {
      print("Error loading events: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final f = DateFormat('dd-MM-yyyy');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<Events>(
      builder: (ctx, eventData, child) {
        final allEvents = eventData.eventlist;

        if (allEvents.isEmpty) {
          return const Center(child: Text('No available events'));
        }

        // --- CLIENT SIDE SLICING LOGIC ---
        final int totalPages = (allEvents.length / _itemsPerPage).ceil();
        
        // Safety check
        if (_page > totalPages) _page = 1;
        if (_page < 1) _page = 1;

        final int startIndex = (_page - 1) * _itemsPerPage;
        final int endIndex = startIndex + _itemsPerPage;
        
        final displayedEvents = allEvents.sublist(
          startIndex, 
          endIndex > allEvents.length ? allEvents.length : endIndex
        );
        // ---------------------------------

        return ListView.builder(
          key: const PageStorageKey('events-list-key'),
          // +1 for the Pagination Row at the bottom
          itemCount: displayedEvents.length + 1, 
          padding: const EdgeInsets.only(bottom: 80), 
          itemBuilder: (_, i) {
            
            // --- RENDER PAGINATION CONTROLS (Last Item) ---
            if (i == displayedEvents.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    // 1. FIRST PAGE (<<)
                    IconButton(
                      tooltip: 'First Page',
                      icon: const Icon(Icons.first_page),
                      onPressed: _page > 1
                          ? () => setState(() => _page = 1)
                          : null, 
                    ),

                    // 2. PREVIOUS (<)
                    IconButton(
                      tooltip: 'Previous',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page > 1
                          ? () => setState(() => _page--)
                          : null, 
                    ),
                    
                    const SizedBox(width: 8),

                    // 3. DROPDOWN PAGE SELECTOR
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _page,
                          icon: const Icon(Icons.arrow_drop_down),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _page = newValue;
                              });
                            }
                          },
                          items: List.generate(totalPages, (index) => index + 1)
                              .map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),

                    // 4. NEXT (>)
                    IconButton(
                      tooltip: 'Next',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page < totalPages
                          ? () => setState(() => _page++)
                          : null, 
                    ),

                    // 5. LAST PAGE (>>)
                    IconButton(
                      tooltip: 'Last Page',
                      icon: const Icon(Icons.last_page),
                      onPressed: _page < totalPages
                          ? () => setState(() => _page = totalPages)
                          : null, 
                    ),
                  ],
                ),
              );
            }

            // --- RENDER EVENT ITEM ---
            final event = displayedEvents[i];

            return widget.staff
                ? EventAdmin(
                    key: ValueKey(event.id),
                    id: event.id,
                    eventdata: event,
                    user: widget.user,
                    hostname: widget.hostname,
                  )
                : GestureDetector(
                    key: ValueKey(event.id),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ViewEvent(
                            title: event.title,
                            startdate: f.format(
                                DateTime.parse(event.startdate)),
                            enddate: f.format(
                                DateTime.parse(event.enddate)),
                            staff: widget.staff,
                            user: widget.user,
                            eventid: int.parse(event.id),
                            hostname: widget.hostname,
                            datediff: DateTime.now().difference(
                                DateTime.parse(event.startdate)),
                            datebook: '',
                            price: event.price,
                            total: 0,
                            status: event.status,
                            cancelreason:
                                event.cancelreason.toString(),
                            slotvolunteer: event.slotvolunteer,
                          ),
                        ),
                      );
                    },
                    child: EventListTile(
                      id: event.id,
                      eventdata: event,
                      hostname: widget.hostname,
                      userid: int.parse(widget.user.id),
                      usertype: widget.user.usertype,
                      highlight: _highlightedEventId ==
                          int.tryParse(event.id),
                    ),
                  );
          },
        );
      },
    );
  }
}