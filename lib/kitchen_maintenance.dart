import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  TextEditingController descriptionController = TextEditingController();

  // --- Facility Status ---
  Map<String, String> cleaningTasks = {
    'Surface wipe-down (tables, counters, stove top)': 'No',
    'Sink & taps cleaned / no blockage': 'No',
    'Stove and burners free of grease': 'No',
    'Fridge interior wiped & checked for expired food': 'No',
    'Floor swept & mopped': 'No',
    'Trash bins emptied / liners replaced': 'No',
  };

  Map<String, String> ventilationChecklist = {
    'Extractor fan working': 'No',
    'Windows operational / openable': 'No',
    'Air vents unobstructed': 'No',
    'Filter (if any) clean / replaced recently': 'No',
  };

  Map<String, String> wasteManagement = {
    'General bin emptied': 'No',
    'Recycling bin available & labelled': 'No',
    'Hazardous waste separated (e.g., oils)': 'No',
    'Food waste container emptied': 'No',
  };

  Map<String, String> cleaningChecklist = {
    'Equipment sanitized (knives, spatulas)': 'No',
    'Expired food removed from storage': 'No',
    'All handles and knobs wiped with disinfectant': 'No',
  };

  // --- Kitchen wear with total, used, unused ---
  final Map<String, Map<String, String>> kitchenWearCooking = {
    'Cooking Pots and Pans': {'total': '0', 'used': '0', 'unused': '0'},
    'Knives': {'total': '0', 'used': '0', 'unused': '0'},
    'Cutting Boards': {'total': '0', 'used': '0', 'unused': '0'},
    'Gas Stove': {'total': '0', 'used': '0', 'unused': '0'},
    'Water Kettle': {'total': '0', 'used': '0', 'unused': '0'},
  };

  final Map<String, Map<String, String>> kitchenWearUtensils = {
    'Plates': {'total': '0', 'used': '0', 'unused': '0'},
    'Bowls': {'total': '0', 'used': '0', 'unused': '0'},
    'Cups': {'total': '0', 'used': '0', 'unused': '0'},
    'Mugs': {'total': '0', 'used': '0', 'unused': '0'},
    'Spoons / Forks': {'total': '0', 'used': '0', 'unused': '0'},
    'Tongs': {'total': '0', 'used': '0', 'unused': '0'},
    'Spatulas': {'total': '0', 'used': '0', 'unused': '0'},
    'Ladles': {'total': '0', 'used': '0', 'unused': '0'},
    'Storage Containers': {'total': '0', 'used': '0', 'unused': '0'},
    'Cooking Gloves / Mitts': {'total': '0', 'used': '0', 'unused': '0'},
    'Cleaning Supplies (Sponges, Cloths)': {'total': '0', 'used': '0', 'unused': '0'},
  };

  String storeCondition = 'Good';
  String fridgeCondition = 'Good';
  String waterFilterCondition = 'Good';
  String waterFilterType = 'None';
  String waterSupplyDetail = 'Municipal';
  bool hygienePests = false;
  bool hygieneMold = false;

  bool _isSubmitting = false;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  DateTime? selectedDateTime;

  // Controllers for Used & Unused fields (and a separate total map for display)
  final Map<String, TextEditingController> _usedControllers = {};
  final Map<String, TextEditingController> _unusedControllers = {};
  final Map<String, String> _totalValues = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all items in both maps
    void initForMap(Map<String, Map<String, String>> wearMap) {
      for (var key in wearMap.keys) {
        final usedCtrl = TextEditingController(text: wearMap[key]!['used'] ?? '0');
        final unusedCtrl = TextEditingController(text: wearMap[key]!['unused'] ?? '0');

        // compute initial total
        int u = int.tryParse(usedCtrl.text) ?? 0;
        int un = int.tryParse(unusedCtrl.text) ?? 0;
        _totalValues[key] = (u + un).toString();

        // listeners to update totals reliably and update the underlying wearMap
        usedCtrl.addListener(() {
          final usedText = usedCtrl.text;
          final usedVal = int.tryParse(usedText) ?? 0;
          final unusedVal = int.tryParse(unusedCtrl.text) ?? 0;
          final total = usedVal + unusedVal;
          _totalValues[key] = total.toString();
          wearMap[key]!['used'] = usedVal.toString();
          wearMap[key]!['unused'] = unusedVal.toString(); // keep in sync
          wearMap[key]!['total'] = total.toString();
          if (mounted) setState(() {}); // update UI
        });

        unusedCtrl.addListener(() {
          final unusedText = unusedCtrl.text;
          final unusedVal = int.tryParse(unusedText) ?? 0;
          final usedVal = int.tryParse(usedCtrl.text) ?? 0;
          final total = usedVal + unusedVal;
          _totalValues[key] = total.toString();
          wearMap[key]!['used'] = usedVal.toString(); // keep in sync
          wearMap[key]!['unused'] = unusedVal.toString();
          wearMap[key]!['total'] = total.toString();
          if (mounted) setState(() {});
        });

        _usedControllers[key] = usedCtrl;
        _unusedControllers[key] = unusedCtrl;
      }
    }

    initForMap(kitchenWearCooking);
    initForMap(kitchenWearUtensils);
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var ctrl in _usedControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _unusedControllers.values) {
      ctrl.dispose();
    }
    descriptionController.dispose();
    super.dispose();
  }

  // --- Image Picker (Modified to include choice) ---
  Future<void> _pickImage(BuildContext context) async {
    // Request permissions
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
                  title: const Text('Photo Library'),
                  onTap: () async {
                    Navigator.of(bc).pop();
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        _imageFile = pickedFile;
                        _imageBytes = bytes;
                      });
                    }
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _imageFile = pickedFile;
                      _imageBytes = bytes;
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

  // --- Reset Form ---
  void _resetForm() {
    setState(() {
      storeCondition = 'Good';
      fridgeCondition = 'Good';
      waterFilterCondition = 'Good';
      waterFilterType = 'None';
      waterSupplyDetail = 'Municipal';
      hygienePests = false;
      hygieneMold = false;
      cleaningTasks.updateAll((key, value) => 'No');
      ventilationChecklist.updateAll((key, value) => 'No');
      wasteManagement.updateAll((key, value) => 'No');
      cleaningChecklist.updateAll((key, value) => 'No');

      kitchenWearCooking.updateAll(
          (key, value) => {'total': '0', 'used': '0', 'unused': '0'});
      kitchenWearUtensils.updateAll(
          (key, value) => {'total': '0', 'used': '0', 'unused': '0'});

      // update controllers to reflect reset
      for (var key in _usedControllers.keys) {
        _usedControllers[key]!.text = '0';
      }
      for (var key in _unusedControllers.keys) {
        _unusedControllers[key]!.text = '0';
      }
      _totalValues.updateAll((key, value) => '0');

      _imageFile = null;
      selectedDateTime = null;
      descriptionController.clear();
    });
  }

// Change the _showSuccessDialog return type from void to Future<void>

Future<void> _showSuccessDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    onPressed: () => Navigator.of(ctx).pop(),
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

  // --- DateTime Picker ---
  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
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

  // --- Submit Function (UPDATED WITH USER_ID) ---
  Future<void> _submitKitchenStatus() async {
    setState(() => _isSubmitting = true);
    try {
      // ✅ Get userId from Auth provider
      final auth = Provider.of<Auth>(context, listen: false);
      final userId = auth.userId;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final uri =
          Uri.parse('https://devcms.com.my/charmsAPI/api/kitchen-maintenance');
      final request = http.MultipartRequest('POST', uri);

      // ✅ Add user_id to request
      request.fields['user_id'] = userId.toString();

      Map<String, int> convertYesNo(Map<String, String> map) {
        return map.map((key, value) => MapEntry(key, value == 'Yes' ? 1 : 0));
      }

      request.fields.addAll({
        'store_condition': storeCondition,
        'fridge_condition': fridgeCondition,
        'water_filter_condition': waterFilterCondition,
        'water_filter_type': waterFilterType,
        'water_supply_detail': waterSupplyDetail,
        'hygiene_pests': hygienePests ? '1' : '0',
        'hygiene_mold': hygieneMold ? '1' : '0',
        'description': descriptionController.text,
        'date_time': selectedDateTime != null
            ? selectedDateTime!.toIso8601String()
            : DateTime.now().toIso8601String(),
      });

      convertYesNo(cleaningTasks)
          .forEach((key, value) => request.fields['cleaning_tasks[$key]'] = value.toString());
      convertYesNo(ventilationChecklist)
          .forEach((key, value) => request.fields['ventilation_checklist[$key]'] = value.toString());
      convertYesNo(wasteManagement)
          .forEach((key, value) => request.fields['waste_management[$key]'] = value.toString());
      convertYesNo(cleaningChecklist)
          .forEach((key, value) => request.fields['cleaning_checklist[$key]'] = value.toString());

      kitchenWearCooking.forEach((item, map) {
        map.forEach((key, val) {
          request.fields['kitchen_wear_cooking[$item][$key]'] = val;
        });
      });

      kitchenWearUtensils.forEach((item, map) {
        map.forEach((key, val) {
          request.fields['kitchen_wear_utensils[$item][$key]'] = val;
        });
      });

      if (_imageFile != null) {
        request.files.add(http.MultipartFile.fromBytes('photo', _imageBytes!, filename: _imageFile!.name));
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      // ✅ Accept both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
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
            ).then((_) {
              _resetForm();
            });
          } catch (e) {
            _showSuccessDialog(
              context,
              'Report submitted successfully! ✅\n\n'
              'You can now submit a new report.',
            ).then((_) {
              _resetForm();
            });
          }
        }
      } else {
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
                content: Text(
                    'Error (HTTP ${response.statusCode}): ${respStr.length > 100 ? "${respStr.substring(0, 100)}..." : respStr}'),
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

  // --- Dropdown / Switch / Table Builders ---
  Widget buildInlineYesNoDropdown(
      String label, String currentValue, Function(String) onChanged, int number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('$number. $label')),
          SizedBox(
            width: 80,
            child: DropdownButtonFormField<String>(
              initialValue: currentValue,
              items: ['Yes', 'No']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              dropdownColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKitchenWearTable(Map<String, Map<String, String>> wearMap) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Used')),
                DataColumn(label: Text('Unused')),
              ],
              rows: wearMap.keys.map((key) {
                final usedCtrl = _usedControllers.putIfAbsent(key, () => TextEditingController(text: wearMap[key]!['used'] ?? '0'));
                final unusedCtrl = _unusedControllers.putIfAbsent(key, () => TextEditingController(text: wearMap[key]!['unused'] ?? '0'));
                final totalText = _totalValues[key] ??
    ((int.tryParse(usedCtrl.text) ?? 0) +
     (int.tryParse(unusedCtrl.text) ?? 0)).toString();


                return DataRow(cells: [
                  DataCell(Text(key, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: Text(
                        totalText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: usedCtrl,
                        keyboardType: TextInputType.number,
                        onTap: () {
                          usedCtrl.selection = TextSelection.fromPosition(TextPosition(offset: usedCtrl.text.length));
                        },
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: unusedCtrl,
                        keyboardType: TextInputType.number,
                        onTap: () {
                          unusedCtrl.selection = TextSelection.fromPosition(TextPosition(offset: unusedCtrl.text.length));
                        },
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdownWithHelper({
    required String label,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
    required String helper,
    required int number,
  }) {
    const options = ['Good', 'Moderate', 'Damaged'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. $label',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: selectedValue,
            items: options
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 4),
          Text(helper,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget buildSwitchTile(
      String label, bool value, void Function(bool) onChanged, int number) {
    return SwitchListTile(
      title: Text('$number. $label'),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.teal,
    );
  }

  Widget buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required String roman,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$roman. $title',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _pickImage(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.camera_alt, color: Colors.white),
                SizedBox(width: 8),
                Text('Add Photo (Optional)',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        if (_imageFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imageBytes!,
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDateTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedDateTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!)
                        : 'Select Date & Time',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.teal),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Build UI ---
  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF1),
      appBar: AppBar(
        title: const Text('Kitchen Maintenance',
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
            // Facility Status
            buildSectionCard(
              icon: Icons.cleaning_services,
              title: 'Facility Status',
              roman: 'I',
              children: [
                const Text('Cleaning Tasks',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...cleaningTasks.keys.map((key) {
                  int index = cleaningTasks.keys.toList().indexOf(key) + 1;
                  return buildInlineYesNoDropdown(key, cleaningTasks[key]!,
                      (val) => setState(() => cleaningTasks[key] = val), index);
                }),
                const Divider(),
                const Text('Ventilation Checklist',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...ventilationChecklist.keys.map((key) {
                  int index =
                      ventilationChecklist.keys.toList().indexOf(key) + 1;
                  return buildInlineYesNoDropdown(key, ventilationChecklist[key]!,
                      (val) => setState(() => ventilationChecklist[key] = val), index);
                }),
                const Divider(),
                const Text('Waste Management',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...wasteManagement.keys.map((key) {
                  int index = wasteManagement.keys.toList().indexOf(key) + 1;
                  return buildInlineYesNoDropdown(key, wasteManagement[key]!,
                      (val) => setState(() => wasteManagement[key] = val), index);
                }),
              ],
            ),

            // Equipment Condition
            buildSectionCard(
              icon: Icons.kitchen,
              title: 'Equipment Condition',
              roman: 'II',
              children: [
                buildDropdownWithHelper(
                    label: 'Store Condition',
                    selectedValue: storeCondition,
                    onChanged: (v) => setState(() => storeCondition = v ?? 'Good'),
                    helper:
                        'Check shelving integrity, pests, and organization (Good / Moderate / Damaged).',
                    number: 1),
                buildDropdownWithHelper(
                    label: 'Fridge Condition',
                    selectedValue: fridgeCondition,
                    onChanged: (v) => setState(() => fridgeCondition = v ?? 'Good'),
                    helper:
                        'Check cooling, seals, interior cleanliness, and expiration checks.',
                    number: 2),
                buildDropdownWithHelper(
                    label: 'Water Filter Condition',
                    selectedValue: waterFilterCondition,
                    onChanged: (v) =>
                        setState(() => waterFilterCondition = v ?? 'Good'),
                    helper:
                        'Check for leaks, flow problems, and if filters need replacement.',
                    number: 3),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: waterFilterType,
                  items: ['None', 'Carbon', 'Sediment', 'Reverse Osmosis', 'UV']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => waterFilterType = v ?? 'None'),
                  decoration: InputDecoration(
                      labelText: '4. Water Filter Type',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: waterSupplyDetail,
                  items: ['Municipal', 'Well', 'Bottled', 'Intermittent']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => waterSupplyDetail = v ?? 'Municipal'),
                  decoration: InputDecoration(
                      labelText: '5. Water Supply Source',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),

            // Hygiene Issues
            buildSectionCard(
              icon: Icons.health_and_safety,
              title: 'Hygiene Issues',
              roman: 'III',
              children: [
                buildSwitchTile('Pests present (flies, rodents)', hygienePests,
                    (val) => setState(() => hygienePests = val), 1),
                buildSwitchTile('Mold / damp spots observed', hygieneMold,
                    (val) => setState(() => hygieneMold = val), 2),
                const SizedBox(height: 6),
                const Text(
                    'If either is ticked, please attach a photo and add details below.'),
              ],
            ),

            // Cleaning Checklist
            buildSectionCard(
              icon: Icons.check_box,
              title: 'Cleaning Checklist',
              roman: 'IV',
              children: cleaningChecklist.keys.map((key) {
                int index = cleaningChecklist.keys.toList().indexOf(key) + 1;
                return buildInlineYesNoDropdown(key, cleaningChecklist[key]!,
                    (val) => setState(() => cleaningChecklist[key] = val), index);
              }).toList(),
            ),

            // Kitchen Wear
            buildSectionCard(
              icon: Icons.inventory_2,
              title: 'Kitchenware Details',
              roman: 'V',
              children: [
                const Text('Cooking Equipment',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                buildKitchenWearTable(kitchenWearCooking),
                const SizedBox(height: 12),
                const Text('Utensils & Supplies',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                buildKitchenWearTable(kitchenWearUtensils),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Additional Description / Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter any notes related to kitchen wear or issues',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildDateTimePicker(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitKitchenStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'SUBMIT REPORT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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