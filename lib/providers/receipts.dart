import 'dart:async';
import 'dart:convert';

import 'package:charms/models/receipt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Receipts with ChangeNotifier {
  List<BookingReceipt> _bookingdata = [];
  List<SpecialReceipt> _specialReceipt = [];
  List<BookingAddon> _addons = [];

  List<BookingReceipt> get bookingdata {
    return [..._bookingdata];
  }

  List<SpecialReceipt> get specialReceipt {
    return [..._specialReceipt];
  }

  List<BookingAddon> get addons {
    return [..._addons];
  }

  Future<void> fetchBookingData(String hostname, int confirmnum) async {
    final url = '${hostname}receipt/booking/$confirmnum';
    try {
      final response = await http.get(Uri.parse(url));
      final extractedBody = jsonDecode(response.body);
      final receiptdata = extractedBody['data']; // ← this is a single object

      _bookingdata = [
        BookingReceipt(
          id: receiptdata['id'] ?? 0,
          pax: receiptdata['pax'],
          datebook: receiptdata['created_at'] ?? '',
          total: double.parse(receiptdata['amount']),
          clientname: '${receiptdata['firstname']} ${receiptdata['lastname']}',
          clientaddress:
              '${receiptdata['address1']}, ${receiptdata['address2']}',
          clientcity: receiptdata['city'] ?? '',
          clientpostcode: receiptdata['postcode'] ?? 0,
          clientstate: receiptdata['state'] ?? '',
          clientcountry: receiptdata['country'] ?? '',
          clientemail: receiptdata['email'] ?? '',
          paymentdate: receiptdata['paydate'] ?? '',
          paymentid: receiptdata['paymentid'] ?? '',
          confirmnum: confirmnum,
          price: double.parse(receiptdata['price']),
        ),
      ];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchResearcherBooking(String hostname, int confirmnum) async {
    final url = '${hostname}receipt/bookingres/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedBody = jsonDecode(response.body);
      final receiptdata = extractedBody['data']; // ← this is a single object

      _bookingdata = [
        BookingReceipt(
          id: receiptdata['id'] ?? 0,
          pax: receiptdata['pax'],
          datebook: receiptdata['created_at'] ?? '',
          total: double.parse(receiptdata['amount']),
          clientname: '${receiptdata['firstname']} ${receiptdata['lastname']}',
          clientaddress:
              '${receiptdata['address1']}, ${receiptdata['address2']}',
          clientcity: receiptdata['city'] ?? '',
          clientpostcode: receiptdata['postcode'] ?? 0,
          clientstate: receiptdata['state'] ?? '',
          clientcountry: receiptdata['country'] ?? '',
          clientemail: receiptdata['email'] ?? '',
          paymentdate: receiptdata['paydate'] ?? '',
          paymentid: receiptdata['paymentid'] ?? '',
          confirmnum: confirmnum,
          price: double.parse(receiptdata['price']),
        ),
      ];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchBookingAddon(String hostname, int confirmnum) async {
    final url = '${hostname}receipt/addon/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final Map<String, dynamic> extractedEvent = jsonDecode(response.body);

      final List<BookingAddon> loadeddata = [];

      // Check if success is true and data is a list
      if (extractedEvent['success'] == true) {
        final List<dynamic> data = extractedEvent['data'];

        for (var receiptdata in data) {
          loadeddata.add(
            BookingAddon(
              id: receiptdata['id'],
              item: receiptdata['name'],
              price: receiptdata['price'],
              quantity: receiptdata['quantity'],
            ),
          );
        }
      } else {
        // You can handle the empty or failed response here
        print(extractedEvent['message'] ?? 'No addons found.');
      }

      _addons = loadeddata;
      notifyListeners();
    } catch (error) {
      print('Error fetching booking addons: $error');
      rethrow;
    }
  }

  Future<void> fetchResAddon(String hostname, int confirmnum) async {
    final url = '${hostname}receipt/addonres/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final Map<String, dynamic> extractedEvent = jsonDecode(response.body);

      final List<BookingAddon> loadeddata = [];

      // Check if success is true and data is a list
      if (extractedEvent['success'] == true) {
        final List<dynamic> data = extractedEvent['data'];

        for (var receiptdata in data) {
          loadeddata.add(
            BookingAddon(
              id: receiptdata['id'],
              item: receiptdata['name'],
              price: receiptdata['price'],
              quantity: receiptdata['quantity'],
            ),
          );
        }
      } else {
        // You can handle the empty or failed response here
        print(extractedEvent['message'] ?? 'No addons found.');
      }

      _addons = loadeddata;
      notifyListeners();
    } catch (error) {
      print('Error fetching booking addons: $error');
      rethrow;
    }
  }

  Future<void> fetchSpecialReceipt(
    String hostname,
    int specialid,
    int userid,
  ) async {
    final url = '${hostname}receipt/addon/';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<SpecialReceipt> loadeddata = [];
      extractedEvent.forEach((receiptdata) {
        loadeddata.add(
          SpecialReceipt(
            receiptNumber: receiptdata[''],
            paymentDate: receiptdata[''],
            clientName: receiptdata[''],
            clientEmail: receiptdata[''],
            clientInstitution: receiptdata[''],
            startDate: receiptdata[''],
            endDate: receiptdata[''],
            needBoat: receiptdata[''],
            pax: receiptdata[''],
            groupMembers: receiptdata[''],
            slotFee: receiptdata[''],
            boatFee: receiptdata[''],
            additionalFees: receiptdata[''],
            totalAmount: receiptdata[''],
            paymentMethod: receiptdata[''],
            transactionId: receiptdata[''],
            status: receiptdata[''],
          ),
        );
      });
      _specialReceipt = loadeddata;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
