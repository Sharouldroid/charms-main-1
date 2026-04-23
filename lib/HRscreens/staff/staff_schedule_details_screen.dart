import 'dart:typed_data';
import 'package:charms/HRproviders/attendances.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  String? _clockInImageUrl; 
  String? _clockOutTimeStr; 

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

      final imageUrl = attendanceProvider.lastCheckedImageUrl;
      final clockOutTime = attendanceProvider.lastCheckedClockOutTime; 

      if (mounted) {
        setState(() {
          isClockIn = hasAttendance;
          _clockInImageUrl = imageUrl;
          isClockOut = clockOutTime != null && clockOutTime.isNotEmpty;
          _clockOutTimeStr = clockOutTime;
          _isCheckingAttendance = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingAttendance = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isCheckingAttendance = true);
    await _checkExistingAttendance();
  }

  Future<Uint8List> _compressImageBytes(Uint8List rawBytes) async {
    try {
      final img.Image? originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) throw Exception('Failed to decode image');

      const int maxWidth = 800;
      img.Image finalImage = originalImage;

      if (originalImage.width > maxWidth) {
        final int targetHeight =
            (originalImage.height * (maxWidth / originalImage.width)).round();
        finalImage = img.copyResize(originalImage,
            width: maxWidth, height: targetHeight);
      }

      return Uint8List.fromList(img.encodeJpg(finalImage, quality: 70));
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return rawBytes;
    }
  }

  Future<void> _handleClockIn() async {
    setState(() => _isLoading = true);

    try {
      final ImagePicker picker = ImagePicker();

      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera, 
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (picked == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No image captured. Clock in cancelled.')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final Uint8List rawBytes = await picked.readAsBytes();
      final Uint8List imageBytes = await _compressImageBytes(rawBytes);

      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);

      final result = await attendanceProvider.recordAttendance(
        staffId: widget.staffId,
        scheduleId: widget.scheduleId,
        image: imageBytes,
        clockInTime: DateTime.now().toIso8601String(),
      );

      if (result['success'] == true && mounted) {
        setState(() {
          isClockIn = true;
          _clockInImageUrl = result['imageUrl']; 
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

  Future<void> _handleClockOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clock Out'),
        content: const Text('Are you sure you are done with your shift and want to clock out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
      final attendanceProvider = Provider.of<Attendances>(context, listen: false);
      
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

  void _viewProofImage() {
    if (_clockInImageUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Attendance Proof',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue,
              automaticallyImplyLeading: false,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                _clockInImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Failed to load image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAttendance) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Schedule Details',
              style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Details',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Information',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DetailsRow(
                          label: 'Location', value: widget.location),
                      DetailsRow(
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy')
                            .format(widget.workDate),
                      ),
                      DetailsRow(
                          label: 'Start Time', value: widget.startTime),
                      DetailsRow(
                          label: 'End Time', value: widget.endTime),
                      DetailsRow(
                        label: 'Status',
                        value: isClockOut 
                               ? 'Shift Completed' 
                               : isClockIn 
                                    ? 'Clocked In' 
                                    : widget.status,
                        valueColor: isClockIn || isClockOut
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ CHANGED: Now only shows if clocked in AND NOT clocked out
              if (isClockIn && !isClockOut && _clockInImageUrl != null) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Proof',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _viewProofImage,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _clockInImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Failed to load proof image'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap image to view full screen',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ✅ The Action Button Area
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!isClockIn)
                // STAGE 1: Need to Clock In
                ElevatedButton.icon(
                  onPressed: _handleClockIn,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Clock In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )
              else if (isClockIn && !isClockOut)
                // STAGE 2: Need to Clock Out
                ElevatedButton.icon(
                  onPressed: _handleClockOut,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Clock Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )
              else if (isClockOut)
                // STAGE 3: Done for the day
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Center(
                    child: Text(
                      'Shift completed! Clocked out at ${_clockOutTimeStr ?? "Unknown Time"}',
                      style: const TextStyle(
                        color: Colors.green, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DetailsRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 16)),
          Text(value,
              style: TextStyle(color: valueColor, fontSize: 16)),
        ],
      ),
    );
  }
}