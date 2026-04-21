import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../HRmodels/payment.dart';

class Payments with ChangeNotifier {
  // Hostname updated to match your CHARMS API production URL
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';
  
  List<Payment> _payments = [];

  List<Payment> get payments => [..._payments];

  Future<void> fetchPayments() async {
    try {
      // Aligned with Route::get('/', [HRPaymentController::class, 'getAllPayment'])
      final response = await http.get(Uri.parse('$_hostname/payment/'));
      
      if (response.statusCode == 200) {
        final List<dynamic> paymentData = json.decode(response.body);
        _payments = paymentData.map((data) => Payment.fromJson(data)).toList();
        notifyListeners();
      }
    } catch (error) {
      throw Exception('Failed to fetch payments: $error');
    }
  }

Future<void> fetchPaymentsByMonth(int year, int month) async {
  try {
    final url = Uri.parse('$_hostname/payment/by-month?year=$year&month=$month');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> paymentData = json.decode(response.body);
      _payments = paymentData.map((data) => Payment.fromJson(data)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to fetch monthly payments: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to fetch payments: $error');
  }
}

  // Add this new method for fetching the full year
Future<void> fetchPaymentsByYear(int year) async {
  try {
    List<Payment> allPayments = [];

    for (int month = 1; month <= 12; month++) {
      final url = Uri.parse('$_hostname/payment/by-month?year=$year&month=$month');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> paymentData = json.decode(response.body);
        allPayments.addAll(
          paymentData.map((data) => Payment.fromJson(data)).toList(),
        );
      }
    }

    _payments = allPayments; // set once after all months loaded
    notifyListeners();
  } catch (error) {
    throw Exception('Failed to fetch yearly payments: $error');
  }
}

  Future<Payment> getPaymentById(int paymentId) async {
    try {
      // Aligned with Route::get('/{id}', [HRPaymentController::class, 'getPaymentById'])
      final response = await http.get(Uri.parse('$_hostname/payment/$paymentId'));
      
      if (response.statusCode == 200) {
        return Payment.fromJson(json.decode(response.body));
      }
      throw Exception('Payment not found');
    } catch (error) {
      throw Exception('Failed to fetch payment: $error');
    }
  }

  Future<void> addPayment(Payment payment) async {
    try {
      // Aligned with Route::post('/create', [HRPaymentController::class, 'createPayment'])
      final response = await http.post(
        Uri.parse('$_hostname/payment/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payment.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchPayments();
      } else {
        throw Exception('Failed to add payment: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error adding payment: $error');
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      // Aligned with Route::put('/{id}', [HRPaymentController::class, 'updatePayment'])
      final response = await http.put(
        Uri.parse('$_hostname/payment/${payment.paymentId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payment.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchPayments();
      } else {
        throw Exception('Failed to update payment: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error updating payment: $error');
    }
  }

  Future<void> deletePayment(int paymentId) async {
    try {
      // Aligned with Route::delete('/{id}', [HRPaymentController::class, 'deletePayment'])
      final response = await http.delete(
        Uri.parse('$_hostname/payment/$paymentId'),
      );

      if (response.statusCode == 204) {
        _payments.removeWhere((payment) => payment.paymentId == paymentId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete payment');
      }
    } catch (error) {
      throw Exception('Error deleting payment: $error');
    }
  }
}