import 'dart:async';
import 'dart:convert';
import 'package:charms/models/indemnity.dart';
import 'package:intl/intl.dart';

import 'package:charms/models/event.dart';
import 'package:charms/models/paymentrecord.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResearcherEvents with ChangeNotifier {
  final List<Event> _eventslist = [];
  List<PaymentRecord> _paymentrecord = [];
  List<Map<String, dynamic>> _bookedeventslist = [];
  List<Event> _bookedmemberevents = [];
  List<Participant> _participantlist = [];

  List<IndemnityResponse> _indemAnswer = [];

  List<IndemnityResponse> get indemAnswer {
    return [..._indemAnswer];
  }

  List<Event> get eventlist {
    return [..._eventslist];
  }

  List<PaymentRecord> get paymentrecord {
    return [..._paymentrecord];
  }

  List<Map<String, dynamic>> get bookedeventslist {
    return [..._bookedeventslist];
  }

  List<Event> get bookedmemberevents {
    return [..._bookedmemberevents];
  }

  List<Participant> get participantlist {
    return [..._participantlist];
  }

  Future<void> createBooking(
    String hostname,
    int userid,
    int pax,
    int eventid,
    int confirmnum,
    int isgroup,
    int booktype,
    String size,
    double amount,
  ) async {
    final url = '${hostname}researcher/create';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'pax': pax,
        'eventid': eventid,
        'confirmationno': confirmnum,
        // 'isgroup': isgroup,
        'booktype': booktype,
        // 'shirtsize': size,
        'amount': amount,
      }),
    );

    notifyListeners();
  }

  Future<void> addBookingGroup(
    String hostname,
    String name,
    String idnum,
    String email,
    int eventid,
    int confirmnum,
    String size,
  ) async {
    final url = '${hostname}researcher/group';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'name': name,
        'idnum': idnum,
        'email': email,
        'eventid': eventid,
        'confirmationno': confirmnum,
      }),
    );

    notifyListeners();
  }

  Future<void> fetchBookedEvent(String hostname, int admin, int userid) async {
    final url = '${hostname}researcher/booked/$admin/$userid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      List<Map<String, dynamic>> loadedEvents = [];

      for (var eventData in extractedEvent) {
        loadedEvents.add({
          'id': eventData['id']?.toString() ?? '0', // Ensure ID is a string
          'title': eventData['title'] ?? 'Untitled',
          'startdate': eventData['startdate'] ?? '',
          'enddate': eventData['enddate'] ?? '',
          'slotvolunteer':
              eventData['slotvolunteer'] ?? 0, // Default to 0 if null
          'slotresearcher':
              eventData['slotresearcher'] ?? 0, // Default to 0 if null
          'datebook': eventData['created_at'] ?? '',
          'confirmnum':
              eventData['confirmationno'] ?? 0, // Ensure default value
          'booktype': eventData['booktype'] ?? 0, // Default to 0 if null
          'price':
              double.tryParse(eventData['amount']?.toString() ?? '0.0') ??
              0.0, // Handle parsing issues
          'priceresearcher':
              double.tryParse(
                eventData['priceresearcher']?.toString() ?? '0.0',
              ) ??
              0.0,
          'total':
              double.tryParse(eventData['amount']?.toString() ?? '0.0') ?? 0.0,
          'status': eventData['status'] ?? 0, // Ensure default value
          'cancelreason': eventData['cancelreason'] ?? 'No reason provided',
        });
      }
      _bookedeventslist = loadedEvents;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> refundBooking(String hostname, int confirmnum) async {
    final url = '${hostname}booking/refund';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({'confirmnum': confirmnum}),
    );

    notifyListeners();
  }

  Future<void> fetchMemberEvent(String hostname, String email) async {
    final url = '${hostname}researcher/member/email/$email';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<Event> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(
          Event(
            id: eventData['id'].toString(),
            title: eventData['title'] ?? '',
            startdate: eventData['startdate'] ?? '',
            enddate: eventData['enddate'] ?? '',
            slotvolunteer: eventData['slotvolunteer'] ?? 0,
            slotresearcher: eventData['slotresearcher'] ?? 0,
            datebook: eventData['created_at'] ?? '',
            confirmnum: eventData['confirmationno'] ?? 0,
            booktype: eventData['booktype'] ?? 0,
            price: double.parse(eventData['amount']),
            priceresearcher: double.parse(eventData['amount']),
            total: double.parse(eventData['amount']),
            status: eventData['status'] ?? 0,
            cancelreason: eventData['cancelreason'] ?? '',
          ),
        );
      });
      _bookedmemberevents = loadedEvent;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchPaymentRecord(String hostname, int confirmnum) async {
    final url = '${hostname}researcher/fetchpayment/$confirmnum';

    final f = DateFormat('dd-MM-yyyy');

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<PaymentRecord> loadedRecord = [];
      extractedData.forEach((paymentData) {
        loadedRecord.add(
          PaymentRecord(
            id: paymentData['id'] ?? 0,
            confirmnum: paymentData['confirmnum'] ?? 0,
            amount: paymentData['amount'] ?? 0,
            paymentstatus: paymentData['paymentstatus'] ?? 0,
            paymentid: paymentData['paymentid'] ?? '',
            date: f.format(DateTime.parse(paymentData['created_at'])),
          ),
        );
      });
      _paymentrecord = loadedRecord;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchParticipant(String hostname, int eventid) async {
    final url = '${hostname}researcher/participant/res/$eventid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<Participant> loadedData = [];
      extractedData.forEach((participantdata) {
        loadedData.add(
          Participant(
            id: participantdata['id'],
            name: participantdata['name'],
            phone: participantdata['phone'],
            email: participantdata['email'],
            pax: participantdata['pax'],
            confirmnum: participantdata['confirmationno'],
            type: participantdata['booktype'],
            date: participantdata['created_at'],
            status: participantdata['status'],
            total: double.parse(participantdata['amount']),
            userid: participantdata['userid'],
              gender: participantdata['gender'] ?? '',
            shirtsize: participantdata['shirtsize'] ?? '',
            diet: participantdata['diet'] ?? '',
            health: participantdata['health'] ?? '',
            
          ),
        );
      });
      _participantlist = loadedData;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<int> fetchSlot(String hostname, int eventid) async {
    var url = '${hostname}researcher/count/$eventid';
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);

    // print(data[0]['slotcount']);

    return data['slotcount'] ?? 0;
  }

  Future<bool> checkBooked(
    String hostname,
    int eventid,
    int userid,
    int volorres, // Note: This parameter isn't used in the Laravel version
  ) async {
    try {
      final url = Uri.parse('${hostname}researcher/check/$userid/$eventid');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['exists']
            as bool; // Using the 'exists' field from Laravel response
      } else {
        throw Exception('Failed to check booking: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking booking: $e');
      rethrow;
    }
  }

  Future<bool> checkBookedMembers(
    String hostname,
    int eventid,
    String email,
  ) async {
    var url = '${hostname}researcher/checkmember/$email/$eventid';
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);

    // print(data[0]['confirmationno']);

    if (data[0]['confirmationno'] != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> addIndemnitiestoBooking(
    String hostname,
    int userid,
    String answers,
    int confirmnum,
  ) async {
    final url = '${hostname}researcher/addtobooking';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'confirmnum': confirmnum,
        'indemitem': answers,
      }),
    );
    notifyListeners();
  }

  Future<void> fetchUserIndemnities(
    String hostname,
    int userid,
    int confirmnum,
  ) async {
    final url = '${hostname}researcher/resindemnity/$userid/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<IndemnityResponse> loadedIndem = [];
      extactedData.forEach((indemData) {
        loadedIndem.add(IndemnityResponse(answers: indemData['indemnities']));
      });
      _indemAnswer = loadedIndem;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateUserIndemnity(
    String hostname,
    int userid,
    String answers,
    int confirmnum,
  ) async {
    final url = '${hostname}researcher/userupdate';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'confirmnum': confirmnum,
        'indemitem': answers,
      }),
    );
    notifyListeners();
  }

  Future<void> purchaseOptionalItem(
    String hostname,
    String itemname,
    int itemprice,
    int userid,
    int quantity,
    int confirmnum,
  ) async {
    final url = '${hostname}researcher/addon';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'name': itemname,
        'quantity': quantity,
        'confirmnum': confirmnum,
        'userid': userid,
        'price': itemprice,
      }),
    );
    notifyListeners();
  }
}

Future<int> fetchSlot(String hostname, int eventid) async {
  var url = '${hostname}researcher/count/$eventid';
  var response = await http.get(Uri.parse(url));
  var data = jsonDecode(response.body);

  // print(data[0]['slotcount']);

  return data['slotcount'] ?? 0;
}
