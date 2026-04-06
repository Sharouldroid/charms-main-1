import 'dart:async';
import 'dart:convert';
import 'package:charms/models/event.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';

class EventsDaytrip with ChangeNotifier {
  List<DayTrip> _dtlist = [];
  // List<KPPData> _dtdata = [];

  List<DayTrip> get dtlist {
    return [..._dtlist];
  }

  // List<KPPData> get _dtdata {
  //   return [..._dtdata];
  // }

  // List<KPPAffiliation> get KPPAffiliation {
  //   return [..._KPPAffiliation];
  // }

  Future<void> applyDaytrip(
    String hostname,
    int userid,
    int companyid,
    int pax,
    String selecteddate,
    String selectedtime,
    int amount,
  ) async {
    final url = '${hostname}dt/create';

    final f = DateFormat('yyyy-MM-dd');

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'companyid': companyid,
        'pax': pax,
        'selecteddate': f.format(DateTime.parse(selecteddate)),
        'selectedtime': selectedtime,
        'amount': amount,
      }),
    );

    showSimpleNotification(
      const Text(
        'New Day Trip created.',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      duration: const Duration(seconds: 2),
      background: Colors.green,
    );

    _dtlist.add(DayTrip(
      id: 0,
      userid: userid,
      companyid: companyid,
      pax: pax,
      selecteddate: selecteddate,
      selectedtime: selectedtime,
      amount: amount,
      status: 0,
    ));

    notifyListeners();
  }

  Future<void> paymentDT(String hostname, int amount, int userid) async {
    final url = '${hostname}create-payment-intent';
    // var total = amount * count;
    var total = amount * 100;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'amount': total, 'currency': 'myr'}),
      );

      final responseData = jsonDecode(response.body);
      final clientSecret = responseData['clientSecret'];
      final paymentid = responseData['paymentid'];

      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        allowsRemovalOfLastSavedPaymentMethod: true,
        merchantDisplayName: 'Conservation Management Solutions Sdn Bhd',
      ));

      await Stripe.instance.presentPaymentSheet();

      if (response.statusCode == 200) {
        saveDTpayment(hostname, amount.toDouble(), 1, paymentid, userid);
        // processDT(hostname, 0, '', userid, 11);
      }

      showSimpleNotification(
        const Text(
          'Payment Completed!',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        duration: const Duration(seconds: 2),
        background: Colors.green,
      );
    } on StripeException catch (e) {
      // Handle failure or cancellation by the user
      print('Payment failed: ${e.error.localizedMessage}');

      showSimpleNotification(
        Text(
          'Payment Failed! ${e.error.localizedMessage}',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        duration: const Duration(seconds: 2),
        background: Colors.red,
      );
    } catch (e) {
      // Handle other types of exceptions
      print('Payment error: $e');
      showSimpleNotification(
        Text(
          'Payment Error! $e',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        duration: const Duration(seconds: 2),
        background: Colors.orange,
      );
    }
  }

  Future<void> saveDTpayment(String hostname, double amount, int status,
      String paymentid, int userid) async {
    final url = '${hostname}dt/payment';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'paymentid': paymentid,
        'paymentstatus': status,
        'amount': amount,
      }),
    );
    notifyListeners();
  }

  Future<void> processDT(
      String hostname, int dtid, String reason, int userid, int status) async {
    final url = '${hostname}dt/process';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'reason': reason,
        'id': dtid,
        'status': status,
        'userid': userid,
      }),
    );

    notifyListeners();
  }

  Future<void> fetchDaytrip(String hostname, int admin, int userid) async {
    final url = '${hostname}dt/fetch?admin=$admin&userid=$userid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<DayTrip> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(DayTrip(
          id: eventData['id'],
          userid: eventData['userid'],
          companyid: eventData['companyid'],
          pax: eventData['pax'],
          selecteddate: eventData['selecteddate'].toString(),
          selectedtime: eventData['selectedtime'].toString(),
          amount: eventData['amount'],
          status: eventData['status'],
          processedby: eventData['processedby'],
          rejectreason: eventData['rejectreason'],
          company: eventData['companyname'],
        ));
      });
      _dtlist = loadedEvent;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

// kpp group & indemnity
  // Future<List<KPPData>> fetchKPPData(
  //     String hostname, int dtid, int type) async {
  //   final url = '${hostname}daytrip/fetch/$dtid/type/$type';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     final extractedEvent = jsonDecode(response.body);
  //     final List<KPPData> loadedEvent = [];
  //     extractedEvent.forEach((eventData) {
  //       loadedEvent.add(KPPData(
  //         id: eventData['id'],
  //         dtid: eventData['dtid'],
  //         filename: eventData['filename'],
  //       ));
  //     });
  //     _kppdata = loadedEvent;
  //     notifyListeners();
  //     return _kppdata;
  //   } catch (error) {
  //     rethrow;
  //   }
  // }

  Future<void> storeIndemnity(
      String hostname, String answer, int userid) async {
    final url = '${hostname}dt/indemnity';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'indemnity': answer,
      }),
    );

    notifyListeners();
  }
// kpp group & indemnity
}
