import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/main.dart';

// ── Models ──────────────────────────────────────────────────────────────────
 
class InternSummaryRow {
  final int internId;
  final int? userId;
  final String internName;
  final String institution;
  final String email;
  final String? photoUrl;
  final int? scheduleId;
  final int totalDays;
  final int completedDays;
  final String todayStatus; // 'completed' | 'in_progress' | 'absent'
  final DateTime? todayClockIn;
  final DateTime? todayClockOut;
  final String? lastSeenDate;
  final String? lastSeenLocation;
 
  InternSummaryRow({
    required this.internId,
    this.userId,
    required this.internName,
    required this.institution,
    required this.email,
    this.photoUrl,
    this.scheduleId,
    required this.totalDays,
    required this.completedDays,
    required this.todayStatus,
    this.todayClockIn,
    this.todayClockOut,
    this.lastSeenDate,
    this.lastSeenLocation,
  });
 
  factory InternSummaryRow.fromJson(Map<String, dynamic> j) => InternSummaryRow(
        internId: (j['intern_id'] as num).toInt(),
        userId: j['user_id'] != null ? (j['user_id'] as num).toInt() : null,
        internName: j['intern_name']?.toString() ?? 'Unknown',
        institution: j['institution']?.toString() ?? '-',
        email: j['email']?.toString() ?? '-',
        photoUrl: j['photo_url']?.toString(),
        scheduleId: j['schedule_id'] != null ? (j['schedule_id'] as num).toInt() : null,
        totalDays: (j['total_days'] as num?)?.toInt() ?? 0,
        completedDays: (j['completed_days'] as num?)?.toInt() ?? 0,
        todayStatus: j['today_status']?.toString() ?? 'absent',
        todayClockIn: j['today_clock_in'] != null
            ? DateTime.tryParse(j['today_clock_in'].toString())
            : null,
        todayClockOut: j['today_clock_out'] != null
            ? DateTime.tryParse(j['today_clock_out'].toString())
            : null,
        lastSeenDate: j['last_seen_date']?.toString(),
        lastSeenLocation: j['last_seen_location']?.toString(),
      );
 
  Color get statusColor {
    switch (todayStatus) {
      case 'completed':  return Colors.green;
      case 'in_progress': return Colors.orange;
      default:           return Colors.red;
    }
  }
 
  String get statusLabel {
    switch (todayStatus) {
      case 'completed':  return 'Done';
      case 'in_progress': return 'Active';
      default:           return 'Absent';
    }
  }
 
  IconData get statusIcon {
    switch (todayStatus) {
      case 'completed':  return Icons.check_circle_rounded;
      case 'in_progress': return Icons.radio_button_checked_rounded;
      default:           return Icons.cancel_rounded;
    }
  }
}
 
class DailyRecord {
  final int id;
  final String workDate;
  final String scheduleDescription;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInLocation;
 
  DailyRecord({
    required this.id,
    required this.workDate,
    required this.scheduleDescription,
    this.clockInTime,
    this.clockOutTime,
    this.clockInLocation,
  });
 
  factory DailyRecord.fromJson(Map<String, dynamic> j) => DailyRecord(
        id: (j['id'] as num).toInt(),
        workDate: j['work_date']?.toString() ?? '',
        scheduleDescription: j['schedule_description']?.toString() ?? '-',
        clockInTime: j['clock_in_time'] != null
            ? DateTime.tryParse(j['clock_in_time'].toString())
            : null,
        clockOutTime: j['clock_out_time'] != null
            ? DateTime.tryParse(j['clock_out_time'].toString())
            : null,
        clockInLocation: j['clock_in_location']?.toString(),
      );
 
  bool get hasClockOut => clockOutTime != null;
 
  String get duration {
    if (clockInTime == null || clockOutTime == null) return '-';
    final d = clockOutTime!.difference(clockInTime!);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
 
  String? get gpsCoords {
    if (clockInLocation == null) return null;
    final m = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)').firstMatch(clockInLocation!);
    return m != null ? '${m.group(1)},${m.group(2)}' : null;
  }
}
 
class AdminByDateRecord {
  final int id;
  final int internId;
  final String internName;
  final String institution;
  final String? photoUrl;
  final String workDate;
  final String scheduleDescription;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInLocation;
 
  AdminByDateRecord({
    required this.id,
    required this.internId,
    required this.internName,
    required this.institution,
    this.photoUrl,
    required this.workDate,
    required this.scheduleDescription,
    this.clockInTime,
    this.clockOutTime,
    this.clockInLocation,
  });
 
  factory AdminByDateRecord.fromJson(Map<String, dynamic> j) => AdminByDateRecord(
        id: (j['id'] as num).toInt(),
        internId: (j['intern_id'] as num).toInt(),
        internName: j['intern_name']?.toString() ?? 'Unknown',
        institution: j['institution']?.toString() ?? '-',
        photoUrl: j['photo_url']?.toString(),
        workDate: j['work_date']?.toString() ?? '',
        scheduleDescription: j['schedule_description']?.toString() ?? '-',
        clockInTime: j['clock_in_time'] != null
            ? DateTime.tryParse(j['clock_in_time'].toString())
            : null,
        clockOutTime: j['clock_out_time'] != null
            ? DateTime.tryParse(j['clock_out_time'].toString())
            : null,
        clockInLocation: j['clock_in_location']?.toString(),
      );
 
  bool get hasClockOut => clockOutTime != null;
  Color get statusColor => hasClockOut ? Colors.green : Colors.orange;
  String get statusLabel => hasClockOut ? 'Done' : 'Active';
 
  String? get gpsCoords {
    if (clockInLocation == null) return null;
    final m = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)').firstMatch(clockInLocation!);
    return m != null ? '${m.group(1)},${m.group(2)}' : null;
  }
}
 
// ── Main Screen ──────────────────────────────────────────────────────────────
 
class AdminInternAttendanceScreen extends StatefulWidget {
  const AdminInternAttendanceScreen({super.key});
 
  @override
  State<AdminInternAttendanceScreen> createState() =>
      _AdminInternAttendanceScreenState();
}
 
class _AdminInternAttendanceScreenState
    extends State<AdminInternAttendanceScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryBlue = Color(0xFF2563EB);
  final String _base = AppConfig.hostname;
 
  late TabController _tabController;
 
  // Tab 1: By Intern
  List<InternSummaryRow> _interns = [];
  Map<String, dynamic> _internSummary = {};
  bool _loadingInterns = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  List<InternSummaryRow> get _filteredInterns {
    return _interns.where((intern) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          intern.internName.toLowerCase().contains(q) ||
          intern.institution.toLowerCase().contains(q);
      final matchesStatus =
          _statusFilter == 'all' || intern.todayStatus == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }
 
  // Tab 2: By Date
  List<AdminByDateRecord> _byDateRecords = [];
  bool _loadingByDate = false;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _byDateSummary = {};
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _byDateRecords.isEmpty) {
        _loadByDate();
      }
    });
    _loadByIntern();
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
 
  // ── API calls ─────────────────────────────────────────────────────────────
 
  Future<void> _loadByIntern() async {
    setState(() => _loadingInterns = true);
    try {
      final res = await http.get(
          Uri.parse('$_base/api/internship/attendance/admin/by-intern'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          setState(() {
            _interns = (body['data'] as List)
                .map((e) => InternSummaryRow.fromJson(e))
                .toList();
            _internSummary = body['summary'] ?? {};
          });
        }
      }
    } catch (e) {
      debugPrint('loadByIntern error: $e');
    } finally {
      if (mounted) setState(() => _loadingInterns = false);
    }
  }
 
  Future<void> _loadByDate() async {
    setState(() => _loadingByDate = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await http.get(Uri.parse(
          '$_base/api/internship/attendance/admin?date=$dateStr'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          setState(() {
            _byDateRecords = (body['data'] as List)
                .map((e) => AdminByDateRecord.fromJson(e))
                .toList();
            _byDateSummary = body['summary'] ?? {};
          });
        }
      }
    } catch (e) {
      debugPrint('loadByDate error: $e');
    } finally {
      if (mounted) setState(() => _loadingByDate = false);
    }
  }
 
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadByDate();
    }
  }
 
  Future<void> _openMap(String coords) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coords');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
 
  // ── Build ─────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Intern Attendance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(0))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'By Intern'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'By Date'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildByInternTab(),
          _buildByDateTab(),
        ],
      ),
    );
  }
 
  // ── Tab 1: By Intern ──────────────────────────────────────────────────────
 
  Widget _buildByInternTab() {
    if (_loadingInterns) return const Center(child: CircularProgressIndicator());
 
    return RefreshIndicator(
      onRefresh: _loadByIntern,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  _buildInternSummaryCards(),
                  const SizedBox(height: 12),
                  _buildSearchAndFilter(),
                ],
              ),
            ),
          ),
          if (_filteredInterns.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _interns.isEmpty
                          ? 'No attendance records yet.'
                          : 'No results match your search.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _InternSummaryCard(
                    row: _filteredInterns[i],
                    baseUrl: _base,
                    onOpenMap: _openMap,
                  ),
                  childCount: _filteredInterns.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
 
  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search by name or institution...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusFilterChip(
                label: 'All',
                selected: _statusFilter == 'all',
                color: _primaryBlue,
                onTap: () => setState(() => _statusFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _StatusFilterChip(
                label: 'Active',
                selected: _statusFilter == 'in_progress',
                color: Colors.orange,
                onTap: () => setState(() => _statusFilter = 'in_progress'),
              ),
              const SizedBox(width: 8),
              _StatusFilterChip(
                label: 'Done',
                selected: _statusFilter == 'completed',
                color: Colors.green,
                onTap: () => setState(() => _statusFilter = 'completed'),
              ),
              const SizedBox(width: 8),
              _StatusFilterChip(
                label: 'Absent',
                selected: _statusFilter == 'absent',
                color: Colors.red,
                onTap: () => setState(() => _statusFilter = 'absent'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInternSummaryCards() {
    final total     = _internSummary['total_interns'] ?? 0;
    final present   = _internSummary['present_today'] ?? 0;
    final absent    = _internSummary['absent_today'] ?? 0;
    final completed = _internSummary['completed_today'] ?? 0;
 
    return Row(children: [
      _StatCard(label: 'Total', value: '$total',
          icon: Icons.people_rounded, color: _primaryBlue),
      const SizedBox(width: 8),
      _StatCard(label: 'Present', value: '$present',
          icon: Icons.login_rounded, color: Colors.orange),
      const SizedBox(width: 8),
      _StatCard(label: 'Done', value: '$completed',
          icon: Icons.check_circle_rounded, color: Colors.green),
      const SizedBox(width: 8),
      _StatCard(label: 'Absent', value: '$absent',
          icon: Icons.cancel_rounded, color: Colors.red),
    ]);
  }
 
  // ── Tab 2: By Date ────────────────────────────────────────────────────────
 
  Widget _buildByDateTab() {
    return RefreshIndicator(
      onRefresh: _loadByDate,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Date picker row
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05),
                              blurRadius: 8, offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_month_rounded,
                              color: _primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Viewing attendance for',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text(
                              DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_rounded,
                            color: Colors.grey, size: 18),
                      ]),
                    ),
                  ),
 
                  const SizedBox(height: 10),
 
                  // Summary for selected date
                  if (_byDateSummary.isNotEmpty)
                    Row(children: [
                      _StatCard(
                          label: 'Present',
                          value: '${_byDateSummary['total_records'] ?? 0}',
                          icon: Icons.how_to_reg_rounded,
                          color: _primaryBlue),
                      const SizedBox(width: 8),
                      _StatCard(
                          label: 'Done',
                          value: '${_byDateSummary['completed'] ?? 0}',
                          icon: Icons.check_circle_rounded,
                          color: Colors.green),
                      const SizedBox(width: 8),
                      _StatCard(
                          label: 'Active',
                          value: '${_byDateSummary['in_progress'] ?? 0}',
                          icon: Icons.radio_button_checked_rounded,
                          color: Colors.orange),
                    ]),
                ],
              ),
            ),
          ),
 
          if (_loadingByDate)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (_byDateRecords.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No attendance on this date.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ByDateCard(
                    record: _byDateRecords[i],
                    onOpenMap: _openMap,
                  ),
                  childCount: _byDateRecords.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
 
// ── Intern Summary Card (Tab 1) ──────────────────────────────────────────────
 
class _InternSummaryCard extends StatefulWidget {
  final InternSummaryRow row;
  final String baseUrl;
  final void Function(String) onOpenMap;
 
  const _InternSummaryCard({
    required this.row,
    required this.baseUrl,
    required this.onOpenMap,
  });
 
  @override
  State<_InternSummaryCard> createState() => _InternSummaryCardState();
}
 
class _InternSummaryCardState extends State<_InternSummaryCard> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  bool _expanded = false;
  bool _loadingHistory = false;
  List<DailyRecord> _history = [];
 
  Future<void> _loadHistory() async {
    if (_history.isNotEmpty) {
      setState(() => _expanded = !_expanded);
      return;
    }
    setState(() { _expanded = true; _loadingHistory = true; });
    try {
      final res = await http.get(Uri.parse(
          '${widget.baseUrl}/api/internship/attendance/admin/intern/${widget.row.internId}'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          setState(() {
            _history = (body['records'] as List)
                .map((e) => DailyRecord.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('loadHistory error: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final timeFormat = DateFormat('hh:mm a');
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _loadHistory,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _primaryBlue.withOpacity(0.1),
                        backgroundImage: row.photoUrl != null
                            ? NetworkImage(row.photoUrl!) : null,
                        child: row.photoUrl == null
                            ? Text(
                                row.internName.isNotEmpty
                                    ? row.internName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: _primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.internName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(row.institution,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Today's status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: row.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: row.statusColor.withOpacity(0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(row.statusIcon, color: row.statusColor, size: 13),
                          const SizedBox(width: 4),
                          Text(row.statusLabel,
                              style: TextStyle(
                                  color: row.statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),
 
                  const SizedBox(height: 10),
 
                  // Today's clock-in/out if present
                  if (row.todayStatus != 'absent') ...[
                    Row(children: [
                      Expanded(child: _MiniTimeChip(
                          label: 'In',
                          time: row.todayClockIn != null
                              ? timeFormat.format(row.todayClockIn!.toLocal())
                              : '-',
                          color: _primaryBlue)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTimeChip(
                          label: 'Out',
                          time: row.todayClockOut != null
                              ? timeFormat.format(row.todayClockOut!.toLocal())
                              : 'Not yet',
                          color: row.todayClockOut != null
                              ? Colors.green : Colors.grey)),
                    ]),
                    const SizedBox(height: 8),
                  ],
 
                  // Stats row
                  Row(children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${row.totalDays} day${row.totalDays != 1 ? 's' : ''} total  ·  '
                        '${row.completedDays} completed',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(_expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade400, size: 18),
                    Text(_expanded ? 'Hide history' : 'View history',
                        style: const TextStyle(
                            fontSize: 12, color: _primaryBlue,
                            fontWeight: FontWeight.w500)),
                  ]),
                ],
              ),
            ),
          ),
 
          // ── Expanded history ────────────────────────────────────────────
          if (_expanded) ...[
            Divider(color: Colors.grey.shade100, height: 1),
            if (_loadingHistory)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_history.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No records found.',
                    style: TextStyle(color: Colors.grey.shade400)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 14),
                itemCount: _history.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (_, i) =>
                    _DailyRecordTile(record: _history[i], onOpenMap: widget.onOpenMap),
              ),
          ],
        ],
      ),
    );
  }
}
 
// ── Daily Record Tile (inside intern card) ───────────────────────────────────
 
class _DailyRecordTile extends StatelessWidget {
  final DailyRecord record;
  final void Function(String) onOpenMap;
 
  const _DailyRecordTile({required this.record, required this.onOpenMap});
 
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');
    final Color statusColor = record.hasClockOut ? Colors.green : Colors.orange;
 
    DateTime? workDt = DateTime.tryParse(record.workDate);
 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              workDt != null ? dateFormat.format(workDt) : record.workDate,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.hasClockOut ? 'Completed' : 'In Progress',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _MiniTimeChip(
                label: 'In',
                time: record.clockInTime != null
                    ? timeFormat.format(record.clockInTime!.toLocal()) : '-',
                color: const Color(0xFF2563EB))),
            const SizedBox(width: 8),
            Expanded(child: _MiniTimeChip(
                label: 'Out',
                time: record.clockOutTime != null
                    ? timeFormat.format(record.clockOutTime!.toLocal()) : 'Not yet',
                color: record.hasClockOut ? Colors.green : Colors.grey)),
          ]),
          if (record.hasClockOut) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.timer_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('Duration: ${record.duration}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ],
          if (record.clockInLocation != null &&
              record.clockInLocation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: record.gpsCoords != null
                  ? () => onOpenMap(record.gpsCoords!) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 13, color: Colors.green.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.clockInLocation!.split('\n').first,
                      style: TextStyle(
                          fontSize: 11,
                          color: record.gpsCoords != null
                              ? Colors.blue : Colors.grey.shade500,
                          decoration: record.gpsCoords != null
                              ? TextDecoration.underline : null),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
 
// ── By Date Card (Tab 2) ─────────────────────────────────────────────────────
 
class _ByDateCard extends StatelessWidget {
  final AdminByDateRecord record;
  final void Function(String) onOpenMap;
 
  const _ByDateCard({required this.record, required this.onOpenMap});
 
  static const Color _primaryBlue = Color(0xFF2563EB);
 
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
 
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _primaryBlue.withOpacity(0.1),
              backgroundImage: record.photoUrl != null
                  ? NetworkImage(record.photoUrl!) : null,
              child: record.photoUrl == null
                  ? Text(
                      record.internName.isNotEmpty
                          ? record.internName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: _primaryBlue, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.internName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(record.institution,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: record.statusColor.withOpacity(0.3)),
              ),
              child: Text(record.statusLabel,
                  style: TextStyle(
                      color: record.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MiniTimeChip(
                label: 'Clock In',
                time: record.clockInTime != null
                    ? timeFormat.format(record.clockInTime!.toLocal()) : '-',
                color: _primaryBlue)),
            const SizedBox(width: 8),
            Expanded(child: _MiniTimeChip(
                label: 'Clock Out',
                time: record.clockOutTime != null
                    ? timeFormat.format(record.clockOutTime!.toLocal()) : 'Not yet',
                color: record.hasClockOut ? Colors.green : Colors.grey)),
          ]),
          if (record.clockInLocation != null &&
              record.clockInLocation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: record.gpsCoords != null
                  ? () => onOpenMap(record.gpsCoords!) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      record.clockInLocation!.split('\n').first,
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (record.gpsCoords != null)
                    const Icon(Icons.open_in_new_rounded,
                        size: 12, color: Colors.blue),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
 
// ── Shared Widgets ────────────────────────────────────────────────────────────
 
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
 
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
        ),
      );
}
 
class _MiniTimeChip extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
 
  const _MiniTimeChip({
    required this.label,
    required this.time,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(time,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
      );
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}