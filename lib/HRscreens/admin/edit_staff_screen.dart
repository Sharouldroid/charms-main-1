import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';

class EditStaffScreen extends StatefulWidget {
  final Staff staff;

  const EditStaffScreen({super.key, required this.staff});

  @override
  _EditStaffScreenState createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController nameController;
  late TextEditingController icNumberController;
  late TextEditingController dobController;
  late TextEditingController nationalityController;
  late TextEditingController religionController;
  late TextEditingController statusController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController countryController;
  late TextEditingController phoneController;
  late TextEditingController officePhoneController;
  late TextEditingController emailController;
  late TextEditingController occupationController;
  late TextEditingController emergencyNameController;
  late TextEditingController emergencyIcController;
  late TextEditingController emergencyRelationController;
  late TextEditingController emergencyPhoneController;

  // ── Dropdown state (replaces free-text controllers for enum fields) ────────
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedEmergencyGender;

  final Color bgColor    = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController           = TextEditingController(text: '${widget.staff.firstname} ${widget.staff.lastname}');
    icNumberController       = TextEditingController(text: widget.staff.idNum);
    dobController            = TextEditingController(text: widget.staff.dob);
    nationalityController    = TextEditingController(text: widget.staff.nationality);
    religionController       = TextEditingController(text: widget.staff.religion);
    statusController         = TextEditingController(text: 'Active');
    addressController        = TextEditingController(text: '${widget.staff.address1}, ${widget.staff.address2}');
    cityController           = TextEditingController(text: widget.staff.city);
    stateController          = TextEditingController(text: widget.staff.state);
    countryController        = TextEditingController(text: widget.staff.country);
    phoneController          = TextEditingController(text: widget.staff.phone);
    officePhoneController    = TextEditingController(text: widget.staff.officePhone);
    emailController          = TextEditingController(text: widget.staff.email);
    occupationController     = TextEditingController(text: widget.staff.occupation);
    emergencyNameController  = TextEditingController(text: widget.staff.emergencyName);
    emergencyIcController    = TextEditingController(text: widget.staff.emergencyIc);
    emergencyRelationController = TextEditingController(text: widget.staff.emergencyRelation);
    emergencyPhoneController = TextEditingController(text: widget.staff.emergencyPhone);

    // ── Initialise dropdowns from integer values ───────────────────────────
    _selectedGender          = widget.staff.gender == 1 ? 'Male' : 'Female';
    _selectedMaritalStatus   = widget.staff.maritalStatus == 1 ? 'Single' : 'Married';
    _selectedEmergencyGender = widget.staff.emergencyGender == 1 ? 'Male' : 'Female';
  }

  @override
  void dispose() {
    nameController.dispose();
    icNumberController.dispose();
    dobController.dispose();
    nationalityController.dispose();
    religionController.dispose();
    statusController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    phoneController.dispose();
    officePhoneController.dispose();
    emailController.dispose();
    occupationController.dispose();
    emergencyNameController.dispose();
    emergencyIcController.dispose();
    emergencyRelationController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryBlue.withOpacity(0.7), size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  /// Standard text field with validation.
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _fieldDecoration(label, icon),
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                ? '$label cannot be empty'
                : null
            : null,
      ),
    );
  }

  /// Dropdown field — used for Gender, Marital Status, Emergency Gender.
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _fieldDecoration(label, icon),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: required
            ? (val) => val == null ? 'Please select $label' : null
            : null,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: const HRAppBar(title: 'EDIT STAFF'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: HRPageContainer(
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

                  // ── Profile avatar ─────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: Icon(Icons.person_rounded, size: 40, color: primaryBlue),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ID: ${widget.staff.staffId}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Personal Details ───────────────────────────────────
                  _buildSectionHeader('Personal Details', Icons.badge_rounded),
                  _buildTextField('Name', nameController, Icons.person_outline_rounded),
                  _buildTextField('IC Number', icNumberController, Icons.credit_card_rounded),
                  _buildTextField('Date of Birth', dobController, Icons.calendar_today_rounded),
                  _buildTextField('Nationality', nationalityController, Icons.flag_rounded),
                  _buildTextField('Religion', religionController, Icons.mosque_rounded),

                  // Gender — dropdown (fixes the bug)
                  _buildDropdownField(
                    label: 'Gender',
                    icon: Icons.wc_rounded,
                    value: _selectedGender,
                    items: const ['Male', 'Female'],
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),

                  // Marital Status — dropdown (fixes the bug)
                  _buildDropdownField(
                    label: 'Marital Status',
                    icon: Icons.family_restroom_rounded,
                    value: _selectedMaritalStatus,
                    items: const ['Single', 'Married'],
                    onChanged: (val) => setState(() => _selectedMaritalStatus = val),
                  ),

                  _buildTextField('Status', statusController, Icons.info_outline_rounded, required: false),

                  // ── Contact & Address ──────────────────────────────────
                  _buildSectionHeader('Contact & Address', Icons.location_on_rounded),
                  _buildTextField('Phone', phoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                  _buildTextField('Office Phone', officePhoneController, Icons.phone_in_talk_rounded, keyboardType: TextInputType.phone, required: false),
                  _buildTextField('Email', emailController, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                  _buildTextField('Occupation', occupationController, Icons.work_outline_rounded, required: false),
                  _buildTextField('Address', addressController, Icons.home_rounded),
                  _buildTextField('City', cityController, Icons.location_city_rounded),
                  _buildTextField('State', stateController, Icons.map_rounded),
                  _buildTextField('Country', countryController, Icons.public_rounded),

                  // ── Emergency Contact ──────────────────────────────────
                  _buildSectionHeader('Emergency Contact', Icons.health_and_safety_rounded),
                  _buildTextField('Emergency Name', emergencyNameController, Icons.person_rounded, required: false),
                  _buildTextField('Emergency IC', emergencyIcController, Icons.credit_card_rounded, required: false),
                  _buildTextField('Emergency Relation', emergencyRelationController, Icons.diversity_1_rounded, required: false),

                  // Emergency Gender — dropdown (fixes the bug)
                  _buildDropdownField(
                    label: 'Emergency Gender',
                    icon: Icons.wc_rounded,
                    value: _selectedEmergencyGender,
                    items: const ['Male', 'Female'],
                    onChanged: (val) => setState(() => _selectedEmergencyGender = val),
                    required: false,
                  ),

                  _buildTextField('Emergency Phone', emergencyPhoneController, Icons.phone_rounded, keyboardType: TextInputType.phone, required: false),

                  const SizedBox(height: 32),

                  // ── Submit ─────────────────────────────────────────────
                  if (_isLoading)
                    Center(child: CircularProgressIndicator(color: primaryBlue))
                  else
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _updateStaffDetails(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Update Staff Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  // ── Save logic ─────────────────────────────────────────────────────────────

  Future<void> _updateStaffDetails(BuildContext context) async {
    setState(() => _isLoading = true);
    final staffProvider = Provider.of<Staffs>(context, listen: false);

    final nameParts = nameController.text.trim().split(' ');
    final firstname = nameParts.isNotEmpty ? nameParts.first : '';
    final lastname  = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final addressParts = addressController.text.split(',');
    final address1 = addressParts.isNotEmpty ? addressParts.first.trim() : '';
    final address2 = addressParts.length > 1
        ? addressParts.sublist(1).join(',').trim()
        : '';

    final updatedStaff = Staff(
      staffId:           widget.staff.staffId,
      userId:            widget.staff.userId,
      username:          widget.staff.username,
      email:             emailController.text,
      usertype:          widget.staff.usertype,
      firstname:         firstname,
      lastname:          lastname,
      occupation:        occupationController.text,
      phone:             phoneController.text,
      category:          widget.staff.category,
      nationality:       nationalityController.text,
      religion:          religionController.text,
      // ── Enum fields read from dropdown state, NOT from text controllers ──
      gender:            _selectedGender == 'Male' ? 1 : 2,
      maritalStatus:     _selectedMaritalStatus == 'Single' ? 1 : 2,
      emergencyGender:   _selectedEmergencyGender == 'Male' ? 1 : 2,
      // ────────────────────────────────────────────────────────────────────
      officePhone:       officePhoneController.text,
      emergencyName:     emergencyNameController.text,
      emergencyIc:       emergencyIcController.text,
      emergencyRelation: emergencyRelationController.text,
      emergencyPhone:    emergencyPhoneController.text,
      idNum:             icNumberController.text,
      dob:               dobController.text,
      address1:          address1,
      address2:          address2,
      city:              cityController.text,
      postcode:          widget.staff.postcode,
      state:             stateController.text,
      country:           countryController.text,
    );

    try {
      await staffProvider.updateStaffDetails(widget.staff.staffId, updatedStaff);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff details updated successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update staff details: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}