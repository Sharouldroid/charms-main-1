import 'package:charms/models/event.dart';
import 'package:charms/providers/reports.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ViewReport extends StatelessWidget {
  const ViewReport({
    super.key,
    required this.hostname,
    required this.eventdata,
  });

  final String hostname;
  final Event eventdata;

  String _getEventTypeName(int type) {
    switch (type) {
      case 1:
        return 'Volunteer Program';
      case 2:
        return 'Researcher Program';
      case 3:
        return 'Kem Prihatin Penyu';
      default:
        return 'Day Trip';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF05179), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Event Report',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF05179),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF05179),
                        const Color(0xFFF05179).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF05179).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventdata.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getEventTypeName(eventdata.eventtype),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Event Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Event Information', Icons.event),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Start Date',
                          f.format(DateTime.parse(eventdata.startdate)),
                          icon: Icons.calendar_today,
                        ),
                        _buildInfoRow(
                          'End Date',
                          f.format(DateTime.parse(eventdata.enddate)),
                          icon: Icons.event_available,
                        ),
                        _buildInfoRow(
                          'Duration',
                          '${DateTime.parse(eventdata.enddate).difference(DateTime.parse(eventdata.startdate)).inDays + 1} days',
                          icon: Icons.timelapse,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Participant Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Participant Information', Icons.people),
                        const SizedBox(height: 16),
                        FutureBuilder(
                          future: Provider.of<Reports>(context, listen: false)
                              .fetchTotalPax(hostname, int.parse(eventdata.id)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF05179),
                                  ),
                                ),
                              );
                            } else if (snapshot.error != null) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Error loading data: ${snapshot.error}',
                                        style: TextStyle(color: Colors.red[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Consumer<Reports>(
                                builder: (ctx, reportdata, child) {
                                  if (reportdata.pax.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('No participant data available'),
                                        ],
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: reportdata.pax.map((paxData) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatCard(
                                              title: 'Confirmed',
                                              value: '${paxData.confirmedbooking} pax',
                                              icon: Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildStatCard(
                                              title: 'Cancelled',
                                              value: '${paxData.cancelledbooking} pax',
                                              icon: Icons.cancel,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Payment Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Payment Information', Icons.payment),
                        const SizedBox(height: 16),
                        FutureBuilder(
                          future: Provider.of<Reports>(context, listen: false)
                              .fetchTotalPayment(hostname, int.parse(eventdata.id)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF05179),
                                  ),
                                ),
                              );
                            } else if (snapshot.error != null) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Error loading data: ${snapshot.error}',
                                        style: TextStyle(color: Colors.red[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Consumer<Reports>(
                                builder: (ctx, reportdata, child) {
                                  if (reportdata.payment.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('No payment data available'),
                                        ],
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: reportdata.payment.map((paymentData) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatCard(
                                              title: 'Total Paid',
                                              value: 'RM ${paymentData.totalamount.toStringAsFixed(2)}',
                                              icon: Icons.attach_money,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildStatCard(
                                              title: 'Total Refunded',
                                              value: 'RM ${paymentData.totalrefund.toStringAsFixed(2)}',
                                              icon: Icons.money_off,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
