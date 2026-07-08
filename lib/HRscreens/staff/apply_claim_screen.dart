import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';

class ApplyClaimScreen extends StatefulWidget {
  final int staffId;

  const ApplyClaimScreen({
    super.key,
    required this.staffId,
  });

  @override
  State<ApplyClaimScreen> createState() => _ApplyClaimScreenState();
}

class _ApplyClaimScreenState extends State<ApplyClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClaimType;
  String? _selectedProofType;
  DateTime? _claimDate;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _attachedBytes;
  String? _attachedFileName;
  bool _submitting = false;

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5); // Deep Indigo
  final Color staffBg = const Color(0xFFF8FAFC); // Very Light Slate

  final List<String> _claimTypes = const [
    'Travel',
    'Medical',
    'Food',
    'Groceries',
    'Accommodation',
    'Fuel',
    'Other'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _detectProofType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return 'Image';
    }
    return 'PDF';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: staffPrimary,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _claimDate = picked);
    }
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: staffPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_rounded, color: staffPrimary),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: staffPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.photo_library_rounded, color: staffPrimary),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: staffPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.attach_file_rounded, color: staffPrimary),
                  ),
                  title: const Text('Choose File (PDF/Image)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _attachedBytes = bytes;
        _attachedFileName = image.name;
        _selectedProofType = 'Image';
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true, // IMPORTANT for web/PWA
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      // For web: bytes is used
      // For mobile/desktop: bytes may be null unless withData=true (we enabled it)
      final bytes = file.bytes;
      final name = file.name;

      if (bytes != null) {
        setState(() {
          _attachedBytes = bytes;
          _attachedFileName = name;
          _selectedProofType = _detectProofType(name);
        });
      } else {
        // fallback (rare)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file bytes. Please try again.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final claimsProvider = Provider.of<Claims>(context, listen: false);

      final newClaim = Claim(
        claimId: 0,
        staffId: widget.staffId,
        claimType: _selectedClaimType!,
        amount: double.parse(_amountController.text),
        claimDate: _claimDate!,
        description: _descriptionController.text,
        proofFileName: _attachedFileName,
        proofFileType: _selectedProofType,
        proofFile: _attachedBytes,
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await claimsProvider.createClaim(newClaim);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim submitted successfully'), backgroundColor: Colors.teal),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim: $error'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Helper to build consistent inputs
  InputDecoration _buildInputDecoration(String label, IconData icon, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixText: prefixText,
      prefixStyle: TextStyle(color: staffPrimary, fontWeight: FontWeight.bold, fontSize: 16),
      prefixIcon: Icon(icon, color: staffPrimary.withOpacity(0.7), size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: staffPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachedLabel = (_attachedFileName != null && _attachedFileName!.isNotEmpty)
        ? 'Attached: $_attachedFileName'
        : 'Attach Document (Optional)';

    return Scaffold(
      backgroundColor: staffBg, // Modern background
      appBar: const StaffAppBar(title: 'APPLY CLAIM'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: StaffPageContainer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: staffPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.request_quote_rounded, size: 40, color: staffPrimary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
                    decoration: _buildInputDecoration('Claim Type', Icons.category_rounded),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: staffPrimary),
                    initialValue: _selectedClaimType,
                    items: _claimTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please select a claim type' : null,
                    onChanged: (value) => setState(() => _selectedClaimType = value),
                  ),
                  const SizedBox(height: 16),
                  
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _buildInputDecoration('Claim Date', Icons.date_range_rounded).copyWith(
                          suffixIcon: Icon(Icons.calendar_today_rounded, color: staffPrimary.withOpacity(0.7)),
                        ),
                        controller: TextEditingController(
                          text: _claimDate == null
                              ? ''
                              : DateFormat('dd MMM yyyy').format(_claimDate!),
                        ),
                        validator: (_) => _claimDate == null ? 'Please select a date' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _amountController,
                    decoration: _buildInputDecoration('Amount', Icons.attach_money_rounded, prefixText: 'RM '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter an amount';
                      if (double.tryParse(value) == null) return 'Please enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _buildInputDecoration('Description', Icons.subject_rounded),
                    maxLines: 3,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: _buildInputDecoration('Proof Type (Optional)', Icons.file_present_rounded),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: staffPrimary),
                    initialValue: _selectedProofType,
                    onChanged: (proofValue) => setState(() => _selectedProofType = proofValue),
                    items: const ['Image', 'PDF']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            attachedLabel,
                            style: TextStyle(
                              fontSize: 14, 
                              color: _attachedFileName != null ? staffPrimary : Colors.grey.shade600,
                              fontWeight: _attachedFileName != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showAttachmentOptions,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: staffPrimary,
                            side: BorderSide(color: staffPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Attach'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submitClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Modern submit color
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _submitting 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit Claim',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}