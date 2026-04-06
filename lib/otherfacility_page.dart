import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/responsive_helper.dart';

class Facility {
  final int id;
  final String name;
  final String location;
  final String status;
  final String lastChecked;
  final String category;

  Facility({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.lastChecked,
    required this.category,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      status: json['status'],
      lastChecked: json['last_checked'],
      category: json['category'],
    );
  }
}

class OtherFacilityPage extends StatefulWidget {
  const OtherFacilityPage({Key? key}) : super(key: key);

  @override
  State<OtherFacilityPage> createState() => _OtherFacilityPageState();
}

class _OtherFacilityPageState extends State<OtherFacilityPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  String _category = 'Education';

  final List<String> _categories = [
    'Education',
    'Research',
    'Equipment',
    'Sanitation',
    'Health'
  ];

  List<Facility> _facilities = [];
  bool _loading = false;
  bool _submitting = false;
  bool _isSavingReport = false;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    setState(() => _loading = true);
    final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/facilities');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final List data = jsonBody['data'] ?? [];

        setState(() {
          _facilities = data.map((f) => Facility.fromJson(f)).toList();
        });

        if (_facilities.isEmpty) {
          _showSnack('No facilities found');
        }
      } else {
        _showSnack('Failed to load facilities');
      }
    } catch (e) {
      _showSnack('Error fetching facilities: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _submitFacility() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitting = true);

      var uri = Uri.parse('https://devcms.com.my/charmsAPI/api/facilities');
      var request = http.MultipartRequest('POST', uri);
      request.fields['name'] = nameController.text;
      request.fields['location'] = locationController.text;
      request.fields['status'] = 'Operational';
      request.fields['last_checked'] = DateTime.now().toIso8601String();
      request.fields['category'] = _category;

      try {
        var response = await request.send();
        var responseBody = await http.Response.fromStream(response);

        if (response.statusCode == 200) {
          nameController.clear();
          locationController.clear();
          _showSnack('✅ Facility added successfully');
          await _fetchFacilities();
        } else {
          _showSnack('❌ Failed: ${responseBody.body}');
        }
      } catch (e) {
        _showSnack('⚠️ Error: $e');
      } finally {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _deleteFacility(int id) async {
    final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/facilities/$id');
    try {
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        _showSnack('Facility deleted');
        _fetchFacilities();
      } else {
        _showSnack('Delete failed');
      }
    } catch (e) {
      _showSnack('Error deleting facility: $e');
    }
  }

  Future<void> _saveFacilityReport() async {
    setState(() => _isSavingReport = true);

    final url = 'https://devcms.com.my/charmsAPI/api/facilities/save-report';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        final filePath =
            '${dir.path}/facility_report_${DateTime.now().millisecondsSinceEpoch}.html';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        _showSnack('✅ Report saved to Downloads: $filePath');
      } else {
        _showSnack('❌ Failed: ${response.body}');
      }
    } catch (e) {
      _showSnack('⚠️ Error: $e');
    }

    setState(() => _isSavingReport = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------- PAGE EXPLANATION WIDGET ----------------------
  Widget _buildPageGuidance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_add, color: Colors.teal.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                'Facility Registry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use this page to register any new assets, specialized equipment, or additional facilities '
            'that are not included in the standard categories. Keeping this list updated ensures '
            'every facility is tracked and included in our maintenance schedules.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.teal.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: const Text(
          'Facility Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF05179),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh List",
            onPressed: _fetchFacilities,
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Added guidance notes at the top
            _buildPageGuidance(),
            const SizedBox(height: 20),

            // --- Form Card ---
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add New Facility',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Facility Name',
                          prefixIcon: const Icon(Icons.home_work),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField(
                        value: _category,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() {
                          _category = value.toString();
                        }),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitFacility,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          label: Text(
                            _submitting ? 'Submitting...' : 'Submit',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF05179),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingReport ? null : _saveFacilityReport,
                icon: _isSavingReport
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSavingReport ? 'Saving...' : 'Save Report',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text('Facility List',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : _facilities.isEmpty
                    ? const Center(
                        child: Text('No facilities found.',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _facilities.length,
                        itemBuilder: (context, index) {
                          final facility = _facilities[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade200,
                                child: const Icon(Icons.business,
                                    color: Colors.white),
                              ),
                              title: Text(facility.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('📍 ${facility.location}'),
                                  Text('📂 ${facility.category}'),
                                  Text('⚡ Status: ${facility.status}'),
                                  Text('🕒 Last Checked: ${facility.lastChecked}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteFacility(facility.id),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
