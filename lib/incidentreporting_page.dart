import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:charms/utils/download_bytes.dart';
import 'package:charms/utils/responsive_helper.dart';

class IncidentReportingPage extends StatefulWidget {
  final int userId;  // <-- added

  const IncidentReportingPage({super.key, required this.userId});

  @override
  State<IncidentReportingPage> createState() => _IncidentReportingPageState();
}

class _IncidentReportingPageState extends State<IncidentReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final reporterController = TextEditingController();
  final happenTimeController = TextEditingController();

  String _category = 'Facility Safety';
  String _severity = 'Low';
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _imageUploadTime;

  bool _isViewing = false;
  bool _isDownloading = false;

  final List<String> _categories = [
    'Facility Safety',
    'First Aid',
    'Equipment Failure',
    'Wildlife Encounter',
    'Weather Hazard',
    'Human/Crime Incident',
    'Other'
  ];
  final List<String> _severityLevels = ['Low', 'Medium', 'High', 'Critical'];
  final ImagePicker _picker = ImagePicker();

  String _selectedYear = '2025';
  String _selectedMonthWord = 'January';
  String _selectedFilterCategory = 'All Categories';
  final List<String> _years = ['2025', '2026', '2027', '2028', '2029', '2030'];
  final List<String> _monthsWord =
      List.generate(12, (i) => DateFormat('MMMM').format(DateTime(0, i + 1)));

  DateTime? _incidentHappenTime;

  // For scroll reset after submission
  final ScrollController _scrollController = ScrollController();

  Future<void> _pickImage() async {
    await Permission.camera.request();
    await Permission.photos.request();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Photo Library'),
                onTap: () => _handleImageSource(ImageSource.gallery, bc),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () => _handleImageSource(ImageSource.camera, bc),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImageSource(ImageSource source, BuildContext bc) async {
    Navigator.pop(bc);
    final pickedFile =
        await _picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = pickedFile;
        _imageBytes = bytes;
        _imageUploadTime = DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.now());
      });
    }
  }

  Future<void> _pickHappenTime() async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute);
        setState(() {
          _incidentHappenTime = dt;
          happenTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_incidentHappenTime!);
        });
      }
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uri = Uri.parse('https://devcms.com.my/charmsAPI/api/incidents');
    final request = http.MultipartRequest('POST', uri)
      ..fields['title'] = titleController.text
      ..fields['description'] = descController.text
      ..fields['category'] = _category
      ..fields['severity'] = _severity
      ..fields['location'] = locationController.text
      ..fields['reporter'] = reporterController.text
      ..fields['user_id'] = widget.userId.toString()    // <-- added
      ..fields['happen_time'] = _incidentHappenTime?.toIso8601String() ?? ''
      ..fields['timestamp'] = DateTime.now().toIso8601String();

    if (_image != null) {
      request.fields['photo_uploaded_at'] = _imageUploadTime ?? '';
      request.files.add(http.MultipartFile.fromBytes(
          'photo', _imageBytes!, filename: _image!.name));
    }

    try {
      final streamed = await request.send();
      final responseBody = await http.Response.fromStream(streamed);

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        // Parse response to show success dialog
        try {
          final jsonBody = jsonDecode(responseBody.body);
          final reportId = jsonBody['report_id'] ?? 'N/A';
          final submitterName = jsonBody['submitter'] ?? 'User';
          final submitterType = jsonBody['submitter_type'] ?? 'Reporter';

          _showSuccessDialog(
            context,
            'Incident reported successfully! ✅\n\n'
            'Report ID: $reportId\n'
            'Submitted by: $submitterName ($submitterType)\n'
            'Managers have been notified.',
          ).then((_) {
            _resetForm();
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut);
          });
        } catch (e) {
          // If JSON parsing fails, show generic success
          _showSuccessDialog(
            context,
            'Incident reported successfully! ✅\n\n'
            'You can now submit a new report.',
          ).then((_) {
            _resetForm();
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut);
          });
        }
      } else {
        _showSnack('❌ Submission failed: ${responseBody.body}', Colors.red);
      }
    } catch (e) {
      _showSnack('❌ Error submitting incident: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      titleController.clear();
      descController.clear();
      locationController.clear();
      reporterController.clear();
      happenTimeController.clear();
      _category = 'Facility Safety';
      _severity = 'Low';
      _image = null;
      _imageUploadTime = null;
      _incidentHappenTime = null;
    });
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _monthWordToNumber(String monthWord) =>
      DateFormat('MM').format(DateFormat('MMMM').parse(monthWord));

  Future<void> _fetchIncidents() async {
    setState(() => _isViewing = true);
    final categoryQuery = _selectedFilterCategory == 'All Categories'
        ? ''
        : '&category=${Uri.encodeQueryComponent(_selectedFilterCategory)}';
    final monthNumber = int.parse(_monthWordToNumber(_selectedMonthWord));
    final url = Uri.parse(
        'https://devcms.com.my/charmsAPI/api/incidents/list?year=$_selectedYear&month=$monthNumber$categoryQuery');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isEmpty) {
          _showSnack('ℹ️ No incidents found for the selected filters.',
              Colors.blueGrey);
          return;
        }

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Column(
              children: [
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("📋 List of Incidents",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final item = data[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: Text(item['category'] ?? '-',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue)),
                                  ),
                                  Text(item['severity'] ?? '-',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: item['severity'] == 'Critical'
                                              ? Colors.red
                                              : Colors.orange)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(item['title'] ?? '-',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              const Divider(),
                              _buildInfoRow(Icons.access_time, "Happen Time",
                                  item['happen_time'] ?? '-'),
                              _buildInfoRow(Icons.description, "Description",
                                  item['description'] ?? '-'),
                              _buildInfoRow(Icons.location_on, "Location",
                                  item['location'] ?? '-'),
                              _buildInfoRow(Icons.person, "Reporter",
                                  item['reporter'] ?? '-'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack("❌ Error: $e", Colors.red);
    } finally {
      setState(() => _isViewing = false);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReport() async {
    setState(() => _isDownloading = true);
    final categoryQuery = _selectedFilterCategory == 'All Categories'
        ? ''
        : '&category=${Uri.encodeComponent(_selectedFilterCategory)}';
    final monthNumber = _monthWordToNumber(_selectedMonthWord);
    final url =
        'https://devcms.com.my/charmsAPI/api/incidents/save-report?year=$_selectedYear&month=$monthNumber$categoryQuery';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fileName =
            'incident_report_${DateTime.now().millisecondsSinceEpoch}.html';
        await downloadBytes(bytes: response.bodyBytes, fileName: fileName);
        _showSnack('✅ HTML Report downloaded', Colors.green);
      }
    } catch (e) {
      _showSnack('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Widget _buildPageGuidance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF05179).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF05179).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.report_problem_outlined,
                  color: Color(0xFFF05179), size: 24),
              SizedBox(width: 8),
              Text(
                'Incident Reporting Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF05179),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Safety is our priority. Please use this form to report any accidents, safety hazards, or unusual incidents that occur on-site. Provide accurate details and photos to help management respond effectively.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
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
      backgroundColor: const Color(0xFFEEF1F4),
      appBar: AppBar(
          title: const Text('🚨 Report Incident'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF05179),
          foregroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: padding,
            child: Form(
              key: _formKey,
              child: Column(children: [
                _buildPageGuidance(),
                const SizedBox(height: 16),
                _buildIncidentForm(),
                const SizedBox(height: 24),
                _buildViewDownloadSection(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentForm() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("📝 Incident Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _category = val!),
            decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: 'Incident Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          TextFormField(
              controller: happenTimeController,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Incident Happen Time',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder()),
              onTap: _pickHappenTime,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          TextFormField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder()),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            items: _severityLevels
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => _severity = val!),
            decoration: const InputDecoration(
                labelText: 'Severity',
                prefixIcon: Icon(Icons.warning_amber),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          TextFormField(
              controller: reporterController,
              decoration: const InputDecoration(
                  labelText: 'Reporter Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 20),
          if (_image != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover)),
          if (_image != null) const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: Text(_image != null ? 'Change Photo' : 'Upload Photo'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitIncident,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(_isLoading ? "Submitting..." : "Submit Incident"),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF05179),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
    );
  }

  Widget _buildViewDownloadSection() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("📊 View & Download Reports",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedFilterCategory,
            isExpanded: true,
            items: ['All Categories', ..._categories]
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() => _selectedFilterCategory = val!),
            decoration: const InputDecoration(
                labelText: 'Filter by Category',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Flexible(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedYear,
                  isExpanded: true,
                  items: _years
                      .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(y, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                  decoration: const InputDecoration(
                      labelText: 'Year', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMonthWord,
                  isExpanded: true,
                  items: _monthsWord
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMonthWord = v!),
                  decoration: const InputDecoration(
                      labelText: 'Month', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: _isViewing ? null : _fetchIncidents,
                    icon: _isViewing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.list, size: 18),
                    label: const Text("View", style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(140, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _saveReport,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, size: 18),
                    label: const Text("Save Report",
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(140, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    reporterController.dispose();
    happenTimeController.dispose();
    super.dispose();
  }
}