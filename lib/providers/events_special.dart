import 'dart:async';
import 'dart:convert';
import 'package:charms/models/event.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';

class EventsSpecial with ChangeNotifier {
  List<SpecialEvent> _rsslist = [];
  List<RSSMember> _rssmemberlist = [];
  List<RSSAffiliation> _rssAffiliation = [];

  List<SpecialEvent> get rsslist {
    return [..._rsslist];
  }

  List<RSSMember> get rssmemberlist {
    return [..._rssmemberlist];
  }

  List<RSSAffiliation> get rssAffiliation {
    return [..._rssAffiliation];
  }

  Future<void> applyRSS(
    String hostname,
    int userid,
    int pax,
    String startdate,
    String enddate,
    int needboat,
    int amount,
  ) async {
    final url = '${hostname}rss/store';

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
        'startdate': startdate,
        'enddate': enddate,
        'needboat': needboat,
        'amount': amount,
      }),
    );

    showSimpleNotification(
      const Text(
        'Your application has been received and is being processed.',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      duration: const Duration(seconds: 2),
      background: Colors.green,
    );

    notifyListeners();
  }

  Future<void> addRSSGroup(
    String hostname,
    String name,
    String idnum,
    String email,
    int userid,
  ) async {
    final url = '${hostname}rss/group-booking';

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
        'userid': userid,
      }),
    );

    notifyListeners();
  }

  Future<void> addonRSS(
    String hostname,
    String itemname,
    int quantity,
    int userid,
    int itemprice,
  ) async {
    final url = '${hostname}rss/add-on';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'itemname': itemname,
        'quantity': quantity,
        'userid': userid,
        'amount': itemprice,
      }),
    );
    notifyListeners();
  }

  Future<void> indemnityRSS(
      String hostname, int userid, String indemnity, int ismember) async {
    final url = '${hostname}rss/indemnity';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'ismember': ismember,
        'userid': userid,
        'indemitem': indemnity,
      }),
    );
    notifyListeners();
  }

  Future<void> paymentRSS(
      String hostname, int amount, int specialid, int userid) async {
    final url = '${hostname}create-payment-intent';
    // var total = amount * count;
    final total = (amount * 100).toInt();

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
        saveRSSpayment(hostname, specialid, amount.toDouble(), 1, paymentid);
        processRSS(hostname, specialid, '', userid, 11);
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

  Future<void> saveRSSpayment(String hostname, int specialid, double amount,
      int status, String paymentid) async {
    final url = '${hostname}rss/payment';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'specialid': specialid,
        'paymentid': paymentid,
        'paymentstatus': status,
        'amount': amount,
      }),
    );
    notifyListeners();
  }

  Future<void> processRSS(String hostname, int specialid, String reason,
      int userid, int status) async {
    final url = '${hostname}rss/process';

    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'reason': reason,
        'id': specialid,
        'status': status,
        'userid': userid,
      }),
    );

    notifyListeners();
  }

  Future<void> fetchRSS(String hostname, int admin, int userid) async {
    final url = '${hostname}rss/event/$admin/$userid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<SpecialEvent> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(SpecialEvent(
          id: eventData['id'] ?? 0,
          pax: eventData['pax'] ?? 0,
          startdate: eventData['startdate'].toString(),
          enddate: eventData['enddate'].toString(),
          needboat: eventData['needboat'] ?? 0,
          status: eventData['status'] ?? 0,
          amount: eventData['amount'] ?? 0,
          processedby: eventData['processedby'] ?? 0,
          rejectreason: eventData['rejectreason'] ?? '',
          applicantid: eventData['userid'] ?? 0,
        ));
      });
      _rsslist = loadedEvent;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<RSSMember>> fetchRSSGroup(
      String hostname, int specialid, int userid) async {
    final url = '${hostname}rss/group/$specialid';

    try {
      final response = await http.get(Uri.parse(url));
      final List<dynamic> extractedEvent = jsonDecode(response.body);
      final List<RSSMember> loadedEvent = [];

      for (var eventData in extractedEvent) {
        loadedEvent.add(RSSMember(
          id: eventData['id'],
          name: eventData['name'],
          idnum: eventData['idnum'],
          email: eventData['email'],
        ));
      }

      _rssmemberlist = loadedEvent;
      notifyListeners();
      return _rssmemberlist;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> storeRSSAffiliation(
    String hostname,
    String title,
    String department,
    String institution,
    String location,
    String filename,
    int userid,
  ) async {
    final url = '${hostname}rss/affiliation';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'userid': userid,
        'title': title,
        'department': department,
        'institution': institution,
        'location': location,
        'filename': filename,
      }),
    );

    notifyListeners();
  }

  Future<List<RSSAffiliation>> fetchAffiliation(
      String hostname, int specialid) async {
    final url = '${hostname}rss/fetchaffiliate/$specialid';
    print('Fetching URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load with status ${response.statusCode}');
      }

      // Parse the response as a Map first
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if the request was successful
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Request failed');
      }

      // Get the data array
      final List<dynamic> extractedData = responseData['data'];
      print('Extracted data length: ${extractedData.length}');

      final List<RSSAffiliation> loadedEvents = extractedData.map((eventData) {
        return RSSAffiliation(
          id: eventData['id'],
          title: eventData['title']?.toString() ?? '',
          department: eventData['department']?.toString() ?? '',
          institution: eventData['institution']?.toString() ?? '',
          location: eventData['location']?.toString() ?? '',
          filename: eventData['filename']?.toString() ?? '',
        );
      }).toList();

      _rssAffiliation = loadedEvents;
      notifyListeners();
      return _rssAffiliation;
    } catch (error) {
      print('Error in fetchAffiliation: $error');
      rethrow;
    }
  }
}
