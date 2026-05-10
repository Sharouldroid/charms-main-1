import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/schedule.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

  @override
  _ManageAttendanceScreenState createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  // ── Raw data ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _allRecords   = [];
  List<Schedule>             _allSchedules = [];

  // ── Filter state ──────────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery  = '';
  String _activeChip   = 'Today';
  String _statusFilter = 'All'; // All | Present | Absent | No Clock-In

  bool isLoading = true;

  // ── Palette ───────────────────────────────────────────────────────────────────
  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate   = DateTime(now.year, now.month, now.day);
    _loadData();
  }

  // ── Load both attendance + schedules ──────────────────────────────────────────
  // ── Fix _loadData: load attendance INDEPENDENTLY from schedules ───────────────
Future<void> _loadData() async {
  setState(() => isLoading = true);
  try {
    final attProvider   = Provider.of<Attendances>(context, listen: false);
    final staffProvider = Provider.of<Staffs>(context, listen: false);
    final schedProvider = Provider.of<Schedules>(context, listen: false);

    // ✅ Load staff + attendance together (must succeed)
    await staffProvider.fetchStaff();
    final records = await attProvider.getAllAttendances();

    // ✅ Load schedules SEPARATELY — if it fails, still show attendance records
    List<Schedule> schedules = [];
    try {
      await schedProvider.fetchSchedules();
      schedules = schedProvider.schedules;
    } catch (e) {
      debugPrint('Schedules failed to load (non-critical): $e');
      // Don't rethrow — attendance records still show without schedules
    }

    setState(() {
      _allRecords   = records;
      _allSchedules = schedules;
      isLoading     = false;
    });
  } catch (error) {
    debugPrint('Error loading attendance data: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $error')),
      );
    }
    setState(() => isLoading = false);
  }
}

// ── Fix _markAbsent: use createAbsentRecord instead of recordAttendance ────────
Future<void> _markAbsent(Map<String, dynamic> item, List<Staff> staffList) async {
  final staffName = _getStaffName(item['staff_id'], staffList);
  final date      = item['_display_date'] as DateTime?;
  final dateStr   = date != null ? DateFormat('dd MMM yyyy').format(date) : '—';
  final schedule  = item['_schedule'] as Schedule?;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 8),
          Text('Mark as Absent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Staff: $staffName',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Date: $dateStr',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will create an official Absent record. Staff will see this in their history.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.cancel_rounded, size: 16),
          label: const Text('Mark Absent'),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final attProvider = Provider.of<Attendances>(context, listen: false);

    // ✅ Use the new createAbsentRecord method — sends status=1, no clock_in_time
    final success = await attProvider.createAbsentRecord(
      staffId:    item['staff_id'],
      scheduleId: schedule?.schedId ?? item['schedule_id'],
      workDate:   date != null
          ? DateFormat('yyyy-MM-dd').format(date)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    if (!mounted) return;

    if (success) {
      await _loadData(); // refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$staffName marked as absent for $dateStr'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark absent — check API')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  // ── Build unified list: attendance records + orphan schedules (no clock-in) ───
  List<Map<String, dynamic>> _buildMergedList(List<Staff> staffList) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> result = [];

    // 1. All existing attendance records
    for (final record in _allRecords) {
      final rawDate = record['clock_in_time'] ?? record['created_at'];
      DateTime? date = rawDate != null ? DateTime.tryParse(rawDate.toString()) : null;

      // Date filter
      if (!_passesDateFilter(date)) continue;

      // Search filter
      if (!_passesSearchFilter(record['staff_id'], staffList)) continue;

      // Status filter
      final status = record['attendance_status'];
      if (!_passesStatusFilter(status)) continue;

      result.add({...record, '_type': 'record', '_display_date': date});
    }

    // 2. Schedules with NO matching attendance (past dates only)
    for (final schedule in _allSchedules) {
      final workDate = schedule.workDate;
      final isPast   = workDate.isBefore(DateTime(now.year, now.month, now.day));
      if (!isPast) continue; // skip today/future

      // Check if an attendance record already exists for this schedule
      final hasRecord = _allRecords.any(
        (r) => r['schedule_id']?.toString() == schedule.schedId.toString(),
      );
      if (hasRecord) continue; // already shown above

      // Date filter
      if (!_passesDateFilter(workDate)) continue;

      // Search filter (by staff_id from schedule)
      if (_searchQuery.isNotEmpty) {
        final name = _getStaffName(schedule.staffId, staffList).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) continue;
      }

      // Status filter — these are always "No Clock-In"
      if (_statusFilter != 'All' && _statusFilter != 'No Clock-In') continue;

      result.add({
        'attendance_id':     null,
        'staff_id':          schedule.staffId,
        'schedule_id':       schedule.schedId,
        'attendance_status': -1, // -1 = No Clock-In (derived, not in DB)
        'clock_in_time':     null,
        'clock_out_time':    null,
        'clock_in_location': null,
        '_type':             'no_clockin',
        '_display_date':     workDate,
        '_schedule':         schedule,
      });
    }

    // Sort newest first
    result.sort((a, b) {
      final da = a['_display_date'] as DateTime? ?? DateTime(0);
      final db = b['_display_date'] as DateTime? ?? DateTime(0);
      return db.compareTo(da);
    });

    return result;
  }

  // ── Filter helpers ────────────────────────────────────────────────────────────
  bool _passesDateFilter(DateTime? date) {
    if (date == null) return _fromDate == null && _toDate == null;
    if (_fromDate != null) {
      final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      if (date.isBefore(from)) return false;
    }
    if (_toDate != null) {
      final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
      if (date.isAfter(to)) return false;
    }
    return true;
  }

  bool _passesSearchFilter(dynamic staffId, List<Staff> staffList) {
    if (_searchQuery.isEmpty) return true;
    final id = int.tryParse(staffId?.toString() ?? '') ?? 0;
    return _getStaffName(id, staffList)
        .toLowerCase()
        .contains(_searchQuery.toLowerCase());
  }

  bool _passesStatusFilter(int? status) {
    switch (_statusFilter) {
      case 'Present':    return status == 2;
      case 'Absent':     return status == 1;
      case 'No Clock-In': return status == -1;
      default:           return true;
    }
  }

  String _getStaffName(int staffId, List<Staff> staffList) {
    final staff = staffList.cast<Staff?>().firstWhere(
          (s) => s?.staffId == staffId,
          orElse: () => null,
        );
    return staff != null
        ? '${staff.firstname} ${staff.lastname}'
        : 'Staff ID: $staffId';
  }

  // ── Quick chips ───────────────────────────────────────────────────────────────
  void _applyChip(String chip) {
    final now = DateTime.now();
    setState(() {
      _activeChip = chip;
      switch (chip) {
        case 'Today':
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate   = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          final start = now.subtract(Duration(days: now.weekday - 1));
          _fromDate = DateTime(start.year, start.month, start.day);
          _toDate   = DateTime(now.year, now.month, now.day);
          break;
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate   = DateTime(now.year, now.month, now.day);
          break;
        case 'All':
          _fromDate = null;
          _toDate   = null;
          break;
      }
    });
  }

  Future<void> _pickFromDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (p != null) {
      setState(() {
        _fromDate   = p;
        _activeChip = 'Custom';
        if (_toDate != null && _toDate!.isBefore(p)) _toDate = p;
      });
    }
  }

  Future<void> _pickToDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() { _toDate = p; _activeChip = 'Custom'; });
  }

  // ── Status helpers ────────────────────────────────────────────────────────────
  String _getStatusText(int? status) {
    switch (status) {
      case 2:  return 'Present';
      case 1:  return 'Absent';
      case -1: return 'No Clock-In';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 2:  return Colors.teal;
      case 1:  return Colors.redAccent;
      case -1: return Colors.orange;
      default: return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(int? status) {
    switch (status) {
      case 2:  return Icons.check_circle_rounded;
      case 1:  return Icons.cancel_rounded;
      case -1: return Icons.warning_amber_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  // ── Mark Absent dialog ────────────────────────────────────────────────────────
  // Future<void> _markAbsent(Map<String, dynamic> item, List<Staff> staffList) async {
  //   final staffName = _getStaffName(item['staff_id'], staffList);
  //   final date      = item['_display_date'] as DateTime?;
  //   final dateStr   = date != null ? DateFormat('dd MMM yyyy').format(date) : '—';
  //   final schedule  = item['_schedule'] as Schedule?;

  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: const Row(
  //         children: [
  //           Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
  //           SizedBox(width: 8),
  //           Text('Mark as Absent',
  //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Staff: $staffName',
  //               style: const TextStyle(fontWeight: FontWeight.w600)),
  //           const SizedBox(height: 4),
  //           Text('Date: $dateStr',
  //               style: TextStyle(color: Colors.grey.shade600)),
  //           const SizedBox(height: 12),
  //           Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: Colors.orange.withOpacity(0.07),
  //               borderRadius: BorderRadius.circular(10),
  //               border: Border.all(color: Colors.orange.withOpacity(0.2)),
  //             ),
  //             child: const Row(
  //               children: [
  //                 Icon(Icons.info_outline_rounded,
  //                     size: 15, color: Colors.orange),
  //                 SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     'This will create an official Absent record. Staff will see this in their history.',
  //                     style: TextStyle(fontSize: 12, color: Colors.orange),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
  //         ),
  //         ElevatedButton.icon(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.redAccent,
  //             foregroundColor: Colors.white,
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10)),
  //           ),
  //           icon: const Icon(Icons.cancel_rounded, size: 16),
  //           label: const Text('Mark Absent'),
  //           onPressed: () => Navigator.pop(ctx, true),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm != true) return;

  //   try {
  //     final attProvider = Provider.of<Attendances>(context, listen: false);
  //     // Re-use existing POST /attendance/create with status=1
  //     await attProvider.recordAttendance(
  //       staffId:    item['staff_id'],
  //       scheduleId: schedule?.schedId ?? item['schedule_id'],
  //       clockInTime: DateFormat("yyyy-MM-dd HH:mm:ss")
  //           .format(date ?? DateTime.now()),
  //       // No actual clock_in_time — we'll send the work date start time
  //     );

  //     // Then immediately update the status to 1 (Absent) via the returned record
  //     // OR: we call a direct absent create — let's use the provider properly
  //     await _loadData();

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('$staffName marked as absent for $dateStr'),
  //         backgroundColor: Colors.redAccent,
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to mark absent: $e')),
  //     );
  //   }
  // }

  // ── Edit (status change for existing records) ─────────────────────────────────
  Future<void> _editAttendance(
      BuildContext context, Map<String, dynamic> record) async {
    final formKey = GlobalKey<FormState>();
    int status = record['attendance_status'] ?? 1;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Attendance',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: DropdownButtonFormField<int>(
            initialValue: status,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Absent')),
              DropdownMenuItem(value: 2, child: Text('Present')),
            ],
            onChanged: (v) => status = v ?? 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                try {
                  final success = await Provider.of<Attendances>(
                          context,
                          listen: false)
                      .updateAttendance(
                    record['attendance_id'],
                    {'attendance_status': status},
                  );
                  if (success) {
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Attendance updated successfully')),
                      );
                    }
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Error updating attendance: $error')),
                    );
                  }
                }
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttendance(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Record',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final success = await Provider.of<Attendances>(context, listen: false)
          .deleteAttendance(id);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance deleted successfully')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting attendance: $error')),
        );
      }
    }
  }

  // ── Proof dialog ──────────────────────────────────────────────────────────────
  void _showProofDialog(String fullUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              elevation: 0,
              title: const Text('Proof Image',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              backgroundColor: primaryBlue,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.broken_image_rounded,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Failed to load image',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Attendance card ───────────────────────────────────────────────────────────
  Widget _buildAttendanceCard(
      Map<String, dynamic> item, List<Staff> staffList) {
    final int? status       = item['attendance_status'];
    final Color statusColor = _getStatusColor(status);
    final String staffName  = _getStaffName(item['staff_id'], staffList);
    final String? imageUrl  = item['clock_in_image_url'];
    final DateTime? displayDate = item['_display_date'] as DateTime?;
    final Schedule? schedule    = item['_schedule'] as Schedule?;
    final bool isNoClockIn      = status == -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNoClockIn
              ? Colors.orange.withOpacity(0.4)
              : status == 1
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.transparent,
          width: isNoClockIn || status == 1 ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoClockIn
                    ? Icons.warning_amber_rounded
                    : Icons.fingerprint_rounded,
                size: 24,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),

            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Staff name + status pill
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          staffName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155)),
                        ),
                      ),
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
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date
                  if (displayDate != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy (EEE)').format(displayDate),
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                  // Schedule info
                  if (schedule != null &&
                      schedule.workStartTime != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Shift: ${schedule.workStartTime} → ${schedule.workEndTime ?? '—'}',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],

                  // Clock in/out times (present only)
                  if (!isNoClockIn) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.login_rounded,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'In: ${item['clock_in_time'] ?? '—'}',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Out: ${item['clock_out_time'] ?? '—'}',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],

                  // Location
                  if (item['clock_in_location'] != null) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${item['clock_in_location']}',
                        );
                        launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('View Location',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              )),
                        ],
                      ),
                    ),
                  ],

                  // No Clock-In action button
                  if (isNoClockIn) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cancel_rounded, size: 15),
                        label: const Text('Mark as Absent',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        onPressed: () => _markAbsent(item, staffList),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right actions (existing records only)
            if (!isNoClockIn)
              Column(
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.visibility_rounded,
                            size: 18, color: Colors.blue),
                        tooltip: 'View Proof',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          final fullUrl = imageUrl.startsWith('http')
                              ? imageUrl
                              : 'https://devcms.com.my/charmsAPI/public/storage/$imageUrl';
                          _showProofDialog(fullUrl);
                        },
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded,
                          color: Colors.grey.shade700, size: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _editAttendance(context, item);
                        } else if (value == 'delete') {
                          await _deleteAttendance(item['attendance_id']);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('Edit',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isFiltered = _fromDate != null || _toDate != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MANAGE ATTENDANCE',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<Staffs>(
        builder: (ctx, staffsData, child) {
          final staffList = staffsData.staffList;
          final merged    = _buildMergedList(staffList);

          final totalPresent   = merged.where((r) => r['attendance_status'] == 2).length;
          final totalAbsent    = merged.where((r) => r['attendance_status'] == 1).length;
          final totalNoClockIn = merged.where((r) => r['attendance_status'] == -1).length;

          return Column(
            children: [
              // ── Filter panel ─────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.filter_list_rounded,
                            size: 16, color: primaryBlue),
                        const SizedBox(width: 6),
                        Text('Filter & Search',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: primaryBlue)),
                        const Spacer(),
                        if (isFiltered || _searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _applyChip('All');
                              setState(() => _searchQuery = '');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.close_rounded,
                                      size: 13, color: Colors.redAccent),
                                  SizedBox(width: 4),
                                  Text('Clear all',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Today', 'This Week', 'This Month', 'All']
                            .map((chip) {
                          final active = _activeChip == chip;
                          return GestureDetector(
                            onTap: () => _applyChip(chip),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: active
                                    ? primaryBlue
                                    : primaryBlue.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: active
                                        ? primaryBlue
                                        : primaryBlue.withOpacity(0.2)),
                              ),
                              child: Text(chip,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? Colors.white
                                          : primaryBlue)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // From → To date pickers
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickFromDate,
                            child: _datePill(
                                label: _fromDate != null
                                    ? dateFormat.format(_fromDate!)
                                    : 'From date',
                                active: _fromDate != null),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('→',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickToDate,
                            child: _datePill(
                                label: _toDate != null
                                    ? dateFormat.format(_toDate!)
                                    : 'To date',
                                active: _toDate != null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Status filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All',
                          'Present',
                          'Absent',
                          'No Clock-In',
                        ].map((s) {
                          final active = _statusFilter == s;
                          Color chipColor;
                          switch (s) {
                            case 'Present':    chipColor = Colors.teal; break;
                            case 'Absent':     chipColor = Colors.redAccent; break;
                            case 'No Clock-In': chipColor = Colors.orange; break;
                            default:           chipColor = primaryBlue;
                          }
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _statusFilter = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? chipColor
                                    : chipColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: active
                                        ? chipColor
                                        : chipColor.withOpacity(0.3)),
                              ),
                              child: Text(s,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? Colors.white
                                          : chipColor)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by staff name...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: primaryBlue, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: primaryBlue, width: 1.5)),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ],
                ),
              ),

              // ── Summary row ──────────────────────────────────────────────────
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _summaryChip(Icons.people_rounded,
                            '${merged.length} Total', primaryBlue),
                        const SizedBox(width: 8),
                        _summaryChip(Icons.check_circle_rounded,
                            '$totalPresent Present', Colors.teal),
                        const SizedBox(width: 8),
                        _summaryChip(Icons.cancel_rounded,
                            '$totalAbsent Absent', Colors.redAccent),
                        const SizedBox(width: 8),
                        _summaryChip(Icons.warning_amber_rounded,
                            '$totalNoClockIn No Clock-In', Colors.orange),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ── List ─────────────────────────────────────────────────────────
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: primaryBlue))
                    : merged.isNotEmpty
                        ? RefreshIndicator(
                            color: primaryBlue,
                            onRefresh: _loadData,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.only(bottom: 24),
                              itemCount: merged.length,
                              itemBuilder: (ctx, i) =>
                                  _buildAttendanceCard(
                                      merged[i], staffList),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No records found',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                if (isFiltered ||
                                    _searchQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8),
                                    child: TextButton(
                                      onPressed: () => setState(() {
                                        _applyChip('All');
                                        _searchQuery = '';
                                      }),
                                      child: const Text('Clear filters'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _datePill({required String label, required bool active}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? primaryBlue.withOpacity(0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active
                  ? primaryBlue.withOpacity(0.4)
                  : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 13,
                color: active ? primaryBlue : Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? primaryBlue : Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _summaryChip(IconData icon, String label, Color color) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );
}