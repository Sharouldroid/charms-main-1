import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/schedule_exchange.dart';

class StaffAttendanceHistoryScreen extends StatefulWidget {
  final int staffId;
  final String username;

  const StaffAttendanceHistoryScreen({
    super.key,
    required this.staffId,
    required this.username,
  });

  @override
  State<StaffAttendanceHistoryScreen> createState() =>
      _StaffAttendanceHistoryScreenState();
}

class _StaffAttendanceHistoryScreenState
    extends State<StaffAttendanceHistoryScreen> {
  List<Map<String, dynamic>> _allRecords   = [];
  List<Schedule>             _allSchedules = [];
  List<ScheduleExchange>     _allExchanges = [];
  bool _isLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final attProvider      = Provider.of<Attendances>(context, listen: false);
      final schedProvider    = Provider.of<Schedules>(context, listen: false);
      final exchangeProvider = Provider.of<ScheduleExchanges>(context, listen: false);

      // Fetch attendance + schedules in parallel, then exchanges
      final results = await Future.wait([
        attProvider.getAttendanceByStaffId(widget.staffId),
        schedProvider.fetchSchedulesByStaffId(widget.staffId),
      ]);

      // Fetch exchanges for this staff (stores into provider's _exchanges list)
      await exchangeProvider.fetchExchangesByStaff(widget.staffId);

      setState(() {
        _allRecords   = results[0] as List<Map<String, dynamic>>;
        _allSchedules = results[1] as List<Schedule>;
        _allExchanges = exchangeProvider.exchanges;
        _isLoading    = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ── Find HR-approved exchange for a given schedId ─────────────────────────────
  ScheduleExchange? _findApprovedExchange(int schedId) {
    try {
      return _allExchanges.firstWhere(
        (e) =>
            (e.requesterSched == schedId || e.targetSched == schedId) &&
            e.status == 3, // 3 = HR Approved
      );
    } catch (_) {
      return null;
    }
  }

  // ── Build a unified day-by-day list ──────────────────────────────────────────
  List<Map<String, dynamic>> get _mergedRecords {
    final schedulesThisMonth = _allSchedules.where((s) {
      return s.workDate.month == _selectedMonth &&
          s.workDate.year == _selectedYear;
    }).toList();

    final now = DateTime.now();

    return schedulesThisMonth.map((schedule) {
      final attendance = _allRecords.cast<Map<String, dynamic>?>().firstWhere(
            (r) => r!['schedule_id']?.toString() == schedule.schedId.toString(),
            orElse: () => null,
          );

      // Check if this schedule was part of an HR-approved exchange
      final exchange = _findApprovedExchange(schedule.schedId);

      if (attendance != null) {
        return {
          ...attendance,
          '_schedule':     schedule,
          '_exchange':     exchange, // null if not a swapped schedule
          '_display_date': schedule.workDate,
        };
      } else {
        final isToday = schedule.workDate.year == now.year &&
            schedule.workDate.month == now.month &&
            schedule.workDate.day == now.day;
        final isPast = schedule.workDate.isBefore(
            DateTime(now.year, now.month, now.day));

        // Check if staff rejected this schedule
        final isRejected = schedule.acceptanceStatus == 2;

        return {
          'attendance_id':     null,
          'staff_id':          widget.staffId,
          'schedule_id':       schedule.schedId,
          // Exchanged schedules keep normal status (-1/0) since the backend
          // already owns the swapped schedId under this staff. The exchange
          // field is purely cosmetic — it just shows a "Swapped" label.
          'attendance_status': isRejected
              ? -2                           // -2 = staff did not accept
              : isPast && !isToday ? -1 : 0, // -1 = missed, 0 = upcoming
          'clock_in_time':     null,
          'clock_out_time':    null,
          'clock_in_location': null,
          '_schedule':         schedule,
          '_exchange':         exchange, // null if not a swapped schedule
          '_display_date':     schedule.workDate,
        };
      }
    }).toList()
      ..sort((a, b) {
        final da = a['_display_date'] as DateTime;
        final db = b['_display_date'] as DateTime;
        return db.compareTo(da); // newest first
      });
  }

  // ── Summary ───────────────────────────────────────────────────────────────────
  int get _totalPresent => _mergedRecords.where((r) => r['attendance_status'] == 2).length;
  int get _totalAbsent  => _mergedRecords.where((r) => r['attendance_status'] == 1).length;
  int get _totalMissed  => _mergedRecords.where((r) => r['attendance_status'] == -1).length;
  // Note: -2 (Not Accepted) intentionally excluded from all summary counters

  Duration _workDuration(Map<String, dynamic> r) {
    final inTime  = DateTime.tryParse(r['clock_in_time']?.toString() ?? '');
    final outTime = DateTime.tryParse(r['clock_out_time']?.toString() ?? '');
    if (inTime == null || outTime == null) return Duration.zero;
    return outTime.difference(inTime);
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  Duration get _totalHours =>
      _mergedRecords.fold(Duration.zero, (sum, r) => sum + _workDuration(r));

  // ── Status helpers ────────────────────────────────────────────────────────────
  String _getStatusText(int? status) {
    switch (status) {
      case  2:  return 'Present';
      case  1:  return 'Absent';
      case -1:  return 'No Clock-In';
      case  0:  return 'Upcoming';
      case -2:  return 'Not Accepted';
      default:  return 'Unknown';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case  2:  return Colors.teal;
      case  1:  return Colors.redAccent;
      case -1:  return Colors.orange;
      case  0:  return Colors.blueGrey;
      case -2:  return Colors.grey;
      default:  return Colors.grey;
    }
  }

  IconData _getStatusIcon(int? status) {
    switch (status) {
      case  2:  return Icons.check_circle_rounded;
      case  1:  return Icons.cancel_rounded;
      case -1:  return Icons.warning_amber_rounded;
      case  0:  return Icons.schedule_rounded;
      case -2:  return Icons.block_rounded;
      default:  return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final merged = _mergedRecords;

    return Scaffold(
      backgroundColor: staffBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: staffPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ATTENDANCE HISTORY',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: staffPrimary))
          : RefreshIndicator(
              color: staffPrimary,
              onRefresh: _loadHistory,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        children: [
                          // ── Month + Year selector ───────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _dropdownBox(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedMonth,
                                      isExpanded: true,
                                      icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: staffPrimary),
                                      items: List.generate(12, (i) {
                                        return DropdownMenuItem(
                                          value: i + 1,
                                          child: Text(_months[i],
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                        );
                                      }),
                                      onChanged: (v) =>
                                          setState(() => _selectedMonth = v!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _dropdownBox(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: staffPrimary),
                                    items: List.generate(5, (i) {
                                      final y = DateTime.now().year - i;
                                      return DropdownMenuItem(
                                        value: y,
                                        child: Text(y.toString(),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      );
                                    }),
                                    onChanged: (v) =>
                                        setState(() => _selectedYear = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Summary cards ───────────────────────────────────
                          Row(
                            children: [
                              _buildSummaryCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Present',
                                value: '$_totalPresent days',
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              _buildSummaryCard(
                                icon: Icons.cancel_rounded,
                                label: 'Absent',
                                value: '$_totalAbsent days',
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              _buildSummaryCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'No Clock-In',
                                value: '$_totalMissed days',
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _buildSummaryCard(
                                icon: Icons.timer_rounded,
                                label: 'Hours',
                                value: _formatDuration(_totalHours),
                                color: staffPrimary,
                              ),
                            ],
                          ),

                          // ── Legend ──────────────────────────────────────────
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 15, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '"No Clock-In" means you had a schedule but didn\'t clock in. '
                                    'Contact HR if this was a mistake.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Records list ────────────────────────────────────────────
                  merged.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_note_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No schedule for ${_months[_selectedMonth - 1]} $_selectedYear',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildHistoryCard(merged[i]),
                              childCount: merged.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _dropdownBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: staffCardBorder),
      ),
      child: child,
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: staffCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final int? status                = record['attendance_status'];
    final Color statusColor          = _getStatusColor(status);
    final String? clockIn            = record['clock_in_time'];
    final String? clockOut           = record['clock_out_time'];
    final Duration worked            = _workDuration(record);
    final DateTime displayDate       = record['_display_date'] as DateTime;
    final Schedule? schedule         = record['_schedule'] as Schedule?;
    final ScheduleExchange? exchange = record['_exchange'] as ScheduleExchange?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == -1
              ? Colors.orange.withOpacity(0.4)
              : status == 1
                  ? Colors.redAccent.withOpacity(0.4)
                  : status == -2
                      ? Colors.grey.withOpacity(0.3)
                      : staffCardBorder,
          width: (status == -1 || status == 1 || status == -2) ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(displayDate),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: statusColor),
                  ),
                  Text(
                    DateFormat('MMM').format(displayDate),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('EEEE').format(displayDate),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(status),
                                size: 11, color: statusColor),
                            const SizedBox(width: 3),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Schedule time info
                  if (schedule != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Scheduled: ${schedule.workStartTime ?? '—'} → ${schedule.workEndTime ?? '—'}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],

                  // ── Swapped schedule label (cosmetic only) ──────────────────
                  if (exchange != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 12, color: Colors.purple.shade300),
                        const SizedBox(width: 4),
                        Text(
                          'Swapped schedule',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade300,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 6),

                  // ── Status-specific content ─────────────────────────────────
                  if (status == -2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block_rounded,
                              size: 13, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            'Schedule not accepted',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else if (status == -1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 13, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(
                            'Did not clock in — contact HR',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else if (status == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_rounded,
                              size: 13, color: Colors.redAccent),
                          SizedBox(width: 6),
                          Text(
                            'Marked absent by HR',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else if (status == 0)
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 4),
                        Text('Upcoming shift',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400,
                                fontWeight: FontWeight.w500)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        _timeChip(Icons.login_rounded, Colors.teal,
                            clockIn != null
                                ? DateFormat('HH:mm')
                                    .format(DateTime.parse(clockIn))
                                : '—'),
                        const SizedBox(width: 8),
                        _timeChip(Icons.logout_rounded, Colors.orange,
                            clockOut != null
                                ? DateFormat('HH:mm')
                                    .format(DateTime.parse(clockOut))
                                : 'Not clocked out'),
                        const SizedBox(width: 8),
                        if (worked != Duration.zero)
                          _timeChip(Icons.timer_rounded, staffPrimary,
                              _formatDuration(worked)),
                      ],
                    ),

                  // Location
                  if (record['clock_in_location'] != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${record['clock_in_location']}',
                        );
                        launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'View Location',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}