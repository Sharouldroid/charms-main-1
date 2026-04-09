import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';

class SurauPage extends StatefulWidget {
  final int userId;

  const SurauPage({super.key, required this.userId});

  @override
  State<SurauPage> createState() => _SurauPageState();
}

class _SurauPageState extends State<SurauPage> {
  bool needMaintenance = false;

  String prayerMatCondition = '';
  String speakerCondition = '';
  String generalCleanliness = '';
  String description = '';
  String urgency = 'Low';

  File? image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isLoading = false;

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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  Future<void> _pickTime() async {
    final pickedTime =
        await showTimePicker(context: context, initialTime: selectedTime);
    if (pickedTime != null) setState(() => selectedTime = pickedTime);
  }

  Future<void> _submitData() async {
    setState(() => isLoading = true);

    final uri =
        Uri.parse('https://devcms.com.my/charmsAPI/api/surau-maintenance');
    var request = http.MultipartRequest('POST', uri);

    final reportTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toIso8601String();

    request.fields.addAll({
      'need_maintenance': needMaintenance ? 'Yes' : 'No',
      'prayer_mat_condition': prayerMatCondition,
      'speaker_condition': speakerCondition,
      'cleanliness': generalCleanliness,
      'description': description,
      'urgency': urgency,
      'report_time': reportTime,
      'facility': 'Surau',
      'user_id': widget.userId.toString(),
    });

    if (image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('photo', image!.path));
    }

    try {
      final response = await request.send();
      final responseStream = await http.Response.fromStream(response);
      final responseBody = responseStream.body;

      if (response.statusCode == 200 || response.statusCode == 201) {
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
          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\nYou can now submit a new report.',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '❌ Failed: ${response.statusCode}\n${responseBody.length > 100 ? responseBody.substring(0, 100) + "..." : responseBody}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error submitting: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      needMaintenance = false;
      prayerMatCondition = '';
      speakerCondition = '';
      generalCleanliness = '';
      description = '';
      urgency = 'Low';
      image = null;
    });
  }

  Widget yesNoSelector(String title, String currentValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Yes"),
                value: 'Yes',
                groupValue: currentValue,
                onChanged: (val) => onChanged(val!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text("No"),
                value: 'No',
                groupValue: currentValue,
                onChanged: (val) => onChanged(val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCard(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          const SizedBox(height: 10),
          child
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFB9C4CA),
      appBar: AppBar(
        title: const Text('Surau Maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFF05179),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(children: [
          buildCard('Maintenance Needed?', Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Yes'),
                selected: needMaintenance,
                selectedColor: Colors.teal,
                onSelected: (_) => setState(() => needMaintenance = true),
              ),
              const SizedBox(width: 20),
              ChoiceChip(
                label: const Text('No'),
                selected: !needMaintenance,
                selectedColor: Colors.teal,
                onSelected: (_) => setState(() => needMaintenance = false),
              ),
            ],
          )),

          if (needMaintenance) ...[
            buildCard(
              'Facility Conditions',
              Column(
                children: [
                  yesNoSelector('Prayer Mat in Good Condition?', prayerMatCondition,
                      (val) => setState(() => prayerMatCondition = val)),
                  yesNoSelector('Speaker Working Properly?', speakerCondition,
                      (val) => setState(() => speakerCondition = val)),
                  yesNoSelector('Cleanliness Satisfactory?', generalCleanliness,
                      (val) => setState(() => generalCleanliness = val)),
                ],
              ),
            ),

            buildCard(
              'Additional Details',
              Column(
                children: [
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
                    initialValue: urgency,
                    items: ["Low", "Medium", "High"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => urgency = v!),
                    decoration: const InputDecoration(
                      labelText: 'Urgency Level of Issue',
                      helperText: 'Select how urgent this maintenance report is',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            buildCard(
              'Upload Photo',
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('Add Photo (Camera/Storage)',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  if (image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(image!, height: 150, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),

            buildCard(
              'Date & Time',
              Column(children: [
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, color: Colors.teal),
                  label: Text(
                    'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, color: Colors.teal),
                  label: Text('Time: ${selectedTime.format(context)}',
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _submitData,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(isLoading ? 'Submitting...' : 'SUBMIT REPORT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
        ),
      ),
    );
  }
}