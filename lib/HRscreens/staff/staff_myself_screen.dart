import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRwidgets/custom_drawer.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';

class StaffMySelfScreen extends StatefulWidget {
  @override
  State<StaffMySelfScreen> createState() => _StaffMySelfScreenState();
}

class _StaffMySelfScreenState extends State<StaffMySelfScreen> {
  int _selectedIndex = 4;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  
  late Staff? _currentStaff;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _formKey = GlobalKey<FormState>();
  
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
      final staffsProvider = Provider.of<Staffs>(context, listen: false);
      final authProvider = Provider.of<Auth>(context, listen: false);
      
      // FIXED: fetchStaff() no longer takes a hostname parameter
      await staffsProvider.fetchStaff();
      
      final staffList = staffsProvider.staffList;
      if (staffList.isNotEmpty) {
        _currentStaff = staffList.firstWhere(
          (staff) => staff.username == authProvider.username,
          orElse: () => throw Exception('Staff not found'),
        );
        
        _updateControllers();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading staff data: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllers() {
    if (_currentStaff != null) {
      _nameController.text = "${_currentStaff!.firstname} ${_currentStaff!.lastname}";
      _icNumberController.text = _currentStaff!.idNum;
      _dobController.text = _currentStaff!.dob;
      _emailController.text = _currentStaff!.email;
      _phoneController.text = _currentStaff!.phone;
      _nationalityController.text = _currentStaff!.nationality;
      _religionController.text = _currentStaff!.religion;
      _genderController.text = _currentStaff!.emergencyGender == 1 ? "Male" : "Female";
      _maritalStatusController.text = _currentStaff!.maritalStatus == 1 ? "Single" : "Married";
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
      _emergencyGenderController.text = _currentStaff!.emergencyGender == 1 ? "Male" : "Female";
      _emergencyPhoneController.text = _currentStaff!.emergencyPhone;
    }
  }

  Future<void> _updateStaffInfo() async {
    if (_formKey.currentState!.validate() && _currentStaff != null) {
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
        );

        await Provider.of<Staffs>(context, listen: false)
            .updateStaffDetails(_currentStaff!.staffId, updatedStaff);

        setState(() {
          _isEditing = false;
          _currentStaff = updatedStaff;
        });

        await _loadStaffData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $error')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() => _selectedIndex = index);
    
    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = StaffDashboardScreen(username: _currentStaff?.username ?? '');
        break;
      case 1:
        nextScreen = LeaveDashboardScreen(username: _currentStaff?.username ?? '', staffId: _currentStaff?.staffId ?? 0);
        break;
      case 2:
        nextScreen = PayrollDashboardScreen(username: _currentStaff?.username ?? '');
        break;
      case 3:
        nextScreen = ClaimDashboardScreen(username: _currentStaff?.username ?? '', staffId: _currentStaff?.staffId ?? 0);
        break;
      case 4:
        return; // Already here
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  Future<void> _logout() async {
    await Provider.of<Auth>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, {bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: !enabled ? Colors.grey[200] : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('CHARMS STAFF', style: TextStyle(color: Colors.white)),
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _nameController.text,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    const Text("Personal Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInfoField('Name', _nameController, enabled: _isEditing),
                    _buildInfoField('IC Number', _icNumberController, enabled: _isEditing),
                    _buildInfoField('Date of Birth', _dobController, enabled: _isEditing),
                    _buildInfoField('Email', _emailController, enabled: _isEditing),
                    _buildInfoField('Phone', _phoneController, enabled: _isEditing),
                    _buildInfoField('Nationality', _nationalityController, enabled: _isEditing),
                    _buildInfoField('Religion', _religionController, enabled: _isEditing),
                    _buildInfoField('Gender', _genderController, enabled: _isEditing),
                    _buildInfoField('Marital Status', _maritalStatusController, enabled: _isEditing),
                    _buildInfoField('Status', _statusController, enabled: _isEditing),
                    _buildInfoField('Occupation', _occupationController, enabled: _isEditing),
                    
                    const SizedBox(height: 20),
                    const Text("Address Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInfoField('Address Line 1', _addressController, enabled: _isEditing),
                    _buildInfoField('Address Line 2', _address2Controller, enabled: _isEditing),
                    _buildInfoField('City', _cityController, enabled: _isEditing),
                    _buildInfoField('State', _stateController, enabled: _isEditing),
                    _buildInfoField('Country', _countryController, enabled: _isEditing),
                    _buildInfoField('Postcode', _postcodeController, enabled: _isEditing),
                    _buildInfoField('Office Phone', _officePhoneController, enabled: _isEditing),
                    
                    const SizedBox(height: 20),
                    const Text("Emergency Contact Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInfoField('Emergency Contact Name', _emergencyNameController, enabled: _isEditing),
                    _buildInfoField('Emergency Contact IC', _emergencyIcController, enabled: _isEditing),
                    _buildInfoField('Emergency Contact Relation', _emergencyRelationController, enabled: _isEditing),
                    _buildInfoField('Emergency Gender', _emergencyGenderController, enabled: _isEditing),
                    _buildInfoField('Emergency Contact Phone', _emergencyPhoneController, enabled: _isEditing),
                  ],
                ),
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