import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:charms/models/event.dart';
import 'package:charms/models/paymentrecord.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Events with ChangeNotifier {
  List<Event> _eventslist = [];
  List<PaymentRecord> _paymentrecord = [];
  List<Map<String, dynamic>> _allbookedevents = [];
  List<Map<String, dynamic>> _memberevents = [];
  List<Participant> _participantlist = [];
  late Map<DateTime, List<Event2>> _kEventSource = {};

  List<Event> get eventlist {
    return [..._eventslist];
  }

  List<PaymentRecord> get paymentrecord {
    return [..._paymentrecord];
  }

  List<Map<String, dynamic>> get allbookedevents {
    return [..._allbookedevents];
  }

  List<Map<String, dynamic>> get memberevents {
    return [..._memberevents];
  }

  List<Participant> get participantlist {
    return [..._participantlist];
  }

  Map<DateTime, List<Event2>> get kEventSource {
    return {..._kEventSource};
  }

  // ... (createEvent, updateEvent, fetchEventGeneral, fetchEventAdmin, fetchCalendarEvent, fetchBookedEvent, fetchAllBookedEvent, fetchMemberEvent, fetchPaymentRecord methods remain exactly the same as your code) ...
  // For brevity, I am keeping the focus on the FIX in fetchParticipant below.
  
  Future<void> createEvent(String hostname, Event newEvent, int userid) async {
    final url = '${hostname}event/create';
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
          'slotvolunteer': newEvent.slotvolunteer,
          'slotresearcher': newEvent.slotresearcher,
          'createdby': userid,
          'price': newEvent.price,
          'priceresearcher': newEvent.priceresearcher,
        }),
      );
      if (response.statusCode == 201) {
        final newEvents = Event(
          id: '',
          title: newEvent.title,
          startdate: newEvent.startdate,
          enddate: newEvent.enddate,
          slotvolunteer: newEvent.slotvolunteer,
          slotresearcher: newEvent.slotresearcher,
          eventtype: newEvent.eventtype,
          status: 0,
          price: newEvent.price,
          priceresearcher: newEvent.priceresearcher,
          total: 0,
        );
        _eventslist.add(newEvents);
        notifyListeners();
      } else {
        final errorResponse = jsonDecode(response.body);
        throw errorResponse['message'] ?? 'Failed to create event!';
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateEvent(String hostname, Event newEvent, int eventid) async {
    final eventIndex = _eventslist.indexWhere((event) => event.id == eventid.toString());
    final url = '${hostname}event/update/$eventid';
    await http.put(
      Uri.parse(url),
      headers: {'Content-type': 'application/json', 'Accept': 'application/json'},
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'title': newEvent.title,
        'startdate': newEvent.startdate,
        'enddate': newEvent.enddate,
        'slotvolunteer': newEvent.slotvolunteer,
        'slotresearcher': newEvent.slotresearcher,
        'price': newEvent.price,
        'priceresearcher': newEvent.priceresearcher,
      }),
    );
    _eventslist[eventIndex] = newEvent;
    notifyListeners();
  }

  Future<void> fetchEventGeneral(String hostname, int eventtype) async {
    String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
    final url = '${baseUrl}event/general/$eventtype';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final extractedEvent = jsonDecode(response.body);
        final List<Event> loadedEvent = [];
        Iterable dataList = (extractedEvent is Map && extractedEvent.containsKey('data')) 
            ? extractedEvent['data'] : extractedEvent;
        for (var eventData in dataList) {
           loadedEvent.add(
            Event(
              id: eventData['id'].toString(),
              title: eventData['title'],
              startdate: eventData['startdate'],
              enddate: eventData['enddate'],
              slotvolunteer: eventData['slotvolunteer'],
              slotresearcher: eventData['slotresearcher'],
              price: double.parse(eventData['price'].toString()),
              priceresearcher: double.parse(eventData['priceresearcher'].toString()),
            ),
          );
        }
        _eventslist = loadedEvent;
        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchEventAdmin(String hostname, int eventtype) async {
    String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
    final url = '${baseUrl}event/admin/$eventtype';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final extractedEvent = jsonDecode(response.body);
        final List<Event> loadedEvent = [];
        Iterable dataList = (extractedEvent is Map && extractedEvent.containsKey('data')) 
            ? extractedEvent['data'] : extractedEvent;
        for (var eventData in dataList) {
        loadedEvent.add(
            Event(
              id: eventData['id'].toString(),
              title: eventData['title'],
              startdate: eventData['startdate'],
              enddate: eventData['enddate'],
              slotvolunteer: eventData['slotvolunteer'],
              slotresearcher: eventData['slotresearcher'],
              price: double.parse(eventData['price'].toString()),
              priceresearcher: double.parse(eventData['priceresearcher'].toString()),
            ),
          );
        }
        _eventslist = loadedEvent;
        notifyListeners();
      }
    } catch (error) {
      rethrow;
    }
  }

  Future fetchCalendarEvent(String hostname) async {
    final url = '${hostname}event/general/1';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<Event2> calendarevent = [];
      for (var eventData in extractedEvent) {
        calendarevent.add(Event2(
          title: eventData['title'],
          startdate: DateTime.parse(eventData['startdate']),
          enddate: DateTime.parse(eventData['enddate']),
          id: eventData['id'],
        ));
      }
      final Map<DateTime, List<Event2>> eventMap = {};
      for (var event in calendarevent) {
        final dateKey = DateTime(event.startdate.year, event.startdate.month, event.startdate.day);
        if (eventMap[dateKey] == null) {
          eventMap[dateKey] = [event];
        } else {
          eventMap[dateKey]!.add(event);
        }
      }
      _kEventSource = eventMap;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchBookedEvent(String hostname, String userid) async {
    final url = '${hostname}event/booked/$userid';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Failed to load booked events');
      final extractedData = jsonDecode(response.body);
      List<Map<String, dynamic>> loadedEvents = [];
      for (var event in extractedData) {
        List<Map<String, dynamic>> bookings = [];
        for (var booking in event['bookings']) {
          bookings.add({
            'booking_id': booking['id']?.toString() ?? '0',
            'name': booking['name'] ?? 'No Name',
            'email': booking['user_email'] ?? '',
            'created_at': booking['created_at'] ?? '',
            'confirmnum': booking['confirmationno'],
            'userid': booking['userid'],
            'total': booking['price'],
            'paymentstatus': booking['paymentstatus'],
          });
        }
        loadedEvents.add({
          'id': event['id'].toString(),
          'title': event['title'] ?? 'Untitled Event',
          'startdate': event['startdate'] ?? '',
          'enddate': event['enddate'] ?? '',
          'bookings': bookings,
        });
      }
      _allbookedevents = loadedEvents;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchAllBookedEvent(String hostname) async {
    final url = '${hostname}event/allbooked';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Failed to load booked events');
      final extractedData = jsonDecode(response.body);
      List<Map<String, dynamic>> loadedEvents = [];
      for (var event in extractedData) {
        List<Map<String, dynamic>> bookings = [];
        for (var booking in event['bookings']) {
          bookings.add({
            'booking_id': booking['booking_id']?.toString() ?? '0',
            'name': booking['user_name'] ?? '',
            'email': booking['user_email'] ?? '',
            'created_at': booking['created_at'] ?? '',
            'confirmnum': booking['confirmationno'] ?? 0,
            'userid': booking['userid'] ?? 0,
            'paymentstatus': booking['paymentstatus'],
          });
        }
        loadedEvents.add({
          'id': event['id'].toString(),
          'title': event['title'] ?? 'Untitled',
          'startdate': event['startdate'] ?? '',
          'enddate': event['enddate'] ?? '',
          'bookings': bookings,
        });
      }
      _allbookedevents = loadedEvents;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchMemberEvent(String hostname, String email) async {
    final url = '${hostname}event/member/$email';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final extractedEvent = jsonDecode(response.body);
        if (extractedEvent is List) {
          List<Map<String, dynamic>> loadedEvents = [];
          for (var eventData in extractedEvent) {
            loadedEvents.add({
              'id': eventData['id']?.toString() ?? '0',
              'title': eventData['title'] ?? 'Untitled',
              'startdate': eventData['startdate'] ?? 'Unknown',
              'enddate': eventData['enddate'] ?? 'Unknown',
              'slotvolunteer': eventData['slotvolunteer'] ?? 0,
              'slotresearcher': eventData['slotresearcher'] ?? 0,
              'datebook': eventData['datecreated'] ?? '',
              'confirmnum': eventData['confirmationno'] ?? 0,
              'booktype': eventData['booktype'] ?? 0,
              'price': double.tryParse(eventData['amount']?.toString() ?? '0.0') ?? 0.0,
              'priceresearcher': double.tryParse(eventData['priceresearcher']?.toString() ?? '0.0') ?? 0.0,
              'total': double.tryParse(eventData['amount']?.toString() ?? '0.0') ?? 0.0,
              'status': eventData['status'] ?? 0,
              'cancelreason': eventData['cancelreason'] ?? 'No reason provided',
              'paymentstatus': eventData['paymentstatus'],
            });
          }
          _memberevents = loadedEvents;
        } else {
          throw 'Unexpected response format!';
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        throw errorResponse is Map<String, dynamic> && errorResponse.containsKey('message')
            ? errorResponse['message']
            : 'An unexpected error occurred!';
      }
      notifyListeners();
    } catch (error) {
      throw '❌ Error fetching events: $error';
    }
  }

  Future<void> fetchPaymentRecord(String hostname, int confirmnum) async {
    final url = '${hostname}event/payment/$confirmnum';
    final f = DateFormat('dd-MM-yyyy');
    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<PaymentRecord> loadedRecord = [];
      extractedData.forEach((paymentData) {
        loadedRecord.add(PaymentRecord(
          id: paymentData['id'],
          confirmnum: paymentData['confirmnum'],
          amount: double.parse(paymentData['amount'].toString()),
          paymentstatus: paymentData['paymentstatus'],
          paymentid: paymentData['paymentid'],
          date: f.format(DateTime.parse(paymentData['datecreated'])),
        ));
      });
      _paymentrecord = loadedRecord;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // --- FIXED fetchParticipant METHOD ---
  Future<void> fetchParticipant(
    String hostname,
    int eventid,
    int admin,
    int userid,
  ) async {
    final url = '${hostname}event/participant/$eventid/admin/$admin/user/$userid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<Participant> loadedData = [];
      
      // Handle list or map response safely
      Iterable list = (extractedData is Map && extractedData.containsKey('data')) 
          ? extractedData['data'] 
          : extractedData;

      for (var participantdata in list) {
        // ✅ FIX: Use Participant.fromJson factory
        // This ensures gender (int->string logic) and diet/health (mapping keys) are handled correctly.
        loadedData.add(Participant.fromJson(participantdata));
      }
      
      _participantlist = loadedData;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<int> fetchSlot(String hostname, int eventid) async {
    var url = '${hostname}event/count/$eventid';
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    return data['slotcount'] ?? 0;
  }

  Future<bool> checkBooked(String hostname, int eventid, int userid, int volorres) async {
    var url = '${hostname}booking/check/$userid/$eventid';
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    return data['exists'];
  }

  Future<bool> checkBookedMembers(String hostname, int eventid, String email) async {
    var url = '${hostname}booking/checkmember/$email/$eventid';
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    return data['exists'];
  }
}