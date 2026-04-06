import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/screens/researcher_screen.dart';
import 'package:charms/widgets/volunteer/event_list.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({
    super.key,
    required this.hostname,
    required this.staff,
    required this.user,
    required this.usertype,
  });

  final String hostname;
  final bool staff;
  final User user;
  final int usertype;

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late final ValueNotifier<List<Event2>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Provider.of<Events>(
        context,
        listen: false,
      ).fetchCalendarEvent(widget.hostname).then((_) {
        final events = _getEventsForDay(_selectedDay!);
        _selectedEvents.value = events;
      });
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event2> _getEventsForDay(DateTime day) {
    final ks = Provider.of<Events>(context, listen: false);
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return ks.kEventSource[normalizedDay] ?? [];
  }

  List<Event2> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return [for (final d in days) ..._getEventsForDay(d)];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime.now().subtract(const Duration(days: 1000));
    DateTime lastDay = DateTime.now().add(const Duration(days: 1000));
    
    final isTablet = ResponsiveHelper.isTablet(context);
    final calendarPadding = isTablet ? 16.0 : 12.0;
    final cardMargin = isTablet ? 16.0 : 12.0;
    final rowHeight = isTablet ? 56.0 : 52.0;

    return Column(
      children: [
        Card(
          margin: EdgeInsets.all(cardMargin),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(calendarPadding),
            child: TableCalendar<Event2>(
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarFormat: _calendarFormat,
              rangeSelectionMode: _rangeSelectionMode,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              rowHeight: rowHeight,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: TextStyle(color: Colors.redAccent, fontSize: isTablet ? 14 : 12),
                weekdayStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: isTablet ? 14 : 12),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.bold),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                formatButtonDecoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.blueAccent,
                  size: isTablet ? 28 : 24,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.blueAccent,
                  size: isTablet ? 28 : 24,
                ),
              ),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                cellMargin: EdgeInsets.all(isTablet ? 6 : 4),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                withinRangeDecoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
        ),

        const SizedBox(height: 10),
        ValueListenableBuilder<List<Event2>>(
          valueListenable: _selectedEvents,
          builder: (context, value, _) {
            if (value.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No events on this date'),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: value.length,
              itemBuilder: (context, index) {
                final event = value[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event_note),
                    title: Text(event.title),
                    subtitle: Text('Event ID: ${event.id}'),
                    onTap: () {
                      widget.usertype == 1 ||
                              widget.usertype == 2 ||
                              widget.usertype == 5
                          ? Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => VolunteerEventList(
                                    staff: widget.staff,
                                    user: widget.user,
                                    hostname: widget.hostname,
                                    highlightedEventId: event.id,
                                  ),
                            ),
                          )
                          : widget.usertype == 3
                          ? Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ResearcherScreen(
                                    isstaff: widget.staff,
                                    eventid: event.id,
                                    user: widget.user,
                                    hostname: widget.hostname,
                                    highlightedEventId: event.id,
                                  ),
                            ),
                          )
                          : null;
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
