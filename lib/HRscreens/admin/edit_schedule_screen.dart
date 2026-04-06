import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRproviders/schedules.dart';

class EditScheduleScreen extends StatefulWidget {
  final Schedule schedule;
  final int staffType;

  const EditScheduleScreen({
    Key? key,
    required this.schedule,
    required this.staffType,
  }) : super(key: key);

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedBranch;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TimeOfDay _startBreak;
  late TimeOfDay _endBreak;
  String? _selectedInternSlot;

  final List<String> _branches = ['Chagar Hutang', 'Turtle Lab', 'UMT'];

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    // Convert branch ID to name
    _selectedBranch = _getBranchName(widget.schedule.workLocation);
    
    // Convert time strings to TimeOfDay
    _startTime = _parseTimeString(widget.schedule.workStartTime!);
    _endTime = _parseTimeString(widget.schedule.workEndTime!);
    _startBreak = _parseTimeString(widget.schedule.breakStartTime!);
    _endBreak = _parseTimeString(widget.schedule.breakEndTime!);

    if (widget.staffType == 10) { // If intern
      _selectedInternSlot = 'Slot ${widget.schedule.internSlot}';
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

  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _onSubmit() async {
  if (_formKey.currentState!.validate()) {
    try {
      final updatedSchedule = Schedule(
        schedId: widget.schedule.schedId,
        staffId: widget.schedule.staffId,
        workDate: widget.schedule.workDate,
        workLocation: _getBranchId(_selectedBranch),
        staffType: widget.staffType,
        internSlot: widget.staffType == 10 
            ? int.parse(_selectedInternSlot!.split(' ')[1]) 
            : null,
        workStartTime: _formatTime(_startTime),
        workEndTime: _formatTime(_endTime),
        breakStartTime: _formatTime(_startBreak),
        breakEndTime: _formatTime(_endBreak),
      );

      print('Updating schedule with data: ${updatedSchedule.toString()}');

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

  // Reuse the same helper methods from ScheduleFormScreen
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  int _getBranchId(String branch) {
    switch (branch) {
      case 'Chagar Hutang': return 1;
      case 'Turtle Lab': return 2;
      case 'UMT': return 3;
      default: return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Schedule', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
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
                  decoration: const InputDecoration(labelText: 'Branch'),
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

                // Time pickers
                if (widget.staffType != 10) ...[
                  _buildTimePicker(
                    'Work Start Time',
                    _startTime,
                    (time) => setState(() => _startTime = time!),
                  ),
                  _buildTimePicker(
                    'Work End Time',
                    _endTime,
                    (time) => setState(() => _endTime = time!),
                  ),
                  _buildTimePicker(
                    'Break Start Time',
                    _startBreak,
                    (time) => setState(() => _startBreak = time!),
                  ),
                  _buildTimePicker(
                    'Break End Time',
                    _endBreak,
                    (time) => setState(() => _endBreak = time!),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onSubmit,
                  child: const Text('Update Schedule'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(
  String label,
  TimeOfDay initialTime,
  Function(TimeOfDay?) onTimeSelected,
) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${initialTime.hour.toString().padLeft(2, '0')}:${initialTime.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(width: 8),
          const Icon(Icons.access_time),
        ],
      ),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          setState(() {
            onTimeSelected(picked);
          });
        }
      },
    ),
  );
}
}