import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class LeaveFormScreen extends StatefulWidget {
  final int staffId;

  const LeaveFormScreen({
    super.key,
    required this.staffId,
  });

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLeaveType;
  String? _selectedProofType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  XFile? _attachedFile;
  bool _submitting = false;

  // leave types requiring proof
  final Set<String> _proofRequiredLeaveTypes = {
    'Sick Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Bereavement',
    'Quarantine',
  };

  bool get _isProofRequired =>
      _selectedLeaveType != null &&
      _proofRequiredLeaveTypes.contains(_selectedLeaveType);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStartDate
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked == null) return;

    setState(() {
      if (isStartDate) {
        _startDate = picked;
        // keep end date valid
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
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
                title: const Text('Choose File'),
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
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _attachedFile = image;
      _selectedProofType = 'Image';
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final ext = (file.extension ?? '').toLowerCase();

    setState(() {
      _attachedFile = XFile(file.path!);
      _selectedProofType =
          (ext == 'jpg' || ext == 'jpeg' || ext == 'png') ? 'Image' : 'PDF';
    });
  }

  Future<void> _submitLeave() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_isProofRequired) {
      if ((_selectedProofType ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select proof type.')),
        );
        return;
      }
      if (_attachedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof attachment is required for this leave type.')),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final leavesProvider = Provider.of<Leaves>(context, listen: false);

      final leave = Leave(
        leaveId: 0,
        staffId: widget.staffId,
        leaveType: _selectedLeaveType!,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text.trim(),
        proofFileName: _attachedFile?.name,
        proofFileType: _selectedProofType,
        proofFile: _attachedFile != null ? await _attachedFile!.readAsBytes() : null,
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await leavesProvider.createLeave(leave);
      await leavesProvider.getLeaveByStaffId(staffId: widget.staffId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave application submitted successfully')),
      );

      Navigator.pop(context, true); // tells previous screen to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit leave: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofLabel = _isProofRequired ? 'Proof Type *' : 'Proof Type (Optional)';
    final attachLabel = _isProofRequired ? 'Attach Document *' : 'Attach Document (Optional)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedLeaveType,
                onChanged: (value) {
                  setState(() {
                    _selectedLeaveType = value;
                    if (!_isProofRequired) {
                      _selectedProofType = null;
                      _attachedFile = null;
                    }
                  });
                },
                items: const [
                  'Annual Leave',
                  'Sick Leave',
                  'Maternity Leave',
                  'Paternity Leave',
                  'Emergency Leave',
                  'Unpaid Leave',
                  'Bereavement',
                  'Quarantine',
                  'Half Day Leave 1',
                  'Half Day Leave 2',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please select a leave type' : null,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _startDate == null ? '' : DateFormat('dd/MM/yyyy').format(_startDate!),
                    ),
                    validator: (_) => _startDate == null ? 'Please select a start date' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context, false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _endDate == null ? '' : DateFormat('dd/MM/yyyy').format(_endDate!),
                    ),
                    validator: (_) {
                      if (_endDate == null) return 'Please select an end date';
                      if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                        return 'End date cannot be before start date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for Leave',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please provide a reason for leave' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: proofLabel,
                  border: const OutlineInputBorder(),
                ),
                initialValue: _selectedProofType,
                onChanged: (value) => setState(() => _selectedProofType = value),
                items: const [
                  DropdownMenuItem(value: 'Image', child: Text('Image')),
                  DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                ],
                validator: (value) {
                  if (_isProofRequired && (value == null || value.isEmpty)) {
                    return 'Please select a proof type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _attachedFile != null ? 'Attached: ${_attachedFile!.name}' : attachLabel,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAttachmentOptions,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach'),
                  ),
                ],
              ),

              if (_isProofRequired && _attachedFile == null)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Proof attachment is required for this leave type.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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