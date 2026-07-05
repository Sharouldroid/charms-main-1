import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/internshipmodels/interview_session.dart';
import 'package:charms/internshipproviders/interview_session_provider.dart';

class InterviewSessionPickerScreen extends StatefulWidget {
  final int userId;

  const InterviewSessionPickerScreen({super.key, required this.userId});

  @override
  State<InterviewSessionPickerScreen> createState() =>
      _InterviewSessionPickerScreenState();
}

class _InterviewSessionPickerScreenState
    extends State<InterviewSessionPickerScreen> {
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final provider = context.read<InterviewSessionProvider>();
    try {
      await provider.loadMySession(widget.userId);
      if (provider.mySession == null) {
        await provider.loadAvailableSessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load interview sessions: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndBook(InterviewSession session) async {
    final dateFmt = DateFormat('EEE, dd MMM yyyy').format(session.date.toLocal());
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Interview Slot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Book the interview slot on $dateFmt, ${session.startTime}–${session.endTime}?\n\nOnce booked, this slot is reserved for you.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Book Slot'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBooking = true);
    try {
      await context
          .read<InterviewSessionProvider>()
          .bookSession(session.id, widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Interview slot booked successfully!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed to book slot: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open link'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewSessionProvider>();
    final mySession = provider.mySession;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Interview Session'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : mySession != null
              ? _buildMySessionView(mySession)
              : _buildAvailableSlotsView(provider.availableSessions),
    );
  }

  Widget _buildMySessionView(InterviewSession session) {
    final dateFmt = DateFormat('EEEE, dd MMM yyyy').format(session.date.toLocal());
    final hasLink = session.meetingLink != null && session.meetingLink!.isNotEmpty;

    final Color statusColor = session.isCompleted ? Colors.green : Colors.blueAccent;
    final String statusLabel = session.isCompleted ? 'COMPLETED' : 'BOOKED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.event_available_rounded,
                      color: Colors.blueAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text('Your Interview Session',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(dateFmt, style: const TextStyle(fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${session.startTime} – ${session.endTime}',
                      style: const TextStyle(fontSize: 14)),
                ]),
                const SizedBox(height: 16),
                if (hasLink)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openLink(session.meetingLink!),
                      icon: const Icon(Icons.videocam_rounded),
                      label: const Text('Join Interview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your interviewer will share the meeting link here soon.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSlotsView(List<InterviewSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No interview slots available right now',
                style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Please check back later',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      );
    }

    final sorted = [...sessions]
      ..sort((a, b) {
        final d = a.date.compareTo(b.date);
        if (d != 0) return d;
        return a.startTime.compareTo(b.startTime);
      });

    return AbsorbPointer(
      absorbing: _isBooking,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, index) => _buildSlotCard(sorted[index]),
      ),
    );
  }

  Widget _buildSlotCard(InterviewSession session) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy').format(session.date.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isBooking ? null : () => _confirmAndBook(session),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Text(DateFormat('dd').format(session.date.toLocal()),
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM').format(session.date.toLocal()),
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateFmt,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${session.startTime} – ${session.endTime}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ]),
          ),
        ),
      ),
    );
  }
}
