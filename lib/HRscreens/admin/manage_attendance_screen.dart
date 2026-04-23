import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/attendances.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendances: $error')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final String? imageUrl = record['clock_in_image_url'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          'Staff ID: ${record['staff_id']}', 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Clock In: ${record['clock_in_time'] ?? 'Not recorded'}'),
            
            // ✅ ADDED: Displays the Clock Out time for the Admin to see
            Text('Clock Out: ${record['clock_out_time'] ?? 'Not recorded'}'),
            
            const SizedBox(height: 4),
            Text(
              'Status: ${_getStatusText(record['attendance_status'])}',
              style: TextStyle(
                color: _getStatusColor(record['attendance_status']),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ "View Proof" Eye Button (Only shows if image exists)
            if (imageUrl != null && imageUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                tooltip: 'View Proof',
                onPressed: () {
                  // Ensure URL is fully formed
                  final fullUrl = imageUrl.startsWith('http')
                      ? imageUrl
                      : 'https://devcms.com.my/charmsAPI/public/storage/$imageUrl';

                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppBar(
                            title: const Text('Proof Image',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.blue,
                            automaticallyImplyLeading: false,
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          InteractiveViewer(
                            child: Image.network(
                              fullUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Failed to load image'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Edit/Delete Menu
            PopupMenuButton<String>(
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
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete'),
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
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: const Text('Manage Attendance',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Select Date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceRecords.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: attendanceRecords.length,
                        itemBuilder: (ctx, i) =>
                            _buildAttendanceCard(attendanceRecords[i]),
                      )
                    : const Center(
                        child: Text(
                          'No attendance records for the selected date.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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

  // ✅ Helper for styling status text
  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
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
          title: const Text('Edit Attendance'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Not Clocked In')),
                    DropdownMenuItem(value: 2, child: Text('Clocked In')),
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
                            content: Text('Error updating attendance: $error')),
                      );
                    }
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