import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecordAttendanceScreen extends StatefulWidget {
  const RecordAttendanceScreen({super.key});

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

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5); // Deep Indigo
  final Color staffBg = const Color(0xFFF8FAFC); // Very Light Slate
  final Color staffCardBorder = const Color(0xFFE2E8F0);

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
    if (mounted) {
      setState(() {
        detectedLocation = "Chagar Hutang"; // Replace with actual GPS logic
      });
    }
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: staffPrimary,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
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
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg, // Modern background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: staffPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('RECORD ATTENDANCE',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Today's Schedule Card
                    Container(
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
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: staffPrimary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.calendar_today_rounded, color: staffPrimary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Today: ${todaySchedule['day']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1),
                            ),
                            _buildInfoRow(Icons.location_on_rounded, 'Location', todaySchedule['location'].toString()),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.access_time_rounded, 'Shift', todaySchedule['workTime'].toString()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detected Location Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        color: detectedLocation.contains("Fetching") 
                            ? Colors.orange.withOpacity(0.1) 
                            : Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: detectedLocation.contains("Fetching") 
                              ? Colors.orange.withOpacity(0.3) 
                              : Colors.teal.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            detectedLocation.contains("Fetching") ? Icons.gps_not_fixed_rounded : Icons.gps_fixed_rounded, 
                            color: detectedLocation.contains("Fetching") ? Colors.orange : Colors.teal,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: detectedLocation.contains("Fetching") ? Colors.orange.shade700 : Colors.teal.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  detectedLocation,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (detectedLocation.contains("Fetching"))
                            const SizedBox(
                              height: 16, 
                              width: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)
                            )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                      child: Text(
                        'Standard Shift',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ),

                    // Start and End Time Fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeSelector(
                            label: 'Start Time',
                            time: startTime1,
                            icon: Icons.login_rounded,
                            onTap: () => _selectTime(context, true, false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeSelector(
                            label: 'End Time',
                            time: endTime1,
                            icon: Icons.logout_rounded,
                            onTap: () => _selectTime(context, false, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Overtime Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: staffCardBorder),
                      ),
                      child: SwitchListTile(
                        title: const Text("Log Overtime", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        subtitle: Text("Record extra hours worked today", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        value: isOvertime,
                        activeColor: staffPrimary,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOvertime ? staffPrimary.withOpacity(0.1) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.more_time_rounded, color: isOvertime ? staffPrimary : Colors.grey.shade400),
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            isOvertime = newValue;
                            if (!isOvertime) {
                              overtimeStartTime = null;
                              overtimeEndTime = null;
                            }
                          });
                        },
                      ),
                    ),

                    // Overtime Start and End Time Fields
                    if (isOvertime) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSelector(
                              label: 'Start OT',
                              time: overtimeStartTime,
                              icon: Icons.timer_rounded,
                              onTap: () => _selectTime(context, true, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeSelector(
                              label: 'End OT',
                              time: overtimeEndTime,
                              icon: Icons.timer_off_rounded,
                              onTap: () => _selectTime(context, false, true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Record Attendance Button (Pinned to Bottom)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _recordAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: staffPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.fingerprint_rounded, size: 24),
                label: const Text(
                  'Record Attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modernized helper for simple text rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  // Modernized Tap-to-select field for Time
  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: staffCardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: staffPrimary.withOpacity(0.7), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time != null ? time.format(context) : '--:--',
                    style: TextStyle(
                      color: time != null ? const Color(0xFF1E293B) : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}