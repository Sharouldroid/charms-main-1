import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:charms/utils/responsive_helper.dart';

class FirstAidPage extends StatefulWidget {
  final int userId; // ✅ required

  const FirstAidPage({super.key, required this.userId});

  @override
  State<FirstAidPage> createState() => _FirstAidPageState();
}

class _FirstAidPageState extends State<FirstAidPage> {
  // Contents grouped by type
  final Map<String, List<Map<String, dynamic>>> contentsByType = {
    'Bandages & Dressings': [
      {'name': 'Large Sterile Dressings', 'qty': 3},
      {'name': 'Elastic Bandages', 'qty': 3},
      {'name': 'Adhesive Bandages (Assorted Sizes)', 'qty': 3},
    ],
    'Tools & Equipment': [
      {'name': 'Stretcher (Foldable)', 'qty': 3},
      {'name': 'Tourniquet', 'qty': 3},
      {'name': 'Splints (Assorted Sizes)', 'qty': 3},
      {'name': 'Trauma Shears', 'qty': 3},
      {'name': 'Scissors (Medical Grade)', 'qty': 3},
      {'name': 'Tweezers', 'qty': 3},
    ],
    'Protective Gear & Essentials': [
      {'name': 'Eye Wash Solution', 'qty': 3},
      {'name': 'Emergency Blanket (Thermal)', 'qty': 3},
      {'name': 'Disposable Gloves', 'qty': 3},
      {'name': 'Cold Packs (Instant)', 'qty': 3},
      {'name': 'Basic First Aid Manual', 'qty': 3},
      {'name': 'Whistle', 'qty': 3},
      {'name': 'Flashlight', 'qty': 3},
      {'name': 'Resealable Plastic Bags', 'qty': 3},
    ],
  };

  // Medical supplies grouped by type
  final Map<String, List<Map<String, dynamic>>> medicalsByType = {
    'Pain Relief & Medicines': [
      {'name': 'Paracetamol', 'qty': 3},
      {'name': 'Ibuprofen', 'qty': 3},
      {'name': 'Pain Relievers', 'qty': 3},
      {'name': 'Cough Syrup', 'qty': 3},
      {'name': 'Eye Drops', 'qty': 3},
    ],
    'Wound Care': [
      {'name': 'Antiseptic Wipes', 'qty': 3},
      {'name': 'Antiseptic Cream/Ointment', 'qty': 3},
      {'name': 'Sterile Gauze Pads', 'qty': 3},
      {'name': 'Medical Tape', 'qty': 3},
      {'name': 'Elastic Bandages (Assorted Sizes)', 'qty': 3},
    ],
    'Other First Aid Items': [
      {'name': 'Cold Packs (Instant)', 'qty': 3},
      {'name': 'Burn Gel Packs', 'qty': 3},
      {'name': 'Thermometer (Digital)', 'qty': 3},
      {'name': 'CPR Face Shield', 'qty': 3},
      {'name': 'Eye Wash Solution', 'qty': 3},
      {'name': 'Alcohol Swabs', 'qty': 3},
      {'name': 'First Aid Manual', 'qty': 3},
    ],
  };

  Map<String, String?> expiredItems = {};
  String status = 'Fully Stocked';
  String restockDescription = "";
  File? image;
  bool isSubmitting = false;
  bool isDownloadingReport = false;

  List<Map<String, dynamic>> kits = [];

  // Month/Year dropdowns
  String? selectedMonth;
  String? selectedYear;
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> years = ['2025', '2026', '2027'];

  @override
  void initState() {
    super.initState();
    // Initialize expiry dates for all medical items
    for (var group in medicalsByType.values) {
      for (var med in group) {
        expiredItems[med['name']] = null;
      }
    }
    _fetchKits();
  }

  // Fetch latest kits
  Future<void> _fetchKits() async {
    try {
      final response =
          await http.get(Uri.parse('https://devcms.com.my/charmsAPI/api/firstaid'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            kits = List<Map<String, dynamic>>.from(data['kits']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching kits: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => image = File(picked.path));
  }

  Future<void> _pickExpiryDate(String itemName) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formatted =
          "${picked.year.toString().padLeft(4, '0')}-"
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

  Widget _buildExpiredSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ Expired Items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Column(
          children: medicalsByType.values.expand((group) {
            return group.map((med) {
              String? selectedDate = expiredItems[med['name']];
              Color textColor = _getExpiryColor(selectedDate);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        med['name'],
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: selectedDate)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: selectedDate?.length ?? 0),
                          ),
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          labelText: "Expiry Date",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                        onTap: () {
                          _pickExpiryDate(med['name']);
                        },
                      ),
                    ),
                  ],
                ),
              );
            });
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'ℹ️ Red = Expired, Orange = Expiring in less than 30 days',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(item['name']),
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
              onPressed: () {
                setState(() => item['qty']++);
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => isSubmitting = true);

    final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/firstaid');
    final req = http.MultipartRequest('POST', uri);

    // Flatten lists for JSON
    req.fields['contents'] = jsonEncode(contentsByType.values.expand((x) => x).toList());
    req.fields['medical_supplies'] = jsonEncode(medicalsByType.values.expand((x) => x).toList());
    req.fields['expired_items'] = jsonEncode(expiredItems);
    req.fields['status'] = status;
    req.fields['restock_description'] = restockDescription;
    req.fields['user_id'] = widget.userId.toString(); // ✅ send user_id

    if (image != null) {
      req.files.add(await http.MultipartFile.fromPath(
        'photo',
        image!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    try {
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      final responseData = jsonDecode(resp.body);

      // Accept both 200 and 201 as success
      if (resp.statusCode == 200 || resp.statusCode == 201) {
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
          // Reset form after dialog closed
          setState(() {
            for (var group in contentsByType.values) {
              for (var item in group) item['qty'] = 3;
            }
            for (var group in medicalsByType.values) {
              for (var item in group) item['qty'] = 3;
            }
            expiredItems.updateAll((key, value) => null);
            status = 'Fully Stocked';
            restockDescription = '';
            image = null;
          });
        });

        // Also refresh the list
        _fetchKits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: ${responseData['message'] ?? resp.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _downloadReportWithFilter() async {
    if (selectedMonth == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select month and year')),
      );
      return;
    }

    setState(() => isDownloadingReport = true);

    final url = 'https://devcms.com.my/charmsAPI/api/firstaid/report'
        '?month=$selectedMonth&year=$selectedYear';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        final filePath =
            '${dir.path}/firstaid_report_${selectedMonth}_${selectedYear}_${DateTime.now().millisecondsSinceEpoch}.html';
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
            SnackBar(content: Text('❌ Failed to download: ${response.body}')),
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
      setState(() => isDownloadingReport = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🩺 First Aid Kit'),
        backgroundColor: const Color(0xFFF05179),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🩹 Basic Contents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...contentsByType.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ...entry.value.map(_buildItemRow).toList(),
                  const Divider(),
                ]),

                const SizedBox(height: 10),
                const Text('💊 Medical Supplies',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...medicalsByType.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ...entry.value.map(_buildItemRow).toList(),
                  const Divider(),
                ]),

                const SizedBox(height: 10),
                _buildExpiredSection(),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'Fully Stocked', child: Text('Fully Stocked')),
                    DropdownMenuItem(value: 'Needs Restocking', child: Text('Needs Restocking')),
                  ],
                  onChanged: (v) => setState(() => status = v!),
                  decoration: const InputDecoration(
                      labelText: 'Kit Status', border: OutlineInputBorder()),
                ),

                const SizedBox(height: 20),

                if (status == 'Needs Restocking')
                  TextField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Describe items that need restocking",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      restockDescription = val;
                    },
                  ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            image!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.photo),
                  label: Text(image == null ? 'Add Photo' : 'Change Photo'),
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF05179),
                    side: const BorderSide(color: Color(0xFFF05179)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(isSubmitting ? 'SUBMITTING...' : 'SUBMIT'),
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF05179),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                const SizedBox(height: 16),

                // Month/Year dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMonth,
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
                        value: selectedYear,
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
                  onPressed:
                      isDownloadingReport ? null : _downloadReportWithFilter,
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