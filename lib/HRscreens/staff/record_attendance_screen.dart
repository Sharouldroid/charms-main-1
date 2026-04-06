import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecordAttendanceScreen extends StatefulWidget {
  const RecordAttendanceScreen({Key? key}) : super(key: key);

  @override
  _RecordAttendanceScreenState createState() => _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState extends State<RecordAttendanceScreen> {
  bool isOvertime = false;
  TimeOfDay? startTime1;
  TimeOfDay? endTime1;
  TimeOfDay? overtimeStartTime;
  TimeOfDay? overtimeEndTime;
  String detectedLocation = "Fetching location...";

  // Example schedule for today (you can dynamically pull this based on the actual schedule)
  final Map<String, Object?> todaySchedule = {
    'day': 'Monday',
    'location': 'Chagar Hutang',
    'workTime': '8:00 AM - 4:45 PM',
  };

  // Function to fetch current location (dummy implementation)
  Future<void> _getCurrentLocation() async {
    // Simulate a delay for fetching location
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      detectedLocation = "Chagar Hutang"; // Replace with actual GPS logic
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch location on initialization
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime, bool isOvertime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOvertime) {
          if (isStartTime) {
            overtimeStartTime = picked;
          } else {
            overtimeEndTime = picked;
          }
        } else {
          if (isStartTime) {
            startTime1 = picked;
          } else {
            endTime1 = picked;
          }
        }
      });
    }
  }

  double calculateDuration(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return 0;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final difference = endMinutes - startMinutes;
    return difference > 0 ? difference / 60 : 0;
  }

  void _recordAttendance() {
    final double workHours = calculateDuration(startTime1, endTime1);
    final double overtimeHours = calculateDuration(overtimeStartTime, overtimeEndTime);

    final dummyAttendance = {
      'day': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'location': detectedLocation,
      'start_time1': startTime1?.format(context) ?? 'N/A',
      'end_time1': endTime1?.format(context) ?? 'N/A',
      'start_ot': overtimeStartTime?.format(context) ?? 'N/A',
      'end_ot': overtimeEndTime?.format(context) ?? 'N/A',
      'work_hours': workHours.toStringAsFixed(2),
      'overtime': overtimeHours.toStringAsFixed(2),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dummy Attendance Recorded: $dummyAttendance'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Today's Schedule Card
            Card(
              color: Colors.blue[100],
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today: ${todaySchedule['day']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: ${todaySchedule['location']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Working Hours: ${todaySchedule['workTime']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Detected Location Display
            Card(
              color: Colors.blue[100],
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detectedLocation,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Start and End Time Fields
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time:'),
                    subtitle: Text(startTime1 != null
                        ? startTime1!.format(context)
                        : 'Select Start Time'),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () {
                        _selectTime(context, true, false);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time:'),
                    subtitle: Text(endTime1 != null
                        ? endTime1!.format(context)
                        : 'Select End Time'),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () {
                        _selectTime(context, false, false);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Overtime Checkbox
            CheckboxListTile(
              title: const Text("Overtime?"),
              value: isOvertime,
              onChanged: (newValue) {
                setState(() {
                  isOvertime = newValue!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // Overtime Start and End Time Fields (if overtime is checked)
            if (isOvertime) ...[
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Overtime:'),
                      subtitle: Text(overtimeStartTime != null
                          ? overtimeStartTime!.format(context)
                          : 'Select Start Time'),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () {
                          _selectTime(context, true, true);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Overtime:'),
                      subtitle: Text(overtimeEndTime != null
                          ? overtimeEndTime!.format(context)
                          : 'Select End Time'),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () {
                          _selectTime(context, false, true);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            // Record Attendance Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _recordAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[800],
                ),
                child: const Text(
                  'Record Attendance',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
