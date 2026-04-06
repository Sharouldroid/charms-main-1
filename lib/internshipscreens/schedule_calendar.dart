import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/schedule_provider.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'registrationForm.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for jsonDecode
import 'package:charms/main.dart';
class ScheduleCalendar extends StatefulWidget {
  final bool isAdmin;
  final int userId;

  const ScheduleCalendar({
    super.key,
    required this.isAdmin,
    required this.userId, // Add userId parameter
  });

  @override
  _ScheduleCalendarState createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _duration;

  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);
    await scheduleProvider.loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isAdmin ? 'Admin Calendar' : 'Available Registration Slots'),
      ),
      body: Column(
        children: [
          // Only show date selection and schedule creation for Admin
          if (widget.isAdmin) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: _startDate == null
                            ? ''
                            : _startDate!.toLocal().toString().split(' ')[0],
                      ),
                      onTap: () => _selectDate(context, isStartDate: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: _endDate == null
                            ? ''
                            : _endDate!.toLocal().toString().split(' ')[0],
                      ),
                      onTap: _startDate == null
                          ? null
                          : () => _selectDate(context, isStartDate: false),
                    ),
                    if (_startDate != null && _endDate != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Duration: $_duration days',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitSchedule,
                      child: const Text('Submit Schedule'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.isAdmin
                  ? 'Available Slots'
                  : 'Select a Time Slot to Register',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: scheduleProvider.schedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schedules available.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: scheduleProvider.schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = scheduleProvider.schedules[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: widget.isAdmin
                            ? 2
                            : 4, // More elevation for interns
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: !widget.isAdmin
                              ? const BorderSide(
                                  color: Colors.blueAccent,
                                  width: 1,
                                )
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            schedule.description,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isAdmin
                                  ? 16
                                  : 18, // Larger for interns
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${schedule.startDate.toLocal().toString().split(' ')[0]} - ${schedule.endDate.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Duration: ${schedule.duration} days',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _getRegistrationCount(schedule.id),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final count = snapshot
                                            .data!['currentRegistrations'] ??
                                        0;
                                    final isAvailable = count < 5;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAvailable
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isAvailable
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: isAvailable
                                                ? Colors.green
                                                : Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isAvailable
                                                ? '$count/5 slots filled - Available'
                                                : 'Full ($count/5) - Registration Closed',
                                            style: TextStyle(
                                              color: isAvailable
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Loading availability...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (!widget.isAdmin) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap to register for this slot',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: !widget.isAdmin
                              ? const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.blueAccent,
                                )
                              : const Icon(Icons.event_note),
                          onTap: () {
                            if (!widget.isAdmin) {
                              _checkRegistrationLimit(
                                  schedule.id); // Pass the schedule ID
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // schedule_calendar.dart

  Future<void> _checkRegistrationLimit(int scheduleId) async {
    try {
      final url =
          '${AppConfig.hostname}internship/schedules/$scheduleId/check-registration';
      print('Making request to: $url');

      final response = await http.get(Uri.parse(url));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['available'] == true) {
          // Navigate to the registration form
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationForm(
                  scheduleId: scheduleId,
                  userId: widget.userId), // Pass the schedule ID and user ID
            ),
          );
        } else {
          // Show a more informative error message
          final currentCount = data['currentRegistrations'] ?? 0;
          final maxCount = data['maxRegistrations'] ?? 5;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Registration closed! This slot is full ($currentCount/$maxCount interns registered)'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in _checkRegistrationLimit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          isStartDate ? DateTime.now() : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          _endDate = null; // Reset end date when start date is selected
          _duration = null; // Reset duration when start date is selected
        } else {
          _endDate = selectedDate;
          _duration = _endDate!.difference(_startDate!).inDays;
        }
      });
    }
  }

  void _submitSchedule() {
    if (_formKey.currentState!.validate()) {
      if (_startDate != null && _endDate != null) {
        _showAddEditDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both start and end dates.'),
          ),
        );
      }
    }
  }

  void _showAddEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Enter description'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_descriptionController.text.isNotEmpty &&
                  _startDate != null &&
                  _endDate != null) {
                // Calculate duration
                final duration = _endDate!.difference(_startDate!).inDays;

                // Debug log to verify duration
                print('Duration calculated: $duration');

                // Add schedule with startDate, endDate, and duration
                Provider.of<ScheduleProvider>(context, listen: false)
                    .addSchedule(Schedule(
                  id: DateTime.now().millisecondsSinceEpoch,
                  startDate: _startDate!, // Pass startDate
                  endDate: _endDate!, // Pass endDate
                  description: _descriptionController.text,
                  duration: duration,
                ));
                _descriptionController.clear();
                Navigator.pop(context); // Close the dialog
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getRegistrationCount(int scheduleId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.hostname}internship/schedules/$scheduleId/check-registration'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'currentRegistrations': 0,
          'maxRegistrations': 5,
          'available': true
        };
      }
    } catch (e) {
      print('Error getting registration count: $e');
      return {
        'currentRegistrations': 0,
        'maxRegistrations': 5,
        'available': true
      };
    }
  }
}
