import 'package:charms/HRproviders/attendances.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffScheduleDetailsScreen extends StatefulWidget {
  final String location;
  final DateTime workDate;
  final List<String> assignedStaff;
  final String startTime;
  final String endTime;
  final String startBreak;
  final String endBreak;
  final String status;
  final int scheduleId;
  final int staffId;

  const StaffScheduleDetailsScreen({
    super.key,
    required this.location,
    required this.workDate,
    required this.assignedStaff,
    required this.startTime,
    required this.endTime,
    required this.startBreak,
    required this.endBreak,
    required this.status,
    required this.scheduleId,
    required this.staffId,
  });

  @override
  _StaffScheduleDetailsScreenState createState() =>
      _StaffScheduleDetailsScreenState();
}

class _StaffScheduleDetailsScreenState
    extends State<StaffScheduleDetailsScreen> {
  bool isClockIn = false;
  bool isClockOut = false;
  bool _isLoading = false;
  bool _isCheckingAttendance = true;
  String? _clockOutTimeStr;
  String? _clockInLocationStr;

  // ── Palette ──────────────────────────────────────────────────────────────────
  final Color _primaryBlue = const Color(0xFF2563EB);
  final Color _bgColor = const Color(0xFFF4F7FA);

  @override
  void initState() {
    super.initState();
    _checkExistingAttendance();
  }

  Future<void> _checkExistingAttendance() async {
    try {
      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);
      final hasAttendance = await attendanceProvider.checkAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
      );

      final clockOutTime = attendanceProvider.lastCheckedClockOutTime;
      final clockInLocation = attendanceProvider.lastCheckedClockInLocation;

      if (mounted) {
        setState(() {
          isClockIn = hasAttendance;
          isClockOut = clockOutTime != null && clockOutTime.isNotEmpty;
          _clockOutTimeStr = clockOutTime;
          _clockInLocationStr = clockInLocation;
          _isCheckingAttendance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingAttendance = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isCheckingAttendance = true);
    await _checkExistingAttendance();
  }

  // ── Open Google Maps ─────────────────────────────────────────────────────────
  Future<void> _openGoogleMaps(String coordinates) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$coordinates',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Get GPS location ─────────────────────────────────────────────────────────
  Future<String?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable GPS.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission permanently denied. Please enable it in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // ── Clock In ─────────────────────────────────────────────────────────────────
  Future<void> _handleClockIn() async {
    setState(() => _isLoading = true);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Detecting your location...'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }

      final String? locationStr = await _getCurrentLocation();

      if (locationStr == null) {
        setState(() => _isLoading = false);
        return;
      }

      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);

      final result = await attendanceProvider.recordAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
        clockInTime: DateTime.now().toIso8601String(),
        clockInLocation: locationStr,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          isClockIn = true;
          _clockInLocationStr = locationStr;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked in!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clock in failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clock in: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Clock Out ────────────────────────────────────────────────────────────────
  Future<void> _handleClockOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clock Out'),
        content: const Text(
            'Are you sure you are done with your shift and want to clock out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clock Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    try {
      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);
      final now = DateTime.now();
      final result = await attendanceProvider.clockOutAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
        clockOutTime: now.toIso8601String(),
      );

      if (result['success'] == true && mounted) {
        setState(() {
          isClockOut = true;
          _clockOutTimeStr = DateFormat('hh:mm a').format(now);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked out! Have a good rest.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clock out failed. Please check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAttendance) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Schedule Details',
              style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: _primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Schedule Details',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Schedule Info Card ────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardTitle(
                        'Schedule Information', Icons.event_note_rounded),
                    const SizedBox(height: 12),
                    _buildDetailsRow(
                        Icons.location_on_rounded, 'Location', widget.location),
                    _buildDetailsRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      DateFormat('dd MMM yyyy').format(widget.workDate),
                    ),
                    _buildDetailsRow(
                        Icons.login_rounded, 'Start Time', widget.startTime),
                    _buildDetailsRow(
                        Icons.logout_rounded, 'End Time', widget.endTime),
                    _buildDetailsRow(
                      Icons.info_outline_rounded,
                      'Status',
                      isClockOut
                          ? 'Shift Completed'
                          : isClockIn
                              ? 'Clocked In'
                              : widget.status,
                      valueColor:
                          isClockIn || isClockOut ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Clock-In Location Card — shows after clock-in ─────────────
              if (isClockIn && _clockInLocationStr != null) ...[
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardTitle(
                          'Clock-In Location', Icons.gps_fixed_rounded),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _openGoogleMaps(_clockInLocationStr!),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              // Pin icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_pin,
                                    color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 12),

                              // Coordinates + tap hint
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location Recorded',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // ── Clickable coordinates ────────────────
                                    Row(
                                      children: [
                                        Text(
                                          _clockInLocationStr!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 13,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap to view on Google Maps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Action Button ─────────────────────────────────────────────
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!isClockIn)
                ElevatedButton.icon(
                  onPressed: _handleClockIn,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Clock In',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else if (isClockIn && !isClockOut)
                ElevatedButton.icon(
                  onPressed: _handleClockOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Clock Out',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else if (isClockOut)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Shift completed! Clocked out at ${_clockOutTimeStr ?? "Unknown Time"}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.grey.shade700),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}