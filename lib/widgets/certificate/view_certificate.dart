import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class ViewCertificate extends StatelessWidget {
  const ViewCertificate({super.key, required this.event, required this.user});

  final Event event;
  final User user;

  Future<void> _printCertificate(BuildContext context) async {
    final fStart = DateFormat('dd/MM');
    final fEnd = DateFormat('dd/MM/yy');
    final pdf = pw.Document();

    // Load the certificate background image from assets
    final Uint8List certBytes = await rootBundle
        .load('assets/images/logo/cert.jpg')
        .then((data) => data.buffer.asUint8List());
    final certImage = pw.MemoryImage(certBytes);

    // Use A4 landscape format
    final pageFormat = PdfPageFormat.a4.landscape;
    final double pageWidth = pageFormat.width;
    final double pageHeight = pageFormat.height;

    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        pageFormat: pageFormat,
        build:
            (pw.Context context) => pw.Stack(
              children: [
                // Certificate background image
                pw.Positioned.fill(
                  child: pw.Image(certImage, fit: pw.BoxFit.cover),
                ),
                // Name - positioned on left side below "PROUDLY PRESENTED TO"
                pw.Positioned(
                  right: pageWidth * 0.20,
                  top: pageHeight * 0.43,
                  child: pw.Text(
                    '${user.firstname} ${user.lastname}',
                    style: pw.TextStyle(
                      fontSize: 23,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#996515'),
                    ),
                  ),
                ),
                // Event Title - positioned in the middle-left box area
                pw.Positioned(
                  right: pageWidth * 0.155,
                  top: pageHeight * 0.68,
                  child: pw.Text(
                    event.title,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ),
                // Event Date - positioned at bottom left
                pw.Positioned(
                  right: pageWidth * 0.25,
                  top: pageHeight * 0.68,
                  child: pw.Text(
                    '${fStart.format(DateTime.parse(event.startdate))} - ${fEnd.format(DateTime.parse(event.enddate))}',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      format: pageFormat,
    );
  }

  // Future<void> _printCertificate(BuildContext context) async {
  //   final f = DateFormat('dd/MM/yyyy');
  //   final pdf = pw.Document();

  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) => pw.Center(
  //         child: pw.Container(
  //           padding: const pw.EdgeInsets.all(32),
  //           decoration: pw.BoxDecoration(
  //             border: pw.Border.all(),
  //           ),
  //           child: pw.Column(
  //             mainAxisSize: pw.MainAxisSize.min,
  //             children: [
  //               pw.Text("E-Certificate",
  //                   style: pw.TextStyle(
  //                       fontSize: 30, fontWeight: pw.FontWeight.bold)),
  //               pw.SizedBox(height: 16),
  //               pw.Text("This is to certify that",
  //                   style: pw.TextStyle(fontSize: 16)),
  //               pw.SizedBox(height: 12),
  //               pw.Text('${user.firstname} ${user.lastname}',
  //                   style: pw.TextStyle(
  //                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
  //               pw.SizedBox(height: 12),
  //               pw.Text("has successfully completed",
  //                   style: pw.TextStyle(fontSize: 16)),
  //               pw.SizedBox(height: 12),
  //               pw.Text(event.title,
  //                   style: pw.TextStyle(
  //                       fontSize: 20, fontWeight: pw.FontWeight.bold)),
  //               pw.SizedBox(height: 20),
  //               pw.Text("on"),
  //               pw.SizedBox(height: 10),
  //               pw.Text(
  //                 '${f.format(DateTime.parse(event.startdate))} to ${f.format(DateTime.parse(event.enddate))}',
  //                 style: pw.TextStyle(
  //                     fontSize: 18, fontWeight: pw.FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   await Printing.layoutPdf(onLayout: (format) => pdf.save());
  // }

  @override
  Widget build(BuildContext context) {
    final fStart = DateFormat('dd/MM');
    final fEnd = DateFormat('dd/MM/yy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your E-Certificate'),
        actions: [
          IconButton(
            onPressed: () => _printCertificate(context),
            icon: const Icon(Icons.print),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AspectRatio(
                  aspectRatio: 1.414, // A4 landscape ratio
                  child: Stack(
                    children: [
                      // Certificate background image
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/logo/cert.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Name - positioned using percentage
                      Positioned(
                        right: constraints.maxWidth * 0.19,
                        top: constraints.maxWidth / 1.417 * 0.42,
                        child: Text(
                          '${user.firstname} ${user.lastname}',
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.030,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF996515),
                          ),
                        ),
                      ),
                      // Event Title - positioned using percentage
                      Positioned(
                        right: constraints.maxWidth * 0.152,
                        top: constraints.maxWidth / 1.507 * 0.72,
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.015,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Event Date - positioned using percentage
                      Positioned(
                        right: constraints.maxWidth * 0.25,
                        top: constraints.maxWidth / 1.50 * 0.72,
                        child: Text(
                          '${fStart.format(DateTime.parse(event.startdate))} - ${fEnd.format(DateTime.parse(event.enddate))}',
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.014,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
