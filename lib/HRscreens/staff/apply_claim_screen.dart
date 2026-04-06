
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
    Key? key,
    required this.staffId,
  }) : super(key: key);

  @override
  _ApplyClaimScreenState createState() => _ApplyClaimScreenState();
}

class _ApplyClaimScreenState extends State<ApplyClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClaimType;
  String? _selectedProofType;
  DateTime? _claimDate;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _attachedFile;

  final List<String> _claimTypes = [
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _claimDate = picked;
      });
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
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file),
                title: Text('Choose File'),
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _attachedFile = image;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _attachedFile = XFile(result.files.single.path!);
      });
    }
  }

  Future<void> _submitClaim() async {
  if (_formKey.currentState!.validate() && _selectedProofType != null) {
    try {
      final claimsProvider = Provider.of<Claims>(context, listen: false);
      
      final newClaim = Claim(
        claimId: 0,
        staffId: widget.staffId,
        claimType: _selectedClaimType!,
        amount: double.parse(_amountController.text),
        claimDate: _claimDate!,
        description: _descriptionController.text,
        proofFileName: _attachedFile?.name,
        proofFileType: _selectedProofType,
        proofFile: _attachedFile != null ? await _attachedFile!.readAsBytes() : null,
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await claimsProvider.createClaim(newClaim);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claim submitted successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim. Please try again.')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply Claim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Claim Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClaimType,
                items: _claimTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a claim type';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedClaimType = value;
                  });
                },
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Claim Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _claimDate == null
                          ? ''
                          : DateFormat('dd/MM/yyyy').format(_claimDate!),
                    ),
                    validator: (value) {
                      if (_claimDate == null) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Proof Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProofType,
                onChanged: (String? proofValue) {
                  setState(() {
                    _selectedProofType = proofValue;
                  });
                },
                items: <String>[
                  'Image',
                  'PDF',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a proof type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _attachedFile != null
                          ? "Attached: ${_attachedFile!.name}"
                          : 'Attach Document (Optional)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.attach_file),
                    label: Text("Attach"),
                    onPressed: _showAttachmentOptions,
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
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