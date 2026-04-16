import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/timeslot.dart';
import 'package:charms/HRproviders/schedules.dart';

class EditScheduleScreen extends StatefulWidget {
  final Schedule schedule;
  final int staffType;

  const EditScheduleScreen({
    super.key,
    required this.schedule,
    required this.staffType,
  });

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedBranch;
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
    _initializeValues();
  }

  void _initializeValues() {
    _selectedBranch = _getBranchName(widget.schedule.workLocation);

    // Set the slot based on internSlot value from the schedule
    if (widget.schedule.internSlot != null && widget.schedule.internSlot! > 0) {
      _selectedSlot = 'Slot ${widget.schedule.internSlot}';
    }
  }

  String _getBranchName(int branchId) {
    switch (branchId) {
      case 1: return 'Chagar Hutang';
      case 2: return 'Turtle Lab';
      case 3: return 'UMT';
      default: return 'Chagar Hutang';
    }
  }

  int _getBranchId(String branch) {
    switch (branch) {
      case 'Chagar Hutang': return 1;
      case 'Turtle Lab': return 2;
      case 'UMT': return 3;
      default: return 1;
    }
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

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a slot.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final timeSlot = _slotDetails[_selectedSlot!]!;
        final workStartTime = _convertToMySQLTime(timeSlot.startTime);
        final workEndTime = _convertToMySQLTime(timeSlot.endTime);
        final breakTimes = timeSlot.breaks[0].split(' - ');
        final breakStartTime = _convertToMySQLTime(breakTimes[0]);
        final breakEndTime = _convertToMySQLTime(breakTimes[1]);

        final updatedSchedule = Schedule(
          schedId: widget.schedule.schedId,
          staffId: widget.schedule.staffId,
          workDate: widget.schedule.workDate,
          workLocation: _getBranchId(_selectedBranch),
          staffType: widget.staffType,
          internSlot: int.parse(_selectedSlot!.split(' ')[1]),
          workStartTime: workStartTime,
          workEndTime: workEndTime,
          breakStartTime: breakStartTime,
          breakEndTime: breakEndTime,
        );

        await Provider.of<Schedules>(context, listen: false)
            .updateSchedule(updatedSchedule);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (error) {
        print('Error in _onSubmit: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: $error'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Schedule', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branch dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    border: OutlineInputBorder(),
                  ),
                  items: _branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch,
                      child: Text(branch),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBranch = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Slot details table
                const Text(
                  'Slot Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildSlotExplanation(),
                const SizedBox(height: 16),

                // Slot dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSlot,
                  decoration: const InputDecoration(
                    labelText: 'Select Slot',
                    border: OutlineInputBorder(),
                  ),
                  items: _slots.map((slot) {
                    return DropdownMenuItem(
                      value: slot,
                      child: Text(slot),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSlot = value);
                  },
                  validator: (value) => value == null ? 'Please select a slot' : null,
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Update Schedule', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
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
}