import 'package:charms/models/event.dart';
import 'package:charms/providers/receipts.dart';
import 'package:charms/widgets/receipt/addon_future.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewReceipt extends StatelessWidget {
  const ViewReceipt({
    super.key,
    required this.hostname,
    required this.event,
    required this.volres,
  });

  final String hostname;
  final Event event;
  final int volres;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');

    // --- PDF Generating Function ---
    void printReceipt(BuildContext context) async {
      final pdfDoc = pw.Document();
      final dateFmt = DateFormat('dd-MM-yyyy hh:mm');
      final receiptData = Provider.of<Receipts>(context, listen: false);

      // Safety check for PDF generation too
      if (receiptData.bookingdata.isEmpty) return;

      final booking = receiptData.bookingdata.first;

      pdfDoc.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RECEIPT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Reference Number: ${booking.confirmnum}'),
              pw.Text(
                'Payment Date: ${dateFmt.format(DateTime.parse(booking.paymentdate))}',
              ),
              pw.SizedBox(height: 12),
              pw.Text('Issuer: Conservation Management Solutions Sdn Bhd'),
              pw.SizedBox(height: 12),
              pw.Text('Client: ${booking.clientname}'),
              pw.Text('Email: ${booking.clientemail}'),
              pw.SizedBox(height: 12),
              pw.Text('Address:'),
              pw.Text(booking.clientaddress),
              pw.Text(
                '${booking.clientpostcode}, ${booking.clientcity}, ${booking.clientstate}, ${booking.clientcountry}',
              ),
              pw.SizedBox(height: 20),
              pw.Text('Item: ${event.title}'),
              pw.Text('Pax: ${booking.pax}'),
              pw.Text(
                'Total: RM ${(booking.price * booking.pax).toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 20),
              pw.Text('Addons:'),
              if (receiptData.addons.isNotEmpty)
                pw.Column(
                  children: receiptData.addons
                      .map(
                        (addon) => pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(addon.item),
                            pw.Text(
                              'RM ${addon.price} x ${addon.quantity}',
                            ),
                          ],
                        ),
                      )
                      .toList(),
                )
              else
                pw.Text('No addons'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Grand Total: RM ${booking.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdfDoc.save());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Only allow printing if data is loaded
              final receiptData = Provider.of<Receipts>(context, listen: false);
              if (receiptData.bookingdata.isNotEmpty) {
                printReceipt(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Receipt data not ready")),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: volres == 1
            ? Provider.of<Receipts>(
                context,
                listen: false,
              ).fetchBookingData(hostname, event.confirmnum)
            : Provider.of<Receipts>(
                context,
                listen: false,
              ).fetchResearcherBooking(hostname, event.confirmnum),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // --- SCENARIO 1: Error occurred (likely data is null/missing) ---
          else if (snapshot.hasError) {
             return _buildPaymentPendingState(context);
          } else {
            return Consumer<Receipts>(
              builder: (ctx, receiptdata, _) {
                // --- SCENARIO 2: Data fetched but list is empty ---
                if (receiptdata.bookingdata.isEmpty) {
                   return _buildPaymentPendingState(context);
                }

                // If we are here, data exists!
                final booking = receiptdata.bookingdata.first;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reference & Header Info
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reference Number:',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                event.confirmnum.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Issuer: Conservation Management Solutions Sdn Bhd',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Payment Date: ${f.format(DateTime.parse(booking.paymentdate.toString()))}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Client Details
                      const Text(
                        'Client Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${booking.clientname}'),
                              Text('Address: ${booking.clientaddress}'),
                              Text(
                                '${booking.clientcity}, ${booking.clientstate}',
                              ),
                              Text(
                                '${booking.clientpostcode}, ${booking.clientcountry}',
                              ),
                              const SizedBox(height: 8),
                              Text('Email: ${booking.clientemail}'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Items
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(event.title),
                          subtitle: Text(
                            'RM ${(booking.price * booking.pax).toStringAsFixed(2)}',
                          ),
                          trailing: Text('Pax: ${booking.pax}'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Addons
                      const Text(
                        'Add Ons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AddonFuture(
                        hostname: hostname,
                        confirmnum: event.confirmnum,
                        volres: volres,
                      ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 2),

                      // Total
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: RM ${booking.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // --- Helper Widget: The "Payment Processing" Screen ---
  Widget _buildPaymentPendingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_top_rounded, // Hourglass or Clock icon
              size: 70,
              color: Colors.orange.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              "Receipt Not Ready",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your payment details are still being processed or are incomplete. Please check back later.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Check Again"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Triggers a rebuild of the widget to try fetching again
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => ViewReceipt(
                        hostname: hostname, event: event, volres: volres),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}