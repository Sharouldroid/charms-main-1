import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/timeslot.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';

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

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  final List<String> _branches = ['Chagar Hutang', 'Turtle Lab'];
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
      default:
        return 1;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
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
      backgroundColor: bgColor, // Modern Background
      appBar: const HRAppBar(title: 'ASSIGN SHIFT'),
      body: FutureBuilder(
        future: _staffFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryBlue));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: HRPageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    // Calendar Section
                    _buildSectionTitle('Select Dates'),
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildSelectedDatesDisplay(),
                    const SizedBox(height: 24),

                    // Shift Details Section
                    _buildSectionTitle('Shift Details'),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown('Select Branch', _branches, _selectedBranch, (value) {
                            setState(() => _selectedBranch = value);
                          }, Icons.location_on_rounded),
                          const SizedBox(height: 20),
                          _buildDropdown('Select Slot', _slots, _selectedSlot, (value) {
                            setState(() => _selectedSlot = value);
                          }, Icons.access_time_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Slot Information Panel
                    _buildSectionTitle('Slot Information'),
                    _buildSlotExplanation(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildSlotExplanation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: _slotDetails.entries.map((entry) {
          final isLast = entry.key == _slotDetails.entries.last.key;
          return Column(
            children: [
              _buildTableRow(entry.key, entry.value),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow(String slotNumber, TimeSlot timeSlot) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              slotNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.work_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Work: ${timeSlot.startTime} - ${timeSlot.endTime}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...timeSlot.breaks.map((break_) => Row(
                  children: [
                    Icon(Icons.coffee_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Break: $break_',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime(2100),
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => _selectedDays.any((d) => isSameDay(d, day)),
          enabledDayPredicate: _isDateSelectable,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDatesDisplay() {
    if (_selectedDays.isEmpty) return const SizedBox.shrink();

    final List<DateTime> sortedDates = _selectedDays.toList()..sort();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 18, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Selected Dates (${sortedDates.length})',
                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedDates.map((date) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
                ],
              ),
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? selectedValue, ValueChanged<String?> onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: primaryBlue.withOpacity(0.7), size: 22),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
      value: selectedValue,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
      )).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? '$hint is required' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal, // Modernized publish color
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.send_rounded),
      label: const Text('Publish Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}