import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/download_bytes.dart';
import 'package:charms/utils/responsive_helper.dart';

class LandscapePage extends StatefulWidget {
  final int userId; // ✅ required

  const LandscapePage({super.key, required this.userId});

  @override
  State<LandscapePage> createState() => _LandscapePageState();
}

class _LandscapePageState extends State<LandscapePage> {
  final ImagePicker _picker = ImagePicker();

  // Status options
  final List<String> signboardOptions = ['Good', 'Faded', 'Damaged', 'Missing'];
  final List<String> trashOptions = ['Clean', 'Needs Immediate Cleaning'];
  final List<String> waterSupplyOptions = ['Good', 'Leaking', 'Clogged', 'No Water'];
  final List<String> waterPressureOptions = ['Strong', 'Moderate', 'Weak', 'No Pressure'];
  final List<String> treeOptions = ['Needs Pruning', 'Hazardous Branches', 'Fallen / Severely Damaged'];
  final List<String> leftoverEquipmentOptions = ['None', 'Equipment Present', 'Hazardous', 'Needs Removal'];

  // Form State Variables
  String signboardStatus = 'Good';
  String trashStatus = 'Clean';
  String waterSupplyStatus = 'Good';
  String waterPressureStatus = 'Strong';
  String treeStatus = 'Needs Pruning';
  String leftoverEquipStatus = 'None';

  XFile? signboardPhoto;
  XFile? trashPhoto;
  XFile? waterSupplyPhoto;
  XFile? waterPressurePhoto;
  XFile? treePhoto;
  XFile? leftoverEquipPhoto;

  Uint8List? signboardPhotoBytes;
  Uint8List? trashPhotoBytes;
  Uint8List? waterSupplyPhotoBytes;
  Uint8List? waterPressurePhotoBytes;
  Uint8List? treePhotoBytes;
  Uint8List? leftoverEquipPhotoBytes;

  // Description controllers
  final TextEditingController signboardDescController = TextEditingController();
  final TextEditingController trashDescController = TextEditingController();
  final TextEditingController waterSupplyDescController = TextEditingController();
  final TextEditingController waterPressureDescController = TextEditingController();
  final TextEditingController treeDescController = TextEditingController();
  final TextEditingController leftoverDescController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final String apiUrl = 'https://devcms.com.my/charmsAPI/api/landscape';
  bool _isSubmitting = false;

  // ------------------ REPORT VARIABLES ------------------
  String? selectedMonth;
  String? selectedYear;
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> years = ['2025', '2026', '2027'];
  bool isDownloadingReport = false;

  // ------------------ HELPER METHODS ------------------

  // ✅ Auto Clear Function
  void _resetForm() {
    setState(() {
      // Reset Dropdowns
      signboardStatus = 'Good';
      trashStatus = 'Clean';
      waterSupplyStatus = 'Good';
      waterPressureStatus = 'Strong';
      treeStatus = 'Needs Pruning';
      leftoverEquipStatus = 'None';

      // Clear Controllers
      signboardDescController.clear();
      trashDescController.clear();
      waterSupplyDescController.clear();
      waterPressureDescController.clear();
      treeDescController.clear();
      leftoverDescController.clear();
      notesController.clear();

      // Clear Photos
      signboardPhoto = null;
      trashPhoto = null;
      waterSupplyPhoto = null;
      waterPressurePhoto = null;
      treePhoto = null;
      leftoverEquipPhoto = null;
    });
  }

  // ✅ UPDATED: Allows choosing Camera or Gallery
  Future<void> _pickImage(Function(XFile, Uint8List) setter) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 75,
                  );
                  if (image != null) setter(image, await image.readAsBytes());
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                  );
                  if (image != null) setter(image, await image.readAsBytes());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFor(String field) async {
    switch (field) {
      case 'signboard': await _pickImage((img, bytes) => setState(() { signboardPhoto = img; signboardPhotoBytes = bytes; })); break;
      case 'trash': await _pickImage((img, bytes) => setState(() { trashPhoto = img; trashPhotoBytes = bytes; })); break;
      case 'watersupply': await _pickImage((img, bytes) => setState(() { waterSupplyPhoto = img; waterSupplyPhotoBytes = bytes; })); break;
      case 'waterpressure': await _pickImage((img, bytes) => setState(() { waterPressurePhoto = img; waterPressurePhotoBytes = bytes; })); break;
      case 'tree': await _pickImage((img, bytes) => setState(() { treePhoto = img; treePhotoBytes = bytes; })); break;
      case 'leftover': await _pickImage((img, bytes) => setState(() { leftoverEquipPhoto = img; leftoverEquipPhotoBytes = bytes; })); break;
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [Icon(icon, color: Colors.pink.shade400), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))]);
  }

  Widget _descriptionText(String text) {
    return Padding(padding: const EdgeInsets.only(top: 4, bottom: 10), child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3)));
  }

  Widget _buildDropDown(String label, String value, List<String> list, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField(
        initialValue: value,
        decoration: _boxDecoration(),
        items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    ]);
  }

  InputDecoration _boxDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildPhotoButton(String label, XFile? photo, Uint8List? photoBytes, VoidCallback pick) {
    return Row(children: [
      ElevatedButton.icon(
        onPressed: pick,
        icon: const Icon(Icons.camera_alt),
        label: Text(photo == null ? "Add Photo" : "Change Photo"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300, foregroundColor: Colors.white),
      ),
      const SizedBox(width: 10),
      if (photo != null) SizedBox(width: 100, height: 100, child: Image.memory(photoBytes!, fit: BoxFit.cover)),
    ]);
  }

  // ------------------ SUBMIT FORM ------------------
  Future<void> _submitForm() async {
    final missing = <String>[];
    if (signboardPhoto == null) missing.add("Signboard");
    if (trashPhoto == null) missing.add("Trash");
    if (waterSupplyPhoto == null) missing.add("Water Supply");
    if (waterPressurePhoto == null) missing.add("Water Pressure");
    if (treePhoto == null) missing.add("Tree");
    if (leftoverEquipPhoto == null) missing.add("Leftover Equipment");

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please capture images for: ${missing.join(', ')}"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = http.MultipartRequest("POST", Uri.parse(apiUrl));

      // Fields
      request.fields["signboard_status"] = signboardStatus;
      request.fields["trash_status"] = trashStatus;
      request.fields["water_supply_status"] = waterSupplyStatus;
      request.fields["water_pressure_status"] = waterPressureStatus;
      request.fields["tree_status"] = treeStatus;
      request.fields["leftover_equipment_status"] = leftoverEquipStatus;

      request.fields["signboard_desc"] = signboardDescController.text;
      request.fields["trash_desc"] = trashDescController.text;
      request.fields["water_supply_desc"] = waterSupplyDescController.text;
      request.fields["water_pressure_desc"] = waterPressureDescController.text;
      request.fields["tree_desc"] = treeDescController.text;
      request.fields["leftover_desc"] = leftoverDescController.text;
      request.fields["notes"] = notesController.text;
      request.fields["user_id"] = widget.userId.toString(); // ✅ send user_id

      // Photos
      request.files.add(http.MultipartFile.fromBytes("signboard_photo", signboardPhotoBytes!, filename: signboardPhoto!.name));
      request.files.add(http.MultipartFile.fromBytes("trash_photo", trashPhotoBytes!, filename: trashPhoto!.name));
      request.files.add(http.MultipartFile.fromBytes("water_supply_photo", waterSupplyPhotoBytes!, filename: waterSupplyPhoto!.name));
      request.files.add(http.MultipartFile.fromBytes("water_pressure_photo", waterPressurePhotoBytes!, filename: waterPressurePhoto!.name));
      request.files.add(http.MultipartFile.fromBytes("tree_photo", treePhotoBytes!, filename: treePhoto!.name));
      request.files.add(http.MultipartFile.fromBytes("leftover_equipment_photo", leftoverEquipPhotoBytes!, filename: leftoverEquipPhoto!.name));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final responseData = jsonDecode(response.body);

      // Accept both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        final reportId = responseData['report_id']?.toString() ?? 'N/A';
        final submitterName = responseData['submitter'] ?? 'User';
        final submitterType = responseData['submitter_type'] ?? 'Reporter';

        // Show success dialog
        _showSuccessDialog(
          context,
          'Report submitted successfully! ✅\n\n'
          'Report ID: $reportId\n'
          'Submitted by: $submitterName ($submitterType)\n'
          'Managers have been notified.',
        ).then((_) {
          // ✅ AUTO CLEAR FORM AFTER DIALOG CLOSED
          _resetForm();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Server error: ${responseData['message'] ?? response.statusCode}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ✅ Success dialog (copied from CampsitePage)
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

  // ------------------ DOWNLOAD REPORT ------------------
  Future<void> _downloadReport() async {
    if (selectedMonth == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select month and year')),
      );
      return;
    }

    setState(() => isDownloadingReport = true);

    final url = 'https://devcms.com.my/charmsAPI/api/landscape/report?month=$selectedMonth&year=$selectedYear';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final fileName = 'landscape_report_${selectedMonth}_${selectedYear}_${DateTime.now().millisecondsSinceEpoch}.html';
        await downloadBytes(bytes: response.bodyBytes, fileName: fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Report downloaded')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed to download report: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDownloadingReport = false);
      }
    }
  }

  // ------------------ UI CARD BUILDER ------------------
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String description,
    required Widget dropdown,
    required Widget picker,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100.withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          _descriptionText(description),
          dropdown,
          const SizedBox(height: 12),
          picker,
        ],
      ),
    );
  }

  @override
  void dispose() {
    signboardDescController.dispose();
    trashDescController.dispose();
    waterSupplyDescController.dispose();
    waterPressureDescController.dispose();
    treeDescController.dispose();
    leftoverDescController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F7),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("Landscape and Infrastructure"),
        ),
        backgroundColor: const Color(0xFFF05179),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              padding: padding,
              children: [
                // 1. Signboard
                _buildSectionCard(
                  title: "Signboard",
                  icon: Icons.signpost,
                  description: "Check signboard condition.",
                  dropdown: _buildDropDown("Status", signboardStatus, signboardOptions,
                      (v) => setState(() => signboardStatus = v!)),
                  picker: Column(children: [
                    _buildPhotoButton("Signboard", signboardPhoto, signboardPhotoBytes, () => _pickFor("signboard")),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: signboardDescController,
                      maxLines: 2,
                      decoration: _boxDecoration().copyWith(hintText: "Description"),
                    )
                  ]),
                ),

                // 2. Trash
                _buildSectionCard(
                  title: "Trash",
                  icon: Icons.delete,
                  description: "Ensure area is clean.",
                  dropdown: _buildDropDown("Status", trashStatus, trashOptions,
                      (v) => setState(() => trashStatus = v!)),
                  picker: Column(children: [
                    _buildPhotoButton("Trash", trashPhoto, trashPhotoBytes, () => _pickFor("trash")),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: trashDescController,
                      maxLines: 2,
                      decoration: _boxDecoration().copyWith(hintText: "Description"),
                    )
                  ]),
                ),

                // 3. Water Supply
                _buildSectionCard(
                  title: "Water Supply",
                  icon: Icons.water_drop,
                  description: "Check pipes.",
                  dropdown: _buildDropDown("Status", waterSupplyStatus, waterSupplyOptions,
                      (v) => setState(() => waterSupplyStatus = v!)),
                  picker: Column(children: [
                    _buildPhotoButton("Water Supply", waterSupplyPhoto, waterSupplyPhotoBytes, () => _pickFor("watersupply")),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: waterSupplyDescController,
                      maxLines: 2,
                      decoration: _boxDecoration().copyWith(hintText: "Description"),
                    )
                  ]),
                ),

                // 4. Water Pressure
                _buildSectionCard(
                  title: "Water Pressure",
                  icon: Icons.speed,
                  description: "Check pressure.",
                  dropdown: _buildDropDown("Status", waterPressureStatus, waterPressureOptions,
                      (v) => setState(() => waterPressureStatus = v!)),
                  picker: Column(children: [
                    _buildPhotoButton("Water Pressure", waterPressurePhoto, waterPressurePhotoBytes, () => _pickFor("waterpressure")),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: waterPressureDescController,
                      maxLines: 2,
                      decoration: _boxDecoration().copyWith(hintText: "Description"),
                    )
                  ]),
                ),

                // 5. Tree Condition
                _buildSectionCard(
                  title: "Tree Condition",
                  icon: Icons.nature,
                  description: "Inspect trees.",
                  dropdown: _buildDropDown("Status", treeStatus, treeOptions,
                      (v) => setState(() => treeStatus = v!)),
                  picker: Column(children: [
                    _buildPhotoButton("Tree", treePhoto, treePhotoBytes, () => _pickFor("tree")),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: treeDescController,
                      maxLines: 2,
                      decoration: _boxDecoration().copyWith(hintText: "Description"),
                    )
                  ]),
                ),

                // 6. Leftover Equipment
                _buildSectionCard(
                  title: "Leftover Equipment",
                  icon: Icons.home_repair_service,
                  description: "Check for leftovers.",
                  dropdown: _buildDropDown("Status", leftoverEquipStatus, leftoverEquipmentOptions,
                      (v) => setState(() => leftoverEquipStatus = v!)),
                  picker: Column(children: [
                    _buildPhotoButton("Leftover Equipment", leftoverEquipPhoto, leftoverEquipPhotoBytes, () => _pickFor("leftover")),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: leftoverDescController,
                      maxLines: 2,
                      decoration: _boxDecoration().copyWith(hintText: "Description"),
                    )
                  ]),
                ),

                const SizedBox(height: 10),
                _sectionHeader("Notes", Icons.note_alt),
                _descriptionText("Additional notes."),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: _boxDecoration().copyWith(hintText: "Optional notes..."),
                ),

                const SizedBox(height: 25),

                // SUBMIT BUTTON
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.send, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Submit Report", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),

                const SizedBox(height: 30),

                // ------------------ SAVE REPORT SECTION ------------------
                const Text("Generate Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedMonth,
                        items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => selectedMonth = v),
                        decoration: const InputDecoration(labelText: 'Select Month', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedYear,
                        items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (v) => setState(() => selectedYear = v),
                        decoration: const InputDecoration(labelText: 'Select Year', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: isDownloadingReport
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                  label: const Text('SAVE REPORT'),
                  onPressed: isDownloadingReport ? null : _downloadReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}