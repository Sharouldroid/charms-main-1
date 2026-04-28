import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

  @override
  _ManageAttendanceScreenState createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  List<Map<String, dynamic>> attendanceRecords = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
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
        attendanceRecords = records;
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

  String _getStaffName(int staffId, List<Staff> staffList) {
    final Staff? staff = staffList.cast<Staff?>().firstWhere(
          (s) => s?.staffId == staffId,
          orElse: () => null,
        );
    return staff != null
        ? '${staff.firstname} ${staff.lastname}'
        : 'Staff ID: $staffId';
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record, List<Staff> staffList) {
    final String? imageUrl = record['clock_in_image_url'];
    final int? status = record['attendance_status'];
    final int staffId = record['staff_id'];
    final String staffName = _getStaffName(staffId, staffList);

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
            // Left Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 24,
                color: _getStatusColor(status),
              ),
            ),
            const SizedBox(width: 16),

            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffName, // Staff Name instead of Staff ID
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.login_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'In: ${record['clock_in_time'] ?? 'Not recorded'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Out: ${record['clock_out_time'] ?? 'Not recorded'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Modern Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
                          size: 20, color: Colors.blue),
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
                        color: Colors.grey.shade700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _editAttendance(context, record);
                      } else if (value == 'delete') {
                        await _deleteAttendance(record['attendance_id']);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Edit',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
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
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
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
          return Column(
            children: [
              // Date Picker Card
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: primaryBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_month_rounded, size: 20),
                      label: const Text('Change',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Attendance List
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryBlue))
                    : attendanceRecords.isNotEmpty
                        ? ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: attendanceRecords.length,
                            itemBuilder: (ctx, i) => _buildAttendanceCard(
                                attendanceRecords[i], staffList),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No records for this date',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
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

  String _getStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Not Clocked In';
      case 2:
        return 'Clocked In';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.teal;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _loadAttendances();
    }
  }

  Future<void> _deleteAttendance(int id) async {
    try {
      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);
      final success = await attendanceProvider.deleteAttendance(id);
      if (success) {
        await _loadAttendances();
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

  Future<void> _editAttendance(
      BuildContext context, Map<String, dynamic> record) async {
    final formKey = GlobalKey<FormState>();
    int status = record['attendance_status'] ?? 1;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Attendance',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Not Clocked In')),
                    DropdownMenuItem(value: 2, child: Text('Clocked In')),
                  ],
                  onChanged: (value) => status = value ?? 1,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
                              content: Text('Attendance updated successfully')),
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
              child:
                  const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}