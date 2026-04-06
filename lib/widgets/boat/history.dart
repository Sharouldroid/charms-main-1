import 'package:charms/models/event.dart';
import 'package:charms/providers/boats.dart';
import 'package:charms/providers/events.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class History extends StatefulWidget {
  final String hostname;
  final bool isAdmin;

  const History({
    super.key,
    required this.hostname,
    required this.isAdmin,
  });

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final ImagePicker _picker = ImagePicker();
  File? _paymentProof;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sejarah Perjalanan'),
      ),
      body: FutureBuilder(
        future: Provider.of<Events>(context, listen: false)
            .fetchEventGeneral(widget.hostname, 1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.error != null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Consumer<Events>(
            builder: (ctx, eventData, child) => ListView.builder(
              itemCount: eventData.eventlist.length,
              itemBuilder: (_, i) => FutureBuilder(
                future: Provider.of<Boats>(context, listen: false)
                    .getTripDetails(
                        widget.hostname, int.parse(eventData.eventlist[i].id)),
                builder: (context, tripSnapshot) {
                  final event = eventData.eventlist[i];
                  final tripData = tripSnapshot.data;
                  final isCompleted = tripData?['timereturn'] != null;
                  final paymentStatus = tripData?['paymentstatus'] ?? 0;
                  final hasPaymentProof = tripData?['filename'] != null;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              _buildStatusIndicator(isCompleted, paymentStatus),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(DateTime.parse(event.startdate))} - '
                            '${dateFormat.format(DateTime.parse(event.enddate))}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (tripData != null &&
                              tripData['timedepart'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Bertolak: ${dateFormat.format(tripData['timedepart']!)} '
                                  '${timeFormat.format(tripData['timedepart']!)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          if (tripData != null &&
                              tripData['timereturn'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward,
                                    size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Pulang: ${dateFormat.format(tripData['timereturn']!)} '
                                  '${timeFormat.format(tripData['timereturn']!)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Bayaran: ${_getPaymentStatusText(paymentStatus)}',
                                    style: TextStyle(
                                      color:
                                          _getPaymentStatusColor(paymentStatus),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasPaymentProof)
                                    Text(
                                      'Resit: ${tripData!['filename']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              if (widget.isAdmin && paymentStatus != 1)
                                TextButton(
                                  onPressed: () => _showPaymentDialog(
                                      context, event, tripData?['id']),
                                  child: const Text('Kemaskini Bayaran'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(bool isCompleted, int paymentStatus) {
    if (paymentStatus == 1) {
      return const Icon(Icons.payment, color: Colors.green, size: 24);
    } else if (isCompleted) {
      return const Icon(Icons.check_circle, color: Colors.blue, size: 24);
    } else {
      return const Icon(Icons.pending, color: Colors.orange, size: 24);
    }
  }

  String _getPaymentStatusText(int status) {
    switch (status) {
      case 0:
        return 'Belum Dibayar';
      case 1:
        return 'Telah Dibayar';
      case 2:
        return 'Dalam Proses';
      default:
        return 'Tidak Diketahui';
    }
  }

  Color _getPaymentStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showPaymentDialog(
      BuildContext context, Event event, int? tripId) async {
    int? selectedStatus;
    File? paymentProof;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pengurusan Bayaran'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event: ${event.title}'),
                  const SizedBox(height: 16),
                  const Text('Status Bayaran:'),
                  DropdownButtonFormField<int>(
                    initialValue: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Belum Dibayar')),
                      DropdownMenuItem(value: 1, child: Text('Telah Dibayar')),
                      DropdownMenuItem(value: 2, child: Text('Dalam Proses')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedStatus = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Resit Pembayaran:'),
                  const SizedBox(height: 8),
                  if (paymentProof != null)
                    Image.file(paymentProof!, height: 100),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() => paymentProof = File(pickedFile.path));
                      }
                    },
                    child: const Text('Muat Naik Resit'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedStatus != null || paymentProof != null) {
                    Navigator.of(ctx).pop();
                    await _processPayment(
                        context, tripId!, selectedStatus, paymentProof);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPayment(
      BuildContext context, int tripId, int? status, File? proofFile) async {
    try {
      setState(() => _isUploading = true);

      await Provider.of<Boats>(context, listen: false).updatePayment(
        widget.hostname,
        tripId,
        status,
        proofFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maklumat bayaran berjaya dikemaskini!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengemaskini: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
