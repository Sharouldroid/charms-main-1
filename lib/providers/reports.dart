import 'dart:async';
import 'dart:convert';

import 'package:charms/models/event.dart';
import 'package:charms/models/report.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Reports with ChangeNotifier {
  List<ReportPax> _pax = [];
  List<ReportPayment> _payment = [];
  List<ReportData> _datamonth = [];
  List<ReportData> _datayear = [];
  List<Event> _eventslist = [];

  List<Event> get eventlist {
    return [..._eventslist];
  }

  List<ReportPax> get pax {
    return [..._pax];
  }

  List<ReportPayment> get payment {
    return [..._payment];
  }

  List<ReportData> get datamonth {
    return [..._datamonth];
  }

  List<ReportData> get datayear {
    return [..._datayear];
  }

Future<void> fetchTotalPax(String hostname, int eventid) async {
  // 1. SAFE URL CONSTRUCTION
  // This ensures there is exactly one slash between hostname and the path
  String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
  final url = '${baseUrl}report/bookingpax/$eventid';

  print('Attempting to fetch: $url'); // DEBUG: Check your console for this!

  try {
    final response = await http.get(Uri.parse(url));

    // 2. CHECK STATUS CODE BEFORE DECODING
    if (response.statusCode == 200) {
      // 3. DEBUG THE BODY IF IT FAILS AGAIN
      // print('Response body: ${response.body}'); 
      
      final extractedEvent = jsonDecode(response.body);
      final List<ReportPax> loadeddata = [];
      
      // Handle cases where the API returns a Map instead of a List
      if (extractedEvent is List) {
        extractedEvent.forEach((reportdata) {
          loadeddata.add(ReportPax(
            confirmedbooking: int.tryParse(reportdata['confirmedbooking'].toString()) ?? 0,
            cancelledbooking: int.tryParse(reportdata['cancelledbooking'].toString()) ?? 0,
          ));
        });
      }
      
      _pax = loadeddata;
      notifyListeners();
    } else {
      // If server returns 404 or 500, throw an error so the UI knows
      throw Exception('Server Error: ${response.statusCode}');
    }
  } catch (error) {
    print('Error fetching pax: $error');
    rethrow;
  }
}

Future<void> fetchTotalPayment(String hostname, int eventid) async {
  String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
  final url = '${baseUrl}report/bookingpayment/$eventid';

  print('Attempting to fetch payment: $url');

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final extractedEvent = jsonDecode(response.body);
      final List<ReportPayment> loadeddata = [];
      
      if (extractedEvent is List) {
        extractedEvent.forEach((reportdata) {
          loadeddata.add(ReportPayment(
            totalamount: double.tryParse(reportdata['totalamount'].toString()) ?? 0.0,
            totalrefund: double.tryParse(reportdata['totalrefund'].toString()) ?? 0.0,
          ));
        });
      }
      _payment = loadeddata;
      notifyListeners();
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  } catch (error) {
    print('Error fetching payment: $error');
    rethrow;
  }
}

Future<void> fetchMonthlyReport(String hostname, String type) async {
    String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
    final url = '${baseUrl}report/monthly/$type';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final extractedEvent = jsonDecode(response.body);
        final List<ReportData> loadeddata = [];
        
        if (extractedEvent is List) {
          extractedEvent.forEach((reportdata) {
            loadeddata.add(ReportData(
              // Title is still int (Month 1, 2, 3...)
              title: int.tryParse(reportdata['month'].toString()) ?? 0,
              
              // Sum is still int (Total people)
              sum: int.tryParse(reportdata['total'].toString()) ?? 0,
              
              // ✅ AMOUNT: Parse as double and KEEP it as double
              totalamount: double.tryParse(reportdata['totalamount'].toString()) ?? 0.0,
            ));
          });
        }
        _datamonth = loadeddata;
        notifyListeners();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchYearlyReport(String hostname, String type) async {
    String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
    final url = '${baseUrl}report/yearly/$type';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final extractedEvent = jsonDecode(response.body);
        final List<ReportData> loadeddata = [];

        if (extractedEvent is List) {
          extractedEvent.forEach((reportdata) {
            loadeddata.add(ReportData(
              title: int.tryParse(reportdata['year'].toString()) ?? 0,
              sum: int.tryParse(reportdata['total'].toString()) ?? 0,
              
              // ✅ AMOUNT: Parse as double and KEEP it as double
              totalamount: double.tryParse(reportdata['totalamount'].toString()) ?? 0.0,
            ));
          });
        }
        _datayear = loadeddata;
        notifyListeners();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchrangereport(
      String hostname, String startdate, String enddate) async {
    String baseUrl = hostname.endsWith('/') ? hostname : '$hostname/';
    final url = '${baseUrl}report/range?startdate=$startdate&enddate=$enddate';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<Event> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(Event(
          id: eventData['id'].toString(),
          title: eventData['title'],
          startdate: eventData['startdate'],
          enddate: eventData['enddate'],
          slotvolunteer: eventData['slotvolunteer'],
          slotresearcher: eventData['slotresearcher'],
          price: eventData['price'],
          priceresearcher: eventData['priceresearcher'],
          // status: 0,
        ));
      });
      // print(startdate);
      // print(enddate);
      _eventslist = loadedEvent;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
