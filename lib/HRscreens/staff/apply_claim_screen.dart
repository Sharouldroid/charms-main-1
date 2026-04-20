import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRmodels/claim.dart';

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
    );
    if (picked != null) {
      setState(() => _claimDate = picked);
    }
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Choose File (PDF/Image)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
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
          const SnackBar(content: Text('Unable to read file bytes. Please try again.')),
        );
      }
    }
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    // Optional: require attachment
    // if (_attachedBytes == null || _attachedFileName == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please attach a proof file.')),
    //   );
    //   return;
    // }

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
        const SnackBar(content: Text('Claim submitted successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachedLabel = (_attachedFileName != null && _attachedFileName!.isNotEmpty)
        ? 'Attached: $_attachedFileName'
        : 'Attach Document (Optional)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Claim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Claim Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClaimType,
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
                    decoration: const InputDecoration(
                      labelText: 'Claim Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _claimDate == null
                          ? ''
                          : DateFormat('dd/MM/yyyy').format(_claimDate!),
                    ),
                    validator: (_) => _claimDate == null ? 'Please select a date' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Proof Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProofType,
                onChanged: (proofValue) => setState(() => _selectedProofType = proofValue),
                items: const ['Image', 'PDF']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please select a proof type' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      attachedLabel,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Attach"),
                    onPressed: _showAttachmentOptions,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Claim',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}