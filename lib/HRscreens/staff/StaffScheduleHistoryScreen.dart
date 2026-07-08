import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/schedule_exchange.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StaffScheduleHistoryScreen extends StatefulWidget {
  final int staffId;
  final String username;

  const StaffScheduleHistoryScreen({
    super.key,
    required this.staffId,
    required this.username,
  });

  @override
  State<StaffScheduleHistoryScreen> createState() =>
      _StaffScheduleHistoryScreenState();
}

class _StaffScheduleHistoryScreenState
    extends State<StaffScheduleHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Schedule> _rejectedSchedules = [];
  List<ScheduleExchange> _exchangeHistory = [];

  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  // ── Location helpers ──────────────────────────────────────────────────────
  String _locationName(String? loc) {
    switch (loc) {
      case '1': return 'Chagar Hutang';
      case '2': return 'Turtle Lab';
      case '3': return 'UMT';
      default:  return '—';
    }
  }

  Color _locationColor(String? loc) {
    switch (loc) {
      case '1': return const Color(0xFF0891B2);
      case '2': return const Color(0xFF7C3AED);
      case '3': return const Color(0xFFF59E0B);
      default:  return Colors.grey;
    }
  }

  Widget _locationBadge(String? loc) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _locationColor(loc).withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _locationColor(loc).withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.location_on_rounded, size: 10, color: _locationColor(loc)),
      const SizedBox(width: 3),
      Text(_locationName(loc),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _locationColor(loc))),
    ]),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await Provider.of<Schedules>(context, listen: false)
          .fetchSchedulesByStaffId(widget.staffId);

      await Provider.of<ScheduleExchanges>(context, listen: false)
          .fetchExchangesByStaff(widget.staffId);

      if (mounted) {
        setState(() {
          _rejectedSchedules = schedules
              .where((s) => s.acceptanceStatus == 2)
              .toList()
            ..sort((a, b) => b.workDate.compareTo(a.workDate));

          _exchangeHistory = Provider.of<ScheduleExchanges>(
                  context, listen: false)
              .exchanges
            ..sort((a, b) =>
                (b.createdAt ?? DateTime(0))
                    .compareTo(a.createdAt ?? DateTime(0)));
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Rejected schedule card ────────────────────────────────────────────────
  Widget _buildRejectedCard(Schedule s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_rounded,
                    color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy (EEE)').format(s.workDate),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    // ✅ Location badge
                    _locationBadge(s.workLocation.toString()),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_rounded,
                        size: 12, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text('Rejected',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent)),
                  ],
                ),
              ),
            ]),

            if (s.workStartTime != null || s.workEndTime != null) ...[
              const SizedBox(height: 10),
              Divider(color: staffCardBorder, height: 1),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  '${s.workStartTime ?? '—'} → ${s.workEndTime ?? '—'}',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
              ]),
            ],

            // ── Rejection reason ─────────────────────────────────────────
            if (s.staffNote != null && s.staffNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reason',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent)),
                          const SizedBox(height: 2),
                          Text(s.staffNote!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Exchange history card ─────────────────────────────────────────────────
  Widget _buildExchangeCard(ScheduleExchange ex) {
    final isRequester = ex.requesterId == widget.staffId;
    final myDate       = isRequester ? ex.requesterWorkDate    : ex.targetWorkDate;
    final theirDate    = isRequester ? ex.targetWorkDate       : ex.requesterWorkDate;
    final theirName    = isRequester ? ex.targetName           : ex.requesterName;
    final myLocation   = isRequester ? ex.requesterWorkLocation : ex.targetWorkLocation;
    final theirLocation = isRequester ? ex.targetWorkLocation  : ex.requesterWorkLocation;

    final Color statusColor = ex.statusColor;
    final String statusText = ex.statusText;

    IconData statusIcon;
    switch (ex.status) {
      case 3:  statusIcon = Icons.check_circle_rounded; break;
      case 2:
      case 4:  statusIcon = Icons.cancel_rounded; break;
      case 1:  statusIcon = Icons.pending_rounded; break;
      default: statusIcon = Icons.swap_horiz_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRequester
                          ? 'You requested exchange'
                          : 'Exchange request received',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    if (ex.createdAt != null)
                      Text(
                        DateFormat('dd MMM yyyy').format(ex.createdAt!),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(statusText,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ]),

            const SizedBox(height: 12),
            Divider(color: staffCardBorder, height: 1),
            const SizedBox(height: 12),

            // ── Schedule swap details ─────────────────────────────────────
            Row(children: [
              Expanded(
                child: _scheduleBlock(
                  label: 'Your Schedule',
                  date: myDate,
                  workLocation: myLocation, // ✅
                  color: staffPrimary,
                  icon: Icons.person_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz_rounded,
                    color: Colors.grey.shade400, size: 22),
              ),
              Expanded(
                child: _scheduleBlock(
                  label: theirName ?? 'Other Staff',
                  date: theirDate,
                  workLocation: theirLocation, // ✅
                  color: Colors.teal,
                  icon: Icons.people_rounded,
                ),
              ),
            ]),

            // ── Notes ────────────────────────────────────────────────────
            if (_hasNotes(ex)) ...[
              const SizedBox(height: 12),
              _buildNotesSection(ex, isRequester),
            ],
          ],
        ),
      ),
    );
  }

  // ── Schedule block with location badge ───────────────────────────────────
  Widget _scheduleBlock({
    required String label,
    required String? date,
    required String? workLocation,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            date != null ? _formatDateStr(date) : '—',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          // ✅ Location badge
          _locationBadge(workLocation),
        ],
      ),
    );
  }

  bool _hasNotes(ScheduleExchange ex) =>
      (ex.requesterNote?.isNotEmpty ?? false) ||
      (ex.targetNote?.isNotEmpty ?? false) ||
      (ex.hrNote?.isNotEmpty ?? false);

  Widget _buildNotesSection(ScheduleExchange ex, bool isRequester) {
    return Column(children: [
      if (ex.requesterNote?.isNotEmpty ?? false)
        _noteRow(
          label: isRequester
              ? 'Your Note'
              : '${ex.requesterName ?? "Requester"} Note',
          note: ex.requesterNote!,
          color: staffPrimary,
        ),
      if (ex.targetNote?.isNotEmpty ?? false)
        _noteRow(
          label: isRequester
              ? '${ex.targetName ?? "Target"} Note'
              : 'Your Note',
          note: ex.targetNote!,
          color: Colors.teal,
        ),
      if (ex.hrNote?.isNotEmpty ?? false)
        _noteRow(
          label: 'HR Note',
          note: ex.hrNote!,
          color: Colors.orange,
        ),
    ]);
  }

  Widget _noteRow({
    required String label,
    required String note,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes_rounded, size: 13, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(note,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateStr(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy (EEE)').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
      appBar: StaffAppBar(
        title: 'Schedule History',
        bottomHeight: 48,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Rejected (${_rejectedSchedules.length})',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Exchanges (${_exchangeHistory.length})',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: staffPrimary))
          : RefreshIndicator(
              color: staffPrimary,
              onRefresh: _loadData,
              child: StaffPageContainer(
                child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Rejected Schedules ────────────────────────
                  _rejectedSchedules.isEmpty
                      ? _emptyState(
                          icon: Icons.event_available_rounded,
                          message: 'No rejected schedules',
                          sub: 'Schedules you rejected will appear here',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.only(top: 16, bottom: 32),
                          itemCount: _rejectedSchedules.length,
                          itemBuilder: (_, i) =>
                              _buildRejectedCard(_rejectedSchedules[i]),
                        ),

                  // ── Tab 2: Exchange History ───────────────────────────
                  _exchangeHistory.isEmpty
                      ? _emptyState(
                          icon: Icons.swap_horiz_rounded,
                          message: 'No exchange history',
                          sub:
                              'Schedule exchange requests will appear here',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.only(top: 16, bottom: 32),
                          itemCount: _exchangeHistory.length,
                          itemBuilder: (_, i) =>
                              _buildExchangeCard(_exchangeHistory[i]),
                        ),
                ],
                ),
              ),
            ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}