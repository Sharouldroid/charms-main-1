import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:charms/utils/responsive_helper.dart';

class BackpackingPage extends StatefulWidget {
  final int userId; // ✅ required

  const BackpackingPage({super.key, required this.userId});

  @override
  State<BackpackingPage> createState() => _BackpackingPageState();
}

class _BackpackingPageState extends State<BackpackingPage> {
  // ---------------------------------------------------------
  // 1. DATA STRUCTURE
  // ---------------------------------------------------------
  Map<String, List<Map<String, dynamic>>> itemsBySection = {
    'Medical': [
      {
        'name': 'First Aid Kit',
        'qty': 1,
        'subItems': [
          {'name': 'Paracetamol', 'qty': 3},
          {'name': 'Pain Relievers', 'qty': 3},
          {'name': 'Cough Syrup', 'qty': 3},
          {'name': 'Alcohol Swabs', 'qty': 3},
          {'name': 'First Aid Manual', 'qty': 3},
        ],
      },
      {
        'name': 'Bandages',
        'qty': 0,
        'subItems': [
          {'name': 'Triangular Bandage', 'qty': 3},
          {'name': 'Crepe Bandage', 'qty': 3},
        ],
      },
      {'name': 'Antiseptic Wipes', 'qty': 3},
    ],
    'Emergency Response': [
      {'name': 'Oxygen Tank', 'qty': 1},
      {'name': 'Fire Extinguisher', 'qty': 1},
      {'name': 'AED', 'qty': 1},
    ],
    'Safety': [
      {'name': 'Flashlight', 'qty': 3},
    ],
  };

  String status = 'Fully Stocked';
  String restockDescription = "";
  File? image;
  bool isSubmitting = false;

  // Report Download Variables
  String? selectedMonth;
  String? selectedYear;
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> years = ['2025', '2026', '2027'];
  bool isDownloadingReport = false;

  // Expired items tracker
  Map<String, String?> expiredItems = {};

  @override
  void initState() {
    super.initState();
    _initializeExpiryTracking();
  }

  // ---------------------------------------------------------
  // 2. EXPIRY TRACKING LOGIC
  // ---------------------------------------------------------
  void _initializeExpiryTracking() {
    expiredItems.clear();

    // 1. Initialize expiry for Medical sub-items
    if (itemsBySection.containsKey('Medical')) {
      for (var item in itemsBySection['Medical']!) {
        if (item.containsKey('subItems')) {
          for (var sub in item['subItems']) {
            // Exclude Bandages from expiry tracking
            if (sub['name'] != 'Triangular Bandage' &&
                sub['name'] != 'Crepe Bandage') {
              expiredItems[sub['name']] = null;
            }
          }
        }
      }
    }

    // 2. Initialize expiry for Emergency items
    expiredItems['Oxygen Tank'] = null;
    expiredItems['Fire Extinguisher'] = null;
    expiredItems['AED'] = null;
  }

  // ---------------------------------------------------------
  // 3. AUTO CLEAR LOGIC
  // ---------------------------------------------------------
  void _resetForm() {
    setState(() {
      status = 'Fully Stocked';
      restockDescription = '';
      image = null;

      // Reset Expiry Dates (only clears values for keys that exist)
      expiredItems.updateAll((key, value) => null);

      // Reset Quantities
      itemsBySection = {
        'Medical': [
          {
            'name': 'First Aid Kit',
            'qty': 1,
            'subItems': [
              {'name': 'Paracetamol', 'qty': 3},
              {'name': 'Pain Relievers', 'qty': 3},
              {'name': 'Cough Syrup', 'qty': 3},
              {'name': 'Alcohol Swabs', 'qty': 3},
              {'name': 'First Aid Manual', 'qty': 3},
            ],
          },
          {
            'name': 'Bandages',
            'qty': 0,
            'subItems': [
              {'name': 'Triangular Bandage', 'qty': 3},
              {'name': 'Crepe Bandage', 'qty': 3},
            ],
          },
          {'name': 'Antiseptic Wipes', 'qty': 3},
        ],
        'Emergency Response': [
          {'name': 'Oxygen Tank', 'qty': 1},
          {'name': 'Fire Extinguisher', 'qty': 1},
          {'name': 'AED', 'qty': 1},
        ],
        'Safety': [
          {'name': 'Flashlight', 'qty': 3},
        ],
      };
    });
  }

  // ------------------ Flatten items for Laravel ------------------
  List<Map<String, dynamic>> _flattenItems() {
    List<Map<String, dynamic>> flattened = [];

    itemsBySection.forEach((section, items) {
      for (var item in items) {
        if (item.containsKey('subItems')) {
          for (var sub in item['subItems']) {
            flattened.add({
              'name': sub['name'],
              'qty': sub['qty'],
              'section': section,
            });
          }
        } else {
          flattened.add({
            'name': item['name'],
            'qty': item['qty'],
            'section': section,
          });
        }
      }
    });

    return flattened;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    setState(() => isSubmitting = true);

    final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/backpack');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';

    req.fields['items'] = jsonEncode(_flattenItems());
    req.fields['status'] = status;
    req.fields['restock_description'] = restockDescription;
    req.fields['expired_items'] = jsonEncode(expiredItems);
    req.fields['user_id'] = widget.userId.toString(); // ✅ send user_id

    if (image != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          image!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(resp.body);

      // Accept both 200 and 201 as success
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          final reportId = decoded['report_id']?.toString() ?? 'N/A';
          final submitterName = decoded['submitter'] ?? 'User';
          final submitterType = decoded['submitter_type'] ?? 'Reporter';

          // Show success dialog
          _showSuccessDialog(
            context,
            'Report submitted successfully! ✅\n\n'
            'Report ID: $reportId\n'
            'Submitted by: $submitterName ($submitterType)\n'
            'Managers have been notified.',
          ).then((_) {
            // Reset form after dialog closed
            _resetForm();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '❌ Failed: ${decoded['message'] ?? 'Unknown Error'}')),
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
        setState(() => isSubmitting = false);
      }
    }
  }

  // ------------------ Download Report ------------------
  Future<void> _downloadReport() async {
    if (selectedMonth == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select month and year')),
      );
      return;
    }

    setState(() => isDownloadingReport = true);

    final url =
        'https://devcms.com.my/charmsAPI/api/backpack/report?month=$selectedMonth&year=$selectedYear';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir.createSync(recursive: true);

        final filePath =
            '${dir.path}/backpack_report_${selectedMonth}_${selectedYear}_${DateTime.now().millisecondsSinceEpoch}.html';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Report saved to: $filePath')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('❌ Failed to download report: ${response.body}')),
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

  // ------------------ UI ITEM ROWS ------------------
  Widget _buildItemRow(Map<String, dynamic> item) {
    bool hasSub = item['subItems'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!hasSub)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (item['qty'] > 0) item['qty']--;
                      });
                    },
                  ),
                  Text(item['qty'].toString()),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => item['qty']++),
                  ),
                ],
              ),
          ],
        ),
        if (hasSub)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Column(
              children: List<Widget>.from(
                item['subItems'].map((sub) => _buildSubItemRow(sub)),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSubItemRow(Map<String, dynamic> subItem) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(subItem['name']),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: () {
                setState(() {
                  if (subItem['qty'] > 0) subItem['qty']--;
                });
              },
            ),
            Text(subItem['qty'].toString()),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => setState(() => subItem['qty']++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String sectionName, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map(_buildItemRow).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ------------------ Expired Section ------------------
  Widget _buildExpiredSection() {
    if (expiredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ Expired Items Check',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Column(
          children: expiredItems.keys.map((name) {
            String? selectedDate = expiredItems[name];
            Color textColor = _getExpiryColor(selectedDate);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(name, style: TextStyle(color: textColor)),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: selectedDate),
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: "Expiry Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      onTap: () => _pickExpiryDate(name),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'ℹ️ Red = Expired, Orange = Expiring < 30 days',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _pickExpiryDate(String itemName) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formatted = "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        expiredItems[itemName] = formatted;
      });
    }
  }

  Color _getExpiryColor(String? expiryDate) {
    if (expiryDate == null) return Colors.black;
    DateTime exp = DateTime.parse(expiryDate);
    final now = DateTime.now();
    if (exp.isBefore(now)) return Colors.red;
    if (exp.difference(now).inDays <= 30) return Colors.orange;
    return Colors.black;
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  // ------------------ BUILD UI ------------------
  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎒 Backpack Equipment'),
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
                ...itemsBySection.entries
                    .map((e) => _buildSection(e.key, e.value))
                    .toList(),

                const Divider(height: 30),

                _buildExpiredSection(),

                const SizedBox(height: 16),

                // STATUS DROPDOWN
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(
                        value: 'Fully Stocked', child: Text('Fully Stocked')),
                    DropdownMenuItem(
                        value: 'Needs Restocking', child: Text('Needs Restocking')),
                  ],
                  onChanged: (v) => setState(() => status = v!),
                  decoration: const InputDecoration(
                    labelText: 'Backpack Status',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                if (status == 'Needs Restocking')
                  TextField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Describe items that need restocking",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => restockDescription = val,
                  ),

                const SizedBox(height: 16),

                // PICK IMAGE BUTTON
                ElevatedButton.icon(
                  icon: image != null
                      ? Image.file(image!, width: 24, height: 24, fit: BoxFit.cover)
                      : const Icon(Icons.photo),
                  label: Text(image == null ? 'Add Photo' : 'Change Photo'),
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF05179),
                    side: const BorderSide(color: Color(0xFFF05179)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                const SizedBox(height: 16),

                // SUBMIT BUTTON
                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSubmitting ? 'SUBMITTING...' : 'SUBMIT'),
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF05179),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                const SizedBox(height: 30),

                // ------------------ REPORT DOWNLOAD SECTION ------------------
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedMonth,
                        items: months
                            .map((month) => DropdownMenuItem(
                                  value: month,
                                  child: Text(month),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedMonth = v);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select Month',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedYear,
                        items: years
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedYear = v);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select Year',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: isDownloadingReport
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                  label: const Text('SAVE REPORT'),
                  onPressed: isDownloadingReport ? null : _downloadReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
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