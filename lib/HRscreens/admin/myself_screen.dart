import 'dart:io';

import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/user.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/users.dart' as hr_users;
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/admin_list_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  File? _profileImage;

  final _formKey = GlobalKey<FormState>();

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
    final authProvider = context.read<hr_auth.Auth>();
    if (authProvider.usertype == 6) {
      await _loadUserData();
    } else {
      await _loadStaffData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final usersProvider = Provider.of<hr_users.Users>(context, listen: false);
      final authProvider = context.read<hr_auth.Auth>();

      await usersProvider.fetchUserByUsername(authProvider.username);
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
      final usertype = authProvider.usertype.toString();

      await staffsProvider.fetchStaff();
      final staffList = staffsProvider.staffList;

      // Safe matching to avoid "Bad state: No element"
      final matches = staffList.where((s) {
        final sUser = s.username.trim().toLowerCase();
        final sType = s.usertype.toString();
        return sUser == username && sType == usertype;
      }).toList();

      if (matches.isEmpty) {
        throw Exception('No matching staff found for username=$username, usertype=$usertype');
      }

      _currentStaff = matches.first;
      _updateControllersWithStaffData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllersWithUserData(User userData) {
    _firstNameController.text = userData.firstname;
    _lastNameController.text = userData.lastname;
    _dobController.text = userData.dob;
    _emailController.text = userData.email;
    _phoneController.text = userData.phone;
    _genderController.text = userData.gender == 1 ? 'Male' : 'Female';
    _addressController.text = userData.address1;
    _address2Controller.text = userData.address2 ?? '';
    _cityController.text = userData.city;
    _stateController.text = userData.state;
    _countryController.text = userData.country;
    _postcodeController.text = userData.postcode.toString();
    _occupationController.text = userData.occupation;
  }

  void _updateControllersWithStaffData() {
    final s = _currentStaff;
    if (s == null) return;

    _firstNameController.text = s.firstname;
    _lastNameController.text = s.lastname;
    _dobController.text = s.dob;
    _emailController.text = s.email;
    _phoneController.text = s.phone;
    _genderController.text = s.emergencyGender == 1 ? 'Male' : 'Female';
    _addressController.text = s.address1;
    _address2Controller.text = s.address2;
    _cityController.text = s.city;
    _stateController.text = s.state;
    _countryController.text = s.country;
    _postcodeController.text = s.postcode.toString();
    _occupationController.text = s.occupation;
  }

  Future<void> _updateStaffInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final usersProvider = Provider.of<hr_users.Users>(context, listen: false);
      if (usersProvider.userlist.isEmpty) {
        throw Exception('No user data found to update');
      }

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

      await usersProvider.updateUser(usersProvider.userlist.first.id, payload);
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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    final username = context.read<hr_auth.Auth>().username;
    final routes = [
      () => AdminDashboard(username: username),
      () => ManageStaffScreen(),
      () => AdminListScreen(),
      () => const MySelfScreen(),
    ];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => routes[index]()),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, {bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled && _isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled || !_isEditing,
          fillColor: (!enabled || !_isEditing) ? Colors.grey[200] : null,
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _updateStaffInfo();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Back to Dashboard',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoField('First Name', _firstNameController, enabled: true),
                    _buildInfoField('Last Name', _lastNameController, enabled: true),
                    _buildInfoField('Email', _emailController, enabled: true),
                    _buildInfoField('Phone', _phoneController, enabled: true),
                    _buildInfoField('Date of Birth', _dobController, enabled: true),
                    _buildInfoField('Gender', _genderController, enabled: true),
                    _buildInfoField('Occupation', _occupationController, enabled: true),
                    _buildInfoField('Address Line 1', _addressController, enabled: true),
                    _buildInfoField('Address Line 2', _address2Controller, enabled: true),
                    _buildInfoField('City', _cityController, enabled: true),
                    _buildInfoField('State', _stateController, enabled: true),
                    _buildInfoField('Country', _countryController, enabled: true),
                    _buildInfoField('Postcode', _postcodeController, enabled: true),
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