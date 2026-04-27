import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';

class EditStaffScreen extends StatefulWidget {
  final Staff staff;

  const EditStaffScreen({super.key, required this.staff});

  @override
  _EditStaffScreenState createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for staff personal, address, and occupation details
  late TextEditingController nameController;
  late TextEditingController icNumberController;
  late TextEditingController dobController;
  late TextEditingController nationalityController;
  late TextEditingController religionController;
  late TextEditingController genderController;
  late TextEditingController maritalStatusController;
  late TextEditingController statusController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController countryController;
  late TextEditingController phoneController;
  late TextEditingController officePhoneController;
  late TextEditingController emailController;
  late TextEditingController occupationController;

  // Controllers for emergency contact details
  late TextEditingController emergencyNameController;
  late TextEditingController emergencyIcController;
  late TextEditingController emergencyRelationController;
  late TextEditingController emergencyGenderController;
  late TextEditingController emergencyPhoneController;

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with staff data
    nameController = TextEditingController(text: "${widget.staff.firstname} ${widget.staff.lastname}");
    icNumberController = TextEditingController(text: widget.staff.idNum);
    dobController = TextEditingController(text: widget.staff.dob);
    nationalityController = TextEditingController(text: widget.staff.nationality);
    religionController = TextEditingController(text: widget.staff.religion);
    genderController = TextEditingController(text: widget.staff.emergencyGender == 1 ? "Male" : "Female");
    maritalStatusController = TextEditingController(text: widget.staff.maritalStatus == 1 ? "Single" : "Married");
    statusController = TextEditingController(text: "Active"); // Default value
    addressController = TextEditingController(text: "${widget.staff.address1}, ${widget.staff.address2}");
    cityController = TextEditingController(text: widget.staff.city);
    stateController = TextEditingController(text: widget.staff.state);
    countryController = TextEditingController(text: widget.staff.country);
    phoneController = TextEditingController(text: widget.staff.phone);
    officePhoneController = TextEditingController(text: widget.staff.officePhone);
    emailController = TextEditingController(text: widget.staff.email);
    occupationController = TextEditingController(text: widget.staff.occupation);

    // Initialize emergency contact details
    emergencyNameController = TextEditingController(text: widget.staff.emergencyName);
    emergencyIcController = TextEditingController(text: widget.staff.emergencyIc);
    emergencyRelationController = TextEditingController(text: widget.staff.emergencyRelation);
    emergencyGenderController = TextEditingController(text: widget.staff.emergencyGender == 1 ? "Male" : "Female");
    emergencyPhoneController = TextEditingController(text: widget.staff.emergencyPhone);
  }

  // Helper for Section Headers
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

  // Modernized helper function to create a text field with validation and icons
  Widget buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
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
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // Modern Background
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('EDIT STAFF', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2
          ),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
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
                  
                  // Profile Header Indicator
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
                          "ID: ${widget.staff.staffId}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Personal Details
                  _buildSectionHeader("Personal Details", Icons.badge_rounded),
                  buildTextField("Name", nameController, Icons.person_outline_rounded),
                  buildTextField("IC Number", icNumberController, Icons.credit_card_rounded),
                  buildTextField("Date of Birth", dobController, Icons.calendar_today_rounded),
                  buildTextField("Nationality", nationalityController, Icons.flag_rounded),
                  buildTextField("Religion", religionController, Icons.mosque_rounded),
                  buildTextField("Gender", genderController, Icons.wc_rounded),
                  buildTextField("Marital Status", maritalStatusController, Icons.family_restroom_rounded),
                  buildTextField("Status", statusController, Icons.info_outline_rounded),
                  
                  // Address Details
                  _buildSectionHeader("Contact & Address", Icons.location_on_rounded),
                  buildTextField("Phone", phoneController, Icons.phone_android_rounded),
                  buildTextField("Office Phone", officePhoneController, Icons.phone_in_talk_rounded),
                  buildTextField("Email", emailController, Icons.email_rounded),
                  buildTextField("Occupation", occupationController, Icons.work_outline_rounded),
                  buildTextField("Address", addressController, Icons.home_rounded),
                  buildTextField("City", cityController, Icons.location_city_rounded),
                  buildTextField("State", stateController, Icons.map_rounded),
                  buildTextField("Country", countryController, Icons.public_rounded),
                  
                  // Emergency Contact Details
                  _buildSectionHeader("Emergency Contact", Icons.health_and_safety_rounded),
                  buildTextField("Emergency Name", emergencyNameController, Icons.person_rounded),
                  buildTextField("Emergency IC", emergencyIcController, Icons.credit_card_rounded),
                  buildTextField("Emergency Relation", emergencyRelationController, Icons.diversity_1_rounded),
                  buildTextField("Emergency Gender", emergencyGenderController, Icons.wc_rounded),
                  buildTextField("Emergency Phone", emergencyPhoneController, Icons.phone_rounded),

                  const SizedBox(height: 32),

                  // Submit Button
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
                        "Update Staff Details",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Update staff details using the provider
  Future<void> _updateStaffDetails(BuildContext context) async {
    setState(() => _isLoading = true);
    final staffProvider = Provider.of<Staffs>(context, listen: false);

    final updatedStaff = Staff(
      staffId: widget.staff.staffId,
      userId: widget.staff.userId,
      username: widget.staff.username,
      email: emailController.text,
      usertype: widget.staff.usertype,
      firstname: nameController.text.split(' ').isNotEmpty ? nameController.text.split(' ')[0] : '',
      lastname: nameController.text.split(' ').length > 1 ? nameController.text.split(' ').sublist(1).join(' ') : '',
      occupation: occupationController.text,
      phone: phoneController.text,
      category: widget.staff.category,
      nationality: nationalityController.text,
      religion: religionController.text,
      maritalStatus: maritalStatusController.text == "Single" ? 1 : 2,
      officePhone: officePhoneController.text,
      emergencyName: emergencyNameController.text,
      emergencyIc: emergencyIcController.text,
      emergencyRelation: emergencyRelationController.text,
      emergencyGender: emergencyGenderController.text == "Male" ? 1 : 2,
      emergencyPhone: emergencyPhoneController.text,
      idNum: icNumberController.text,
      dob: dobController.text,
      address1: addressController.text.split(',').isNotEmpty ? addressController.text.split(',')[0].trim() : '',
      address2: addressController.text.split(',').length > 1 ? addressController.text.split(',').sublist(1).join(',').trim() : '',
      city: cityController.text,
      postcode: widget.staff.postcode,
      state: stateController.text,
      country: countryController.text,
    );

    try {
      await staffProvider.updateStaffDetails(widget.staff.staffId, updatedStaff);     
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Staff details updated successfully!"), backgroundColor: Colors.teal),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update staff details: $error"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers when the screen is closed
    nameController.dispose();
    icNumberController.dispose();
    dobController.dispose();
    nationalityController.dispose();
    religionController.dispose();
    genderController.dispose();
    maritalStatusController.dispose();
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
    emergencyGenderController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }
}