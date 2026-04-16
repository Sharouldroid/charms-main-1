import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart';

class QuartersPage extends StatefulWidget {
  const QuartersPage({super.key});

  @override
  State<QuartersPage> createState() => _QuartersPageState();
}

class _QuartersPageState extends State<QuartersPage> {
  // Facility status maps (Yes/No)
  final Map<String, String> roomCleanliness = {
    'Clean': 'No',
    'Needs Sweeping': 'No',
    'Needs Mopping': 'No',
    'Trash Not Emptied': 'No',
  };

  final Map<String, String> toiletCondition = {
    'Working': 'No',
    'Clogged': 'No',
    'Dirty': 'No',
    'Leaking': 'No',
  };

  final Map<String, String> plumbingCondition = {
    'Normal': 'No',
    'Low Water Pressure': 'No',
    'Leak Detected': 'No',
    'No Water Supply': 'No',
  };

  final Map<String, String> electricalStatus = {
    'Lights Working': 'No',
    'Fans Working': 'No',
    'Sockets Functional': 'No',
    'Switches Functional': 'No',
    'Any Short Circuit': 'No',
  };

  final Map<String, String> pestPresence = {
    'No Pests': 'No',
    'Ants': 'No',
    'Cockroaches': 'No',
    'Rats': 'No',
    'Mosquitoes': 'No',
  };

  final Map<String, String> bedCondition = {
    'Mattress Clean': 'No',
    'Bed Frame Stable': 'No',
    'Sheets Need Change': 'No',
    'Pillow Missing': 'No',
  };

  final Map<String, String> hammockCondition = {
    'Ropes Secure': 'No',
    'Fabric Clean': 'No',
    'No Tears/Holes': 'No',
    'Hooks Stable': 'No',
  };

  // Issue types
  final List<String> issueOptions = [
    'Plumbing',
    'Electricity',
    'Cleanliness',
    'Pest Control',
    'Furniture/Bedding',
    'Water Supply',
    'Ventilation',
    'Locks/Doors/Windows',
    'Sanitation',
    'Other',
  ];

  final Map<String, bool> issueSelected = {};
  final Map<String, TextEditingController> issueDescControllers = {};

  String blockSelection = 'Female Block';
  final TextEditingController otherBlockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isToiletChecked = false;
  bool isQuartersChecked = false;
  DateTime selectedDateTime = DateTime.now();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var issue in issueOptions) {
      issueSelected[issue] = false;
      issueDescControllers[issue] = TextEditingController();
    }
    // Diagnostic – check if userId is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<Auth>(context, listen: false);
      print('QuartersPage – userId: ${auth.userId}');
    });
  }

  @override
  void dispose() {
    otherBlockController.dispose();
    descriptionController.dispose();
    for (var ctrl in issueDescControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

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

  Future<void> _pickImage() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();

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
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library (Storage)'),
                  onTap: () async {
                    Navigator.of(bc).pop();
                    final pickedFile = await _picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 85);
                    if (pickedFile != null) {
                      setState(() => _image = File(pickedFile.path));
                    }
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera (Take Photo)'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final pickedFile = await _picker.pickImage(
                      source: ImageSource.camera, imageQuality: 85);
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

  Future<void> _submitReport() async {
    if (blockSelection == 'Other' && otherBlockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify the block name.')),
      );
      return;
    }

    final selectedIssues = issueSelected.entries.where((e) => e.value).toList();
    if (selectedIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one issue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<Auth>(context, listen: false);
      final userId = auth.userId;
      print('Submitting with userId: $userId'); // 🔍 Diagnostic

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/quarters-maintenance');
      final request = http.MultipartRequest('POST', uri);

      final String finalBlock = blockSelection == 'Other'
          ? otherBlockController.text
          : blockSelection;

      request.fields['block'] = finalBlock;
      request.fields['description'] = descriptionController.text;
      request.fields['selected_datetime'] = selectedDateTime.toIso8601String();
      // ✅ ADDED BACK: toilet_area and quarters_area
      request.fields['toilet_area'] = isToiletChecked ? '1' : '0';
      request.fields['quarters_area'] = isQuartersChecked ? '1' : '0';
      request.fields['user_id'] = userId.toString();

      roomCleanliness.forEach((key, value) => request.fields['room_cleanliness[$key]'] = (value == 'Yes') ? '1' : '0');
      toiletCondition.forEach((key, value) => request.fields['toilet_condition[$key]'] = (value == 'Yes') ? '1' : '0');
      plumbingCondition.forEach((key, value) => request.fields['plumbing_condition[$key]'] = (value == 'Yes') ? '1' : '0');
      electricalStatus.forEach((key, value) => request.fields['electrical_status[$key]'] = (value == 'Yes') ? '1' : '0');
      pestPresence.forEach((key, value) => request.fields['pest_presence[$key]'] = (value == 'Yes') ? '1' : '0');
      bedCondition.forEach((key, value) => request.fields['bed_condition[$key]'] = (value == 'Yes') ? '1' : '0');
      hammockCondition.forEach((key, value) => request.fields['hammock_condition[$key]'] = (value == 'Yes') ? '1' : '0');

      int idx = 0;
      for (var entry in issueSelected.entries) {
        if (entry.value) {
          final type = entry.key;
          final desc = issueDescControllers[type]?.text ?? '';
          request.fields['issues[$idx][type]'] = type;
          request.fields['issues[$idx][description]'] = desc;
          idx++;
        }
      }

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _image!.path,
          filename: 'quarters_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(responseBody);
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
          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\n'
            'You can now submit a new report.',
          );
        }
      } else {
        if (mounted) {
          try {
            final errorData = jsonDecode(responseBody);
            final errorMessage = errorData['message'] ?? 'Unknown error occurred';
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error (HTTP ${response.statusCode}): $errorMessage'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error (HTTP ${response.statusCode}): ${responseBody.length > 100 ? "${responseBody.substring(0, 100)}..." : responseBody}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    descriptionController.clear();
    otherBlockController.clear();
    setState(() {
      _image = null;
      isToiletChecked = false;
      isQuartersChecked = false;
      blockSelection = 'Female Block';
      selectedDateTime = DateTime.now();
      roomCleanliness.updateAll((key, value) => 'No');
      toiletCondition.updateAll((key, value) => 'No');
      plumbingCondition.updateAll((key, value) => 'No');
      electricalStatus.updateAll((key, value) => 'No');
      pestPresence.updateAll((key, value) => 'No');
      bedCondition.updateAll((key, value) => 'No');
      hammockCondition.updateAll((key, value) => 'No');
      issueSelected.updateAll((key, value) => false);
      for (var ctrl in issueDescControllers.values) {
        ctrl.clear();
      }
    });
  }

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
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildYesNoDropdown(String key, Map<String, String> mapRef) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(key)),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<String>(
            initialValue: mapRef[key],
            items: const [
              DropdownMenuItem(value: 'Yes', child: Text('Yes')),
              DropdownMenuItem(value: 'No', child: Text('No')),
            ],
            onChanged: (val) {
              setState(() {
                mapRef[key] = val ?? 'No';
              });
            },
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildYesNoSection(String title, Map<String, String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        ...items.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: _buildYesNoDropdown(entry.key, items),
          );
        }),
      ],
    );
  }

  Widget buildIssuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issues (choose one or more)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...issueOptions.map((issue) {
          final selected = issueSelected[issue] ?? false;
          final descCtrl = issueDescControllers[issue];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(issue, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to add description'),
                value: selected,
                onChanged: (val) {
                  setState(() => issueSelected[issue] = val ?? false);
                },
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 0, bottom: 8),
                  child: TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: '$issue — Description (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFB9C4CA),
      appBar: AppBar(
        title: const Text('Quarters Maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Submit Maintenance Issue',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: blockSelection,
                          decoration: const InputDecoration(labelText: 'Block'),
                          items: ['Female Block', 'Male Block', 'Researcher Block', 'Other']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (val) => setState(() => blockSelection = val!),
                        ),
                        if (blockSelection == 'Other')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextFormField(
                              controller: otherBlockController,
                              decoration: const InputDecoration(labelText: 'Specify Block Name'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'General Description (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        buildIssuesSection(),
                        const SizedBox(height: 16),
                        const Text('Facility Status',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 10),
                        buildYesNoSection('Room Cleanliness', roomCleanliness),
                        const SizedBox(height: 8),
                        buildYesNoSection('Toilet Condition', toiletCondition),
                        const SizedBox(height: 8),
                        buildYesNoSection('Plumbing & Water Supply', plumbingCondition),
                        const SizedBox(height: 8),
                        buildYesNoSection('Electrical Status', electricalStatus),
                        const SizedBox(height: 8),
                        buildYesNoSection('Pest Presence', pestPresence),
                        const SizedBox(height: 8),
                        buildYesNoSection('Bed Condition', bedCondition),
                        const SizedBox(height: 8),
                        buildYesNoSection('Hammock Condition', hammockCondition),
                        const SizedBox(height: 16),
                        const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo, color: Colors.white),
                          label: const Text('Add Photo (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_image != null)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDateTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8), color: Colors.grey[50]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${selectedDateTime.toLocal()}'.split('.')[0], style: const TextStyle(fontSize: 16)),
                                const Icon(Icons.calendar_today, color: Colors.teal),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSubmitting ? Colors.grey : Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text('SUBMIT REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}