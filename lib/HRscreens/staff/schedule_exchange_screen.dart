import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScheduleExchangeScreen extends StatefulWidget {
  final int myStaffId;
  final Schedule mySchedule;

  const ScheduleExchangeScreen({
    super.key,
    required this.myStaffId,
    required this.mySchedule,
  });

  @override
  State<ScheduleExchangeScreen> createState() => _ScheduleExchangeScreenState();
}

class _ScheduleExchangeScreenState extends State<ScheduleExchangeScreen> {
  final Color primaryBlue = const Color(0xFF4F46E5);

  Staff? _selectedStaff;
  Schedule? _selectedTargetSchedule;
  List<Schedule> _targetSchedules = [];
  bool _loadingSchedules = false;
  bool _submitting       = false;
  String _deptFilter     = 'All';
  final TextEditingController _noteController = TextEditingController();

  static const _depts = ['All', 'Marine Biologist', 'Taaras', 'General'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _onStaffSelected(Staff staff) async {
    setState(() {
      _selectedStaff          = staff;
      _selectedTargetSchedule = null;
      _targetSchedules        = [];
      _loadingSchedules       = true;
    });
    try {
      final schedules = await Provider.of<Schedules>(context, listen: false)
          .fetchSchedulesByStaffId(staff.staffId);
      // Only future schedules
      final now = DateTime.now();
      setState(() {
        _targetSchedules = schedules.where((s) =>
            s.workDate.isAfter(DateTime(now.year, now.month, now.day))).toList();
        _loadingSchedules = false;
      });
    } catch (e) {
      setState(() => _loadingSchedules = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedStaff == null || _selectedTargetSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a staff and their schedule.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _submitting = true);
    final success = await Provider.of<ScheduleExchanges>(context, listen: false)
        .requestExchange(
          requesterId:   widget.myStaffId,
          targetId:      _selectedStaff!.staffId,
          requesterSched: widget.mySchedule.schedId,
          targetSched:   _selectedTargetSchedule!.schedId,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
    setState(() => _submitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '✅ Exchange request sent! Waiting for ${_selectedStaff!.firstname} to respond.'
          : '❌ Failed to send request. Try again.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allStaff = context.watch<Staffs>().staffList
        .where((s) => s.staffId != widget.myStaffId)
        .toList();

    final filteredStaff = _deptFilter == 'All'
        ? allStaff
        : _deptFilter == 'General'
            ? allStaff.where((s) => s.department == null || s.department!.isEmpty).toList()
            : allStaff.where((s) => s.department == _deptFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Request Schedule Exchange',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── My schedule card ─────────────────────────────────────────────
            _sectionLabel('Your Schedule', Icons.event_note_rounded),
            _scheduleCard(widget.mySchedule, isMe: true),
            const SizedBox(height: 20),

            // ── Dept filter chips ─────────────────────────────────────────────
            _sectionLabel('Filter by Department', Icons.account_tree_rounded),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _depts.map((dept) {
                  final active = _deptFilter == dept;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _deptFilter = dept;
                      _selectedStaff = null;
                      _selectedTargetSchedule = null;
                      _targetSchedules = [];
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? primaryBlue : Colors.grey.shade300),
                      ),
                      child: Text(dept,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: active ? Colors.white : Colors.grey.shade600)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Staff picker ──────────────────────────────────────────────────
            _sectionLabel('Select Staff to Exchange With', Icons.people_rounded),
            const SizedBox(height: 8),
            filteredStaff.isEmpty
                ? _emptyBox('No staff found for this department')
                : SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredStaff.length,
                      itemBuilder: (ctx, i) {
                        final staff = filteredStaff[i];
                        final selected = _selectedStaff?.staffId == staff.staffId;
                        return GestureDetector(
                          onTap: () => _onStaffSelected(staff),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 90,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected ? primaryBlue.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: selected ? primaryBlue : Colors.grey.shade200,
                                  width: selected ? 2 : 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: primaryBlue.withOpacity(0.1),
                                  child: Icon(Icons.person_rounded,
                                      color: primaryBlue, size: 22),
                                ),
                                const SizedBox(height: 6),
                                Text('${staff.firstname}\n${staff.lastname}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? primaryBlue : const Color(0xFF1E293B))),
                                if (staff.department != null && staff.department!.isNotEmpty)
                                  Text(staff.department!,
                                      style: TextStyle(fontSize: 9,
                                          color: Colors.teal.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),

            // ── Target schedule picker ────────────────────────────────────────
            if (_selectedStaff != null) ...[
              _sectionLabel(
                  'Select ${_selectedStaff!.firstname}\'s Schedule to Swap',
                  Icons.swap_horiz_rounded),
              const SizedBox(height: 8),
              _loadingSchedules
                  ? const Center(child: CircularProgressIndicator())
                  : _targetSchedules.isEmpty
                      ? _emptyBox('No upcoming schedules for this staff')
                      : Column(
                          children: _targetSchedules.map((sched) {
                            final selected = _selectedTargetSchedule?.schedId == sched.schedId;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTargetSchedule = sched),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: selected ? primaryBlue.withOpacity(0.07) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: selected ? primaryBlue : Colors.grey.shade200,
                                      width: selected ? 2 : 1),
                                ),
                                child: Row(children: [
                                  Icon(Icons.calendar_today_rounded,
                                      color: selected ? primaryBlue : Colors.grey, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('dd MMM yyyy (EEE)').format(sched.workDate),
                                          style: TextStyle(fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: selected ? primaryBlue : const Color(0xFF1E293B))),
                                      const SizedBox(height: 2),
                                      Text('${sched.workStartTime ?? '—'} → ${sched.workEndTime ?? '—'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  )),
                                  if (selected)
                                    Icon(Icons.check_circle_rounded, color: primaryBlue, size: 20),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 20),
            ],

            // ── Note ─────────────────────────────────────────────────────────
            _sectionLabel('Note (Optional)', Icons.note_rounded),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. I have a family event on that day...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primaryBlue, width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit ────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _submitting ? null : _submitRequest,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Sending...' : 'Send Exchange Request',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) => Row(children: [
    Icon(icon, size: 16, color: primaryBlue),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryBlue)),
  ]);

  Widget _scheduleCard(Schedule s, {bool isMe = false}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isMe ? primaryBlue.withOpacity(0.07) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isMe ? primaryBlue.withOpacity(0.3) : Colors.grey.shade200),
    ),
    child: Row(children: [
      Icon(Icons.event_rounded, color: primaryBlue, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('dd MMM yyyy (EEE)').format(s.workDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text('${s.workStartTime ?? '—'} → ${s.workEndTime ?? '—'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    ]),
  );

  Widget _emptyBox(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 18),
      const SizedBox(width: 8),
      Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    ]),
  );
}