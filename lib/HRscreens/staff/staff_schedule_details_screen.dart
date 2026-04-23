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
  bool _isLoading = false;
  bool _isCheckingAttendance = true;
  String? _clockInImageUrl; // ✅ store proof image URL

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

      // ✅ Also get image URL if already clocked in
      final imageUrl = attendanceProvider.lastCheckedImageUrl;

      if (mounted) {
        setState(() {
          isClockIn = hasAttendance;
          _clockInImageUrl = imageUrl;
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

  // ✅ Auto open camera directly — no dialog
  Future<void> _handleClockIn() async {
    setState(() => _isLoading = true);

    try {
      final ImagePicker picker = ImagePicker();

      // ✅ Directly open camera (gallery on web)
      final XFile? picked = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
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
          _clockInImageUrl = result['imageUrl']; // ✅ store returned image URL
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

  // ✅ Show proof image in full screen
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
                          label: 'Break Start', value: widget.startBreak),
                      DetailsRow(
                          label: 'Break End', value: widget.endBreak),
                      DetailsRow(
                        label: 'Status',
                        value: isClockIn ? 'Clocked In' : widget.status,
                        valueColor: isClockIn
                            ? Colors.green
                            : widget.status.toLowerCase() == 'active'
                                ? Colors.green
                                : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Show proof image if clocked in
              if (isClockIn && _clockInImageUrl != null) ...[
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

              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Staff',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.assignedStaff.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            margin:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  widget.assignedStaff[index].isNotEmpty
                                      ? widget.assignedStaff[index][0]
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              ),
                              title: Text(
                                widget.assignedStaff[index],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${widget.startTime} - ${widget.endTime}',
                                style:
                                    TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Clock In button — directly opens camera
              if (!isClockIn)
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _handleClockIn,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Clock In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
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