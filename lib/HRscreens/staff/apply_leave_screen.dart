import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';
import 'dart:typed_data';

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

  bool _submitting = false;
  Uint8List? _attachedBytes;
  String? _attachedFileName;

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5); // Deep Indigo
  final Color staffBg = const Color(0xFFF8FAFC); // Very Light Slate

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
                    decoration: BoxDecoration(
                        color: staffPrimary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child:
                        Icon(Icons.photo_library_rounded, color: staffPrimary),
                  ),
                  title: const Text('Choose from Gallery',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: staffPrimary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(Icons.picture_as_pdf_rounded,
                        color: staffPrimary),
                  ),
                  title: const Text('Choose PDF / Document',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(); // Now actually used
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
    allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    withData: true, // ← key fix, same as ApplyClaimScreen
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.single;
  final bytes = file.bytes;
  final name = file.name;
  final ext = (file.extension ?? '').toLowerCase();

  if (bytes != null) {
    setState(() {
      _attachedBytes = bytes;
      _attachedFileName = name;
      _selectedProofType =
          (ext == 'jpg' || ext == 'jpeg' || ext == 'png') ? 'Image' : 'PDF';
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Unable to read file. Please try again.'),
          backgroundColor: Colors.redAccent),
    );
  }
}

  Future<void> _submitLeave() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_isProofRequired) {
      if ((_selectedProofType ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select proof type.'),
              backgroundColor: Colors.redAccent),
        );
        return;
      }
      if (_attachedFileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Proof attachment is required for this leave type.'),
              backgroundColor: Colors.redAccent),
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
        proofFileName: _attachedFileName,
        proofFileType: _selectedProofType,
        proofFile:_attachedBytes,
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await leavesProvider.createLeave(leave);
      await leavesProvider.getLeaveByStaffId(staffId: widget.staffId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Leave application submitted successfully'),
            backgroundColor: Colors.teal),
      );

      Navigator.pop(context, true); // tells previous screen to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to submit leave: $e'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Helper to build consistent inputs
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: staffPrimary.withOpacity(0.7), size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final proofLabel =
        _isProofRequired ? 'Proof Type *' : 'Proof Type (Optional)';
    final attachLabel =
        _isProofRequired ? 'Attach Document *' : 'Attach Document (Optional)';

    return Scaffold(
      backgroundColor: staffBg, // Modern background
      appBar: const StaffAppBar(title: 'APPLY LEAVE'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
                      child: Icon(Icons.beach_access_rounded,
                          size: 40, color: staffPrimary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
                    decoration: _buildInputDecoration(
                        'Leave Type', Icons.category_rounded),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: staffPrimary),
                    initialValue: _selectedLeaveType,
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value;
                        if (!_isProofRequired) {
                          _selectedProofType = null;
                          _attachedFileName  = null;
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
                    ]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    validator: (value) =>
                        (value == null || value.isEmpty)
                            ? 'Please select a leave type'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _buildInputDecoration(
                            'Start Date', Icons.date_range_rounded),
                        controller: TextEditingController(
                          text: _startDate == null
                              ? ''
                              : DateFormat('dd MMM yyyy').format(_startDate!),
                        ),
                        validator: (_) => _startDate == null
                            ? 'Please select a start date'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _buildInputDecoration(
                                'End Date', Icons.date_range_rounded)
                            .copyWith(
                          suffixIcon: Icon(Icons.calendar_today_rounded,
                              color: staffPrimary.withOpacity(0.7)),
                        ),
                        controller: TextEditingController(
                          text: _endDate == null
                              ? ''
                              : DateFormat('dd MMM yyyy').format(_endDate!),
                        ),
                        validator: (_) {
                          if (_endDate == null)
                            return 'Please select an end date';
                          if (_startDate != null &&
                              _endDate!.isBefore(_startDate!)) {
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
                    decoration: _buildInputDecoration(
                        'Reason for Leave', Icons.subject_rounded),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Please provide a reason for leave'
                            : null,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),

                  DropdownButtonFormField<String>(
                    decoration:
                        _buildInputDecoration(proofLabel, Icons.attachment_rounded),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: staffPrimary),
                    initialValue: _selectedProofType,
                    onChanged: (value) =>
                        setState(() => _selectedProofType = value),
                    items: const [
                      DropdownMenuItem(value: 'Image', child: Text('Image')),
                      DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    ],
                    validator: (value) {
                      if (_isProofRequired &&
                          (value == null || value.isEmpty)) {
                        return 'Please select a proof type';
                      }
                      return null;
                    },
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
                            _attachedFileName != null
                                ? 'Attached: $_attachedFileName'
                                : attachLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: _attachedFileName != null
                                  ? staffPrimary
                                  : Colors.grey.shade600,
                              fontWeight: _attachedFileName != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showAttachmentOptions,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: staffPrimary,
                            side: BorderSide(color: staffPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.upload_file_rounded,
                              size: 18),
                          label: const Text('Attach'),
                        ),
                      ],
                    ),
                  ),

                  if (_isProofRequired && _attachedFileName == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        'Proof attachment is required for this leave type.',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submitLeave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Modern submit color
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit Leave Request',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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