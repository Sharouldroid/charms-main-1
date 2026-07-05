import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/internshipmodels/interview_session.dart';
import 'package:charms/internshipproviders/interview_session_provider.dart';

class InterviewSessionAdminScreen extends StatefulWidget {
  const InterviewSessionAdminScreen({super.key});

  @override
  State<InterviewSessionAdminScreen> createState() =>
      _InterviewSessionAdminScreenState();
}

class _InterviewSessionAdminScreenState
    extends State<InterviewSessionAdminScreen> {
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      await context.read<InterviewSessionProvider>().loadAllSessions();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
        child: child!,
      ),
    );
    if (selectedDate == null || !mounted) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null || !mounted) return;

    final defaultEndMinutes = startTime.hour * 60 + startTime.minute + 30;
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (defaultEndMinutes ~/ 60) % 24,
        minute: defaultEndMinutes % 60,
      ),
    );
    if (endTime == null || !mounted) return;

    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    try {
      await context
          .read<InterviewSessionProvider>()
          .createSession(selectedDate, startStr, endStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Interview slot created'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed to create slot: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _editLink(InterviewSession session) async {
    final controller = TextEditingController(text: session.meetingLink ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Meeting Link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://zoom.us/j/...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await context
          .read<InterviewSessionProvider>()
          .updateMeetingLink(session.id, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Meeting link saved'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed to save link: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _markCompleted(InterviewSession session) async {
    try {
      await context.read<InterviewSessionProvider>().completeSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Interview marked as completed'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _confirmDelete(InterviewSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Slot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this interview slot? This cannot be undone.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<InterviewSessionProvider>().deleteSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🗑️ Slot deleted'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed to delete: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _confirmCancelBooking(InterviewSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
            'Free up this slot? ${session.internName ?? 'The intern'} will need to book a new one.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<InterviewSessionProvider>().cancelBooking(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Booking cancelled — slot is available again'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<InterviewSessionProvider>().allSessions;
    final filtered = _filterStatus == 'all'
        ? sessions
        : sessions.where((s) => s.status == _filterStatus).toList();

    final sorted = [...filtered]..sort((a, b) {
        final d = a.date.compareTo(b.date);
        if (d != 0) return d;
        return a.startTime.compareTo(b.startTime);
      });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Interview Sessions'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDate,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text('New Slot'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _filterChip('all', 'All'),
                    _filterChip('available', 'Available'),
                    _filterChip('booked', 'Booked'),
                    _filterChip('completed', 'Completed'),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sorted.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No interview slots yet',
                                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) => _buildSessionCard(sorted[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (_) => setState(() => _filterStatus = value),
        selectedColor: Colors.blueAccent.withOpacity(0.2),
        checkmarkColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildSessionCard(InterviewSession session) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy').format(session.date.toLocal());

    Color statusColor;
    IconData statusIcon;
    switch (session.status) {
      case 'booked':
        statusColor = Colors.blueAccent;
        statusIcon = Icons.event_available_rounded;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
    }

    final hasLink = session.meetingLink != null && session.meetingLink!.isNotEmpty;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$dateFmt • ${session.startTime}–${session.endTime}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(session.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
            if (session.internName != null && session.internName!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(session.internName!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ]),
            ],
            if (hasLink) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openLink(session.meetingLink!),
                borderRadius: BorderRadius.circular(6),
                child: Row(children: [
                  Icon(Icons.link, size: 14, color: Colors.indigo.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(session.meetingLink!,
                        style: TextStyle(
                            color: Colors.indigo.shade400,
                            fontSize: 12,
                            decoration: TextDecoration.underline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.open_in_new, size: 12, color: Colors.indigo.shade300),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!session.isCancelled)
                  OutlinedButton.icon(
                    onPressed: () => _editLink(session),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: Text(hasLink ? 'Edit Link' : 'Add Link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                if (session.isBooked)
                  OutlinedButton.icon(
                    onPressed: () => _markCompleted(session),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Mark Completed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                if (session.isBooked)
                  OutlinedButton.icon(
                    onPressed: () => _confirmCancelBooking(session),
                    icon: const Icon(Icons.undo, size: 14),
                    label: const Text('Cancel Booking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                if (session.isAvailable)
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(session),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
