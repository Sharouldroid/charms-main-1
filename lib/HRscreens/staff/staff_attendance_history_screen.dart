import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRproviders/attendances.dart';

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
  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = true;

  // Filter state
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  // Palette
  final Color staffPrimary   = const Color(0xFF4F46E5);
  final Color staffBg        = const Color(0xFFF8FAFC);
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
      final provider = Provider.of<Attendances>(context, listen: false);
      final records =
          await provider.getAttendanceByStaffId(widget.staffId);
      setState(() {
        _allRecords = records;
        _isLoading = false;
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

  // ── Filtered by month + year ──────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    return _allRecords.where((r) {
      if (r['clock_in_time'] == null) return false;
      final dt = DateTime.tryParse(r['clock_in_time'].toString());
      if (dt == null) return false;
      return dt.month == _selectedMonth && dt.year == _selectedYear;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['clock_in_time'].toString()) ??
            DateTime(0);
        final db = DateTime.tryParse(b['clock_in_time'].toString()) ??
            DateTime(0);
        return db.compareTo(da); // newest first
      });
  }

  // ── Summary for selected month ────────────────────────────────────────────────
  int get _totalPresent =>
      _filtered.where((r) => r['attendance_status'] == 2).length;
  int get _totalAbsent =>
      _filtered.where((r) => r['attendance_status'] == 1).length;

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
      _filtered.fold(Duration.zero, (sum, r) => sum + _workDuration(r));

  String _getStatusText(int? status) {
    switch (status) {
      case 2:  return 'Present';
      case 1:  return 'Absent';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 2:  return Colors.teal;
      case 1:  return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
          ? Center(
              child: CircularProgressIndicator(color: staffPrimary))
          : RefreshIndicator(
              color: staffPrimary,
              onRefresh: _loadHistory,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Month / Year selector ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        children: [
                          // Month + Year row
                          Row(
                            children: [
                              // Month dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: staffCardBorder),
                                  ),
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
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        );
                                      }),
                                      onChanged: (v) => setState(
                                          () => _selectedMonth = v!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Year picker
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: staffCardBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: staffPrimary),
                                    items: List.generate(5, (i) {
                                      final y =
                                          DateTime.now().year - i;
                                      return DropdownMenuItem(
                                        value: y,
                                        child: Text(y.toString(),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600)),
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

                          // ── Summary cards ───────────────────────────────
                          Row(
                            children: [
                              _buildSummaryCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Present',
                                value: '$_totalPresent days',
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 10),
                              _buildSummaryCard(
                                icon: Icons.cancel_rounded,
                                label: 'Absent',
                                value: '$_totalAbsent days',
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 10),
                              _buildSummaryCard(
                                icon: Icons.timer_rounded,
                                label: 'Total Hours',
                                value: _formatDuration(_totalHours),
                                color: staffPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Records list ──────────────────────────────────────────
                  filtered.isEmpty
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
                                  'No attendance for ${_months[_selectedMonth - 1]} $_selectedYear',
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
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) =>
                                  _buildHistoryCard(filtered[i]),
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: staffCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final int? status = record['attendance_status'];
    final Color statusColor = _getStatusColor(status);
    final String? clockIn  = record['clock_in_time'];
    final String? clockOut = record['clock_out_time'];
    final Duration worked  = _workDuration(record);

    DateTime? clockInDt =
        clockIn != null ? DateTime.tryParse(clockIn) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    clockInDt != null
                        ? DateFormat('dd').format(clockInDt)
                        : '—',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: statusColor),
                  ),
                  Text(
                    clockInDt != null
                        ? DateFormat('MMM').format(clockInDt)
                        : '',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        clockInDt != null
                            ? DateFormat('EEEE').format(clockInDt)
                            : 'Unknown',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _timeChip(Icons.login_rounded, Colors.teal,
                          clockIn != null
                              ? DateFormat('HH:mm').format(
                                  DateTime.parse(clockIn))
                              : '—'),
                      const SizedBox(width: 8),
                      _timeChip(Icons.logout_rounded, Colors.orange,
                          clockOut != null
                              ? DateFormat('HH:mm').format(
                                  DateTime.parse(clockOut))
                              : '—'),
                      const SizedBox(width: 8),
                      if (worked != Duration.zero)
                        _timeChip(Icons.timer_rounded, staffPrimary,
                            _formatDuration(worked)),
                    ],
                  ),
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
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 13, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text(
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