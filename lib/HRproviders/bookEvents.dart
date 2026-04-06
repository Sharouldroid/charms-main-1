import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookEvents with ChangeNotifier {
  Future<void> createBooking(String hostname, int userid, int pax, int eventid,
      int confirmnum, int isgroup) async {
    final url = '${hostname}booking/create';
    var rnd = math.Random();
    var next = rnd.nextDouble() * 100000;
    while (next < 10000) {
      next *= 10;
    }

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
        'confirmnum': confirmnum,
        'isgroup': isgroup,
      }),
    );

    // final newEvents = Event(
    //   id: '',
    //   title: newEvent.title,
    //   startdate: newEvent.startdate,
    //   enddate: newEvent.enddate,
    //   eventtype: newEvent.eventtype,
    // );
    // _eventslist.add(newEvents);
    notifyListeners();
  }

  Future<void> addBookingGroup(String hostname, String name, String idnum,
      String email, int confirmnum) async {
    final url = '${hostname}booking/group';

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
        'confirmnum': confirmnum,
      }),
    );

    // final newEvents = Event(
    //   id: '',
    //   title: newEvent.title,
    //   startdate: newEvent.startdate,
    //   enddate: newEvent.enddate,
    //   eventtype: newEvent.eventtype,
    // );
    // _eventslist.add(newEvents);
    notifyListeners();
  }
}
