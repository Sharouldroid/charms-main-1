import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/main.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class AdminAttendanceSummary {
  final int totalRecords;
  final int completed;
  final int inProgress;
  final int uniqueInterns;

  AdminAttendanceSummary({
    required this.totalRecords,
    required this.completed,
    required this.inProgress,
    required this.uniqueInterns,
  });

  factory AdminAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceSummary(
      totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      uniqueInterns: (json['unique_interns'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAttendanceRecord {
  final int id;
  final int internId;
  final int scheduleId;
  final String scheduleDescription;
  final String internName;
  final String internEmail;
  final String institution;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInLocation;

  AdminAttendanceRecord({
    required this.id,
    required this.internId,
    required this.scheduleId,
    required this.scheduleDescription,
    required this.internName,
    required this.internEmail,
    required this.institution,
    this.clockInTime,
    this.clockOutTime,
    this.clockInLocation,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceRecord(
      id: (json['id'] as num).toInt(),
      internId: (json['intern_id'] as num).toInt(),
      scheduleId: (json['schedule_id'] as num).toInt(),
      scheduleDescription: json['schedule_description']?.toString() ?? '-',
      internName: json['intern_name']?.toString() ?? 'Unknown',
      internEmail: json['intern_email']?.toString() ?? '-',
      institution: json['institution']?.toString() ?? '-',
      clockInTime: json['clock_in_time'] != null
          ? DateTime.tryParse(json['clock_in_time'].toString())
          : null,
      clockOutTime: json['clock_out_time'] != null
          ? DateTime.tryParse(json['clock_out_time'].toString())
          : null,
      clockInLocation: json['clock_in_location']?.toString(),
    );
  }

  bool get hasClockOut => clockOutTime != null;

  String get shiftDuration {
    if (clockInTime == null || clockOutTime == null) return '-';
    final d = clockOutTime!.difference(clockInTime!);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  /// Extract raw GPS coordinates from location string
  /// Location format: "Place name\n(lat, lng)"
  String? get gpsCoordinates {
    if (clockInLocation == null) return null;
    final match = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)')
        .firstMatch(clockInLocation!);
    if (match != null) return '${match.group(1)},${match.group(2)}';
    return null;
  }
}

class ScheduleOption {
  final int id;
  final String description;
  final String? startDate;

  ScheduleOption({required this.id, required this.description, this.startDate});

  factory ScheduleOption.fromJson(Map<String, dynamic> json) {
    return ScheduleOption(
      id: (json['id'] as num).toInt(),
      description: json['description']?.toString() ?? '-',
      startDate: json['start_date']?.toString(),
    );
  }

  String get label {
    if (startDate != null) {
      final d = DateTime.tryParse(startDate!);
      if (d != null) {
        return '${DateFormat('dd MMM yyyy').format(d)} — $description';
      }
    }
    return description;
  }
}

// ── Screen ──────────────────────────────────────────────────────────────────

class AdminInternAttendanceScreen extends StatefulWidget {
  const AdminInternAttendanceScreen({super.key});

  @override
  State<AdminInternAttendanceScreen> createState() =>
      _AdminInternAttendanceScreenState();
}

class _AdminInternAttendanceScreenState
    extends State<AdminInternAttendanceScreen> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _bgColor = Color(0xFFF4F7FA);

  final String _baseUrl = AppConfig.hostname;

  bool _isLoading = true;
  String? _error;

  List<AdminAttendanceRecord> _records = [];
  AdminAttendanceSummary? _summary;
  List<ScheduleOption> _scheduleOptions = [];

  // Filters
  int? _selectedScheduleId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadScheduleOptions();
    _loadAttendance();
  }

  Future<void> _loadScheduleOptions() async {
    try {
      final url = '$_baseUrl/api/internship/attendance/schedules';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          setState(() {
            _scheduleOptions = decoded
                .map((e) => ScheduleOption.fromJson(e as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule options: $e');
    }
  }

  Future<void> _loadAttendance() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      var url = '$_baseUrl/api/internship/attendance/admin';
      final params = <String>[];
      if (_selectedScheduleId != null) {
        params.add('schedule_id=$_selectedScheduleId');
      }
      if (_selectedDate != null) {
        params.add('date=${DateFormat('yyyy-MM-dd').format(_selectedDate!)}');
      }
      if (params.isNotEmpty) url += '?${params.join('&')}';

      debugPrint('Admin attendance URL: $url');
      final res = await http.get(Uri.parse(url));
      debugPrint('Admin attendance status: ${res.statusCode}');
      debugPrint('Admin attendance body: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['success'] == true) {
          final data = decoded['data'] as List;
          setState(() {
            _records = data
                .map((e) => AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
                .toList();
            _summary = AdminAttendanceSummary.fromJson(
                decoded['summary'] as Map<String, dynamic>);
            _isLoading = false;
          });
        }
      } else {
        setState(() { _error = 'Failed to load: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAttendance();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedScheduleId = null;
      _selectedDate = null;
    });
    _loadAttendance();
  }

  Future<void> _openGoogleMaps(String coordinates) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$coordinates');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Intern Attendance',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // ── Summary Stats ───────────────────────────
                              if (_summary != null) _buildSummaryRow(),
                              const SizedBox(height: 16),
                              // ── Filters ─────────────────────────────────
                              _buildFilters(),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      // ── Records List ─────────────────────────────────────
                      if (_records.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No attendance records found.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey.shade500),
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
                              (context, index) =>
                                  _AttendanceAdminCard(
                                record: _records[index],
                                onOpenMap: _openGoogleMaps,
                              ),
                              childCount: _records.length,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final s = _summary!;
    return Row(
      children: [
        _StatCard(label: 'Total', value: '${s.totalRecords}',
            icon: Icons.list_alt_rounded, color: _primaryBlue),
        const SizedBox(width: 8),
        _StatCard(label: 'Interns', value: '${s.uniqueInterns}',
            icon: Icons.people_rounded, color: Colors.purple),
        const SizedBox(width: 8),
        _StatCard(label: 'Done', value: '${s.completed}',
            icon: Icons.check_circle_rounded, color: Colors.green),
        const SizedBox(width: 8),
        _StatCard(label: 'Active', value: '${s.inProgress}',
            icon: Icons.radio_button_checked_rounded, color: Colors.orange),
      ],
    );
  }

  Widget _buildFilters() {
    final hasFilter = _selectedScheduleId != null || _selectedDate != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 16, color: _primaryBlue),
              const SizedBox(width: 6),
              const Text('Filters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              if (hasFilter)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text('Clear all',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Schedule filter
          if (_scheduleOptions.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selectedScheduleId,
              decoration: InputDecoration(
                labelText: 'Schedule Slot',
                prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              hint: const Text('All schedules', style: TextStyle(fontSize: 13)),
              items: [
                const DropdownMenuItem(value: null, child: Text('All schedules')),
                ..._scheduleOptions.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.label,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (val) {
                setState(() => _selectedScheduleId = val);
                _loadAttendance();
              },
            ),
            const SizedBox(height: 10),
          ],

          // Date filter
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.date_range_rounded, size: 18,
                    color: _selectedDate != null ? _primaryBlue : Colors.grey),
                const SizedBox(width: 10),
                Text(
                  _selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                      : 'Filter by date',
                  style: TextStyle(
                      fontSize: 13,
                      color: _selectedDate != null ? Colors.black87 : Colors.grey),
                ),
                const Spacer(),
                if (_selectedDate != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = null);
                      _loadAttendance();
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.grey),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ── Admin Attendance Card ────────────────────────────────────────────────────

class _AttendanceAdminCard extends StatelessWidget {
  final AdminAttendanceRecord record;
  final void Function(String coordinates) onOpenMap;

  const _AttendanceAdminCard({
    required this.record,
    required this.onOpenMap,
  });

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');

    final clockIn = record.clockInTime != null
        ? timeFormat.format(record.clockInTime!.toLocal())
        : '-';
    final clockOut = record.clockOutTime != null
        ? timeFormat.format(record.clockOutTime!.toLocal())
        : 'Not yet';
    final clockInDate = record.clockInTime != null
        ? dateFormat.format(record.clockInTime!.toLocal())
        : '-';

    final statusColor = record.hasClockOut ? Colors.green : Colors.orange;
    final statusText = record.hasClockOut ? 'Completed' : 'In Progress';
    final statusIcon = record.hasClockOut
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: name + status ──────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryBlue.withOpacity(0.1),
                child: Text(
                  record.internName.isNotEmpty
                      ? record.internName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: _primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.internName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(record.institution,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Schedule info ──────────────────────────────────────────────
          Row(children: [
            Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '$clockInDate · ${record.scheduleDescription}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),

          const Divider(height: 16),

          // ── Clock in / out times ───────────────────────────────────────
          Row(children: [
            Expanded(child: _TimeChip(
                icon: Icons.login_rounded,
                label: 'Clock In',
                time: clockIn,
                color: _primaryBlue)),
            const SizedBox(width: 10),
            Expanded(child: _TimeChip(
                icon: Icons.logout_rounded,
                label: 'Clock Out',
                time: clockOut,
                color: record.hasClockOut ? Colors.green : Colors.grey)),
          ]),

          // ── Duration ──────────────────────────────────────────────────
          if (record.hasClockOut) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.timer_rounded, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text('Duration: ${record.shiftDuration}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ],

          // ── Location ──────────────────────────────────────────────────
          if (record.clockInLocation != null &&
              record.clockInLocation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: record.gpsCoordinates != null
                  ? () => onOpenMap(record.gpsCoordinates!)
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 15, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.clockInLocation!
                                .split('\n')
                                .first, // show place name only
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (record.gpsCoordinates != null) ...[
                            const SizedBox(height: 2),
                            const Text('Tap to view on Google Maps',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    if (record.gpsCoordinates != null)
                      const Icon(Icons.open_in_new_rounded,
                          size: 14, color: Colors.blue),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 3),
          Text(time,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}