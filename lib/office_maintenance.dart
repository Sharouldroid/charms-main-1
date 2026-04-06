import 'dart:io';
import 'dart:convert'; // ADDED for jsonDecode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';

class OfficePage extends StatefulWidget {
  final int userId; // ADDED

  const OfficePage({super.key, required this.userId}); // ADDED

  @override
  State<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends State<OfficePage> {
  // Yes/No states
  Map<String, String> cleanliness = {
    'Floor Clean': 'No',
    'Desk Clean': 'No',
    'Bookshelf Organized': 'No',
    'Trash Emptied': 'No',
  };

  Map<String, String> furnitureCondition = {
    'Chairs in Good Condition': 'No',
    'Tables Stable': 'No',
    'Cabinets Functional': 'No',
  };

  Map<String, String> electricalItems = {
    'Lights Working': 'No',
    'Fans Working': 'No',
    'Sockets Safe': 'No',
  };

  // Stationeries (keep checkbox)
  Map<String, bool> stationaries = {
    'Pens': false,
    'Pencils': false,
    'Paper': false,
    'Measuring Tape': false,
    'Stapler': false,
    'Marker': false,
    'Other Stationery (for Turtle Data Collection)': false,
  };

  final TextEditingController _otherStationeryController = TextEditingController();

  String description = '';
  String urgency = 'Low';
  File? image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _otherStationeryController.dispose();
    super.dispose();
  }

  // ✅ Success Dialog (now accepts dynamic details like campsite)
  void _showSuccessDialog(BuildContext context, String message,
      {String? reportId, String? submitter, String? submitterType}) {
    showDialog(
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
                if (reportId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Report ID: $reportId',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
                if (submitter != null && submitterType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Submitted by: $submitter ($submitterType)',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _resetForm(); // reset after dialog closed
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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

  // Image Picker with Choice
  Future<void> _pickImage() async {
    await Permission.camera.request();
    await Permission.photos.request();

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
                  title: const Text('Photo Library (Storage)'),
                  onTap: () async {
                    Navigator.of(bc).pop();
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (pickedFile != null) {
                      setState(() => image = File(pickedFile.path));
                    }
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.teal),
                title: const Text('Camera (Take Photo)'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() => image = File(pickedFile.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Date Picker
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  // Time Picker
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null) setState(() => selectedTime = pickedTime);
  }

  // Submit Data to Laravel API
  Future<void> _submitData() async {
    setState(() => _isLoading = true);

    final uri =
        Uri.parse('https://devcms.com.my/charmsAPI/api/office-maintenance');
    var request = http.MultipartRequest('POST', uri);

    final reportTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toIso8601String();

    // Handle "Other" stationery text
    List<String> selectedStationaries = stationaries.keys
        .where((k) => stationaries[k] == true &&
            k != 'Other Stationery (for Turtle Data Collection)')
        .toList();

    if (stationaries['Other Stationery (for Turtle Data Collection)'] == true &&
        _otherStationeryController.text.isNotEmpty) {
      selectedStationaries.add("Other: ${_otherStationeryController.text}");
    }

    request.fields.addAll({
      'cleanliness': cleanliness.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', '),
      'furniture_condition': furnitureCondition.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', '),
      'electrical_items': electricalItems.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', '),
      'stationaries': selectedStationaries.join(', '),
      'description': description,
      'urgency': urgency,
      'report_time': reportTime,
      'facility': 'Office',
      'user_id': widget.userId.toString(), // ADDED
    });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image!.path));
    }

    try {
      final response = await request.send();
      final responseStream = await http.Response.fromStream(response);
      final responseBody = responseStream.body;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response to get details
        try {
          final responseData = jsonDecode(responseBody);
          final reportId = responseData['report_id']?.toString() ?? 'N/A';
          final submitterName = responseData['submitter'] ?? 'User';
          final submitterType = responseData['submitter_type'] ?? 'Reporter';

          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\nManagers have been notified.',
            reportId: reportId,
            submitter: submitterName,
            submitterType: submitterType,
          );
        } catch (e) {
          // Fallback if JSON parsing fails
          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\nYou can now submit a new report.',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '❌ Failed: ${response.statusCode}\n${responseBody.length > 100 ? responseBody.substring(0, 100) + "..." : responseBody}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Reset Form
  void _resetForm() {
    setState(() {
      cleanliness.updateAll((key, value) => 'No');
      furnitureCondition.updateAll((key, value) => 'No');
      electricalItems.updateAll((key, value) => 'No');
      stationaries.updateAll((key, value) => false);
      _otherStationeryController.clear();
      description = '';
      urgency = 'Low';
      image = null;
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
    });
  }

  // Yes/No Group Builder
  Widget buildYesNoGroup(String title, Map<String, String> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black)),
            const SizedBox(height: 8),
            ...items.keys.map((key) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key, style: const TextStyle(fontSize: 15)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Yes'),
                            value: 'Yes',
                            groupValue: items[key],
                            onChanged: (val) =>
                                setState(() => items[key] = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('No'),
                            value: 'No',
                            groupValue: items[key],
                            onChanged: (val) =>
                                setState(() => items[key] = val!),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  // Checkbox Card Builder with conditional TextField
  Widget buildCheckboxGroup(String title, Map<String, bool> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black)),
            const SizedBox(height: 8),
            ...items.keys.map((key) {
              bool isOther = key == 'Other Stationery (for Turtle Data Collection)';
              return Column(
                children: [
                  CheckboxListTile(
                    title: Text(key),
                    value: items[key],
                    onChanged: (val) {
                      setState(() {
                        items[key] = val!;
                        if (!val && isOther) {
                          _otherStationeryController.clear();
                        }
                      });
                    },
                  ),
                  if (isOther && items[key] == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _otherStationeryController,
                        decoration: const InputDecoration(
                          labelText: 'Specify Other Stationery',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // Photo Upload Section
  Widget _buildPhotoUploadSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Add Photo (Camera/Storage)',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            if (image != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image!, height: 120),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Date & Time Picker Section
  Widget _buildDateTimeSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date & Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                  const Icon(Icons.calendar_today, color: Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time: ${selectedTime.format(context)}'),
                  const Icon(Icons.access_time, color: Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Build UI
  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFB9C4CA),
      appBar: AppBar(
        title: const Text('Office Maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFF05179),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: padding,
                child: Column(
                  children: [
                    buildYesNoGroup('Cleanliness', cleanliness),
                    buildYesNoGroup('Furniture Condition', furnitureCondition),
                    buildYesNoGroup('Electrical Items', electricalItems),
                    buildCheckboxGroup(
                        'Stationeries (For Turtle Data Collection)', stationaries),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Additional Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            TextField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onChanged: (val) => description = val,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: urgency,
                              items: ["Low", "Medium", "High"]
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => urgency = v!),
                              decoration: const InputDecoration(
                                labelText: 'Urgency Level of Issue',
                                helperText:
                                    'Select how urgent this maintenance report is',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildPhotoUploadSection(),
                    _buildDateTimeSection(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitData,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Submitting...' : 'SUBMIT REPORT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}