import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/user.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/users.dart' as hr_users;
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/admin_list_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRscreens/staff/change_pass_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/logout_helper.dart'; // ← replaces inline logout

class MySelfScreen extends StatefulWidget {
  const MySelfScreen({super.key});

  @override
  State<MySelfScreen> createState() => _MySelfScreenState();
}

class _MySelfScreenState extends State<MySelfScreen> {
  int _selectedIndex = 3;

  Staff? _currentStaff;
  bool _isLoading = true;
  bool _isEditing = false;
  XFile? _profileImage;

  final _formKey = GlobalKey<FormState>();

  // ── Matches AdminDashboard palette ──────────────────────────────────────────
  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryBlue = const Color(0xFF2563EB);

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dobController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _genderController;
  late TextEditingController _addressController;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postcodeController;
  late TextEditingController _occupationController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    Future.microtask(_loadUserOrStaffData);
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dobController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _genderController = TextEditingController();
    _addressController = TextEditingController();
    _address2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _postcodeController = TextEditingController();
    _occupationController = TextEditingController();
  }

  Future<void> _loadUserOrStaffData() async {
    await _loadStaffData();
    if (_currentStaff == null) await _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final usersProvider = Provider.of<hr_users.Users>(context, listen: false);
      final authProvider = context.read<hr_auth.Auth>();
      final token = authProvider.token;

      await usersProvider.fetchUserByUsername(authProvider.username,
          token: token);
      if (usersProvider.userlist.isNotEmpty) {
        _updateControllersWithUserData(usersProvider.userlist.first);
      } else {
        throw Exception('No user record returned');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStaffData() async {
    try {
      final staffsProvider = context.read<Staffs>();
      final authProvider = context.read<hr_auth.Auth>();
      final username = authProvider.username.trim().toLowerCase();

      await staffsProvider.fetchStaff();
      final matches = staffsProvider.staffList
          .where((s) => s.username.trim().toLowerCase() == username)
          .toList();

      if (matches.isEmpty) {
        debugPrint('No matching staff found for username=$username');
        return;
      }
      _currentStaff = matches.first;
      _updateControllersWithStaffData();
    } catch (error) {
      debugPrint('Error loading staff data: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllersWithUserData(User user) {
    _firstNameController.text = user.firstname;
    _lastNameController.text = user.lastname;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _dobController.text = user.dob;
    _genderController.text = user.gender == 1 ? 'Male' : 'Female';
    _addressController.text = user.address1;
    _address2Controller.text = user.address2 ?? '';
    _cityController.text = user.city;
    _stateController.text = user.state;
    _countryController.text = user.country;
    _postcodeController.text = user.postcode.toString();
    _occupationController.text = user.occupation;
  }

  void _updateControllersWithStaffData() {
    if (_currentStaff == null) return;
    _firstNameController.text = _currentStaff!.firstname;
    _lastNameController.text = _currentStaff!.lastname;
    _emailController.text = _currentStaff!.email;
    _phoneController.text = _currentStaff!.phone;
    _dobController.text = _currentStaff!.dob;
    _genderController.text =
        _currentStaff!.emergencyGender == 1 ? 'Male' : 'Female';
    _addressController.text = _currentStaff!.address1;
    _address2Controller.text = _currentStaff!.address2;
    _cityController.text = _currentStaff!.city;
    _stateController.text = _currentStaff!.state;
    _countryController.text = _currentStaff!.country;
    _postcodeController.text = _currentStaff!.postcode.toString();
    _occupationController.text = _currentStaff!.occupation;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) setState(() => _profileImage = picked);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _updateStaffInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final authProvider = context.read<hr_auth.Auth>();
      final token = authProvider.token;

      if (_currentStaff != null) {
        final updatedStaff = Staff(
          staffId: _currentStaff!.staffId,
          userId: _currentStaff!.userId,
          username: _currentStaff!.username,
          email: _emailController.text,
          usertype: _currentStaff!.usertype,
          firstname: _firstNameController.text,
          lastname: _lastNameController.text,
          occupation: _occupationController.text,
          gender: _genderController.text == 'Male' ? 1 : 2, 
          phone: _phoneController.text,
          category: _currentStaff!.category,
          nationality: _currentStaff!.nationality,
          religion: _currentStaff!.religion,
          maritalStatus: _currentStaff!.maritalStatus,
          officePhone: _currentStaff!.officePhone,
          emergencyName: _currentStaff!.emergencyName,
          emergencyIc: _currentStaff!.emergencyIc,
          emergencyRelation: _currentStaff!.emergencyRelation,
          emergencyGender: _genderController.text == 'Male' ? 1 : 2,
          emergencyPhone: _currentStaff!.emergencyPhone,
          idNum: _currentStaff!.idNum,
          dob: _dobController.text,
          address1: _addressController.text,
          address2: _address2Controller.text,
          city: _cityController.text,
          postcode: int.tryParse(_postcodeController.text) ?? 0,
          state: _stateController.text,
          country: _countryController.text,
          filepath: _currentStaff!.filepath,
          filename: _currentStaff!.filename,
        );

        await context
            .read<Staffs>()
            .updateStaffDetails(_currentStaff!.staffId, updatedStaff);

        if (_profileImage != null) {
          await context
              .read<Staffs>()
              .uploadStaffPhoto(_currentStaff!.staffId, _profileImage!);
        }
      } else {
        final usersProvider =
            Provider.of<hr_users.Users>(context, listen: false);
        final payload = {
          'firstname': _firstNameController.text,
          'lastname': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'dob': _dobController.text,
          'address1': _addressController.text,
          'address2': _address2Controller.text,
          'city': _cityController.text,
          'postcode': int.tryParse(_postcodeController.text) ?? 0,
          'state': _stateController.text,
          'country': _countryController.text,
          'occupation': _occupationController.text,
          'gender': _genderController.text == 'Male' ? 1 : 2,
        };

        if (usersProvider.userlist.isNotEmpty) {
          await usersProvider.updateUser(
              usersProvider.userlist.first.id, payload,
              token: token);
        }
      }

      await _loadUserOrStaffData();

      if (mounted) {
        setState(() => _isEditing = false);
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

  /// Full logout — clears both app_auth and hr_auth via LogoutHelper.
  Future<void> _logout() async {
    await LogoutHelper.fullLogout(context);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    final username = context.read<hr_auth.Auth>().username;
    final routes = [
      () => AdminDashboard(username: username),
      () => ManageStaffScreen(username: username),
      () => AdminListScreen(username: username),
      () => const MySelfScreen(),
    ];
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => routes[index]()));
  }

  // ── Shared field builder ─────────────────────────────────────────────────────
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
              color: active ? _primaryBlue : Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon,
              size: 20, color: active ? _primaryBlue : Colors.grey.shade400),
          filled: true,
          fillColor: active ? Colors.white : Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.3)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _primaryBlue, width: 1.5),
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
        validator: (v) => null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        backgroundColor: _primaryBlue,
        centerTitle: true,
        title: const Text(
          'CHARMS ADMIN',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
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
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Back to Login',
              onPressed: _logout,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ─────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isEditing ? _pickImage : null,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryBlue.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 52,
                                    backgroundColor:
                                        _primaryBlue.withOpacity(0.12),
                                    backgroundImage: _profileImage != null
                                        ? (kIsWeb
                                            ? NetworkImage(_profileImage!.path)
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
                                            (_currentStaff?.filepath == null ||
                                                _currentStaff!
                                                    .filepath!.isEmpty))
                                        ? Icon(Icons.person_rounded,
                                            size: 52, color: _primaryBlue)
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
                                        color: _primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${_firstNameController.text} ${_lastNameController.text}'
                                    .trim()
                                    .isNotEmpty
                                ? '${_firstNameController.text} ${_lastNameController.text}'
                                    .trim()
                                : 'My Profile',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _emailController.text.isNotEmpty
                                ? _emailController.text
                                : '',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_note_rounded,
                                      size: 14, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text('Editing profile',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Personal Info ──────────────────────────────────────
                    _buildSectionHeader('PERSONAL INFORMATION'),
                    _buildInfoField('First Name', _firstNameController,
                        Icons.badge_rounded,
                        enabled: true),
                    _buildInfoField('Last Name', _lastNameController,
                        Icons.badge_outlined,
                        enabled: true),
                    _buildInfoField(
                        'Date of Birth', _dobController, Icons.cake_rounded,
                        enabled: true),
                    _buildInfoField(
                        'Gender', _genderController, Icons.wc_rounded,
                        enabled: true),
                    _buildInfoField('Occupation', _occupationController,
                        Icons.work_rounded,
                        enabled: true),

                    const SizedBox(height: 8),
                    // ── Contact ────────────────────────────────────────────
                    _buildSectionHeader('CONTACT'),
                    _buildInfoField(
                        'Email', _emailController, Icons.email_rounded,
                        enabled: true),
                    _buildInfoField(
                        'Phone', _phoneController, Icons.phone_rounded,
                        enabled: true),

                    const SizedBox(height: 8),
                    // ── Address ────────────────────────────────────────────
                    _buildSectionHeader('ADDRESS'),
                    _buildInfoField('Address Line 1', _addressController,
                        Icons.location_on_rounded,
                        enabled: true),
                    _buildInfoField('Address Line 2', _address2Controller,
                        Icons.location_on_outlined,
                        enabled: true),
                    _buildInfoField(
                        'City', _cityController, Icons.location_city_rounded,
                        enabled: true),
                    _buildInfoField(
                        'State', _stateController, Icons.map_rounded,
                        enabled: true),
                    _buildInfoField(
                        'Country', _countryController, Icons.flag_rounded,
                        enabled: true),
                    _buildInfoField(
                        'Postcode', _postcodeController, Icons.pin_rounded,
                        enabled: true),

                    const SizedBox(height: 24),

                    // ── Change Password ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.lock_outline_rounded,
                            color: _primaryBlue),
                        label: Text(
                          'Change Password',
                          style: TextStyle(
                              color: _primaryBlue,
                              fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: _primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChangePassScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postcodeController.dispose();
    _occupationController.dispose();
    super.dispose();
  }
}