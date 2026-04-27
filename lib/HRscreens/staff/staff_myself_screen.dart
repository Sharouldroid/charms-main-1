import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/change_pass_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/screens/dashboard_screen.dart';

class StaffMySelfScreen extends StatefulWidget {
  const StaffMySelfScreen({super.key});

  @override
  State<StaffMySelfScreen> createState() => _StaffMySelfScreenState();
}

class _StaffMySelfScreenState extends State<StaffMySelfScreen> {
  int _selectedIndex = 4;

  Staff? _currentStaff;
  bool _isLoading = true;
  bool _isEditing = false;

  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  // ── Matches StaffDashboardScreen palette ─────────────────────────────────────
  final Color staffPrimary = const Color(0xFF4F46E5);
  final Color staffBg = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  late TextEditingController _nameController;
  late TextEditingController _icNumberController;
  late TextEditingController _dobController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _nationalityController;
  late TextEditingController _religionController;
  late TextEditingController _genderController;
  late TextEditingController _maritalStatusController;
  late TextEditingController _statusController;
  late TextEditingController _addressController;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postcodeController;
  late TextEditingController _officePhoneController;
  late TextEditingController _occupationController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyIcController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _emergencyGenderController;
  late TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadStaffData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _icNumberController = TextEditingController();
    _dobController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _nationalityController = TextEditingController();
    _religionController = TextEditingController();
    _genderController = TextEditingController();
    _maritalStatusController = TextEditingController();
    _statusController = TextEditingController();
    _addressController = TextEditingController();
    _address2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _postcodeController = TextEditingController();
    _officePhoneController = TextEditingController();
    _occupationController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyIcController = TextEditingController();
    _emergencyRelationController = TextEditingController();
    _emergencyGenderController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  Future<void> _loadStaffData() async {
    try {
      final staffsProvider = context.read<Staffs>();
      final authProvider = context.read<hr_auth.Auth>();

      await staffsProvider.fetchStaff();

      final staffList = staffsProvider.staffList;
      if (staffList.isNotEmpty) {
        _currentStaff = staffList.firstWhere(
          (staff) => staff.username == authProvider.username,
          orElse: () => throw Exception('Staff not found'),
        );
        _updateControllers();
      }
    } catch (error) {
      debugPrint('Error loading staff data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllers() {
    if (_currentStaff == null) return;
    _nameController.text =
        "${_currentStaff!.firstname} ${_currentStaff!.lastname}";
    _icNumberController.text = _currentStaff!.idNum;
    _dobController.text = _currentStaff!.dob;
    _emailController.text = _currentStaff!.email;
    _phoneController.text = _currentStaff!.phone;
    _nationalityController.text = _currentStaff!.nationality;
    _religionController.text = _currentStaff!.religion;
    _genderController.text =
        _currentStaff!.emergencyGender == 1 ? "Male" : "Female";
    _maritalStatusController.text =
        _currentStaff!.maritalStatus == 1 ? "Single" : "Married";
    _statusController.text = "Active";
    _addressController.text = _currentStaff!.address1;
    _address2Controller.text = _currentStaff!.address2;
    _cityController.text = _currentStaff!.city;
    _stateController.text = _currentStaff!.state;
    _countryController.text = _currentStaff!.country;
    _postcodeController.text = _currentStaff!.postcode.toString();
    _officePhoneController.text = _currentStaff!.officePhone ?? '';
    _occupationController.text = _currentStaff!.occupation;
    _emergencyNameController.text = _currentStaff!.emergencyName;
    _emergencyIcController.text = _currentStaff!.emergencyIc;
    _emergencyRelationController.text = _currentStaff!.emergencyRelation;
    _emergencyGenderController.text =
        _currentStaff!.emergencyGender == 1 ? "Male" : "Female";
    _emergencyPhoneController.text = _currentStaff!.emergencyPhone;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) setState(() => _profileImage = pickedFile);
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _updateStaffInfo() async {
    if (!_formKey.currentState!.validate() || _currentStaff == null) return;

    try {
      setState(() => _isLoading = true);

      final updatedStaff = Staff(
        staffId: _currentStaff!.staffId,
        userId: _currentStaff!.userId,
        username: _currentStaff!.username,
        email: _emailController.text,
        usertype: _currentStaff!.usertype,
        firstname: _currentStaff!.firstname,
        lastname: _currentStaff!.lastname,
        occupation: _occupationController.text,
        phone: _phoneController.text,
        category: _currentStaff!.category,
        nationality: _nationalityController.text,
        religion: _religionController.text,
        maritalStatus: _maritalStatusController.text == "Single" ? 1 : 2,
        officePhone: _officePhoneController.text,
        emergencyName: _emergencyNameController.text,
        emergencyIc: _emergencyIcController.text,
        emergencyRelation: _emergencyRelationController.text,
        emergencyGender: _emergencyGenderController.text == "Male" ? 1 : 2,
        emergencyPhone: _emergencyPhoneController.text,
        idNum: _icNumberController.text,
        dob: _dobController.text,
        address1: _addressController.text,
        address2: _address2Controller.text,
        city: _cityController.text,
        postcode: int.tryParse(_postcodeController.text) ?? 0,
        state: _stateController.text,
        country: _countryController.text,
        filepath: _currentStaff!.filepath,
      );

      await context
          .read<Staffs>()
          .updateStaffDetails(_currentStaff!.staffId, updatedStaff);

      if (_profileImage != null) {
        await context
            .read<Staffs>()
            .uploadStaffPhoto(_currentStaff!.staffId, _profileImage!);
      }

      setState(() {
        _isEditing = false;
        _currentStaff = updatedStaff;
      });

      await _loadStaffData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(DashboardScreen.routeName, (route) => false);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen =
            StaffDashboardScreen(username: _currentStaff?.username ?? '');
        break;
      case 1:
        nextScreen = LeaveDashboardScreen(
          username: _currentStaff?.username ?? '',
          staffId: _currentStaff?.staffId ?? 0,
        );
        break;
      case 2:
        nextScreen =
            PayrollDashboardScreen(username: _currentStaff?.username ?? '');
        break;
      case 3:
        nextScreen = ClaimDashboardScreen(
          username: _currentStaff?.username ?? '',
          staffId: _currentStaff?.staffId ?? 0,
        );
        break;
      case 4:
        return;
      default:
        return;
    }

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => nextScreen));
  }

  // ── Field builder ─────────────────────────────────────────────────────────────
  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = false,
  }) {
    final bool active = enabled && _isEditing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: active,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: active ? staffPrimary : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon,
              size: 20,
              color: active ? staffPrimary : Colors.grey.shade400),
          filled: true,
          fillColor: active ? Colors.white : Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: staffPrimary.withOpacity(0.3)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: staffCardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: staffPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: staffPrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: staffPrimary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text(
          'STAFF PORTAL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: staffPrimary,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check_circle_rounded : Icons.edit_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                _updateStaffInfo();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Cancel',
              onPressed: () => setState(() => _isEditing = false),
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Back to Dashboard',
              onPressed: _logout,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: staffPrimary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Indigo banner with avatar — mirrors StaffDashboard ───────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        top: 24, bottom: 28, left: 24, right: 24),
                    decoration: BoxDecoration(
                      color: staffPrimary,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor:
                                      Colors.indigo.shade300,
                                  backgroundImage: _profileImage != null
                                      ? (kIsWeb
                                          ? NetworkImage(
                                                  _profileImage!.path)
                                              as ImageProvider
                                          : FileImage(
                                              File(_profileImage!.path)))
                                      : (_currentStaff?.filepath != null &&
                                              _currentStaff!
                                                  .filepath!.isNotEmpty)
                                          ? NetworkImage(
                                              'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}')
                                          : null,
                                  child: (_profileImage == null &&
                                          (_currentStaff?.filepath ==
                                                  null ||
                                              _currentStaff!
                                                  .filepath!.isEmpty))
                                      ? const Icon(Icons.person_rounded,
                                          size: 52, color: Colors.white)
                                      : null,
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: staffPrimary, width: 2),
                                    ),
                                    child: Icon(Icons.camera_alt,
                                        size: 14, color: staffPrimary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'My Profile',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text,
                          style: TextStyle(
                            color: Colors.indigo.shade200,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_note_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Editing profile',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Form body ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    child: Form(
                      key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Personal Details ───────────────────────────
                            _buildSectionHeader(
                                'Personal Details', Icons.person_rounded),
                            _buildInfoField('Full Name', _nameController,
                                Icons.badge_rounded,
                                enabled: true),
                            _buildInfoField(
                                'IC Number', _icNumberController,
                                Icons.credit_card_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Date of Birth', _dobController,
                                Icons.cake_rounded,
                                enabled: true),
                            _buildInfoField('Email', _emailController,
                                Icons.email_rounded,
                                enabled: true),
                            _buildInfoField('Phone', _phoneController,
                                Icons.phone_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Nationality', _nationalityController,
                                Icons.flag_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Religion', _religionController,
                                Icons.auto_awesome_rounded,
                                enabled: true),
                            _buildInfoField('Gender', _genderController,
                                Icons.wc_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Marital Status', _maritalStatusController,
                                Icons.favorite_rounded,
                                enabled: true),
                            _buildInfoField('Status', _statusController,
                                Icons.verified_rounded,
                                enabled: false),
                            _buildInfoField(
                                'Occupation', _occupationController,
                                Icons.work_rounded,
                                enabled: true),

                            // ── Address ─────────────────────────────────────
                            _buildSectionHeader(
                                'Address Details',
                                Icons.location_on_rounded),
                            _buildInfoField(
                                'Address Line 1', _addressController,
                                Icons.location_on_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Address Line 2', _address2Controller,
                                Icons.location_on_outlined,
                                enabled: true),
                            _buildInfoField('City', _cityController,
                                Icons.location_city_rounded,
                                enabled: true),
                            _buildInfoField('State', _stateController,
                                Icons.map_rounded,
                                enabled: true),
                            _buildInfoField('Country', _countryController,
                                Icons.public_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Postcode', _postcodeController,
                                Icons.pin_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Office Phone', _officePhoneController,
                                Icons.phone_in_talk_rounded,
                                enabled: true),

                            // ── Emergency Contact ───────────────────────────
                            _buildSectionHeader(
                                'Emergency Contact',
                                Icons.emergency_rounded),
                            _buildInfoField(
                                'Contact Name', _emergencyNameController,
                                Icons.person_pin_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Contact IC', _emergencyIcController,
                                Icons.credit_card_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Relation', _emergencyRelationController,
                                Icons.people_alt_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Gender', _emergencyGenderController,
                                Icons.wc_rounded,
                                enabled: true),
                            _buildInfoField(
                                'Contact Phone', _emergencyPhoneController,
                                Icons.phone_rounded,
                                enabled: true),

                            // ── Change Password ─────────────────────────────
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.lock_outline_rounded,
                                    color: staffPrimary),
                                label: Text(
                                  'Change Password',
                                  style: TextStyle(
                                      color: staffPrimary,
                                      fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  side: BorderSide(
                                      color: staffPrimary, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ChangePassScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icNumberController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _genderController.dispose();
    _maritalStatusController.dispose();
    _statusController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postcodeController.dispose();
    _officePhoneController.dispose();
    _occupationController.dispose();
    _emergencyNameController.dispose();
    _emergencyIcController.dispose();
    _emergencyRelationController.dispose();
    _emergencyGenderController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}