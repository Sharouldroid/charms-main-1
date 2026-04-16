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
    // Try loading from staff list first (works for both admin and staff)
    // Falls back to user endpoint if not found in staff
    await _loadStaffData();
    
    // If staff data didn't load, try user endpoint
    if (_currentStaff == null) {
      await _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final usersProvider = Provider.of<hr_users.Users>(context, listen: false);
      final authProvider = context.read<hr_auth.Auth>();
      final token = authProvider.token;

      await usersProvider.fetchUserByUsername(authProvider.username, token: token);
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
      final staffList = staffsProvider.staffList;

      // Match by username only (admin might have different usertype representation)
      final matches = staffList.where((s) {
        final sUser = s.username.trim().toLowerCase();
        return sUser == username;
      }).toList();

      if (matches.isEmpty) {
        debugPrint('No matching staff found for username=$username');
        return; // Don't throw, let it fall back to user endpoint
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
    _genderController.text = _currentStaff!.emergencyGender == 1 ? 'Male' : 'Female';
    _addressController.text = _currentStaff!.address1;
    _address2Controller.text = _currentStaff!.address2;
    _cityController.text = _currentStaff!.city;
    _stateController.text = _currentStaff!.state;
    _countryController.text = _currentStaff!.country;
    _postcodeController.text = _currentStaff!.postcode.toString();
    _occupationController.text = _currentStaff!.occupation;
  }

  Future<void> _updateStaffInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final usersProvider = Provider.of<hr_users.Users>(context, listen: false);
      final authProvider = context.read<hr_auth.Auth>();
      final token = authProvider.token;

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
        await usersProvider.updateUser(usersProvider.userlist.first.id, payload, token: token);
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
  () => ManageStaffScreen(username: username),  
  () => AdminListScreen(username: username),     
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