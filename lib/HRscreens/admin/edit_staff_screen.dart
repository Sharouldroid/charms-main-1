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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Edit Staff Details', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Details
                Text("Personal Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                buildTextField("Name", nameController),
                buildTextField("IC Number", icNumberController),
                buildTextField("Date of Birth", dobController),
                buildTextField("Nationality", nationalityController),
                buildTextField("Religion", religionController),
                buildTextField("Gender", genderController),
                buildTextField("Marital Status", maritalStatusController),
                buildTextField("Status", statusController),
                SizedBox(height: 20),
                
                // Address Details
                Text("Address Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                buildTextField("Address", addressController),
                buildTextField("City", cityController),
                buildTextField("State", stateController),
                buildTextField("Country", countryController),
                buildTextField("Phone", phoneController),
                buildTextField("Office Phone", officePhoneController),
                buildTextField("Email", emailController),
                buildTextField("Occupation", occupationController),
                
                SizedBox(height: 20),

                // Emergency Contact Details
                Text("Emergency Contact Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                buildTextField("Emergency Name", emergencyNameController),
                buildTextField("Emergency IC", emergencyIcController),
                buildTextField("Emergency Relation", emergencyRelationController),
                buildTextField("Emergency Gender", emergencyGenderController),
                buildTextField("Emergency Phone", emergencyPhoneController),

                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle form submission
                        _updateStaffDetails(context);
                      }
                    },
                    child: Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to create a text field with validation
  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
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

  // Update staff details using the provider
  Future<void> _updateStaffDetails(BuildContext context) async {
  final staffProvider = Provider.of<Staffs>(context, listen: false);

  final updatedStaff = Staff(
    staffId: widget.staff.staffId,
    userId: widget.staff.userId,
    username: widget.staff.username,
    email: emailController.text,
    usertype: widget.staff.usertype,
    firstname: nameController.text.split(' ')[0],
    lastname: nameController.text.split(' ')[1],
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
    address1: addressController.text.split(',')[0].trim(),
    address2: addressController.text.split(',')[1].trim(),
    city: cityController.text,
    postcode: widget.staff.postcode,
    state: stateController.text,
    country: countryController.text,
  );

  try {
await staffProvider.updateStaffDetails(widget.staff.staffId, updatedStaff); //    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Staff details updated successfully!")),
    );
    
    Navigator.pop(context);
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update staff details: $error")),
    );
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