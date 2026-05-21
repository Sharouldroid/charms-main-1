import 'dart:convert';
import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRscreens/staff/schedule_exchange_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  final int acceptanceStatus;
  final String? staffNote;

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
    this.acceptanceStatus = 0,
    this.staffNote,
  });

  @override
  _StaffScheduleDetailsScreenState createState() =>
      _StaffScheduleDetailsScreenState();
}

class _StaffScheduleDetailsScreenState
    extends State<StaffScheduleDetailsScreen> {
  bool isClockIn  = false;
  bool isClockOut = false;
  bool _isLoading = false;
  bool _isCheckingAttendance = true;
  String? _clockOutTimeStr;
  String? _clockInLocationStr;
  late int _acceptanceStatus;

  final Color _primaryBlue = const Color(0xFF2563EB);
  final Color _bgColor     = const Color(0xFFF4F7FA);

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
        staffId: widget.staffId, scheduleId: widget.scheduleId,
      );
      final clockOutTime    = ap.lastCheckedClockOutTime;
      final clockInLocation = ap.lastCheckedClockInLocation;
      if (mounted) {
        setState(() {
          isClockIn  = hasAttendance;
          isClockOut = clockOutTime != null && clockOutTime.isNotEmpty;
          _clockOutTimeStr    = clockOutTime;
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

  // ── Accept schedule ────────────────────────────────────────────────────────
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
      content: Text(success ? '✅ Schedule accepted!' : 'Failed to accept.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));

    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, {'refreshDashboard': true});
    }
  }

  // ── Reject schedule ────────────────────────────────────────────────────────
  Future<void> _handleReject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 8),
          Text('Reject Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this schedule:',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. I have a personal commitment...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Not Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please provide a reason.'), backgroundColor: Colors.orange));
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
      content: Text(success ? '❌ Schedule Not Accepted.' : 'Failed to reject.'),
      backgroundColor: success ? Colors.redAccent : Colors.grey,
    ));

    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, {'refreshDashboard': true});
    }
  }

  // ── Request Exchange ───────────────────────────────────────────────────────
  void _handleExchange() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScheduleExchangeScreen(
        myStaffId:  widget.staffId,
        mySchedule: Schedule(
          schedId:       widget.scheduleId,
          staffId:       widget.staffId,
          workDate:      widget.workDate,
          workLocation:  _locationNameToInt(widget.location),
          staffType:     1,
          workStartTime: widget.startTime,
          workEndTime:   widget.endTime,
        ),
      ),
    ));
  }

  int _locationNameToInt(String location) {
  switch (location.trim()) {
    case 'Chagar Hutang': return 1;
    case 'Turtle Lab':    return 2;
    case 'UMT':           return 3;
    default:              return 1;
  }
}

  // ── Clock In ───────────────────────────────────────────────────────────────
  Future<void> _handleClockIn() async {
    setState(() => _isLoading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Detecting your location...'),
        ]),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blueGrey,
      ));

      final locationStr = await _getCurrentLocation();
      if (locationStr == null) { setState(() => _isLoading = false); return; }

      // Try to resolve coordinates to a human-readable place name
      String displayLocation = locationStr;
      final parts = locationStr.split(', ');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          final placeName = await _getPlaceName(lat, lng);
          if (placeName != null) {
            displayLocation = '$placeName\n($locationStr)';
          }
        }
      }

      final ap = Provider.of<Attendances>(context, listen: false);
      final result = await ap.recordAttendance(
        staffId: widget.staffId, scheduleId: widget.scheduleId,
        clockInTime: DateTime.now().toIso8601String(),
        clockInLocation: displayLocation, // ← human-readable name + coords
      );

      if (result['success'] == true && mounted) {
        setState(() { isClockIn = true; _clockInLocationStr = displayLocation; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Successfully clocked in!'), backgroundColor: Colors.green));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to clock in: $error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Clock Out ──────────────────────────────────────────────────────────────
  Future<void> _handleClockOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clock Out'),
        content: const Text('Are you sure you want to clock out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clock Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      final ap  = Provider.of<Attendances>(context, listen: false);
      final now = DateTime.now();
      final result = await ap.clockOutAttendance(
        staffId: widget.staffId, scheduleId: widget.scheduleId,
        clockOutTime: now.toIso8601String(),
      );
      if (result['success'] == true && mounted) {
        setState(() { isClockOut = true; _clockOutTimeStr = DateFormat('hh:mm a').format(now); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Successfully clocked out!'), backgroundColor: Colors.green));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Get GPS coordinates as string ──────────────────────────────────────────
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
    } catch (e) { return null; }
  }

  // ── Reverse geocode coordinates to place name (Nominatim) ─────────────────
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
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAttendance) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Details', style: TextStyle(color: Colors.white)),
            centerTitle: true, backgroundColor: _primaryBlue,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPast = widget.workDate.isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Schedule Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Schedule Info Card ──────────────────────────────────────────
              _buildCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('Schedule Information', Icons.event_note_rounded),
                  const SizedBox(height: 12),
                  _buildDetailsRow(Icons.location_on_rounded, 'Location', widget.location),
                  _buildDetailsRow(Icons.calendar_today_rounded, 'Date',
                      DateFormat('dd MMM yyyy').format(widget.workDate)),
                  _buildDetailsRow(Icons.login_rounded,  'Start Time', widget.startTime),
                  _buildDetailsRow(Icons.logout_rounded, 'End Time',   widget.endTime),
                  _buildDetailsRow(Icons.info_outline_rounded, 'Status',
                    isClockOut ? 'Shift Completed' : isClockIn ? 'Clocked In' : widget.status,
                    valueColor: isClockIn || isClockOut ? Colors.green : Colors.red,
                  ),
                ],
              )),
              const SizedBox(height: 16),

              // ── Schedule Acceptance Card ────────────────────────────────────
              _buildCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('Schedule Acceptance', Icons.how_to_reg_rounded),
                  const SizedBox(height: 12),

                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _acceptanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _acceptanceColor.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(_acceptanceIcon, color: _acceptanceColor, size: 20),
                      const SizedBox(width: 8),
                      Text(_acceptanceText,
                          style: TextStyle(color: _acceptanceColor,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                  ),

                  // Accept / Reject buttons — only when Pending and not past
                  if (_acceptanceStatus == 0 && !isPast) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoading ? null : _handleAccept,
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoading ? null : _handleReject,
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          label: const Text('Not Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ],

                  // Exchange button — only when Accepted and not past
                  if (_acceptanceStatus == 1 &&
                      !isPast &&
                      !isClockIn &&
                      !isClockOut) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryBlue,
                          side: BorderSide(color: _primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _handleExchange,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text(
                          'Request Schedule Exchange',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              )),
              const SizedBox(height: 16),

              // ── Clock-In Location Card ──────────────────────────────────────
              if (isClockIn && _clockInLocationStr != null) ...[
                _buildCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardTitle('Clock-In Location', Icons.gps_fixed_rounded),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openGoogleMaps(_clockInLocationStr!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.location_pin, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location Recorded',
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 13, color: Colors.green)),
                              const SizedBox(height: 4),
                              Text(_clockInLocationStr!,
                                  style: const TextStyle(fontSize: 13, color: Colors.blue,
                                      decoration: TextDecoration.underline)),
                              const SizedBox(height: 4),
                              const Text('Tap to view on Google Maps',
                                  style: TextStyle(fontSize: 11, color: Colors.grey,
                                      fontStyle: FontStyle.italic)),
                            ],
                          )),
                        ]),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 16),
              ],

              // ── Clock In / Out button ───────────────────────────────────────
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_acceptanceStatus == 1 || _acceptanceStatus == 0) ...[
                if (!isClockIn)
                  ElevatedButton.icon(
                    onPressed: _acceptanceStatus == 1 ? _handleClockIn : null,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Clock In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _acceptanceStatus == 1 ? _primaryBlue : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                else if (isClockIn && !isClockOut)
                  ElevatedButton.icon(
                    onPressed: _handleClockOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Clock Out',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                else if (isClockOut)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                      const SizedBox(width: 10),
                      Flexible(child: Text(
                        'Shift completed! Clocked out at ${_clockOutTimeStr ?? "Unknown"}',
                        style: const TextStyle(color: Colors.green,
                            fontWeight: FontWeight.bold, fontSize: 15),
                      )),
                    ]),
                  ),
              ] else if (_acceptanceStatus == 2)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.block_rounded, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Schedule Not Accepted — Cannot clock in.',
                        style: TextStyle(color: Colors.redAccent,
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Acceptance helpers ─────────────────────────────────────────────────────
  Color get _acceptanceColor {
    switch (_acceptanceStatus) {
      case 1:  return Colors.green;
      case 2:  return Colors.redAccent;
      default: return Colors.orange;
    }
  }

  IconData get _acceptanceIcon {
    switch (_acceptanceStatus) {
      case 1:  return Icons.check_circle_rounded;
      case 2:  return Icons.cancel_rounded;
      default: return Icons.pending_rounded;
    }
  }

  String get _acceptanceText {
    switch (_acceptanceStatus) {
      case 1:  return 'Accepted — You confirmed this schedule';
      case 2:  return 'Not Accepted — You declined this schedule';
      default: return 'Pending — Please accept or not accept this schedule';
    }
  }

  Widget _buildCard({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 4))]),
    child: child,
  );

  Widget _buildCardTitle(String title, IconData icon) => Row(children: [
    Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: _primaryBlue, size: 18)),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildDetailsRow(IconData icon, String label, String value, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        Expanded(child: Text(value,
          style: TextStyle(fontSize: 14, color: valueColor ?? Colors.grey.shade700),
          textAlign: TextAlign.end)),
      ]));
}