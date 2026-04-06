import 'dart:async';
import 'dart:convert';

import 'package:charms/HRmodels/event.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Events with ChangeNotifier {
  // ✅ UPDATED BASE URL
  static const String _hostname = 'https://devcms.com.my/charmsAPI/api/';

  List<Event> _eventslist = [];
  late Map<DateTime, List<Event2>> _kEventSource = {};

  List<Event> get eventlist {
    return [..._eventslist];
  }

  Map<DateTime, List<Event2>> get kEventSource {
    return {..._kEventSource};
  }

  // 1. CREATE EVENT
  Future<void> createEvent(String hostname, Event newEvent, int userid) async {
    final url = '${_hostname}event-general/create';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'title': newEvent.title,
          'startdate': newEvent.startdate,
          'enddate': newEvent.enddate,
          'createdby': userid,
          'eventtype': newEvent.eventtype,
        }),
      );

      if (response.statusCode == 200) {
        final newEvents = Event(
          id: '',
          title: newEvent.title,
          startdate: newEvent.startdate,
          enddate: newEvent.enddate,
          eventtype: newEvent.eventtype,
        );
        _eventslist.add(newEvents);
        notifyListeners();
      } else {
         throw Exception('Failed to create event: ${response.body}');
      }
    } catch (error) {
      rethrow;
    }
  }

  // 2. FETCH EVENTS (GENERAL)
  Future<void> fetchEvent(String hostname) async {
    final url = '${_hostname}event-general/';

    try {
      final response = await http.get(Uri.parse(url));
      
      if(response.statusCode == 200) {
        final List<dynamic> extractedEvent = jsonDecode(response.body);
        final List<Event> loadedEvent = [];
        
        extractedEvent.forEach((eventData) {
          loadedEvent.add(Event(
            id: eventData['id'].toString(), // Event.id is String, so this is correct
            title: eventData['title'],
            startdate: eventData['startdate'],
            enddate: eventData['enddate'],
            // ✅ FIX 1: Parse to int? instead of String
            eventtype: eventData['eventtype'] != null 
                ? int.tryParse(eventData['eventtype'].toString()) 
                : null,
          ));
        });
        _eventslist = loadedEvent;
        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  // 3. FETCH CALENDAR EVENTS
  Future fetchCalendarEvent(String hostname) async {
    final url = '${_hostname}event-general/'; 

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> extractedEvent = jsonDecode(response.body);
        final List<Event2> calendarevent = [];
        
        extractedEvent.forEach((eventData) {
          calendarevent.add(Event2(
              title: eventData['title'],
              startdate: DateTime.parse(eventData['startdate']),
              enddate: DateTime.parse(eventData['enddate']),
              // ✅ FIX 2: Event2.id is int, so we must parse it
              id: int.parse(eventData['id'].toString()) 
          ));
        });
        
        _kEventSource = {
          for (var item in calendarevent)
            DateTime.utc(
                item.startdate.year, item.startdate.month, item.startdate.day): [
              item
            ]
        };
        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }
}