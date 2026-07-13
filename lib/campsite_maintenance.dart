import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/responsive_helper.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CampsitePage extends StatefulWidget {
  final int userId;

  const CampsitePage({super.key, required this.userId});

  @override
  State<CampsitePage> createState() => _CampsitePageState();
}

class _CampsitePageState extends State<CampsitePage> {
  Map<String, String> cleanlinessOptions = {
    'Toilet Clean': 'No',
    'Campsite Area Clean': 'No',
    'Tent Clean': 'No',
    'Trash Around': 'No',
  };

  Map<String, bool> damageAreas = {
    'Bench': false,
    'Board': false,
    'Tent': false,
    'Toilet': false,
    'Fence': false,
    'Other': false,
  };

  List<Map<String, String>> issueList = [
    {'type': 'Cleanliness', 'description': ''},
    {'type': 'Damage', 'description': ''},
    {'type': 'Toilet Issue', 'description': ''},
    {'type': 'Other', 'description': ''},
  ];

  List<TextEditingController> issueControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final TextEditingController _otherDamageController = TextEditingController();

  DateTime selectedDateTime = DateTime.now();
  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  String safeSnippet(String str, int length) {
    return str.length <= length ? str : '${str.substring(0, length)}...';
  }

  Future<void> _pickImage(BuildContext context) async {
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
                  _executePick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  _executePick(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executePick(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _image = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _submitReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      var uri = Uri.parse('https://devcms.com.my/charmsAPI/api/campsite-issues');
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = widget.userId.toString();
      request.fields['cleanliness'] = json.encode(cleanlinessOptions);

      List<String> selectedDamageStrings = damageAreas.entries
          .where((e) => e.value)
          .map((e) {
            if (e.key == 'Other' && _otherDamageController.text.isNotEmpty) {
              return "Other: ${_otherDamageController.text}";
            }
            return e.key;
          })
          .toList();

      request.fields['damage_area'] = json.encode(selectedDamageStrings);
      request.fields['campsite_issues'] = json.encode(issueList);

      if (_image != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          _imageBytes!,
          filename: 'campsite_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      // ✅ FIXED: Accept both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          // Parse response to get details
          try {
            final responseData = jsonDecode(respStr);
            final reportId = responseData['report_id'] ?? 'N/A';
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
              // RESET FORM AFTER DIALOG CLOSED
              setState(() {
                _image = null;
                cleanlinessOptions.updateAll((key, value) => 'No');
                damageAreas.updateAll((key, value) => false);

                for (var controller in issueControllers) {
                  controller.clear();
                }

                _otherDamageController.clear();

                issueList = [
                  {'type': 'Cleanliness', 'description': ''},
                  {'type': 'Damage', 'description': ''},
                  {'type': 'Toilet Issue', 'description': ''},
                  {'type': 'Other', 'description': ''},
                ];
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
                cleanlinessOptions.updateAll((key, value) => 'No');
                damageAreas.updateAll((key, value) => false);

                for (var controller in issueControllers) {
                  controller.clear();
                }

                _otherDamageController.clear();

                issueList = [
                  {'type': 'Cleanliness', 'description': ''},
                  {'type': 'Damage', 'description': ''},
                  {'type': 'Toilet Issue', 'description': ''},
                  {'type': 'Other', 'description': ''},
                ];
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

  Future<void> _selectDateTime(BuildContext pickerContext) async {
    final DateTime? pickedDate = await showDatePicker(
      context: pickerContext,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: pickerContext,
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

  String _roman(int number) {
    if (number < 1) return number.toString();
    final Map<int, String> romanMap = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    String result = '';
    int remaining = number;
    romanMap.forEach((value, numeral) {
      while (remaining >= value) {
        result += numeral;
        remaining -= value;
      }
    });
    return result;
  }

  @override
  void dispose() {
    for (var controller in issueControllers) {
      controller.dispose();
    }
    _otherDamageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF1),
      appBar: AppBar(
        title: const Text(
          'Campsite Maintenance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF05179),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Maintenance Schedule'),
                  _buildMaintenanceCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Submit Maintenance Issue'),
                  _buildIssueForm(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Facility Status'),
                  _buildFacilityStatusCard(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      );

  Widget _buildMaintenanceCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildScheduleItem(Icons.cleaning_services,
                  'Daily area cleaning at 7:00 AM'),
              _buildScheduleItem(Icons.wc, 'Toilet inspection every 3 days'),
              _buildScheduleItem(Icons.forest, 'Weekly tent inspection (Sunday)'),
              _buildScheduleItem(Icons.recycling, 'Trash disposal once a week'),
            ],
          ),
        ),
      );

  Widget _buildScheduleItem(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );

  Widget _buildIssueForm() {
    return Column(
      children: [
        ...issueList.asMap().entries.map((entry) {
          int idx = entry.key;
          Map<String, String> issue = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issue ${idx + 1}: ${issue['type']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: issueControllers[idx],
                    onChanged: (val) => issueList[idx]['description'] = val,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildImagePicker(),
        const SizedBox(height: 16),
        _buildDateTimePicker(),
      ],
    );
  }

  Widget _buildFacilityStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cleanliness Checklist',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Column(
              children:
                  cleanlinessOptions.keys.toList().asMap().entries.map((entry) {
                int idx = entry.key;
                String key = entry.value;
                String numberLabel = _roman(idx + 1);
                return Row(
                  children: [
                    Text('$numberLabel. $key'),
                    const Spacer(),
                    DropdownButton<String>(
                      value: cleanlinessOptions[key],
                      items: const [
                        DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                        DropdownMenuItem(value: 'No', child: Text('No')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          cleanlinessOptions[key] = val ?? 'No';
                        });
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
            const Divider(height: 20),
            const Text('Damage Areas',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Column(
              children: damageAreas.keys.map((key) {
                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(key),
                      value: damageAreas[key],
                      onChanged: (val) {
                        setState(() => damageAreas[key] = val ?? false);
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (key == 'Other' && damageAreas['Other'] == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: TextFormField(
                          controller: _otherDamageController,
                          decoration: InputDecoration(
                            labelText: 'Please specify other damage',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 1,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitReport(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: Colors.white),
                    SizedBox(width: 8),
                    Text('SUBMIT REPORT',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      );

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attach Photo', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
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
                    blurRadius: 6),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.white),
                SizedBox(width: 8),
                Text('Add Photo (Optional)',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        if (_image != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imageBytes!,
                  width: double.infinity, height: 160, fit: BoxFit.cover)),
        ],
      ],
    );
  }

  Widget _buildDateTimePicker() {
    final isTablet = ResponsiveHelper.isTablet(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: isTablet ? 14 : 10),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Date & Time',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: isTablet ? 18 : 16, color: Colors.black)),
          SizedBox(height: isTablet ? 14 : 10),
          ElevatedButton.icon(
            onPressed: () => _selectDateTime(context),
            icon: Icon(Icons.calendar_today, color: Colors.teal, size: isTablet ? 24 : 20),
            label: Text(
                'Selected: ${selectedDateTime.toLocal().toString().split('.')[0]}',
                style: TextStyle(color: Colors.black, fontSize: isTablet ? 16 : 14)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          )
        ]),
      ),
    );
  }
}