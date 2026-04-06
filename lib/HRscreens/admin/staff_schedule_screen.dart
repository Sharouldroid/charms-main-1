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
    Key? key,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.staffType,
  }) : super(key: key);

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

  Future<void> _handleDelete(
      Schedule schedule, BuildContext dialogContext) async {
    try {
      await Provider.of<Schedules>(context, listen: false)
          .deleteSchedule(schedule.schedId);

      Navigator.of(dialogContext).pop();

      if (mounted) {
        await _loadSchedules(); // Refresh data first

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      Navigator.of(dialogContext).pop();
      if (mounted) {
        await _loadSchedules(); // Ensure list is updated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(
      Schedule schedule, BuildContext dialogContext) async {
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
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Staff Schedule',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userDetails == null
              ? const Center(child: Text('User details not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StaffListScreen(),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _userDetails!['fullName'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _userDetails!['staffId'] ??
                                            'Unknown ID',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "This week's schedule:",
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _schedules.isEmpty
                              ? const Center(
                                  child: Text('No schedules available'))
                              : ListView.builder(
                                  itemCount: _schedules.length,
                                  itemBuilder: (context, index) {
                                    final schedule = _schedules[index];
                                    String branch = '';
                                    final workLocation = schedule.workLocation;
                                    switch (workLocation) {
                                      case 1:
                                        branch = 'Chagar Hutang';
                                        break;
                                      case 2:
                                        branch = 'Turtle Lab';
                                        break;
                                      case 3:
                                        branch = 'UMT';
                                        break;
                                      default:
                                        branch = 'N/A';
                                        break;
                                    }

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        tileColor: Colors.grey[200],
                                        leading:
                                            const Icon(Icons.calendar_month),
                                        title: Text(
                                            'Date: ${_formatDate(schedule.workDate)}'),
                                        subtitle: Text(
                                          'Location: ${branch}',
                                        ),
                                        trailing:
                                            const Icon(Icons.arrow_forward),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Schedule Details'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Date: ${_formatDate(schedule.workDate)}',
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Location: ${branch}',
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Work: ${schedule.workStartTime} - ${schedule.workEndTime}',
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Break: ${schedule.breakStartTime ?? 'N/A'} - ${schedule.breakEndTime ?? 'N/A'}',
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      _handleDelete(
                                                          schedule, context),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => _handleEdit(
                                                      schedule, context),
                                                  child: const Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                        color: Colors.blue),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Dismiss'),
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
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
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
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
