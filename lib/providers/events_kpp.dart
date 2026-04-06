import 'dart:async';
import 'dart:convert';
import 'package:charms/models/event.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';

class EventsKPP with ChangeNotifier {
  List<SpecialEvent> _kpplist = [];
  List<KPPData> _kppdata = [];
  // List<KPPAffiliation> _KPPAffiliation = [];

  List<SpecialEvent> get kpplist {
    return [..._kpplist];
  }

  List<KPPData> get kppdata {
    return [..._kppdata];
  }

  // List<KPPAffiliation> get KPPAffiliation {
  //   return [..._KPPAffiliation];
  // }

  Future<void> applyKPP(
    String hostname,
    int staffid,
    String picemail,
    int pax,
    String startdate,
    String enddate,
    int amount,
  ) async {
    final url = '${hostname}kpp/create';

    final f = DateFormat('dd-MM-yyyy');

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': staffid, // applying staff
        'email': picemail,
        'pax': pax,
        'startdate': f.format(DateTime.parse(startdate)),
        'enddate': f.format(DateTime.parse(enddate)),
        'amount': amount,
      }),
    );

    showSimpleNotification(
      const Text(
        'New Kem Prihatin Penyu created.',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      duration: const Duration(seconds: 2),
      background: Colors.green,
    );

    _kpplist.add(SpecialEvent(
      id: 0,
      pax: pax,
      startdate: startdate,
      enddate: enddate,
      applicantid: staffid,
      picemail: picemail,
      amount: amount,
      status: 0,
    ));

    notifyListeners();
  }

  Future<void> paymentKPP(
      String hostname, int amount, int kppid, int userid) async {
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
        saveKPPpayment(hostname, kppid, amount.toDouble(), 1, paymentid);
        processKPP(hostname, kppid, '', userid, 11);
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

  Future<void> saveKPPpayment(String hostname, int kppid, double amount,
      int status, String paymentid) async {
    final url = '${hostname}kpp/payment';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'kppid': kppid,
        'paymentid': paymentid,
        'paymentstatus': status,
        'amount': amount,
      }),
    );
    notifyListeners();
  }

  Future<void> processKPP(
      String hostname, int kppid, String reason, int userid, int status) async {
    final url = '${hostname}kpp/process';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'reason': reason,
        'id': kppid,
        'status': status,
        'userid': userid,
      }),
    );

    notifyListeners();
  }

  Future<void> fetchKPP(String hostname, int admin, String email) async {
    final url = '${hostname}kpp/fetch?admin=$admin&email=$email';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<SpecialEvent> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(SpecialEvent(
          id: eventData['id'],
          pax: eventData['pax'],
          startdate: eventData['startdate'].toString(),
          enddate: eventData['enddate'].toString(),
          needboat: 0,
          status: eventData['status'],
          amount: eventData['amount'],
          processedby: eventData['processedby'],
          rejectreason: eventData['rejectreason'],
          applicantid: eventData['staffid'],
          picemail: eventData['picemail'],
        ));
      });
      _kpplist = loadedEvent;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

// kpp group & indemnity
  Future<List<KPPData>> fetchKPPData(
      String hostname, int kppid, int type) async {
    final url = '${hostname}kpp/fetch/$kppid/type/$type';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<KPPData> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(KPPData(
          id: eventData['id'],
          kppid: eventData['kppid'],
          filename: eventData['filename'],
        ));
      });
      _kppdata = loadedEvent;
      notifyListeners();
      return _kppdata;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> storeKPP(
      String hostname, int kppid, String filename, int type) async {
    final url = '${hostname}kpp/storedata';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'type': type,
        'kppid': kppid,
        'filename': filename,
      }),
    );

    notifyListeners();
  }
// kpp group & indemnity
}
