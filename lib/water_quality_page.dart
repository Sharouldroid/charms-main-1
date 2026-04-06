import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/responsive_helper.dart';

class WaterQualityPage extends StatefulWidget {
  final int userId; // ✅ required

  const WaterQualityPage({super.key, required this.userId});

  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController locationController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  // Data Values
  final Map<String, String> _formData = {
    'Total Alkalinity': '',
    'Sodium Chloride': '',
    'Fluoride': '',
    'Zinc': '',
    'Sulfate': '',
    'Nitrate': '',
    'Nitrite': '',
    'Total Chlorine': '',
    'Manganese': '',
    'Copper': '',
    'Iron': '',
    'Hydrogen Sulfide': '',
    'Hardness': '',
    'pH': '',
  };

  // Lab Test Status
  String labTestStatus = 'Pending';
  final List<String> statusOptions = ['Passed / Safe', 'Failed / Unsafe', 'Pending'];

  // Date & Time
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

  // Report Generation Variables
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
      locationController.clear();
      _formData.updateAll((key, value) => '');
      remarksController.clear();
      labTestStatus = 'Pending';
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
    });
    _formKey.currentState?.reset();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  // ------------------ SUBMIT LOGIC ------------------
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/water-quality');
      var request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['location'] = locationController.text;
      request.fields['remarks'] = remarksController.text;
      request.fields['lab_status'] = labTestStatus;
      request.fields['report_time'] = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ).toIso8601String();
      request.fields['user_id'] = widget.userId.toString(); // ✅ send user_id

      // Add chemical parameters
      _formData.forEach((key, value) {
        String apiField = key.toLowerCase().replaceAll(' ', '_');
        request.fields[apiField] = value;
      });

      final response = await request.send();
      final resStream = await http.Response.fromStream(response);
      final responseData = jsonDecode(resStream.body);

      // Accept both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
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
            // Auto clear form after dialog closed
            _resetForm();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${responseData['message'] ?? resStream.body}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Exception: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

    final url = 'https://devcms.com.my/charmsAPI/api/water-quality/report?month=$selectedMonth&year=$selectedYear';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir.createSync(recursive: true);

        // Get filename from Server Headers (Malaysia Time)
        String fileName = 'water_quality_report_${DateTime.now().millisecondsSinceEpoch}.html';
        String? contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          fileName = contentDisposition.split('filename=')[1].replaceAll('"', '').trim();
        }

        final filePath = '${dir.path}/$fileName';
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
      if (mounted) setState(() => isDownloadingReport = false);
    }
  }

  // ------------------ UI WIDGETS ------------------
  Widget _buildParameterField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixText: label == 'pH' ? '' : 'mg/L',
        ),
        onChanged: (val) => _formData[label] = val,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFB9C4CA),
      appBar: AppBar(
        title: const Text('Water Quality Check'),
        backgroundColor: const Color(0xFFF05179),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 1. Location & Date Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sample Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: locationController,
                            decoration: InputDecoration(
                              labelText: 'Sampling Location',
                              hintText: 'e.g., Main Tank',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Please enter a location' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Date',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                                    ),
                                    child: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickTime,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Time',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      prefixIcon: const Icon(Icons.access_time, color: Colors.teal),
                                    ),
                                    child: Text(selectedTime.format(context)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Chemical Parameters
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chemical Parameters',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 16),
                          _buildParameterField('pH'),
                          _buildParameterField('Total Chlorine'),
                          _buildParameterField('Total Alkalinity'),
                          _buildParameterField('Sodium Chloride'),
                          _buildParameterField('Fluoride'),
                          _buildParameterField('Zinc'),
                          _buildParameterField('Sulfate'),
                          _buildParameterField('Nitrate'),
                          _buildParameterField('Nitrite'),
                          _buildParameterField('Manganese'),
                          _buildParameterField('Copper'),
                          _buildParameterField('Iron'),
                          _buildParameterField('Hydrogen Sulfide'),
                          _buildParameterField('Hardness'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Lab Test Result
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lab Test Evaluation',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: labTestStatus,
                            decoration: InputDecoration(
                              labelText: 'Overall Compliance Status',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.science, color: Colors.purple),
                            ),
                            items: statusOptions.map((status) {
                              Color statusColor = Colors.black;
                              if (status.contains('Passed')) statusColor = Colors.green;
                              if (status.contains('Failed')) statusColor = Colors.red;
                              if (status.contains('Pending')) statusColor = Colors.orange;
                              return DropdownMenuItem(
                                  value: status,
                                  child: Text(status,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)));
                            }).toList(),
                            onChanged: (val) => setState(() => labTestStatus = val!),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Remarks
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Additional Notes',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: remarksController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Remarks (Optional)',
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Submit Button
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitData,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Submitting...' : 'SUBMIT REPORT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
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
                          value: selectedMonth,
                          items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => selectedMonth = v),
                          decoration: const InputDecoration(
                            labelText: 'Select Month',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() => selectedYear = v),
                          decoration: const InputDecoration(
                            labelText: 'Select Year',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: isDownloadingReport
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
      ),
    );
  }
}