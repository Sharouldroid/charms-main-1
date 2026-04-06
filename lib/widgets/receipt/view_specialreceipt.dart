import 'package:charms/providers/receipts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ViewSpecialReceipt extends StatelessWidget {
  const ViewSpecialReceipt({
    super.key,
    required this.hostname,
    required this.specialId,
    required this.userId,
  });

  final String hostname;
  final int specialId;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: 'RM ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Slot Receipt'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Provider.of<Receipts>(context, listen: false)
            .fetchSpecialReceipt(hostname, specialId, userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Consumer<Receipts>(
            builder: (ctx, receiptData, child) {
              final receipt = receiptData.specialReceipt[0];
              final isPaid = receipt.status == 11; // Approved & Paid status

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'CONSERVATION MANAGEMENT SOLUTIONS',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Special Research Slot Receipt'),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        // Receipt Info Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Receipt #${receipt.receiptNumber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    'Date: ${dateFormat.format(receipt.paymentDate)}'),
                              ],
                            ),
                            Chip(
                              label: Text(
                                isPaid ? 'PAID' : 'PENDING',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                                  isPaid ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Client Information
                        const Text(
                          'CLIENT INFORMATION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Name:', receipt.clientName),
                        _buildInfoRow('Email:', receipt.clientEmail),
                        _buildInfoRow(
                            'Institution:', receipt.clientInstitution),
                        const Divider(height: 32),

                        // Booking Details
                        const Text(
                          'BOOKING DETAILS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Slot Type:', 'Researcher Special Slot'),
                        _buildInfoRow('Dates:',
                            '${dateFormat.format(receipt.startDate)} - ${dateFormat.format(receipt.endDate)}'),
                        _buildInfoRow('Boat Arrangement:',
                            receipt.needBoat ? 'Required' : 'Self-arranged'),
                        _buildInfoRow('Participants:', '${receipt.pax} pax'),
                        const SizedBox(height: 8),

                        // Group Members if applicable
                        if (receipt.pax > 1) ...[
                          const Text(
                            'GROUP MEMBERS:',
                            style: TextStyle(fontSize: 14),
                          ),
                          ...receipt.groupMembers
                              .map(
                                (member) => Padding(
                                  padding:
                                      const EdgeInsets.only(left: 16, top: 4),
                                  child: Text('• $member'),
                                ),
                              )
                              ,
                          const SizedBox(height: 12),
                        ],
                        const Divider(height: 32),

                        // Payment Details
                        const Text(
                          'PAYMENT DETAILS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentRow('Slot Fee:',
                            currencyFormat.format(receipt.slotFee)),
                        if (receipt.boatFee > 0)
                          _buildPaymentRow('Boat Fee:',
                              currencyFormat.format(receipt.boatFee)),
                        if (receipt.additionalFees > 0)
                          _buildPaymentRow('Additional Fees:',
                              currencyFormat.format(receipt.additionalFees)),
                        const Divider(height: 24, thickness: 1),
                        _buildPaymentRow(
                          'TOTAL AMOUNT:',
                          currencyFormat.format(receipt.totalAmount),
                          isTotal: true,
                        ),
                        const SizedBox(height: 24),

                        // Payment Method
                        _buildInfoRow('Payment Method:', receipt.paymentMethod),
                        _buildInfoRow('Transaction ID:', receipt.transactionId),
                        const SizedBox(height: 16),

                        // Footer
                        const Divider(height: 32),
                        const Text(
                          'Thank you for supporting marine conservation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'For any inquiries, please contact:',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'info@conservationms.com | +60 12-345 6789',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement share/save receipt functionality
          _shareOrSaveReceipt(context);
        },
        tooltip: 'Share Receipt',
        child: const Icon(Icons.share),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
          Text(
            value,
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }

  void _shareOrSaveReceipt(BuildContext context) {
    // Implement receipt sharing/saving functionality
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receipt Options'),
        content: const Text('Would you like to save or share this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save receipt implementation
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Receipt saved to device')),
              );
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              // Share receipt implementation
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Receipt shared')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
