import 'dart:io';
import 'package:charms/providers/bookevents.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/widgets/volunteer/view_group_participant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

enum PaymentMethod { stripe, qrCode }

class ViewParticipant extends StatefulWidget {
  const ViewParticipant({
    super.key,
    required this.hostname,
    required this.eventid,
    required this.title,
    required this.usertype,
    required this.confirmnum,
    required this.userid,
    required this.currentuser,
    required this.startdate,
    required this.enddate,
  });

  final String hostname;
  final int eventid;
  final String title;
  final int usertype;
  final int confirmnum;
  final int userid;
  final int currentuser;
  final String startdate;
  final String enddate;

  @override
  State<ViewParticipant> createState() => _ViewParticipantState();
}

class _ViewParticipantState extends State<ViewParticipant> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.stripe;
  File? _proofOfPaymentFile;
  String? _fileName;
  String? _uploadError;
  bool _isUploadingProof = false;

  final ImagePicker _picker = ImagePicker();
  static const String qrCodeImagePath = 'assets/images/cmsQR.jpeg';

  // --- PDF GENERATOR (Landscape with All Columns) ---
  Future<void> _downloadVolunteerListPdf(BuildContext context) async {
    try {
      final participantData = Provider.of<Events>(context, listen: false);
      final participants = participantData.participantlist;

      if (participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No participants to download')),
        );
        return;
      }

      final pdf = pw.Document();
      final dateFmt = DateFormat('dd MMMM yyyy'); // Keep full date for "Reg Date" column or change if needed
      final rangeFmt = DateFormat('d MMMM');      // ✅ NEW: Format for "2 April" (No year, No leading zero)
      final dateTimeFmt = DateFormat('dd MMMM yyyy HH:mm');
      
      final currentDate = dateTimeFmt.format(DateTime.now());

      // 2. Format Event Dates (Skip Year)
      String eventDuration = '';
      try {
        if (widget.startdate.isNotEmpty && widget.enddate.isNotEmpty) {
          final sDate = DateTime.parse(widget.startdate);
          final eDate = DateTime.parse(widget.enddate);
          
          // ✅ RESULT: (2 April - 6 April)
          eventDuration = '(${rangeFmt.format(sDate)} - ${rangeFmt.format(eDate)})'; 
        }
      } catch (_) {
        eventDuration = '(${widget.startdate} - ${widget.enddate})';
      }

        pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Volunteer Participant List',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    
                    // --- UPDATED TITLE ROW WITH DATES ---
                    pw.RichText(
                      text: pw.TextSpan(
                        text: 'Event: ${widget.title} ',
                        style: const pw.TextStyle(fontSize: 12),
                        children: [
                          pw.TextSpan(
                            text: eventDuration,
                            style: pw.TextStyle(
                              fontSize: 12, 
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    pw.Text('Generated on: $currentDate',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bookings: ${participants.length}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Total Pax: ${participants.fold(0, (sum, p) => sum + p.pax)}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 10),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(20),  // No
                  1: const pw.FixedColumnWidth(55),  // Reg Date
                  2: const pw.FlexColumnWidth(2),    // Name
                  3: const pw.FixedColumnWidth(37),  // Gender
                  4: const pw.FixedColumnWidth(30),  // Tshirt
                  5: const pw.FixedColumnWidth(65),  // Phone
                  6: const pw.FlexColumnWidth(2),    // Email
                  7: const pw.FlexColumnWidth(1.5),  // Diet Restriction
                  8: const pw.FlexColumnWidth(1.5),  // Health Info
                  9: const pw.FixedColumnWidth(40),  // Status
                  10: const pw.FixedColumnWidth(45), // Amount
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildHeaderCell('No'),
                      _buildHeaderCell('Reg Date'),
                      _buildHeaderCell('Name'),
                      _buildHeaderCell('Gender'),
                      _buildHeaderCell('Tshirt'),
                      _buildHeaderCell('Phone'),
                      _buildHeaderCell('Email'),
                      _buildHeaderCell('Diet Restriction'),
                      _buildHeaderCell('Health Info'),
                      _buildHeaderCell('Status'),
                      _buildHeaderCell('Amount'),
                    ],
                  ),
                  // Data Rows
                  ...participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;

                    // Format Reg Date
                    String regDate = '-';
                    try {
                      if (p.date.isNotEmpty) {
                        regDate = dateFmt.format(DateTime.parse(p.date));
                      }
                    } catch (_) {}

                    String statusText = 'Pending';
                    PdfColor statusColor = PdfColors.orange;
                    
                    if (p.status == 11) {
                      statusText = 'Paid';
                      statusColor = PdfColors.green;
                    } else if (p.status == -1) {
                      statusText = 'Reject';
                      statusColor = PdfColors.red;
                    }

                    return pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        _buildCell('${index + 1}'),
                        _buildCell(regDate),
                        _buildCell(p.name),
                        _buildCell(p.gender == 1 ? 'Male' : (p.gender == 2 ? 'Female' : '-')),
                        _buildCell(p.shirtsize),
                        _buildCell(p.phone),
                        _buildCell(p.email),
                        _buildCell(p.diet),
                        _buildCell(p.health),
                        _buildCell(statusText, color: statusColor),
                        _buildCell(p.total.toStringAsFixed(2)),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        format: PdfPageFormat.a4.landscape,
        name: 'Volunteer_List_${widget.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    }
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      ),
    );
  }

  pw.Widget _buildCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.black),
        tightBounds: true,
      ),
    );
  }

  // --- HELPER: Pick Image ---
  Future<void> _pickProofOfPayment(StateSetter setDialogState) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 1080,
      );

      if (image != null) {
        setDialogState(() {
          _proofOfPaymentFile = File(image.path);
          _fileName = image.name;
          _uploadError = null;
        });
      }
    } catch (e) {
      setDialogState(() {
        _uploadError = 'Failed to pick file: $e';
      });
    }
  }

  // --- HELPER: Upload Proof ---
  Future<void> _uploadProofOfPayment(
    BuildContext dialogContext,
    StateSetter setDialogState,
    int confirmnum,
    double amount,
  ) async {
    if (_proofOfPaymentFile == null) {
      setDialogState(() {
        _uploadError = 'Please select a proof of payment file';
      });
      return;
    }

    setDialogState(() {
      _isUploadingProof = true;
      _uploadError = null;
    });

    try {
      var uri = Uri.parse(
        'https://devcms.com.my/charmsAPI/api/receipt/upload-receipt',
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['confirmnum'] = confirmnum.toString();
      request.fields['amount'] = amount.toStringAsFixed(2);

      request.files.add(
        await http.MultipartFile.fromPath(
          'receipt',
          _proofOfPaymentFile!.path,
          filename: _fileName,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment uploaded successfully! Status will update shortly.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } else {
        setDialogState(() {
          _uploadError = 'Server Error: ${response.statusCode} - $responseData';
          _isUploadingProof = false;
        });
      }
    } catch (e) {
      setDialogState(() {
        _uploadError = 'Connection error: $e';
        _isUploadingProof = false;
      });
    }
  }

  // --- DIALOG: Select Payment Method ---
  void _showPaymentMethodDialog(
    BuildContext context,
    int confirmnum,
    double totalAmount,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateSB) {
              return AlertDialog(
                title: const Text('Select Payment Method'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.credit_card,
                          color: Colors.blue,
                        ),
                        title: const Text('Online Payment'),
                        subtitle: const Text('Credit/Debit Card and FPX'),
                        trailing: Radio<PaymentMethod>(
                          value: PaymentMethod.stripe,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setStateSB(() => _selectedPaymentMethod = value!);
                            Navigator.of(ctx).pop();
                            _processStripePayment(confirmnum, totalAmount);
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.qr_code, color: Colors.green),
                        title: const Text('QR Code Payment'),
                        subtitle: const Text('Scan QR code to pay'),
                        trailing: Radio<PaymentMethod>(
                          value: PaymentMethod.qrCode,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setStateSB(() => _selectedPaymentMethod = value!);
                            Navigator.of(ctx).pop();
                            _showQRCodePaymentDialog(confirmnum, totalAmount);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // --- LOGIC: Stripe Payment ---
  Future<void> _processStripePayment(int confirmnum, double amount) async {
    await Provider.of<StripeService>(context, listen: false).makePayment(
      widget.hostname,
      amount,
      confirmnum,
      1,
      widget.eventid,
      widget.userid,
    );
    setState(() {});
  }

  // --- DIALOG: QR Code ---
  void _showQRCodePaymentDialog(int confirmnum, double totalAmount) {
    _proofOfPaymentFile = null;
    _fileName = null;
    _uploadError = null;
    _isUploadingProof = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateSB) {
              return AlertDialog(
                title: const Text('QR Code Payment'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Please scan the QR code below.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Image.asset(
                          qrCodeImagePath,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Amount: RM ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Reference: SEATRU-$confirmnum',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed:
                            _isUploadingProof
                                ? null
                                : () => _pickProofOfPayment(setStateSB),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Proof File'),
                      ),
                      if (_proofOfPaymentFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${_fileName ?? ''}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                      if (_uploadError != null)
                        Text(
                          _uploadError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        _isUploadingProof
                            ? null
                            : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        (_proofOfPaymentFile != null && !_isUploadingProof)
                            ? () => _uploadProofOfPayment(
                              ctx,
                              setStateSB,
                              confirmnum,
                              totalAmount,
                            )
                            : null,
                    child:
                        _isUploadingProof
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Upload & Confirm'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // --- DIALOG: Cancel Booking ---
  void _showCancelDialog(
    BuildContext context,
    GlobalKey<FormState> formKey,
    String reason,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Please input reason',
              textAlign: TextAlign.center,
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                validator:
                    (value) =>
                        value!.trim().isEmpty
                            ? 'Please input cancel reason'
                            : null,
                onSaved: (value) => reason = value!,
              ),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  child: const Text('Proceed'),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    Provider.of<BookEvents>(
                      context,
                      listen: false,
                    ).processBooking(
                      widget.hostname,
                      -1,
                      widget.userid,
                      widget.eventid,
                      widget.confirmnum,
                      reason,
                    );
                    Provider.of<BookEvents>(
                      context,
                      listen: false,
                    ).refundBooking(widget.hostname, widget.confirmnum);
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String reason = '';
    final GlobalKey<FormState> formKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.title}\'s Participants')),
      body: FutureBuilder(
        future: Provider.of<Events>(context, listen: false).fetchParticipant(
          widget.hostname,
          widget.eventid,
          widget.usertype == 1 || widget.usertype == 5 ? 1 : 0,
          widget.userid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.error != null) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Consumer<Events>(
                builder:
                    (ctx, participantdata, child) =>
                        participantdata.participantlist.isNotEmpty
                            ? Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                        participantdata.participantlist.length,
                                    itemBuilder: (_, i) {
                                      final participant =
                                          participantdata.participantlist[i];
                                      return ExpansionTile(
                                        title: Text(
                                          'Booked by: ${participant.name}',
                                        ),
                                        subtitle: Text(
                                          '${participant.pax} pax',
                                        ),
                                        trailing:
                                            (widget.usertype == 1 ||
                                                    widget.usertype == 5) &&
                                                participant.status == 11
                                                ? IconButton(
                                                  onPressed:
                                                      () => _showCancelDialog(
                                                        context,
                                                        formKey,
                                                        reason,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                  ),
                                                )
                                                : participant.status == -1
                                                ? const Text(
                                                  'Booking Cancelled',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                )
                                                : (participant.status == 2 ||
                                                            participant.status ==
                                                                0) &&
                                                        participant.userid ==
                                                            widget.currentuser
                                                ? TextButton.icon(
                                                  onPressed: () {
                                                    _showPaymentMethodDialog(
                                                      context,
                                                      participant.confirmnum,
                                                      participant.total,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons
                                                        .monetization_on_outlined,
                                                  ),
                                                  label: Text(
                                                    'Pay RM ${participant.total}',
                                                  ),
                                                )
                                                : const SizedBox.shrink(),
                                        children: [
                                          Text(
                                            'Confirmation Number: ${participant.confirmnum}',
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Phone Number: ${participant.phone}',
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Email Address: ${participant.email}',
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Status: ${participant.status == 11 ? 'Paid' : participant.status == -1 ? 'Rejected' : 'Pending'} ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  participant.status == 11
                                                      ? Colors.green
                                                      : participant.status == -1
                                                      ? Colors.red
                                                      : Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          if ((widget.usertype == 1 ||
                                                  widget.usertype == 5) &&
                                              participant.paymentproof != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10.0,
                                                bottom: 10.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    "Payment Receipt:",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Container(
                                                    height: 200,
                                                    width: double.infinity,
                                                    child: Image.network(
                                                      // ✅ FIXED URL
                                                      "https://devcms.com.my/charmsAPI/api/receipt/view/${participant.paymentproof!.split('/').last}",
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null)
                                                          return child;
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      },
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const Center(
                                                          child: Text(
                                                            "Error: Could not load image",
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          participant.type != 1
                                              ? const Text('Group Members')
                                              : const SizedBox.shrink(),
                                          participant.type != 1
                                              ? ViewGroupParticipant(
                                                programname: widget.title,
                                                confirmnum:
                                                    participant.confirmnum,
                                                hostname: widget.hostname,
                                                booktype: participant.type,
                                              )
                                              : const Text(
                                                'Individual Booking',
                                              ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                // Download PDF Button (Only for user type 1)
                                if (widget.usertype == 1)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => _downloadVolunteerListPdf(
                                              context,
                                            ),
                                        icon: const Icon(Icons.picture_as_pdf),
                                        label: const Text(
                                          'Download Volunteer List PDF',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                            : const Center(child: Text('No Participation')),
              );
            }
          }
        },
      ),
    );
  }
}