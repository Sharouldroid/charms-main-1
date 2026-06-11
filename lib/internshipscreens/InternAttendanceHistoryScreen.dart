import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/InternAttendanceProvider.dart';
import 'package:charms/internshipmodels/InternAttendanceRecord.dart';

class InternAttendanceHistoryScreen extends StatefulWidget {
  final int userId;
 
  const InternAttendanceHistoryScreen({super.key, required this.userId});
 
  @override
  State<InternAttendanceHistoryScreen> createState() =>
      _InternAttendanceHistoryScreenState();
}
 
class _InternAttendanceHistoryScreenState
    extends State<InternAttendanceHistoryScreen> {
  static const Color _primaryBlue = Color(0xFF2563EB);
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternAttendanceProvider>().fetchHistory(widget.userId);
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Consumer<InternAttendanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingHistory) {
            return const Center(child: CircularProgressIndicator());
          }
 
          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records yet.',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
 
          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchHistory(widget.userId),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final record = provider.history[index];
                return _AttendanceCard(record: record);
              },
            ),
          );
        },
      ),
    );
  }
}
 
class _AttendanceCard extends StatelessWidget {
  final InternAttendanceRecord record;
 
  const _AttendanceCard({required this.record});
 
  static const Color _primaryBlue = Color(0xFF2563EB);
 
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
 
    // Show the actual work date, fallback to schedule start date
    final scheduleDate = (record.workDate ?? record.scheduleStartDate) != null
        ? dateFormat.format((record.workDate ?? record.scheduleStartDate)!)
        : 'Unknown date';
 
    final clockIn = record.clockInTime != null
        ? timeFormat.format(record.clockInTime!.toLocal())
        : '-';
    final clockOut = record.clockOutTime != null
        ? timeFormat.format(record.clockOutTime!.toLocal())
        : 'Not yet';
 
    final Color statusColor =
        record.hasClockOut ? Colors.green : Colors.orange;
    final String statusText =
        record.hasClockOut ? 'Completed' : 'In Progress';
    final IconData statusIcon = record.hasClockOut
        ? Icons.check_circle_rounded
        : Icons.radio_button_checked_rounded;
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: date + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.event_rounded,
                        color: _primaryBlue, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    scheduleDate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
 
          if (record.scheduleDescription.isNotEmpty &&
              record.scheduleDescription != '-') ...[
            const SizedBox(height: 8),
            Text(
              record.scheduleDescription,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
 
          const Divider(height: 20),
 
          // Clock in / out times
          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  icon: Icons.login_rounded,
                  label: 'Clock In',
                  time: clockIn,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeChip(
                  icon: Icons.logout_rounded,
                  label: 'Clock Out',
                  time: clockOut,
                  color: record.hasClockOut ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
 
          // Duration
          if (record.hasClockOut) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer_rounded,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Duration: ${record.shiftDurationFormatted}',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
 
          // Location
          if (record.clockInLocation != null &&
              record.clockInLocation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.clockInLocation!,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
 
class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;
 
  const _TimeChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(time,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}