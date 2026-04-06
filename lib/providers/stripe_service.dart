import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:overlay_support/overlay_support.dart';

class StripeService with ChangeNotifier {
  Future<void> makePayment(
    String hostname,
    double amount,
    int confirmnum,
    int volres,
    int eventid,
    int userid,
  ) async {
    final url = '${hostname}create-payment-intent';
    final amountInSen = (amount * 100).toInt();
    var total = amountInSen;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'amount': total, 'currency': 'MYR'}),
      );

      final responseData = jsonDecode(response.body);
      final clientSecret = responseData['clientSecret'];
      final paymentid = responseData['paymentid'];
      
      if (response.statusCode != 200) {
        throw Exception('Failed to create PaymentIntent');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          allowsRemovalOfLastSavedPaymentMethod: true,
          merchantDisplayName: 'Conservation Management Solutions Sdn Bhd',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (response.statusCode == 200) {
        if (volres == 1) {
          // FIX: Passed userid here
          savePaymentRecord(
            hostname,
            confirmnum,
            amount.toDouble(),
            1,
            paymentid,
            userid, 
          );
          processBookingVolunteer(
            hostname,
            11,
            userid,
            eventid,
            confirmnum,
            '/',
          );
        } else {
          // FIX: Passed userid here
          saveResearcherPayment(
            hostname,
            confirmnum,
            amount.toDouble(),
            1,
            paymentid,
            userid,
          );
          processBookingResearcher(
            hostname,
            11,
            userid,
            eventid,
            confirmnum,
            '/',
          );
        }
      } else {
        // Payment intent failed on server side (rare here if presentPaymentSheet succeeded)
        if (volres == 1) {
          processBookingVolunteer(
            hostname,
            0,
            userid,
            eventid,
            confirmnum,
            '/',
          );
        } else {
          processBookingResearcher(
            hostname,
            0,
            userid,
            eventid,
            confirmnum,
            '/',
          );
        }
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

  // --- UPDATED: Accepts and Sends 'userid' ---
  Future<void> savePaymentRecord(
    String hostname,
    int confirmnum,
    double amount,
    int status,
    String paymentid,
    int userid, // <--- NEW PARAMETER
  ) async {
    final url = '${hostname}booking/payment';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'confirmnum': confirmnum,
        'amount': amount,
        'paymentstatus': status,
        'paymentid': paymentid,
        'userid': userid, // <--- INCLUDED IN BODY
      }),
    );
    notifyListeners();
  }

  // --- UPDATED: Accepts and Sends 'userid' ---
  Future<void> saveResearcherPayment(
    String hostname,
    int confirmnum,
    double amount,
    int status,
    String paymentid,
    int userid, // <--- NEW PARAMETER
  ) async {
    final url = '${hostname}researcher/payment';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'confirmnum': confirmnum,
        'amount': amount,
        'paymentstatus': status,
        'paymentid': paymentid,
        'userid': userid, // <--- INCLUDED IN BODY
      }),
    );
    notifyListeners();
  }

  Future<void> processBookingVolunteer(
    String hostname,
    int status,
    int userid,
    int eventid,
    int confirmnum,
    String reason,
  ) async {
    final url = '${hostname}booking/process';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'status': status,
        'reason': reason,
        'userid': userid,
        'eventid': eventid,
        'confirmnum': confirmnum,
      }),
    );

    notifyListeners();
  }

  Future<void> processBookingResearcher(
    String hostname,
    int status,
    int userid,
    int eventid,
    int confirmnum,
    String reason,
  ) async {
    final url = '${hostname}researcher/process';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'status': status,
        'reason': reason,
        'userid': userid,
        'confirmnum': confirmnum,
      }),
    );

    notifyListeners();
  }
}