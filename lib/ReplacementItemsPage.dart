import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/responsive_helper.dart';

class ReplacementItemsPage extends StatefulWidget {
  final int userId; // ✅ required

  const ReplacementItemsPage({super.key, required this.userId});

  @override
  State<ReplacementItemsPage> createState() => _ReplacementItemsPageState();
}

class _ReplacementItemsPageState extends State<ReplacementItemsPage> {
  final Map<String, List<String>> facilityItems = {
    "Campsite": ["No replacement items required for this facility.", "Bench", "Board", "Tent", "Other"],
    "Kitchen": ["No replacement items required for this facility.", "Fridge", "Water Filter", "Kitchenware", "Other"],
    "Quarters": [
      "No replacement items required for this facility.",
      "Lights",
      "Fans",
      "Sockets",
      "Switches",
      "Bed",
      "Mattress",
      "Bed Frame",
      "Table",
      "Sheets",
      "Pillow",
      "Other"
    ],
    "Outdoor Classroom": ["No replacement items required for this facility.", "Benches", "Board", "Other"],
    "Water Sport Area": ["No replacement items required for this facility.", "Kayak", "Kayak's Paddle", "Life Jacket", "Snorkel", "Mask", "Stand Up PaddleBoard (SUP)", "Other"],
    "Office": [
      "No replacement items required for this facility.",
      "Desk",
      "Bookshelf",
      "Chairs",
      "Tables",
      "Cabinets",
      "Lights",
      "Fans",
      "Sockets",
      "Stationaries",
      "Other"
    ],
    "BalaiSaf (Surau)": ["No replacement items required for this facility.", "Prayer Mat", "Speaker", "Other"],
  };

  final Map<String, Map<String, bool>> checkedItems = {};
  final Map<String, Map<String, TextEditingController>> descriptions = {};
  final Map<String, List<XFile>> facilityImages = {};
  final Map<String, List<Uint8List>> facilityImageBytes = {};

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false; // ✅ for loading state

  @override
  void initState() {
    super.initState();
    facilityItems.forEach((facility, items) {
      checkedItems[facility] = {};
      descriptions[facility] = {};
      facilityImages[facility] = [];
      facilityImageBytes[facility] = [];
      for (var item in items) {
        checkedItems[facility]![item] = false;
        descriptions[facility]![item] = TextEditingController();
      }
    });
  }

  @override
  void dispose() {
    for (var facility in descriptions.keys) {
      for (var controller in descriptions[facility]!.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future pickImage(String facility) async {
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
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 50,
                  );
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      facilityImages[facility]!.add(pickedFile);
                      facilityImageBytes[facility]!.add(bytes);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.teal),
                title: const Text('Camera (Take Photo)'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 50,
                  );
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      facilityImages[facility]!.add(pickedFile);
                      facilityImageBytes[facility]!.add(bytes);
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

  Widget buildFacilitySection(int index, String facility) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${index + 1}. $facility",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...facilityItems[facility]!.map((item) {
              bool isNoReplacement = item == "No replacement items required for this facility.";
              bool noReplacementChecked = checkedItems[facility]!["No replacement items required for this facility."]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: checkedItems[facility]![item],
                      title: Text(item),
                      onChanged: (val) {
                        setState(() {
                          checkedItems[facility]![item] = val!;

                          if (isNoReplacement && val == true) {
                            for (var otherItem in facilityItems[facility]!) {
                              if (otherItem != item) {
                                checkedItems[facility]![otherItem] = false;
                                descriptions[facility]![otherItem]!.clear();
                              }
                            }
                          }
                        });
                      },
                    ),
                    if (!isNoReplacement &&
                        checkedItems[facility]![item] == true &&
                        !noReplacementChecked)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: TextField(
                          controller: descriptions[facility]![item],
                          decoration: InputDecoration(
                            hintText: "Enter $item description",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            Row(
              children: [
                ...facilityImageBytes[facility]!.map((bytes) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(bytes, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                    )),
                ElevatedButton.icon(
                  onPressed: () => pickImage(facility),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text("Upload", style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submit() async {
    // Check if at least one item is selected
    bool hasData = false;
    checkedItems.forEach((facility, items) {
      items.forEach((item, checked) {
        if (checked && item != "No replacement items required for this facility.") {
          hasData = true;
        }
      });
    });

    if (!hasData) {
      _showErrorDialog(context, "Please select at least one replacement item before submitting.");
      return;
    }

    setState(() => _isSubmitting = true);

    final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/replacement-item');
    bool success = false;
    String? responseReportId;
    String? responseSubmitter;
    String? responseSubmitterType;

    for (var facility in checkedItems.keys) {
      var itemsList = <Map<String, dynamic>>[];

      checkedItems[facility]!.forEach((item, checked) {
        if (checked && item != "No replacement items required for this facility.") {
          itemsList.add({
            'item_name': item,
            'description': descriptions[facility]![item]!.text,
            'photos': []
          });
        }
      });

      if (itemsList.isEmpty) continue;

      var request = http.MultipartRequest('POST', uri);
      request.fields['facility'] = facility;
      request.fields['date'] = DateTime.now().toIso8601String();
      request.fields['user_id'] = widget.userId.toString(); // ✅ send user_id

      for (int i = 0; i < itemsList.length; i++) {
        request.fields['items[$i][item_name]'] = itemsList[i]['item_name'];
        request.fields['items[$i][description]'] = itemsList[i]['description'] ?? '';

        for (int j = 0; j < facilityImages[facility]!.length; j++) {
          request.files.add(http.MultipartFile.fromBytes(
            'items[$i][photos][$j]',
            facilityImageBytes[facility]![j],
            filename: facilityImages[facility]![j].name,
          ));
        }
      }

      try {
        var response = await request.send();
        final resStr = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          success = true;
          // Parse response to get details
          try {
            final responseData = jsonDecode(resStr);
            responseReportId = responseData['report_id']?.toString() ?? 'N/A';
            responseSubmitter = responseData['submitter'] ?? 'User';
            responseSubmitterType = responseData['submitter_type'] ?? 'Reporter';
          } catch (e) {
            // ignore parsing errors
          }
        } else {
          _showErrorDialog(context,
              'Failed to submit $facility.\nStatus: ${response.statusCode}\nResponse: $resStr');
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to submit $facility.\nError: $e');
      }
    }

    setState(() => _isSubmitting = false);

    if (success) {
      _showSuccessDialog(
        context,
        'Report submitted successfully! ✅\n\n'
        'Report ID: ${responseReportId ?? 'N/A'}\n'
        'Submitted by: ${responseSubmitter ?? 'User'} (${responseSubmitterType ?? 'Reporter'})\n'
        'Managers have been notified.',
      ).then((_) {
        // Reset form after dialog closed
        _resetForm();
      });
    }
  }

  void _resetForm() {
    setState(() {
      checkedItems.forEach((facility, items) {
        items.forEach((key, _) {
          checkedItems[facility]![key] = false;
          descriptions[facility]![key]!.clear();
        });
      });
      facilityImages.forEach((facility, images) {
        facilityImages[facility]!.clear();
        facilityImageBytes[facility]!.clear();
      });
    });
  }

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
        title: const Text(
          "Replacement Items",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                ...facilityItems.keys
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) => buildFacilitySection(entry.key, entry.value))
                    ,
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _isSubmitting ? "SUBMITTING..." : "Submit Replacement",
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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