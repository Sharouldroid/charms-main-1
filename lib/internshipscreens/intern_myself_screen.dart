import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/internshipscreens/dashboard_screen.dart';
import 'package:charms/internshipscreens/intern_change_password.dart';
import 'package:charms/utils/logout_helper.dart';

class InternMySelfScreen extends StatefulWidget {
  final int userId;
  final String username;

  const InternMySelfScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<InternMySelfScreen> createState() => _InternMySelfScreenState();
}

class _InternMySelfScreenState extends State<InternMySelfScreen> {
  Staff? _currentStaff;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  XFile? _profileImage;

  final _formKey = GlobalKey<FormState>();

  // ── Editable controllers (what intern CAN change) ───────────────────────────
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;

  // ── Colors matching Intern Dashboard ─────────────────────────────────────────
  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryBlue = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    Future.microtask(_loadStaffData);
  }

  void _initializeControllers() {
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _address2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postcodeController = TextEditingController();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔍 Loading intern profile...');
      final staffsProvider = context.read<Staffs>();
      await staffsProvider.fetchStaff();

      final matches = staffsProvider.staffList
          .where((s) => s.userId == widget.userId)
          .toList();

      if (matches.isEmpty) {
        throw Exception('Profile not found');
      }

      setState(() {
        _currentStaff = matches.first;
        _updateControllers();
      });

      debugPrint('✅ Profile loaded successfully');
    } catch (error) {
      debugPrint('❌ Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllers() {
    if (_currentStaff == null) return;
    _phoneController.text = _currentStaff!.phone;
    _emailController.text = _currentStaff!.email;
    _addressController.text = _currentStaff!.address1;
    _address2Controller.text = _currentStaff!.address2;
    _cityController.text = _currentStaff!.city;
    _stateController.text = _currentStaff!.state;
    _postcodeController.text = _currentStaff!.postcode.toString();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (picked == null) return;

      setState(() {
        _profileImage = picked;
        _isUploadingImage = true;
      });

      await context
          .read<Staffs>()
          .uploadStaffPhoto(_currentStaff!.staffId, picked);

      await _loadStaffData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _profileImage = null;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Create updated staff object (only editable fields changed)
      final updatedStaff = Staff(
        staffId: _currentStaff!.staffId,
        userId: _currentStaff!.userId,
        username: _currentStaff!.username,
        email: _emailController.text, // ✅ Editable
        usertype: _currentStaff!.usertype,
        firstname: _currentStaff!.firstname, // ❌ Not editable
        lastname: _currentStaff!.lastname, // ❌ Not editable
        occupation: _currentStaff!.occupation,
        phone: _phoneController.text, // ✅ Editable
        category: _currentStaff!.category,
        nationality: _currentStaff!.nationality,
        religion: _currentStaff!.religion,
        maritalStatus: _currentStaff!.maritalStatus,
        gender: _currentStaff!.gender, // ✅ Editable
        officePhone: _currentStaff!.officePhone,
        emergencyName: _currentStaff!.emergencyName,
        emergencyIc: _currentStaff!.emergencyIc,
        emergencyRelation: _currentStaff!.emergencyRelation,
        emergencyGender: _currentStaff!.emergencyGender,
        emergencyPhone: _currentStaff!.emergencyPhone,
        idNum: _currentStaff!.idNum, // ❌ Not editable
        dob: _currentStaff!.dob, // ❌ Not editable
        address1: _addressController.text, // ✅ Editable
        address2: _address2Controller.text, // ✅ Editable
        city: _cityController.text, // ✅ Editable
        postcode: int.tryParse(_postcodeController.text) ?? 0, // ✅ Editable
        state: _stateController.text, // ✅ Editable
        country: _currentStaff!.country,
        filepath: _currentStaff!.filepath,
        filename: _currentStaff!.filename,
      );

      await context
          .read<Staffs>()
          .updateStaffDetails(_currentStaff!.staffId, updatedStaff);

      await _loadStaffData();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await LogoutHelper.fullLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  username: widget.username,
                  role: 'Intern',
                  userId: widget.userId,
                ),
              ),
            );
          },
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          // ✅ Edit/Save toggle button
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check_circle : Icons.edit,
              color: Colors.white,
            ),
            tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cancel',
              onPressed: () {
                setState(() => _isEditing = false);
                _updateControllers(); // Reset changes
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Profile Picture Section ─────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryBlue.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: _primaryBlue.withOpacity(0.12),
                                    backgroundImage: _profileImage != null
                                        ? (kIsWeb
                                            ? NetworkImage(_profileImage!.path)
                                                as ImageProvider
                                            : FileImage(File(_profileImage!.path)))
                                        : (_currentStaff?.filepath != null &&
                                                _currentStaff!.filepath!.isNotEmpty)
                                            ? NetworkImage(
                                                'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}')
                                            : null,
                                    child: (_profileImage == null &&
                                            (_currentStaff?.filepath == null ||
                                                _currentStaff!.filepath!.isEmpty))
                                        ? Icon(Icons.person_rounded,
                                            size: 60, color: _primaryBlue)
                                        : _isUploadingImage
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        size: 18, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // ❌ Name is NOT editable (display only)
                          Text(
                            '${_currentStaff?.firstname ?? ''} ${_currentStaff?.lastname ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStaff?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isEditing 
                                  ? Colors.orange.withOpacity(0.1) 
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isEditing ? Icons.edit : Icons.verified_user,
                                  size: 16,
                                  color: _isEditing ? Colors.orange : Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isEditing ? 'Editing Mode' : 'Intern',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isEditing ? Colors.orange : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Read-Only Information Card ──────────────────────────
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    color: Colors.grey.shade600, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Official Information (Read-Only)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact admin to change these details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildReadOnlyRow(
                                'Full Name',
                                '${_currentStaff?.firstname ?? ''} ${_currentStaff?.lastname ?? ''}',
                                Icons.badge),
                            _buildReadOnlyRow(
                                'Date of Birth',
                                _currentStaff?.dob ?? 'N/A',
                                Icons.cake),
                            _buildReadOnlyRow(
                                'Occupation',
                                _currentStaff?.occupation ?? 'Intern',
                                Icons.work),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Editable Contact Card ───────────────────────────────
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit_note,
                                    color: _primaryBlue, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Contact Information (Editable)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildEditableField(
                              'Email',
                              _emailController,
                              Icons.email,
                              enabled: _isEditing,
                            ),
                            _buildEditableField(
                              'Phone Number',
                              _phoneController,
                              Icons.phone,
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Editable Address Card ───────────────────────────────
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: _primaryBlue, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Address (Editable)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildEditableField(
                              'Street Address',
                              _addressController,
                              Icons.home,
                              enabled: _isEditing,
                            ),
                            _buildEditableField(
                              'Address Line 2',
                              _address2Controller,
                              Icons.home_work,
                              enabled: _isEditing,
                            ),
                            _buildEditableField(
                              'City',
                              _cityController,
                              Icons.location_city,
                              enabled: _isEditing,
                            ),
                            _buildEditableField(
                              'State',
                              _stateController,
                              Icons.map,
                              enabled: _isEditing,
                            ),
                            _buildEditableField(
                              'Postcode',
                              _postcodeController,
                              Icons.pin_drop,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                            ),
                            _buildReadOnlyRow(
                              'Country',
                              _currentStaff?.country ?? 'N/A',
                              Icons.flag,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── Change Password Button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InternChangePasswordScreen(
                                userId: widget.userId,
                                username: widget.username,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_reset, size: 20),
                        label: const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: _primaryBlue, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ❌ Read-only display
  Widget _buildReadOnlyRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Editable field
  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? _primaryBlue : Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: enabled ? _primaryBlue : Colors.grey.shade400,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.3)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryBlue, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
}