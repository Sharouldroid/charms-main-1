import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/schedule_provider.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'registrationForm.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class ScheduleCalendar extends StatefulWidget {
  final bool isAdmin;
  final int userId;

  const ScheduleCalendar({
    super.key,
    required this.isAdmin,
    required this.userId,
  });

  @override
  _ScheduleCalendarState createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _duration;

  final TextEditingController _descriptionController = TextEditingController();
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ✅ NEW: Store user's registered schedule IDs
  List<int> _userRegisteredScheduleIds = [];

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
    _loadSchedules();
    _loadUserRegistrations(); // ✅ Load user's registrations
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateDateControllers() {
    _startDateController.text = _startDate == null
        ? ''
        : _startDate!.toLocal().toString().split(' ')[0];
    _endDateController.text = _endDate == null
        ? ''
        : _endDate!.toLocal().toString().split(' ')[0];
  }

  Future<void> _loadSchedules() async {
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);
    await scheduleProvider.loadSchedules();
  }

  // ✅ NEW: Load all schedules user is registered for
  Future<void> _loadUserRegistrations() async {
    if (widget.isAdmin) return; // Only for interns

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/registers/by-user/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both single registration and multiple registrations
        if (data is Map) {
          setState(() {
            _userRegisteredScheduleIds = [data['schedule_id'] as int];
          });
        } else if (data is List) {
          setState(() {
            _userRegisteredScheduleIds = data
                .map((item) => item['schedule_id'] as int)
                .toList();
          });
        }

        print('✅ User registered for schedules: $_userRegisteredScheduleIds');
      }
    } catch (e) {
      print('Error loading user registrations: $e');
    }
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
          if (widget.isAdmin) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      readOnly: true,
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, isStartDate: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        suffixIcon: Icon(Icons.calendar_today),
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
                      final isUserRegistered = _userRegisteredScheduleIds.contains(schedule.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 3,
                        color: isUserRegistered
                            ? Colors.green.withOpacity(0.05)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isUserRegistered
                              ? const BorderSide(color: Colors.green, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  schedule.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // ✅ Show "REGISTERED" badge if user registered
                              if (isUserRegistered)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'REGISTERED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
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
                                    final count = snapshot.data!['currentRegistrations'] ?? 0;
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
                                          color: isAvailable ? Colors.green : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isAvailable ? Icons.check_circle : Icons.cancel,
                                            color: isAvailable ? Colors.green : Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isAvailable
                                                ? '$count/5 slots filled - Available'
                                                : 'Full ($count/5) - Registration Closed',
                                            style: TextStyle(
                                              color: isAvailable ? Colors.green : Colors.red,
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
                              if (!widget.isAdmin && !isUserRegistered) ...[
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
                              if (isUserRegistered) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  '✓ You are registered for this session',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: !widget.isAdmin
                              ? Icon(
                                  isUserRegistered ? Icons.check_circle : Icons.arrow_forward_ios,
                                  color: isUserRegistered ? Colors.green : Colors.blueAccent,
                                )
                              : const Icon(Icons.event_note),
                          onTap: () {
                            if (!widget.isAdmin) {
                              _checkRegistrationLimit(schedule.id);
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

  // ✅ UPDATED: Check registration with duplicate prevention
  Future<void> _checkRegistrationLimit(int scheduleId) async {
    try {

    print('');
    print('========================================');
    print('📋 SCHEDULE TAPPED');
    print('========================================');
    print('Schedule ID: $scheduleId');  // ✅ What schedule was clicked?
    print('User ID: ${widget.userId}');
    print('========================================');
    
      // ✅ STEP 1: Check if user already registered for THIS schedule
      if (_userRegisteredScheduleIds.contains(scheduleId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ You have already registered for this session!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return; // Stop here!
      }

      // ✅ STEP 2: Check slot availability (existing code)
      final url = '${AppConfig.hostname}/api/internship/schedules/$scheduleId/check-registration';
      print('Making request to: $url');

      final response = await http.get(Uri.parse(url));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['available'] == true) {
          // Navigate to the registration form
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationForm(
                scheduleId: scheduleId,
                userId: widget.userId,
              ),
            ),
          );

          // ✅ Reload registrations after coming back
          if (result == true) {
            await _loadUserRegistrations();
          }
        } else {
          final currentCount = data['currentRegistrations'] ?? 0;
          final maxCount = data['maxRegistrations'] ?? 5;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration closed! This slot is full ($currentCount/$maxCount interns registered)'
              ),
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
          _endDate = null;
          _duration = null;
        } else {
          _endDate = selectedDate;
          _duration = _endDate!.difference(_startDate!).inDays;
        }
        _updateDateControllers();
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

                print('Duration calculated: $duration');

                // ✅ FIXED: Add maxRegistrations field
                Provider.of<ScheduleProvider>(context, listen: false)
                    .addSchedule(Schedule(
                  id: DateTime.now().millisecondsSinceEpoch,
                  startDate: _startDate!,
                  endDate: _endDate!,
                  description: _descriptionController.text,
                  duration: duration.toString(),
                  maxRegistrations: 5, // ✅ ADDED: Default 5 slots
                ));

                _descriptionController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Schedule created successfully!')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
        Uri.parse('${AppConfig.hostname}/api/internship/schedules/$scheduleId/check-registration'),
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