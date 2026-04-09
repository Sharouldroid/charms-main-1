import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'dart:convert';

class OthersMaintenancePage extends StatefulWidget {
  final int userId;  // <-- added

  const OthersMaintenancePage({super.key, required this.userId});

  @override
  State<OthersMaintenancePage> createState() => _OthersMaintenancePageState();
}

class _OthersMaintenancePageState extends State<OthersMaintenancePage> {
  // --- Status Maps ---
  final Map<String, String> boatStatus = {
    'Hull Condition': 'Good',
    'Engine Start': 'Good',
    'Propeller': 'Good',
    'Steering': 'Good',
    'Life Jackets': 'Good',
    'Fuel Line': 'Good',
  };

  final Map<String, String> generatorStatus = {
    'Engine Oil Level': 'Good',
    'Coolant Level': 'Good',
    'Battery Voltage': 'Good',
    'Fan Belts': 'Good',
    'Output Voltage': 'Good',
    'Fuel Leaks': 'Good',
  };

  final Map<String, String> generalStatus = {
    'Solar Panels': 'Good',
    'Inverter/Battery': 'Good',
    'Water Pump': 'Good',
    'Tools Inventory': 'Good',
  };

  // --- Issues ---
  final List<String> issueTypes = [
    'Engine Failure', 'Hull Damage', 'Electrical Fault', 
    'Leakage', 'Broken Part', 'Missing Item', 'Other'
  ];
  final Map<String, bool> issueSelected = {};
  final Map<String, TextEditingController> issueDescControllers = {};

  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController(); // <-- added

  @override
  void initState() {
    super.initState();
    for (var type in issueTypes) {
      issueSelected[type] = false;
      issueDescControllers[type] = TextEditingController();
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    for (var ctrl in issueDescControllers.values) ctrl.dispose();
    _scrollController.dispose(); // <-- added
    super.dispose();
  }

  // --- UPDATED SUCCESS DIALOG ---
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
                  decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                ),
                const SizedBox(height: 16),
                const Text('Success!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- IMAGE PICKER (unchanged) ---
  Future<void> _showImagePickerOptions() async {
    await Permission.camera.request();
    await Permission.photos.request();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source, 
        imageQuality: 50,
      );
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- UPDATED SUBMIT REPORT ---
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      var uri = Uri.parse('https://devcms.com.my/charmsAPI/api/others-maintenance');
      var request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['user_id'] = widget.userId.toString();   // <-- added
      request.fields['selected_datetime'] = selectedDateTime.toIso8601String();
      request.fields['description'] = descriptionController.text;

      boatStatus.forEach((k, v) => request.fields['boat_status[$k]'] = v);
      generatorStatus.forEach((k, v) => request.fields['generator_status[$k]'] = v);
      generalStatus.forEach((k, v) => request.fields['general_equipment_status[$k]'] = v);

      int idx = 0;
      issueSelected.forEach((key, val) {
        if (val) {
          request.fields['issues[$idx][type]'] = key;
          request.fields['issues[$idx][description]'] = issueDescControllers[key]?.text ?? '';
          idx++;
        }
      });

      if (idx == 0) { 
        request.fields['issues[0][type]'] = 'Routine Check';
        request.fields['issues[0][description]'] = 'All checks performed.';
      }

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      // Accept both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          try {
            final responseData = jsonDecode(respStr);
            final reportId = responseData['report_id'] ?? 'N/A';
            final submitterName = responseData['submitter'] ?? 'User';
            final submitterType = responseData['submitter_type'] ?? 'Reporter';

            // Show detailed success dialog
            _showSuccessDialog(
              context,
              'Report submitted successfully! ✅\n\n'
              'Report ID: $reportId\n'
              'Submitted by: $submitterName ($submitterType)\n'
              'Managers have been notified.',
            ).then((_) {
              // Reset form after dialog closed
              setState(() {
                _image = null;
                boatStatus.updateAll((key, value) => 'Good');
                generatorStatus.updateAll((key, value) => 'Good');
                generalStatus.updateAll((key, value) => 'Good');
                issueSelected.updateAll((key, value) => false);
                for (var ctrl in issueDescControllers.values) {
                  ctrl.clear();
                }
                descriptionController.clear();
                selectedDateTime = DateTime.now();
              });

              _formKey.currentState?.reset();
              _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut);
            });
          } catch (e) {
            // If JSON parsing fails, show generic success
            _showSuccessDialog(
              context,
              'Report submitted successfully! ✅\n\n'
              'You can now submit a new report.',
            ).then((_) {
              setState(() {
                _image = null;
                boatStatus.updateAll((key, value) => 'Good');
                generatorStatus.updateAll((key, value) => 'Good');
                generalStatus.updateAll((key, value) => 'Good');
                issueSelected.updateAll((key, value) => false);
                for (var ctrl in issueDescControllers.values) {
                  ctrl.clear();
                }
                descriptionController.clear();
                selectedDateTime = DateTime.now();
              });

              _formKey.currentState?.reset();
              _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut);
            });
          }
        }
      } else {
        // Handle error responses
        if (mounted) {
          try {
            final errorData = jsonDecode(respStr);
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
                content: Text('Error (HTTP ${response.statusCode}): ${respStr.length > 100 ? respStr.substring(0, 100) + "..." : respStr}'),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- REST OF THE UI (unchanged except adding ScrollController to SingleChildScrollView) ---

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

  Widget _buildGoodBadSection(String title, Map<String, String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        const SizedBox(height: 6),
        ...items.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(entry.key)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    initialValue: items[entry.key],
                    items: const [
                      DropdownMenuItem(value: 'Good', child: Text('Good')),
                      DropdownMenuItem(value: 'Bad', child: Text('Bad')),
                    ],
                    onChanged: (val) => setState(() => items[entry.key] = val ?? 'Good'),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildIssuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issues (choose one or more)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...issueTypes.map((type) {
          final selected = issueSelected[type] ?? false;
          return Column(
            children: [
              CheckboxListTile(
                title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to add description'),
                value: selected,
                onChanged: (val) => setState(() => issueSelected[type] = val!),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                  child: TextFormField(
                    controller: issueDescControllers[type],
                    decoration: InputDecoration(
                      labelText: '$type — Description (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                )
            ],
          );
        }).toList(),
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
        title: const Text('Others Maintenance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFF05179),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            controller: _scrollController,   // <-- added
            padding: padding,
            child: Form(
              key: _formKey,                 // <-- added
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Submit Maintenance Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 16),

                          // Issues
                          _buildIssuesSection(),
                          
                          const SizedBox(height: 16),

                          // Status Sections
                          const Text('Equipment Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 10),
                          
                          _buildGoodBadSection('Boat Maintenance', boatStatus),
                          const SizedBox(height: 8),
                          _buildGoodBadSection('Generator (Genset)', generatorStatus),
                          const SizedBox(height: 8),
                          _buildGoodBadSection('General Equipment', generalStatus),

                          const SizedBox(height: 20),

                          // Date & Time
                          const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
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
                                  Text('${selectedDateTime.toLocal()}'.split('.')[0], style: const TextStyle(fontSize: 16)),
                                  const Icon(Icons.calendar_today, color: Colors.teal),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Upload Photo
                          const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(Icons.upload_file, color: Colors.white),
                            label: Text(
                              _image != null ? 'Change Photo' : 'Add Photo (Optional)', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          if (_image != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text("Selected: ${_image!.path.split('/').last}", style: const TextStyle(fontSize: 14)),
                            ),

                          const SizedBox(height: 16),

                          // General Description
                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'General Remarks / Notes',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 2,
                          ),

                          const SizedBox(height: 24),

                          // Submit Button
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
      ),
    );
  }
}