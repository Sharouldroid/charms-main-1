import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:charms/internshipmodels/register.dart';
import 'package:charms/internshipproviders/register_provider.dart';
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
  Register? _intern;
  String? _photoUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  bool _notRegistered = false;
  XFile? _profileImage;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  // ── Common country codes (Malaysia first, since most interns are local) ─
  static const List<Map<String, String>> _countryCodes = [
    {'code': '+60', 'name': 'Malaysia'},
    {'code': '+65', 'name': 'Singapore'},
    {'code': '+62', 'name': 'Indonesia'},
    {'code': '+66', 'name': 'Thailand'},
    {'code': '+63', 'name': 'Philippines'},
    {'code': '+84', 'name': 'Vietnam'},
    {'code': '+86', 'name': 'China'},
    {'code': '+91', 'name': 'India'},
  ];
  static const String _otherCodeOption = 'Other';

  String? _selectedAreaCode; // one of _countryCodes' 'code', or 'Other'
  late TextEditingController _customAreaCodeController;

  // ── Editable controllers (what intern CAN change) ───────────────────────
  late TextEditingController _emailController;
  late TextEditingController _areaCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;

  // ── Colors matching Intern Dashboard ─────────────────────────────────────
  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryBlue = Colors.blueAccent;
  final Color _primaryPurple = const Color.fromARGB(255, 123, 64, 251);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    Future.microtask(_loadInternData);
  }

  void _initializeControllers() {
    _emailController = TextEditingController();
    _areaCodeController = TextEditingController();
    _customAreaCodeController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _address2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postcodeController = TextEditingController();
  }

  Future<void> _loadInternData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _notRegistered = false;
    });

    try {
      debugPrint('🔍 Loading intern profile from registration record...');
      final registerProvider = context.read<RegisterProvider>();
      final intern = await registerProvider.getInternDetails(widget.userId);
      final photoUrl = await _fetchPhotoUrl();

      setState(() {
        _intern = intern;
        _photoUrl = photoUrl;
        _updateControllers();
      });

      debugPrint('✅ Profile loaded successfully');
    } catch (error) {
      debugPrint('❌ Error: $error');
      final msg = error.toString();
      // Not registered yet → friendly empty state, not a generic error
      if (msg.contains('404') || msg.toLowerCase().contains('not found')) {
        setState(() => _notRegistered = true);
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _fetchPhotoUrl() async {
    // Photo is stored in HR_userdata, keyed by the same user_id as the
    // registration record.
    try {
      final registerProvider = context.read<RegisterProvider>();
      final filepath = await registerProvider.getInternPhotoPath(widget.userId);
      if (filepath != null && filepath.isNotEmpty) {
        return 'https://devcms.com.my/charmsAPI/public/storage/$filepath';
      }
    } catch (e) {
      debugPrint('⚠️ Could not fetch photo: $e');
    }
    return null;
  }

  void _updateControllers() {
    if (_intern == null) return;
    _emailController.text = _intern!.email;
    _areaCodeController.text = _intern!.areaCode;
    _phoneController.text = _intern!.phoneNumber;
    _addressController.text = _intern!.streetAddress1;
    _address2Controller.text = _intern!.streetAddress2 ?? '';
    _cityController.text = _intern!.city;
    _stateController.text = _intern!.state;
    _postcodeController.text = _intern!.postalCode;

    // Match the loaded area code against the known list; if it's not one
    // of ours, fall back to "Other" with the raw value in the custom field.
    final match = _countryCodes.firstWhere(
      (c) => c['code'] == _intern!.areaCode,
      orElse: () => const {},
    );
    if (match.isNotEmpty) {
      _selectedAreaCode = match['code'];
      _customAreaCodeController.text = '';
    } else {
      _selectedAreaCode = _otherCodeOption;
      _customAreaCodeController.text = _intern!.areaCode;
    }
  }

  String get _effectiveAreaCode {
    if (_selectedAreaCode == _otherCodeOption) {
      return _customAreaCodeController.text.trim();
    }
    return _selectedAreaCode ?? '+60';
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
          .read<RegisterProvider>()
          .uploadInternPhoto(widget.userId, picked);

      await _loadInternData();

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
      final payload = {
        'email': _emailController.text,
        'area_code': _effectiveAreaCode,
        'phone_number': _phoneController.text,
        'street_address_1': _addressController.text,
        'street_address_2': _address2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'postal_code': _postcodeController.text,
      };

      await context
          .read<RegisterProvider>()
          .updateMyDetails(widget.userId, payload);

      await _loadInternData();

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
          onPressed: () => Navigator.pop(context),
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
          if (_intern != null)
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
                _updateControllers();
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
          : _notRegistered
              ? _buildNotRegisteredState()
              : _error != null
                  ? _buildErrorState()
                  : _buildProfileBody(),
    );
  }

  // ── Empty state: intern hasn't registered for a schedule yet ───────────
  Widget _buildNotRegisteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Profile Found Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to register for an internship schedule first.\n'
              'Your profile will appear here once registered.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInternData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text('Failed to load profile',
              style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInternData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient Profile Header (matches Intern Details look) ────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: _profileImage != null
                              ? (kIsWeb
                                  ? NetworkImage(_profileImage!.path)
                                      as ImageProvider
                                  : FileImage(File(_profileImage!.path)))
                              : (_photoUrl != null
                                  ? NetworkImage(_photoUrl!)
                                  : null),
                          child: (_profileImage == null && _photoUrl == null)
                              ? Text(
                                  _intern!.firstName.isNotEmpty
                                      ? _intern!.firstName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : _isUploadingImage
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: _primaryBlue, width: 2),
                            ),
                            child: Icon(Icons.camera_alt,
                                size: 14, color: _primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_intern!.firstName} ${_intern!.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _intern!.email,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isEditing
                                    ? Icons.edit
                                    : Icons.verified_user,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isEditing ? 'Editing Mode' : 'Intern',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Read-Only Personal Information ─────────────────────────
            _sectionTitle('Personal Information (Read-Only)'),
            _infoCard([
              _readOnlyRow(Icons.cake, 'Age', '${_intern!.age}'),
              _readOnlyRow(Icons.person, 'Gender', _intern!.gender),
              _readOnlyRow(
                  Icons.calendar_today, 'Date of Birth', _intern!.dateOfBirth),
            ]),

            const SizedBox(height: 16),

            // ── Editable Contact Information ────────────────────────────
            _sectionTitle('Contact Information (Editable)'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _editableField(
                      'Email',
                      _emailController,
                      Icons.email,
                      enabled: _isEditing,
                    ),
                    _areaCodeDropdown(enabled: _isEditing),
                    if (_selectedAreaCode == _otherCodeOption)
                      _editableField(
                        'Custom Area Code (e.g. +81)',
                        _customAreaCodeController,
                        Icons.dialpad,
                        enabled: _isEditing,
                      ),
                    _editableField(
                      'Phone Number',
                      _phoneController,
                      Icons.phone,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Read-Only Academic Information ──────────────────────────
            _sectionTitle('Academic Information (Read-Only)'),
            _infoCard([
              _readOnlyRow(Icons.school, 'Institution', _intern!.institutionName),
              _readOnlyRow(Icons.menu_book, 'Programme', _intern!.programme),
              _readOnlyRow(Icons.class_, 'Course', _intern!.course),
              _readOnlyRow(Icons.layers, 'Level of Study', _intern!.levelOfStudy),
              if (_intern!.faculty.isNotEmpty)
                _readOnlyRow(Icons.account_balance, 'Faculty', _intern!.faculty),
            ]),

            const SizedBox(height: 16),

            // ── Editable Address ────────────────────────────────────────
            _sectionTitle('Address (Editable)'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _editableField(
                      'Street Address',
                      _addressController,
                      Icons.home,
                      enabled: _isEditing,
                    ),
                    _editableField(
                      'Address Line 2',
                      _address2Controller,
                      Icons.home_work,
                      enabled: _isEditing,
                      requiredField: false,
                    ),
                    _editableField(
                      'City',
                      _cityController,
                      Icons.location_city,
                      enabled: _isEditing,
                    ),
                    _editableField(
                      'State',
                      _stateController,
                      Icons.map,
                      enabled: _isEditing,
                    ),
                    _editableField(
                      'Postcode',
                      _postcodeController,
                      Icons.pin_drop,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    _readOnlyRow(Icons.flag, 'Country', _intern!.country),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Change Password Button ──────────────────────────────────
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: title.contains('Editable') ? _primaryBlue : Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _readOnlyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required bool enabled,
    TextInputType? keyboardType,
    bool requiredField = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? _primaryBlue : Colors.grey.shade500,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: enabled ? _primaryBlue : Colors.grey.shade400,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.3)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryBlue, width: 2),
          ),
        ),
        validator: (value) {
          if (!requiredField) return null;
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

  Widget _areaCodeDropdown({required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _selectedAreaCode ?? '+60',
        items: [
          ..._countryCodes.map(
            (c) => DropdownMenuItem(
              value: c['code'],
              child: Text('${c['code']}  ${c['name']}'),
            ),
          ),
          const DropdownMenuItem(
            value: _otherCodeOption,
            child: Text('Other (enter manually)'),
          ),
        ],
        onChanged: enabled
            ? (value) {
                setState(() => _selectedAreaCode = value);
              }
            : null,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: 'Area Code',
          labelStyle: TextStyle(
            color: enabled ? _primaryBlue : Colors.grey.shade500,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.dialpad,
            size: 20,
            color: enabled ? _primaryBlue : Colors.grey.shade400,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.3)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _areaCodeController.dispose();
    _customAreaCodeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
}