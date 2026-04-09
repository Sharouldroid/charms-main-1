
import 'package:charms/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/attendances.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({Key? key}) : super(key: key);

  @override
  _ManageAttendanceScreenState createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  List<Map<String, dynamic>> attendanceRecords = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

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
      final records = await attendanceProvider.getAllAttendances();
      setState(() {
        attendanceRecords = records;
        isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendances: $error')),
      );
      setState(() => isLoading = false);
    }
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
  // Print detailed info about the record for debugging
  print('Record ID: ${record['attendance_id']}');
  if (record['clock_in_image'] != null) {
    if (record['clock_in_image'] is Map && record['clock_in_image']['data'] is List) {
      final data = record['clock_in_image']['data'];
      print('Image data length: ${data.length}');
      if (data.length > 0) {
        print('First few bytes: ${data.take(10).toList()}');
      }
    }
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    elevation: 4,
    child: Column(
      children: [
        ListTile(
          title: Text('Staff ID: ${record['staff_id']}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Clock In: ${record['clock_in_time'] ?? 'Not recorded'}'),
              Text('Status: ${_getStatusText(record['attendance_status'])}'),
            ],
          ),
          trailing: PopupMenuButton(
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
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ),
        if (record['clock_in_image'] != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: InteractiveViewer(
                      child: ImageUtils.buildImageWidget(
                        record['clock_in_image'],
                        height: 300,
                        width: 300,
                      ),
                    ),
                  ),
                );
              },
              child: ImageUtils.buildImageWidget(record['clock_in_image']),
            ),
          ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: const Text('Manage Attendance',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAttendances,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () => _pickDate(context),
                  child: const Text('Select Date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : attendanceRecords.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: attendanceRecords.length,
                        itemBuilder: (ctx, i) =>
                            _buildAttendanceCard(attendanceRecords[i]),
                      )
                    : const Center(
                        child: Text(
                          'No attendance records for the selected date.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
          ),
        ],
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

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance deleted successfully')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting attendance: $error')),
      );
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
          title: Text('Edit Attendance'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(child: Text('Not Clocked In'), value: 1),
                    DropdownMenuItem(child: Text('Clocked In'), value: 2),
                  ],
                  onChanged: (value) => status = value ?? 1,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Attendance updated successfully')),
                      );
                    }
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error updating attendance: $error')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
