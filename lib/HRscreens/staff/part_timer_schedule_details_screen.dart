import 'dart:convert';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PartTimerScheduleDetailsScreen extends StatefulWidget {
  final String location;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final String status;
  final int scheduleId;
  final int staffId;
  final int acceptanceStatus;
  final String? staffNote;

  const PartTimerScheduleDetailsScreen({
    super.key,
    required this.location,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.scheduleId,
    required this.staffId,
    this.acceptanceStatus = 0,
    this.staffNote,
  });

  @override
  State<PartTimerScheduleDetailsScreen> createState() =>
      _PartTimerScheduleDetailsScreenState();
}

class _PartTimerScheduleDetailsScreenState
    extends State<PartTimerScheduleDetailsScreen> {
  bool isClockIn = false;
  bool isClockOut = false;
  bool _isLoading = false;
  bool _isCheckingAttendance = true;
  String? _clockOutTimeStr;
  String? _clockInLocationStr;
  late int _acceptanceStatus;

  final Color _primary = const Color(0xFFF97316);
  final Color _bgColor = const Color(0xFFFFF7ED);

  @override
  void initState() {
    super.initState();
    _acceptanceStatus = widget.acceptanceStatus;
    _checkExistingAttendance();
  }

  Future<void> _checkExistingAttendance() async {
    try {
      final ap = Provider.of<Attendances>(context, listen: false);
      final hasAttendance = await ap.checkAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
      );
      final clockOutTime = ap.lastCheckedClockOutTime;
      final clockInLocation = ap.lastCheckedClockInLocation;
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

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);
    final success = await Provider.of<Schedules>(context, listen: false)
        .acceptSchedule(widget.scheduleId);
    setState(() {
      _isLoading = false;
      if (success) _acceptanceStatus = 1;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Schedule accepted!' : 'Failed to accept.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, {'refreshDashboard': true});
    }
  }

  Future<void> _handleReject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not Accept Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Not Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<Schedules>(context, listen: false)
        .rejectSchedule(widget.scheduleId, reasonController.text.trim());
    setState(() {
      _isLoading = false;
      if (success) _acceptanceStatus = 2;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Schedule not accepted.' : 'Failed to reject.'),
      backgroundColor: success ? Colors.redAccent : Colors.grey,
    ));
    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, {'refreshDashboard': true});
    }
  }

  Future<void> _handleClockIn() async {
    setState(() => _isLoading = true);
    try {
      final locationStr = await _getCurrentLocation();
      if (locationStr == null) {
        setState(() => _isLoading = false);
        return;
      }

      String displayLocation = locationStr;
      final parts = locationStr.split(', ');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          final placeName = await _getPlaceName(lat, lng);
          if (placeName != null) displayLocation = '$placeName\n($locationStr)';
        }
      }

      final ap = Provider.of<Attendances>(context, listen: false);
      final result = await ap.recordAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
        clockInTime: DateTime.now().toIso8601String(),
        clockInLocation: displayLocation,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          isClockIn = true;
          _clockInLocationStr = displayLocation;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully clocked in!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clock in: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clock Out'),
        content: const Text('Are you sure you want to clock out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clock Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final ap = Provider.of<Attendances>(context, listen: false);
      final result = await ap.clockOutAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
        clockOutTime: now.toIso8601String(),
      );
      if (result['success'] == true && mounted) {
        setState(() {
          isClockOut = true;
          _clockOutTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked out!'),
            backgroundColor: Colors.green,
          ),
        );
        // ✅ ADD THIS — tell dashboard to refresh
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, {'refreshDashboard': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getPlaceName(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(url, headers: {'User-Agent': 'charms-app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openGoogleMaps(String coordinates) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coordinates');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAttendance) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Schedule Details', style: TextStyle(color: Colors.white)),
          backgroundColor: _primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPast = widget.workDate.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Schedule Details', style: TextStyle(color: Colors.white)),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Location', widget.location),
                    _row('Date', DateFormat('dd MMM yyyy').format(widget.workDate)),
                    _row('Start Time', widget.startTime),
                    _row('End Time', widget.endTime),
                    _row(
                      'Status',
                      isClockOut ? 'Shift Completed' : isClockIn ? 'Clocked In' : widget.status,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _acceptanceStatus == 1
                          ? 'Accepted'
                          : _acceptanceStatus == 2
                              ? 'Not Accepted'
                              : 'Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _acceptanceStatus == 1
                            ? Colors.green
                            : _acceptanceStatus == 2
                                ? Colors.redAccent
                                : Colors.orange,
                      ),
                    ),
                    if (_acceptanceStatus == 0 && !isPast) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAccept,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Accept', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleReject,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('Not Accept', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isClockIn && _clockInLocationStr != null) ...[
                const SizedBox(height: 14),
                _card(
                  child: GestureDetector(
                    onTap: () => _openGoogleMaps(_clockInLocationStr!),
                    child: Text(
                      'Clock-in location:\n$_clockInLocationStr',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_acceptanceStatus == 1 || _acceptanceStatus == 0) ...[
                if (!isClockIn)
                  ElevatedButton(
                    onPressed: _acceptanceStatus == 1 ? _handleClockIn : null,
                    style: ElevatedButton.styleFrom(backgroundColor: _primary),
                    child: const Text('Clock In', style: TextStyle(color: Colors.white)),
                  )
                else if (!isClockOut)
                  ElevatedButton(
                    onPressed: _handleClockOut,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Clock Out', style: TextStyle(color: Colors.white)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Shift completed! Clocked out at ${_clockOutTimeStr ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Schedule Not Accepted - Cannot clock in.',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE4C4)),
      ),
      child: child,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
