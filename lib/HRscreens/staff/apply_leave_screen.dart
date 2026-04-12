import 'dart:convert';

import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Add this package

class LeaveFormScreen extends StatefulWidget {
  final int staffId;

  const LeaveFormScreen({
    Key? key,
    required this.staffId,
  }) : super(key: key);

  @override
  _LeaveFormScreenState createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  String? _selectedProofType;
  DateTime? _startDate;
  DateTime? _endDate;
  TextEditingController _reasonController = TextEditingController();
  XFile? _attachedImage;
  XFile? _attachedFile;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
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

  Future<void> _submitLeave() async {
    if (_formKey.currentState!.validate()) {
      try {
        final leavesProvider = Provider.of<Leaves>(context, listen: false);

        // Convert image to base64 if attached
        String? base64Image;
        if (_attachedFile != null) {
          final bytes = await _attachedFile!.readAsBytes();
          base64Image = base64Encode(bytes);
        }

        final newLeave = Leave(
          leaveId: 0,
          staffId: widget.staffId,
          leaveType: _selectedLeaveType!,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text,
          proofFileName: _attachedFile?.name,
          proofFileType: _selectedProofType!,
          proofFile:
              _attachedFile != null ? await _attachedFile!.readAsBytes() : null,
          status: 'Pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await leavesProvider.createLeave(newLeave);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave application submitted successfully')),
        );

        Navigator.pop(context, true);
      } catch (error) {
        print('Error details: $error'); // Add this for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit leave: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Apply for Leave",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedLeaveType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLeaveType = newValue;
                  });
                },
                items: <String>[
                  'Annual Leave',
                  'Sick Leave',
                  'Maternity Leave',
                  'Paternity Leave',
                  'Emergency Leave',
                  'Unpaid Leave',
                  'Bereavement',
                  'Quarantine',
                  'Half Day Leave 1',
                  'Half Day Leave 2'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a leave type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _startDate == null
                          ? ''
                          : DateFormat('dd/MM/yyyy').format(_startDate!),
                    ),
                    validator: (value) {
                      if (_startDate == null) {
                        return 'Please select a start date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectDate(context, false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _endDate == null
                          ? ''
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                    ),
                    validator: (value) {
                      if (_endDate == null) {
                        return 'Please select an end date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for Leave',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a reason for leave';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Proof Type',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedProofType,
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
              SizedBox(height: 20),
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
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitLeave,
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
