import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart';

class OutdoorClassroomPage extends StatefulWidget {
  const OutdoorClassroomPage({super.key});

  @override
  State<OutdoorClassroomPage> createState() => _OutdoorClassroomPageState();
}

class _OutdoorClassroomPageState extends State<OutdoorClassroomPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Yes/No toggle
  String needMaintenance = 'No';

  // Facility Status
  String seatingStatus = 'Good';
  String boardCondition = 'Usable';
  String floorArea = 'Clear';

  // Issue Submission
  String issueType = 'Structural Damage';
  final TextEditingController otherIssueController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  final List<String> issueTypes = [
    'Structural Damage',
    'Broken Furniture',
    'Dirty Area',
    'Missing/Damaged Tools',
    'Pest Problem',
    'Other'
  ];

  @override
  void dispose() {
    otherIssueController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // --- Success Dialog (like campsite) ---
  Future<void> _showSuccessDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 60),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _resetForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'OK',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Pick Image (with permission) ---
  Future<void> _pickImage() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() => _image = File(pickedFile.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() => _image = File(pickedFile.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Submit Report ---
  Future<void> _submitReport() async {
    // Validation
    if (needMaintenance == 'Other' && otherIssueController.text.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please specify the other issue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<Auth>(context, listen: false);
      final userId = auth.userId;
      print('Outdoor – userId: $userId'); // diagnostic

      if (userId == null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      var uri = Uri.parse(
          'https://devcms.com.my/charmsAPI/api/outdoor-classroom-maintenance');
      var request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['need_maintenance'] = needMaintenance;
      request.fields['issue_type'] = issueType;
      request.fields['other_issue'] = otherIssueController.text;
      request.fields['description'] = descriptionController.text;
      request.fields['seating_status'] = seatingStatus;
      request.fields['board_condition'] = boardCondition;
      request.fields['floor_area'] = floorArea;
      request.fields['selected_datetime'] = selectedDateTime.toIso8601String();
      request.fields['user_id'] = userId.toString();  // ✅ send user_id

      if (_image != null && needMaintenance == 'Yes') {
        request.files.add(await http.MultipartFile.fromPath(
            'photo', _image!.path,
            filename: 'outdoor_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(respStr);
          final reportId = responseData['report_id'] ?? 'N/A';
          final submitterName = responseData['submitter'] ?? 'User';
          final submitterType = responseData['submitter_type'] ?? 'Reporter';

          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\n'
            'Report ID: $reportId\n'
            'Submitted by: $submitterName ($submitterType)\n'
            'Managers have been notified.',
          );
        } catch (e) {
          // Fallback if JSON parsing fails
          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\n'
            'You can now submit a new report.',
          );
        }
      } else {
        try {
          final errorData = jsonDecode(respStr);
          final errorMessage = errorData['message'] ?? 'Unknown error';
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Error (HTTP ${response.statusCode}): $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Error (HTTP ${response.statusCode}): ${respStr.length > 100 ? respStr.substring(0,100)+'...' : respStr}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- Reset Form ---
  void _resetForm() {
    setState(() {
      needMaintenance = 'No';
      seatingStatus = 'Good';
      boardCondition = 'Usable';
      floorArea = 'Clear';
      issueType = 'Structural Damage';
      otherIssueController.clear();
      descriptionController.clear();
      selectedDateTime = DateTime.now();
      _image = null;
    });
  }

  // --- Date & Time Picker ---
  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Widget buildRadioGroup(String title, List<String> options, String groupValue,
      void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        ...options.map((value) {
          return RadioListTile<String>(
            title: Text(value),
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFB9C4CA),
        appBar: AppBar(
          title: const Text(
            'Outdoor Classroom Maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFF05179),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maintenance Needed?',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('Yes'),
                                selected: needMaintenance == 'Yes',
                                selectedColor: Colors.teal,
                                onSelected: (_) =>
                                    setState(() => needMaintenance = 'Yes'),
                              ),
                              const SizedBox(width: 20),
                              ChoiceChip(
                                label: const Text('No'),
                                selected: needMaintenance == 'No',
                                selectedColor: Colors.teal,
                                onSelected: (_) =>
                                    setState(() => needMaintenance = 'No'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (needMaintenance == 'Yes')
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Submit Outdoor Classroom Issue',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            DropdownButtonFormField<String>(
                              value: issueType,
                              decoration:
                                  const InputDecoration(labelText: 'Issue Type'),
                              items: issueTypes.map((type) {
                                return DropdownMenuItem(
                                    value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => issueType = value!),
                            ),
                            if (issueType == 'Other')
                              TextFormField(
                                controller: otherIssueController,
                                decoration: const InputDecoration(
                                    labelText: 'Specify Other Issue'),
                              ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder()),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (needMaintenance == 'Yes')
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Facility Status',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            buildRadioGroup('Seating/Benches',
                                ['Good', 'Damaged', 'Missing'], seatingStatus,
                                (val) => setState(() => seatingStatus = val!)),
                            buildRadioGroup('Board Condition',
                                ['Usable', 'Faded', 'Broken'], boardCondition,
                                (val) => setState(() => boardCondition = val!)),
                            buildRadioGroup('Floor Area',
                                ['Clear', 'Muddy', 'Slippery'], floorArea,
                                (val) => setState(() => floorArea = val!)),
                            const SizedBox(height: 16),
                            const Text('Attach Photo',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              label: const Text('Add Photo',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                              ),
                            ),
                            if (_image != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_image!,
                                      height: 150, fit: BoxFit.cover),
                                ),
                              ),
                            const SizedBox(height: 16),
                            const Text('Date & Time',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            InkWell(
                              onTap: () => _selectDateTime(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${selectedDateTime.toLocal()}'
                                            .split('.')[0],
                                        style: const TextStyle(fontSize: 16)),
                                    const Icon(Icons.calendar_today,
                                        color: Colors.teal),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: _isSubmitting
                                  ? ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _submitReport,
                                      icon: const Icon(Icons.send,
                                          color: Colors.white, size: 20),
                                      label: const Text(
                                        'SUBMIT REPORT',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}