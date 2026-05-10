import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

  @override
  _ManageAttendanceScreenState createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  List<Map<String, dynamic>> _allRecords = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  bool isLoading = true;

  // ── Palette ──────────────────────────────────────────────────────────────────
  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    // Default: show today
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate   = DateTime(now.year, now.month, now.day);
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => isLoading = true);
    try {
      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);
      final staffsProvider = Provider.of<Staffs>(context, listen: false);

      await staffsProvider.fetchStaff();
      final records = await attendanceProvider.getAllAttendances();

      setState(() {
        _allRecords = records;
        isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendances: $error')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  // ── Filter logic ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _filteredRecords(List<Staff> staffList) {
    return _allRecords.where((record) {
      // Date range filter
      if (record['clock_in_time'] != null) {
        final clockIn = DateTime.tryParse(record['clock_in_time'].toString());
        if (clockIn != null) {
          if (_fromDate != null) {
            final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
            if (clockIn.isBefore(from)) return false;
          }
          if (_toDate != null) {
            final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
            if (clockIn.isAfter(to)) return false;
          }
        }
      } else {
        // If no clock_in_time and date filter is active, exclude
        if (_fromDate != null || _toDate != null) return false;
      }

      // Search by staff name
      if (_searchQuery.isNotEmpty) {
        final name = _getStaffName(record['staff_id'], staffList).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList();
  }

  String _getStaffName(int staffId, List<Staff> staffList) {
    final Staff? staff = staffList.cast<Staff?>().firstWhere(
          (s) => s?.staffId == staffId,
          orElse: () => null,
        );
    return staff != null
        ? '${staff.firstname} ${staff.lastname}'
        : 'Staff ID: $staffId';
  }

  // ── Date pickers ──────────────────────────────────────────────────────────────
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryBlue,
            onPrimary: Colors.white,
            onSurface: const Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Ensure toDate is not before fromDate
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryBlue,
            onPrimary: Colors.white,
            onSurface: const Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _getStatusText(int? status) {
    switch (status) {
      case 1:  return 'Not Clocked In';
      case 2:  return 'Clocked In';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:  return Colors.redAccent;
      case 2:  return Colors.teal;
      default: return Colors.grey.shade600;
    }
  }

  // ── Proof dialog ──────────────────────────────────────────────────────────────
  void _showProofDialog(String fullUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
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

  // ── Edit attendance ───────────────────────────────────────────────────────────
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Not Clocked In')),
              DropdownMenuItem(value: 2, child: Text('Clocked In')),
            ],
            onChanged: (value) => status = value ?? 1,
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
                  final attendanceProvider =
                      Provider.of<Attendances>(context, listen: false);
                  final success = await attendanceProvider.updateAttendance(
                    record['attendance_id'],
                    {'attendance_status': status},
                  );
                  if (success) {
                    await _loadAttendances();
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
                          content:
                              Text('Error updating attendance: $error')),
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

  // ── Delete attendance ─────────────────────────────────────────────────────────
  Future<void> _deleteAttendance(int id) async {
    try {
      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);
      final success = await attendanceProvider.deleteAttendance(id);
      if (success) {
        await _loadAttendances();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Attendance deleted successfully')),
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

  // ── Card ──────────────────────────────────────────────────────────────────────
  Widget _buildAttendanceCard(
      Map<String, dynamic> record, List<Staff> staffList) {
    final String? imageUrl = record['clock_in_image_url'];
    final int? status = record['attendance_status'];
    final int staffId = record['staff_id'];
    final String staffName = _getStaffName(staffId, staffList);
    final Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: Icon(Icons.fingerprint_rounded,
                  size: 24, color: statusColor),
            ),
            const SizedBox(width: 16),

            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.login_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'In: ${record['clock_in_time'] ?? '—'}',
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
                        'Out: ${record['clock_out_time'] ?? '—'}',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (record['clock_in_location'] != null) ...[
                    const SizedBox(height: 2),
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
                  const SizedBox(height: 8),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Right actions
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
                        await _editAttendance(context, record);
                      } else if (value == 'delete') {
                        await _deleteAttendance(record['attendance_id']);
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
                              style: TextStyle(fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w500)),
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
    final bool isFiltered = _fromDate != null || _toDate != null;

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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAttendances,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<Staffs>(
        builder: (ctx, staffsData, child) {
          final staffList = staffsData.staffList;
          final filtered = _filteredRecords(staffList);

          // Summary counts
          final totalClockIn = filtered
              .where((r) => r['attendance_status'] == 2)
              .length;
          final totalNotClockedIn = filtered
              .where((r) => r['attendance_status'] == 1)
              .length;

          return Column(
            children: [
              // ── Filter Panel ────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range row
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        const Text('Filter by Date',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF1E293B))),
                        const Spacer(),
                        if (isFiltered)
                          GestureDetector(
                            onTap: _clearDateFilter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.close_rounded,
                                      size: 14,
                                      color: Colors.redAccent),
                                  SizedBox(width: 4),
                                  Text('Clear',
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // From date
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickFromDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _fromDate != null
                                    ? primaryBlue.withOpacity(0.07)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _fromDate != null
                                      ? primaryBlue.withOpacity(0.4)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 14,
                                      color: _fromDate != null
                                          ? primaryBlue
                                          : Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _fromDate != null
                                          ? dateFormat.format(_fromDate!)
                                          : 'From date',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _fromDate != null
                                              ? primaryBlue
                                              : Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('→',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold)),
                        ),
                        // To date
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickToDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _toDate != null
                                    ? primaryBlue.withOpacity(0.07)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _toDate != null
                                      ? primaryBlue.withOpacity(0.4)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 14,
                                      color: _toDate != null
                                          ? primaryBlue
                                          : Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _toDate != null
                                          ? dateFormat.format(_toDate!)
                                          : 'To date',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _toDate != null
                                              ? primaryBlue
                                              : Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick date chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickChip('Today', () {
                            final now = DateTime.now();
                            setState(() {
                              _fromDate = DateTime(now.year, now.month, now.day);
                              _toDate   = DateTime(now.year, now.month, now.day);
                            });
                          }),
                          _buildQuickChip('This Week', () {
                            final now = DateTime.now();
                            final weekStart =
                                now.subtract(Duration(days: now.weekday - 1));
                            setState(() {
                              _fromDate = DateTime(
                                  weekStart.year, weekStart.month, weekStart.day);
                              _toDate = DateTime(now.year, now.month, now.day);
                            });
                          }),
                          _buildQuickChip('This Month', () {
                            final now = DateTime.now();
                            setState(() {
                              _fromDate = DateTime(now.year, now.month, 1);
                              _toDate   = DateTime(now.year, now.month, now.day);
                            });
                          }),
                          _buildQuickChip('All', () {
                            setState(() {
                              _fromDate = null;
                              _toDate   = null;
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search by staff name
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by staff name...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: primaryBlue, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ],
                ),
              ),

              // ── Summary row ─────────────────────────────────────────────────
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _buildSummaryChip(
                        icon: Icons.people_rounded,
                        label: '${filtered.length} Records',
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryChip(
                        icon: Icons.check_circle_rounded,
                        label: '$totalClockIn Clocked In',
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryChip(
                        icon: Icons.cancel_rounded,
                        label: '$totalNotClockedIn Absent',
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ── List ────────────────────────────────────────────────────────
              Expanded(
                child: isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(color: primaryBlue))
                    : filtered.isNotEmpty
                        ? RefreshIndicator(
                            color: primaryBlue,
                            onRefresh: _loadAttendances,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.only(bottom: 24),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) =>
                                  _buildAttendanceCard(
                                      filtered[i], staffList),
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
                                  'No attendance records found',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                if (isFiltered || _searchQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TextButton(
                                      onPressed: () => setState(() {
                                        _fromDate = null;
                                        _toDate = null;
                                        _searchQuery = '';
                                      }),
                                      child: const Text('Clear all filters'),
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

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryBlue)),
      ),
    );
  }

  Widget _buildSummaryChip(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}