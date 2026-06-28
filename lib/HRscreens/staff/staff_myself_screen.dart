import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:charms/providers/auth.dart' as app_auth;
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/change_pass_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/utils/logout_helper.dart';

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

  DateTime? _selectedDob;

  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  late TextEditingController _nameController;
  late TextEditingController _icNumberController;
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

  String? _selectedGender;
  String? _selectedEmergencyGender;

  // ── Profile completion check ───────────────────────────────────────────────
  bool get _isProfileIncomplete {
    if (_currentStaff == null) return false;
    return _currentStaff!.idNum.isEmpty ||
        _currentStaff!.phone.isEmpty ||
        _currentStaff!.nationality.isEmpty ||
        _currentStaff!.religion.isEmpty ||
        _currentStaff!.address1.isEmpty ||
        _currentStaff!.city.isEmpty ||
        _currentStaff!.state.isEmpty ||
        _currentStaff!.country.isEmpty ||
        _currentStaff!.emergencyName.isEmpty ||
        _currentStaff!.emergencyPhone.isEmpty ||
        _currentStaff!.dob.isEmpty ||
        _selectedDob == null;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadStaffData();
  }

  void _initializeControllers() {
    _nameController             = TextEditingController();
    _icNumberController         = TextEditingController();
    _emailController            = TextEditingController();
    _phoneController            = TextEditingController();
    _nationalityController      = TextEditingController();
    _religionController         = TextEditingController();
    _genderController           = TextEditingController();
    _maritalStatusController    = TextEditingController();
    _statusController           = TextEditingController();
    _addressController          = TextEditingController();
    _address2Controller         = TextEditingController();
    _cityController             = TextEditingController();
    _stateController            = TextEditingController();
    _countryController          = TextEditingController();
    _postcodeController         = TextEditingController();
    _officePhoneController      = TextEditingController();
    _occupationController       = TextEditingController();
    _emergencyNameController    = TextEditingController();
    _emergencyIcController      = TextEditingController();
    _emergencyRelationController = TextEditingController();
    _emergencyGenderController  = TextEditingController();
    _emergencyPhoneController   = TextEditingController();

    // ── Added Auto-fill Logic for Emergency Contact Gender ──────────────────
    _emergencyRelationController.addListener(() {
      final relation = _emergencyRelationController.text.toLowerCase().trim();
      if (relation == 'mother' || relation == 'wife' || relation == 'sister') {
        setState(() {
          _selectedEmergencyGender = 'Female';
          _emergencyGenderController.text = 'Female';
        });
      } else if (relation == 'father' || relation == 'husband' || relation == 'brother') {
        setState(() {
          _selectedEmergencyGender = 'Male';
          _emergencyGenderController.text = 'Male';
        });
      }
    });
    // ────────────────────────────────────────────────────────────────────────
  }

  Future<void> _loadStaffData() async {
    try {
      final staffsProvider = context.read<Staffs>();
      final authProvider   = context.read<app_auth.Auth>();

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

    _nameController.text             = '${_currentStaff!.firstname} ${_currentStaff!.lastname}';
    _icNumberController.text         = _currentStaff!.idNum;
    _emailController.text            = _currentStaff!.email;
    _phoneController.text            = _currentStaff!.phone;
    _nationalityController.text      = _currentStaff!.nationality;
    _religionController.text         = _currentStaff!.religion;
    _maritalStatusController.text    = _currentStaff!.maritalStatus == 1 ? 'Single' : 'Married';
    _statusController.text           = 'Active';
    _addressController.text          = _currentStaff!.address1;
    _address2Controller.text         = _currentStaff!.address2;
    _cityController.text             = _currentStaff!.city;
    _stateController.text            = _currentStaff!.state;
    _countryController.text          = _currentStaff!.country;
    _postcodeController.text         = _currentStaff!.postcode.toString();
    _officePhoneController.text      = _currentStaff!.officePhone ?? '';
    _occupationController.text       = _currentStaff!.occupation;
    _emergencyNameController.text    = _currentStaff!.emergencyName;
    _emergencyIcController.text      = _currentStaff!.emergencyIc;
    _emergencyRelationController.text = _currentStaff!.emergencyRelation;
    _emergencyPhoneController.text   = _currentStaff!.emergencyPhone;

    _selectedGender          = _currentStaff!.gender == 1 ? 'Male' : 'Female';
    _genderController.text   = _selectedGender!;

    _selectedEmergencyGender         = _currentStaff!.emergencyGender == 1 ? 'Male' : 'Female';
    _emergencyGenderController.text  = _selectedEmergencyGender!;

    try {
      _selectedDob = DateFormat('yyyy-MM-dd').parse(_currentStaff!.dob);
    } catch (_) {
      try {
        _selectedDob = DateFormat('dd/MM/yyyy').parse(_currentStaff!.dob);
      } catch (_) {
        _selectedDob = null;
      }
    }
  }

  Future<void> _selectDob() async {
    if (!_isEditing) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: staffPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) setState(() => _profileImage = pickedFile);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _updateStaffInfo() async {
    if (!_formKey.currentState!.validate() || _currentStaff == null) return;

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select your date of birth.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    try {
      setState(() => _isLoading = true);

      final dobForApi = DateFormat('yyyy-MM-dd').format(_selectedDob!);

      final updatedStaff = Staff(
        staffId:          _currentStaff!.staffId,
        userId:           _currentStaff!.userId,
        username:         _currentStaff!.username,
        email:            _emailController.text,
        usertype:         _currentStaff!.usertype,
        firstname:        _currentStaff!.firstname,
        lastname:         _currentStaff!.lastname,
        occupation:       _occupationController.text,
        phone:            _phoneController.text,
        category:         _currentStaff!.category,
        nationality:      _nationalityController.text,
        religion:         _religionController.text,
        maritalStatus:    _maritalStatusController.text == 'Single' ? 1 : 2,
        officePhone:      _officePhoneController.text,
        gender:           _selectedGender == 'Male' ? 1 : 2,
        emergencyName:    _emergencyNameController.text,
        emergencyIc:      _emergencyIcController.text,
        emergencyRelation: _emergencyRelationController.text,
        emergencyGender:  _selectedEmergencyGender == 'Male' ? 1 : 2,
        emergencyPhone:   _emergencyPhoneController.text,
        idNum:            _icNumberController.text,
        dob:              dobForApi,
        address1:         _addressController.text,
        address2:         _address2Controller.text,
        city:             _cityController.text,
        postcode:         int.tryParse(_postcodeController.text) ?? 0,
        state:            _stateController.text,
        country:          _countryController.text,
        filepath:         _currentStaff!.filepath,
        filename:         _currentStaff!.filename,
      );

      await context.read<Staffs>().updateStaffDetails(_currentStaff!.staffId, updatedStaff);

      if (_profileImage != null) {
        await context.read<Staffs>().uploadStaffPhoto(_currentStaff!.staffId, _profileImage!);
      }

      setState(() {
        _isEditing    = false;
        _currentStaff = updatedStaff;
      });

      await _loadStaffData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $error'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async => LogoutHelper.fullLogout(context);

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = StaffDashboardScreen(username: _currentStaff?.username ?? '');
        break;
      case 1:
        nextScreen = LeaveDashboardScreen(
          username: _currentStaff?.username ?? '',
          staffId:  _currentStaff?.staffId ?? 0,
        );
        break;
      case 2:
        nextScreen = PayrollDashboardScreen(username: _currentStaff?.username ?? '');
        break;
      case 3:
        nextScreen = ClaimDashboardScreen(
          username: _currentStaff?.username ?? '',
          staffId:  _currentStaff?.staffId ?? 0,
        );
        break;
      case 4:
        return;
      default:
        return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextScreen));
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

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
            fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: _buildDecoration(label, icon, active),
        validator: (_) => null,
      ),
    );
  }

  Widget _buildDobField() {
    final bool active   = _isEditing;
    final displayText   = _selectedDob != null
        ? DateFormat('dd MMM yyyy').format(_selectedDob!)
        : 'Tap to select';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: _selectDob,
        child: AbsorbPointer(
          child: TextFormField(
            controller: TextEditingController(text: displayText),
            enabled: active,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _selectedDob != null ? const Color(0xFF1E293B) : Colors.grey.shade400,
            ),
            decoration: _buildDecoration('Date of Birth', Icons.cake_rounded, active).copyWith(
              suffixIcon: Icon(Icons.calendar_today_rounded,
                  size: 18, color: active ? staffPrimary : Colors.grey.shade400),
            ),
            validator: (_) => _selectedDob == null && _isEditing
                ? 'Please select your date of birth'
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool active = _isEditing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _buildDecoration(label, icon, active),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: staffPrimary),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: active ? onChanged : null,
        validator: (_) => null,
      ),
    );
  }

  InputDecoration _buildDecoration(String label, IconData icon, bool active) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: active ? staffPrimary : Colors.grey.shade500,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, size: 20, color: active ? staffPrimary : Colors.grey.shade400),
      filled: true,
      fillColor: active ? Colors.white : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: staffPrimary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: staffPrimary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ]),
    );
  }

  Widget _buildDepartmentBadge(String? department) {
    final String label;
    final IconData icon;

    if (department == 'Marine Biologist') {
      label = 'Marine Biologist';
      icon  = Icons.water_rounded;
    } else if (department == 'Taaras') {
      label = 'Taaras';
      icon  = Icons.villa_rounded;
    } else {
      label = 'General Staff';
      icon  = Icons.people_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }

  // ── Profile incomplete banner ─────────────────────────────────────────────
  Widget _buildIncompleteBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Your profile is incomplete. Please fill in all required fields.',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
          ),
        ),
        if (!_isEditing)
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Fill Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
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
        title: const Text('STAFF PORTAL',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
              onPressed: () {
                setState(() => _isEditing = false);
                _updateControllers();
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Back to Login',
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
                  // ── Profile header ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        top: 24, bottom: 28, left: 24, right: 24),
                    decoration: BoxDecoration(
                      color: staffPrimary,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30)),
                    ),
                    child: Column(children: [
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Stack(children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.indigo.shade300,
                              backgroundImage: _profileImage != null
                                  ? (kIsWeb
                                      ? NetworkImage(_profileImage!.path) as ImageProvider
                                      : FileImage(File(_profileImage!.path)))
                                  : (_currentStaff?.filepath != null &&
                                          _currentStaff!.filepath!.isNotEmpty)
                                      ? NetworkImage(
                                          'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}')
                                      : null,
                              child: (_profileImage == null &&
                                      (_currentStaff?.filepath == null ||
                                          _currentStaff!.filepath!.isEmpty))
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
                                  border:
                                      Border.all(color: staffPrimary, width: 2),
                                ),
                                child: Icon(Icons.camera_alt,
                                    size: 14, color: staffPrimary),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text
                            : 'My Profile',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text,
                        style: TextStyle(
                            color: Colors.indigo.shade200,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      if (_currentStaff?.department != null) ...[
                        const SizedBox(height: 8),
                        _buildDepartmentBadge(_currentStaff!.department),
                      ],
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
                    ]),
                  ),

                  // ── Incomplete banner ───────────────────────────────────
                  if (_isProfileIncomplete && !_isEditing)
                    _buildIncompleteBanner(),

                  // ── Form ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                              'Personal Details', Icons.person_rounded),
                          _buildInfoField('Full Name', _nameController,
                              Icons.badge_rounded, enabled: true),
                          _buildInfoField('IC Number', _icNumberController,
                              Icons.credit_card_rounded, enabled: true),
                          _buildDobField(),
                          _buildInfoField('Email', _emailController,
                              Icons.email_rounded, enabled: true),
                          _buildInfoField('Phone', _phoneController,
                              Icons.phone_rounded, enabled: true),
                          _buildInfoField('Nationality', _nationalityController,
                              Icons.flag_rounded, enabled: true),
                          _buildInfoField('Religion', _religionController,
                              Icons.auto_awesome_rounded, enabled: true),
                          _buildDropdownField(
                            label: 'Gender',
                            icon: Icons.wc_rounded,
                            value: _selectedGender,
                            items: const ['Male', 'Female'],
                            onChanged: (val) =>
                                setState(() => _selectedGender = val),
                          ),
                          _buildDropdownField(
                            label: 'Marital Status',
                            icon: Icons.favorite_rounded,
                            value: _maritalStatusController.text.isNotEmpty
                                ? _maritalStatusController.text
                                : null,
                            items: const ['Single', 'Married'],
                            onChanged: (val) => setState(
                                () => _maritalStatusController.text = val ?? ''),
                          ),
                          _buildInfoField('Status', _statusController,
                              Icons.verified_rounded, enabled: false),
                          _buildInfoField('Occupation', _occupationController,
                              Icons.work_rounded, enabled: true),

                          _buildSectionHeader(
                              'Address Details', Icons.location_on_rounded),
                          _buildInfoField('Address Line 1', _addressController,
                              Icons.location_on_rounded, enabled: true),
                          _buildInfoField('Address Line 2', _address2Controller,
                              Icons.location_on_outlined, enabled: true),
                          _buildInfoField('City', _cityController,
                              Icons.location_city_rounded, enabled: true),
                          _buildInfoField('State', _stateController,
                              Icons.map_rounded, enabled: true),
                          _buildInfoField('Country', _countryController,
                              Icons.public_rounded, enabled: true),
                          _buildInfoField('Postcode', _postcodeController,
                              Icons.pin_rounded, enabled: true),
                          _buildInfoField('Office Phone', _officePhoneController,
                              Icons.phone_in_talk_rounded, enabled: true),

                          _buildSectionHeader(
                              'Emergency Contact', Icons.emergency_rounded),
                          _buildInfoField('Contact Name', _emergencyNameController,
                              Icons.person_pin_rounded, enabled: true),
                          _buildInfoField('Contact IC', _emergencyIcController,
                              Icons.credit_card_rounded, enabled: true),
                          _buildInfoField('Relation', _emergencyRelationController,
                              Icons.people_alt_rounded, enabled: true),
                          _buildDropdownField(
                            label: 'Contact Gender',
                            icon: Icons.wc_rounded,
                            value: _selectedEmergencyGender,
                            items: const ['Male', 'Female'],
                            onChanged: (val) =>
                                setState(() => _selectedEmergencyGender = val),
                          ),
                          _buildInfoField('Contact Phone', _emergencyPhoneController,
                              Icons.phone_rounded, enabled: true),

                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.manage_accounts_rounded,
                                  color: staffPrimary),
                              label: Text('Account Settings',
                                  style: TextStyle(
                                      color: staffPrimary,
                                      fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                side: BorderSide(
                                    color: staffPrimary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const ChangePassScreen())),
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
        showMyselfDot: _isProfileIncomplete, // ✅ dot disappears when complete
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icNumberController.dispose();
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