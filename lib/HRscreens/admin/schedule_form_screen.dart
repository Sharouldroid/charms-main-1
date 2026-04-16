import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/timeslot.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';

class ScheduleFormScreen extends StatefulWidget {
  final int staffId;
  final int staffType;

  const ScheduleFormScreen(
      {super.key, required this.staffId, required this.staffType});

  @override
  _ScheduleFormScreenState createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<void> _staffFuture;
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDays = {};
  String? _selectedBranch;
  String? _selectedSlot;

  final List<String> _branches = ['Chagar Hutang', 'Turtle Lab', 'UMT'];
  final List<String> _slots = ['Slot 1', 'Slot 2', 'Slot 3', 'Slot 4'];

  final Map<String, TimeSlot> _slotDetails = {
    'Slot 1': const TimeSlot(
      startTime: '8:00 AM',
      endTime: '12:00 PM',
      breaks: ['12:00 PM - 4:00 PM'],
    ),
    'Slot 2': const TimeSlot(
      startTime: '8:00 AM',
      endTime: '12:00 PM',
      breaks: ['12:00 PM - 4:00 PM'],
    ),
    'Slot 3': const TimeSlot(
      startTime: '12:00 PM',
      endTime: '4:00 AM',
      breaks: ['4:00 PM - 8:00 PM'],
    ),
    'Slot 4': const TimeSlot(
      startTime: '12:00 PM',
      endTime: '8:00 AM',
      breaks: ['4:00 PM - 8:00 PM', '12:00 AM - 4:00 AM'],
    ),
  };

  @override
  void initState() {
    super.initState();
    _staffFuture = Provider.of<Staffs>(context, listen: false).fetchStaff();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate() && _selectedDays.isNotEmpty) {
      final schedulesProvider = Provider.of<Schedules>(context, listen: false);

      if (_selectedSlot == null) {
        _showMessage('Please select a slot.', isError: true);
        return;
      }

      try {
        for (var date in _selectedDays) {
          final timeSlot = _slotDetails[_selectedSlot!]!;
          final workStartTime = _convertToMySQLTime(timeSlot.startTime);
          final workEndTime = _convertToMySQLTime(timeSlot.endTime);
          final breakTimes = timeSlot.breaks[0].split(' - ');
          final breakStartTime = _convertToMySQLTime(breakTimes[0]);
          final breakEndTime = _convertToMySQLTime(breakTimes[1]);

          final newSchedule = Schedule(
            schedId: 0,
            staffId: widget.staffId,
            workDate: date,
            workLocation: _getBranchId(_selectedBranch!),
            staffType: widget.staffType,
            internSlot: int.parse(_selectedSlot!.split(' ')[1]),
            workStartTime: workStartTime,
            workEndTime: workEndTime,
            breakStartTime: breakStartTime,
            breakEndTime: breakEndTime,
          );

          await schedulesProvider.addSchedule(newSchedule);
        }

        _showMessage('Schedules successfully submitted!');
        Navigator.of(context).pop(true);
      } catch (e) {
        _showMessage('Error submitting schedules: $e', isError: true);
      }
    } else if (_selectedDays.isEmpty) {
      _showMessage('Please select at least one date on the calendar.', isError: true);
    }
  }

  int _getBranchId(String branch) {
    switch (branch) {
      case 'Chagar Hutang':
        return 1;
      case 'Turtle Lab':
        return 2;
      case 'UMT':
        return 3;
      default:
        return 1;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _convertToMySQLTime(String time) {
    final parts = time.split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    final minutes = timeParts[1];

    if (parts[1] == 'PM' && hours != 12) {
      hours += 12;
    } else if (parts[1] == 'AM' && hours == 12) {
      hours = 0;
    }

    return '${hours.toString().padLeft(2, '0')}:$minutes:00';
  }

  bool _isDateSelectable(DateTime day) {
    final now = DateTime.now();
    return day.isAfter(now.subtract(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Schedule Form', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _staffFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildSelectedDatesDisplay(),
                    const SizedBox(height: 16),
                    _buildDropdown('Select Branch', _branches, _selectedBranch,
                        (value) {
                      setState(() => _selectedBranch = value);
                    }),
                    const SizedBox(height: 16),
                    const Text(
                      'Intern Slot Details:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildSlotExplanation(),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Select Slot',
                      _slots,
                      _selectedSlot,
                      (value) => setState(() => _selectedSlot = value),
                    ),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotExplanation() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(70),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      children: _slotDetails.entries.map((entry) {
        return _buildTableRow(entry.key, entry.value);
      }).toList(),
    );
  }

  TableRow _buildTableRow(String slotNumber, TimeSlot timeSlot) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            slotNumber,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Working Hours: ${timeSlot.startTime} - ${timeSlot.endTime}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 4),
              ...timeSlot.breaks.map((break_) => Text(
                    '• Break: $break_',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TableCalendar(
        focusedDay: _focusedDay,
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime(2100),
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => _selectedDays.any((d) => isSameDay(d, day)),
        enabledDayPredicate: _isDateSelectable,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            bool exists = _selectedDays.any((d) => isSameDay(d, selectedDay));
            if (exists) {
              _selectedDays.removeWhere((d) => isSameDay(d, selectedDay));
            } else {
              _selectedDays.add(selectedDay);
            }
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.red[300],
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDatesDisplay() {
    if (_selectedDays.isEmpty) return const SizedBox.shrink();

    final List<DateTime> sortedDates = _selectedDays.toList()..sort();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Selected Dates: ${sortedDates.map((date) => '${date.day}/${date.month}/${date.year}').join(", ")}',
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.blue[300],
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(),
      ),
      initialValue: selectedValue,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.black)),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? '$hint is required' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Publish', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}