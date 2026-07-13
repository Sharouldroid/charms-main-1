import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart';

class WaterSportAreaPage extends StatefulWidget {
  const WaterSportAreaPage({super.key});

  @override
  State<WaterSportAreaPage> createState() => _WaterSportAreaPageState();
}

class _WaterSportAreaPageState extends State<WaterSportAreaPage> {
  Map<String, Map<String, String>> equipmentData = {
    "Kayak": {"total": "", "damaged": "", "missing": ""},
    "Kayak's Paddle": {"total": "", "damaged": "", "missing": ""},
    "Life Jacket": {"total": "", "damaged": "", "missing": ""},
    "Snorkel": {"total": "", "damaged": "", "missing": ""},
    "Mask": {"total": "", "damaged": "", "missing": ""},
    "Stand Up PaddleBoard (SUP)": {"total": "", "damaged": "", "missing": ""},
  };

  String description = '';
  String urgency = 'Low';
  XFile? image;
  Uint8List? imageBytes;
  bool isSubmitting = false;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  // Success Dialog (like campsite)
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
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Success!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
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

  // ==========================================
  // Pick Image with Choice Dialog
  // ==========================================
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
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setState(() {
                      image = picked;
                      imageBytes = bytes;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setState(() {
                      image = picked;
                      imageBytes = bytes;
                    });
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
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: selectedTime);
    if (time != null) setState(() => selectedTime = time);
  }

  void _resetForm() {
    setState(() {
      equipmentData.updateAll((key, value) => {"total": "", "damaged": "", "missing": ""});
      description = '';
      urgency = 'Low';
      image = null;
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
    });
  }

  Future<void> _submitData() async {
    // Validate all equipment fields
    for (var equipment in equipmentData.keys) {
      final values = equipmentData[equipment]!;
      if (values["total"]!.isEmpty || values["damaged"]!.isEmpty || values["missing"]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all quantity fields for $equipment.")),
        );
        return;
      }
    }

    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final auth = Provider.of<Auth>(context, listen: false);
      final userId = auth.userId;
      print('WaterSport – userId: $userId'); // diagnostic

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSubmitting = false);
        return;
      }

      final uri = Uri.parse("https://devcms.com.my/charmsAPI/api/watersportmaintenance");
      var request = http.MultipartRequest("POST", uri);

      final reportTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ).toIso8601String();

      // Add equipment fields
      equipmentData.forEach((equipment, values) {
        // Convert equipment name to field key format expected by backend
        String keyBase = equipment.toLowerCase().replaceAll("'s", "").replaceAll(" ", "_").replaceAll("(", "").replaceAll(")", "");
        request.fields["${keyBase}_total_qty"] = values["total"]!;
        request.fields["${keyBase}_damaged_qty"] = values["damaged"]!;
        request.fields["${keyBase}_missing_qty"] = values["missing"]!;
      });

      request.fields.addAll({
        "description": description,
        "urgency": urgency,
        "report_time": reportTime,
        "user_id": userId.toString(),   // ✅ send user_id
      });

      if (image != null) {
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes!, filename: image!.name));
      }

      final response = await request.send();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error (HTTP ${response.statusCode}): $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error (HTTP ${response.statusCode}): ${respStr.length > 100 ? '${respStr.substring(0,100)}...' : respStr}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget buildEquipmentCard(String label) {
    final item = equipmentData[label]!;
    int total = int.tryParse(item["total"]!) ?? 0;
    int damaged = int.tryParse(item["damaged"]!) ?? 0;
    int missing = int.tryParse(item["missing"]!) ?? 0;
    int good = total - damaged - missing;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildQtyField("Total Quantity", item["total"]!, (v) => setState(() => item["total"] = v)),
            const SizedBox(height: 10),
            buildQtyField("Damaged Quantity", item["damaged"]!, (v) => setState(() => item["damaged"] = v)),
            const SizedBox(height: 10),
            buildQtyField("Missing Quantity", item["missing"]!, (v) => setState(() => item["missing"] = v)),
            const SizedBox(height: 10),
            Text("Good Quantity: $good", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget buildQtyField(String label, String value, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget buildUploadPhotoButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file),
              const SizedBox(width: 10),
              Text(image == null ? "Upload Photo (Optional)" : "Change Photo"),
            ],
          ),
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageBytes!, width: double.infinity, height: 150, fit: BoxFit.cover),
            ),
          ),
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
        title: const Text("Water Sport Area Maintenance"),
        backgroundColor: const Color(0xFFF05179),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              children: [
                ...equipmentData.keys.map((e) => buildEquipmentCard(e)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        TextField(
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => description = v,
                        ),
                        const SizedBox(height: 12),
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
                ),
                buildUploadPhotoButton(),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _pickDate,
                        ),
                        ListTile(
                          title: Text("Time: ${selectedTime.format(context)}"),
                          trailing: const Icon(Icons.access_time),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submitData,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(isSubmitting ? "Submitting..." : "SUBMIT REPORT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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