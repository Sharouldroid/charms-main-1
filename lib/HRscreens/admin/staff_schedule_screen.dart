import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRscreens/admin/edit_schedule_screen.dart';
import 'package:charms/HRscreens/admin/schedule_form_screen.dart';
import 'package:charms/HRscreens/admin/staff_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StaffScheduleScreen extends StatefulWidget {
  final int staffId;
  final String firstName;
  final String lastName;
  final int staffType;

  const StaffScheduleScreen({
    super.key,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.staffType,
  });

  @override
  _StaffScheduleScreenState createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen> {
  late int _staffId;
  late String _firstName;
  late String _lastName;
  late int _staffType;
  Map<String, dynamic>? _userDetails;
  List<Schedule> _schedules = [];
  bool _isLoading = true;
  final bool _isScheduleEditingEnabled = false; // Kept your original logic flag

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _staffId = widget.staffId;
    _firstName = widget.firstName;
    _lastName = widget.lastName;
    _staffType = widget.staffType;
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    _userDetails = {
      'fullName': '$_firstName $_lastName',
      'staffId': 'Staff ID: $_staffId',
    };

    try {
      final schedulesProvider = Provider.of<Schedules>(context, listen: false);
      final schedules =
          await schedulesProvider.fetchSchedulesByStaffId(_staffId);
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading schedules: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDelete(Schedule schedule, BuildContext dialogContext) async {
    try {
      await Provider.of<Schedules>(context, listen: false).deleteSchedule(schedule.schedId);

      Navigator.of(dialogContext).pop();

      if (mounted) {
        await _loadSchedules(); // Refresh data first

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.teal, // Modernized success color
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      Navigator.of(dialogContext).pop();
      if (mounted) {
        await _loadSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete schedule'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> handleEdit(Schedule schedule, BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop(); // Close current dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScheduleScreen(
          schedule: schedule,
          staffType: _staffType,
        ),
      ),
    ).then((result) async {
      if (result == true) {
        await _loadSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule updated successfully'),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Modern Helper for Schedule Details Row
  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'STAFF SCHEDULE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _userDetails == null
              ? const Center(child: Text('User details not found'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // User Details Header Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StaffListScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_rounded, size: 28, color: primaryBlue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userDetails!['fullName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userDetails!['staffId'] ?? 'Unknown ID',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Assigned Schedules",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Modernized Schedule List (Replaced SizedBox/SingleChildScrollView anti-pattern with Expanded)
                    Expanded(
                      child: _schedules.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No schedules assigned',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                              itemCount: _schedules.length,
                              itemBuilder: (context, index) {
                                final schedule = _schedules[index];
                                String branch = '';
                                Color branchColor = Colors.blue;
                                
                                switch (schedule.workLocation) {
                                  case 1:
                                    branch = 'Chagar Hutang';
                                    branchColor = Colors.teal;
                                    break;
                                  case 2:
                                    branch = 'Turtle Lab';
                                    branchColor = Colors.orange;
                                    break;
                                  case 3:
                                    branch = 'UMT';
                                    branchColor = Colors.purple;
                                    break;
                                  default:
                                    branch = 'N/A';
                                    branchColor = Colors.grey;
                                    break;
                                }

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
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.calendar_month_rounded, color: Colors.blue),
                                    ),
                                    title: Text(
                                      _formatDate(schedule.workDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: branchColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              branch,
                                              style: TextStyle(color: branchColor, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade600),
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: const Text('Schedule Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 8),
                                              _detailRow(Icons.calendar_today_rounded, 'Date', _formatDate(schedule.workDate)),
                                              _detailRow(Icons.location_on_rounded, 'Location', branch, valueColor: branchColor),
                                              _detailRow(Icons.access_time_rounded, 'Work', '${schedule.workStartTime} - ${schedule.workEndTime}'),
                                              _detailRow(Icons.coffee_rounded, 'Break', '${schedule.breakStartTime ?? 'N/A'} - ${schedule.breakEndTime ?? 'N/A'}'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
                                            ),
                                            if (_isScheduleEditingEnabled)
                                              TextButton(
                                                onPressed: () => handleEdit(schedule, context),
                                                child: const Text('Edit', style: TextStyle(color: Colors.blue)),
                                              ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              onPressed: () => _handleDelete(schedule, context),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Assign Shift", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleFormScreen(
                staffId: _staffId,
                staffType: _staffType,
              ),
            ),
          );
          if (result == true) {
            _loadSchedules();
          }
        },
      ),
    );
  }
}