import 'dart:io';
import 'package:charms/HRmodels/user.dart';
import 'package:charms/HRproviders/users.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/admin_list_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:charms/HRwidgets/custom_drawer.dart';

class MySelfScreen extends StatefulWidget {
  @override
  State<MySelfScreen> createState() => _MySelfScreenState();
}

class _MySelfScreenState extends State<MySelfScreen> {
  int _selectedIndex = 3;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  
  late Staff? _currentStaff;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _profileImage;
  
  final _formKey = GlobalKey<FormState>();
  
  // Keep only the controllers for existing database fields
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
    _loadUserOrStaffData();
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

  void _updateControllersWithUserData(User userData) {
    _firstNameController.text = userData.firstname;
    _lastNameController.text = userData.lastname;
    _dobController.text = userData.dob;
    _emailController.text = userData.email;
    _phoneController.text = userData.phone;
    _genderController.text = userData.gender == 1 ? "Male" : "Female";
    _addressController.text = userData.address1;
    _address2Controller.text = userData.address2 ?? '';
    _cityController.text = userData.city;
    _stateController.text = userData.state;
    _countryController.text = userData.country;
    _postcodeController.text = userData.postcode.toString();
    _occupationController.text = userData.occupation;
  }

  Future<void> _updateStaffInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      
      final userData = {
        'firstname': _firstNameController.text,
        'lastname': _lastNameController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text,
        'address1': _addressController.text,
        'address2': _address2Controller.text,
        'city': _cityController.text,
        'postcode': int.tryParse(_postcodeController.text) ?? 0,
        'state': _stateController.text,
        'country': _countryController.text,
        'occupation': _occupationController.text,
        'gender': _genderController.text == "Male" ? 1 : 2,
      };

      final usersProvider = Provider.of<Users>(context, listen: false);
      
      // FIXED: Removed authProvider.hostname as updateUser expects 2 arguments: (userId, userData)
      await usersProvider.updateUser(
        usersProvider.userlist.first.id,
        userData
      );
      
      await _loadUserData();
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserOrStaffData() async {
  final authProvider = Provider.of<Auth>(context, listen: false);
  final usertype = authProvider.usertype;
  
  if (usertype == 6) {
    await _loadUserData();
  } else {
    await _loadStaffData(); 
  }
}

Future<void> _loadUserData() async {
  try {
    final usersProvider = Provider.of<Users>(context, listen: false);
    final authProvider = Provider.of<Auth>(context, listen: false);
    
    final username = authProvider.username;
    final usertype = authProvider.usertype;
    
    if (usertype == 6) {
      // FIXED: Removed authProvider.hostname as fetchUserByUsername expects 1 argument: (username)
      await usersProvider.fetchUserByUsername(username);
      final userData = usersProvider.userlist.first;
      _updateControllersWithUserData(userData);
    } else {
      await _loadStaffData();
    }
    
    setState(() => _isLoading = false);
  } catch (error) {
    print('Data fetch failed: $error');
    setState(() => _isLoading = false);
  }
}

Future<void> _loadStaffData() async {
  try {
    final staffsProvider = Provider.of<Staffs>(context, listen: false);
    final authProvider = Provider.of<Auth>(context, listen: false);
    
    final username = authProvider.username;
    final usertype = authProvider.usertype;
    
    // FIXED: Removed argument because fetchStaff() in staffs.dart expects 0 arguments
    await staffsProvider.fetchStaff();
    final staffList = staffsProvider.staffList;
    
    _currentStaff = staffList.firstWhere(
      (staff) => staff.username == username && staff.usertype == usertype.toString(),
    );
    
    if (_currentStaff != null) {
      _updateControllersWithStaffData();
    }
    
    setState(() => _isLoading = false);
  } catch (error) {
    print('Staff fetch failed: $error');
    setState(() => _isLoading = false);
  }
}

void _updateControllersWithStaffData() {
  if (_currentStaff != null) {
    _firstNameController.text = _currentStaff!.firstname;
    _lastNameController.text = _currentStaff!.lastname;
    _dobController.text = _currentStaff!.dob;
    _emailController.text = _currentStaff!.email;
    _phoneController.text = _currentStaff!.phone;
    _genderController.text = _currentStaff!.emergencyGender == 1 ? "Male" : "Female";
    _addressController.text = _currentStaff!.address1;
    _address2Controller.text = _currentStaff!.address2;
    _cityController.text = _currentStaff!.city;
    _stateController.text = _currentStaff!.state;
    _countryController.text = _currentStaff!.country;
    _postcodeController.text = _currentStaff!.postcode.toString();
    _occupationController.text = _currentStaff!.occupation;
  }
}

Widget _buildInfoField(String label, TextEditingController controller, {bool enabled = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      enabled: enabled && _isEditing,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: !enabled || !_isEditing,
        fillColor: (!enabled || !_isEditing) ? Colors.grey[200] : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    ),
  );
}

void _onItemTapped(int index) {
  setState(() => _selectedIndex = index);
  
  final authProvider = Provider.of<Auth>(context, listen: false);
  final currentUsername = authProvider.username;
  
  final routes = [
    () => AdminDashboard(username: currentUsername),
    () => ManageStaffScreen(),
    () => AdminListScreen(),
    () => MySelfScreen(),
  ];
  
  if (index < routes.length) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => routes[index]()),
    );
  }
}

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      _profileImage = File(pickedFile.path);
    });
  }
}

Future<void> _logout() async {
  await Provider.of<Auth>(context, listen: false).logout();
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const AuthScreen()),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      title: Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
      centerTitle: true,
      backgroundColor: Colors.blue,
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
      ],
    ),
    drawer: CustomDrawer(
      selectedLanguage: _selectedLanguage,
      languages: _languages,
      onLanguageChanged: (String? newValue) {
        setState(() => _selectedLanguage = newValue!);
      },
      onLogOut: _logout,
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image and Name Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blue,
                                backgroundImage: _profileImage != null 
                                    ? FileImage(_profileImage!) 
                                    : null,
                                child: _profileImage == null
                                    ? Icon(Icons.person, size: 50, color: Colors.white)
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    radius: 15,
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "${_firstNameController.text} ${_lastNameController.text}",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _emailController.text,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  
                  // Personal Details Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Personal Details",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        _buildInfoField('First Name', _firstNameController, enabled: true),
                        _buildInfoField('Last Name', _lastNameController, enabled: true),
                        _buildInfoField('Email', _emailController, enabled: false),
                        _buildInfoField('Phone', _phoneController, enabled: true),
                        _buildInfoField('Date of Birth', _dobController, enabled: true),
                        _buildInfoField('Gender', _genderController, enabled: true),
                        _buildInfoField('Occupation', _occupationController, enabled: true),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Address Details Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Address Details",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        _buildInfoField('Address Line 1', _addressController, enabled: true),
                        _buildInfoField('Address Line 2', _address2Controller, enabled: true),
                        _buildInfoField('City', _cityController, enabled: true),
                        _buildInfoField('State', _stateController, enabled: true),
                        _buildInfoField('Country', _countryController, enabled: true),
                        _buildInfoField('Postcode', _postcodeController, enabled: true),
                      ],
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