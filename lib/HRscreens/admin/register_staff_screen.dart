import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Added for web check
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRproviders/staffs.dart';

class RegisterStaffScreen extends StatelessWidget {
  const RegisterStaffScreen({super.key});

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('REGISTER STAFF',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: const RegisterStaffForm(),
    );
  }
}

class RegisterStaffForm extends StatefulWidget {
  const RegisterStaffForm({super.key});

  @override
  _RegisterStaffFormState createState() => _RegisterStaffFormState();
}

class _RegisterStaffFormState extends State<RegisterStaffForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final Map<String, String> _staffData = {
    'userid': '',
    'username': '',
    'passkey': '',
    'firstname': '',
    'lastname': '',
    'dob': '',
    'gender': '',
    'occupation': '',
    'phone': '',
    'email': '',
    'address1': '',
    'address2': '',
    'city': '',
    'postcode': '',
    'state': '',
    'country': '',
    'usertype': '',
    'id_num': '',
    'filename': '',
    'category': '',
    'nationality': '',
    'religion': '',
    'marital_status': '',
    'office_phone': '',
    'emergency_name': '',
    'emergency_ic': '',
    'emergency_relation': '',
    'emergency_gender': '',
    'emergency_phone': '',
    'department': '', // ✅ NEW
  };

  bool _isLoading = false;
  DateTime? _selectedDate;
  XFile? _profileImage; // ✅ Changed to XFile
  final ImagePicker _picker = ImagePicker();

  late String _tempPassword; // ✅ ADD THIS
  String _generateTempPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#!';
    final rand = Random.secure();
    return List.generate(10, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  // Modern Color Constants
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tempPassword = _generateTempPassword(); //auto-generate once
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _profileImage = picked); // ✅ Assign XFile directly
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      _staffData['password'] = _tempPassword;
      _staffData['passkey'] = _tempPassword;
      _staffData['category'] = (_staffData['category'] ?? '').isEmpty ? '1' : _staffData['category']!;
      _staffData['usertype'] = (_staffData['usertype'] ?? '').isEmpty ? '9' : _staffData['usertype']!;
      _staffData['marital_status'] = (_staffData['marital_status'] ?? '').isEmpty ? '1' : _staffData['marital_status']!;
      _staffData['emergency_gender'] = (_staffData['emergency_gender'] ?? '').isEmpty ? '1' : _staffData['emergency_gender']!;
      _staffData['filename'] = _staffData['filename'] ?? '';

      final int staffId = await Provider.of<Auth>(context, listen: false).registerStaff(_staffData);

      // ✅ Upload photo if selected (Pass XFile directly)
      if (_profileImage != null) {
        await Provider.of<Staffs>(context, listen: false).uploadStaffPhoto(staffId, _profileImage!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff registered successfully!'), backgroundColor: Colors.teal),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $error'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _staffData['dob'] = pickedDate.toIso8601String();
      });
    }
  }

  // Helper for modern input decoration
  InputDecoration _buildInputDecoration(String label, IconData icon) {
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

  // Helper for required input decoration (shows red asterisk)
  InputDecoration _buildRequiredInputDecoration(String label, IconData icon) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              children: <Widget>[
                
                // Profile Picture Section
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade50,
                          // ✅ Web-safe background image logic
                          backgroundImage: _profileImage != null
                              ? (kIsWeb
                                  ? NetworkImage(_profileImage!.path) as ImageProvider
                                  : FileImage(File(_profileImage!.path)))
                              : null,
                          child: _profileImage == null
                              ? Icon(Icons.person_rounded, size: 60, color: Colors.blue.shade200)
                              : null,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                          onPressed: _pickImage,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Profile Photo', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ),

                // Account Details
                _buildSectionHeader('Account Details', Icons.manage_accounts_rounded),
                TextFormField(
                  decoration: _buildRequiredInputDecoration('Username', Icons.alternate_email_rounded),
                  textInputAction: TextInputAction.next,
                  // ✅ KEEP: username validator
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a username' : null,
                  onSaved: (value) => _staffData['username'] = value!,
                ),
                const SizedBox(height: 16),

                // Personal Information
                _buildSectionHeader('Personal Information', Icons.badge_rounded),
                TextFormField(
                  decoration: _buildRequiredInputDecoration('First Name', Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                   validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a first name' : null,
                  onSaved: (value) => _staffData['firstname'] = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildRequiredInputDecoration('Last Name', Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a last name' : null,
                  onSaved: (value) => _staffData['lastname'] = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('ID Number', Icons.credit_card_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                  onSaved: (value) => _staffData['id_num'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  decoration: _buildInputDecoration('Date of Birth', Icons.calendar_today_rounded),
                  onTap: () => _pickDate(context),
                  controller: TextEditingController(
                    text: _selectedDate == null ? '' : "${_selectedDate!.toLocal()}".split(' ')[0],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Gender', Icons.wc_rounded),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Male')),
                    DropdownMenuItem(value: '2', child: Text('Female')),
                  ],
                  onChanged: (value) => setState(() => _staffData['gender'] = value!),
                  // removed validator
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Nationality', Icons.flag_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                  onSaved: (value) => _staffData['nationality'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Religion', Icons.mosque_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                  onSaved: (value) => _staffData['religion'] = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Marital Status', Icons.family_restroom_rounded),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Single')),
                    DropdownMenuItem(value: '2', child: Text('Married')),
                  ],
                  onChanged: (value) => setState(() => _staffData['marital_status'] = value!),
                ),

                // Contact Information
                _buildSectionHeader('Contact Information', Icons.contact_mail_rounded),
                TextFormField(
                  decoration: _buildInputDecoration('Phone', Icons.phone_android_rounded),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _staffData['phone'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildRequiredInputDecoration('Email', Icons.email_rounded),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  // ✅ KEEP: email validator
                  validator: (value) => value == null || !value.contains('@') ? 'Please enter a valid email' : null,
                  onSaved: (value) => _staffData['email'] = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Address Line 1', Icons.home_rounded),
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _staffData['address1'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Address Line 2 (Optional)', Icons.home_work_rounded),
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _staffData['address2'] = value ?? '',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: _buildInputDecoration('City', Icons.location_city_rounded),
                        textInputAction: TextInputAction.next,
                        onSaved: (value) => _staffData['city'] = value ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: _buildInputDecoration('Zip Code', Icons.markunread_mailbox_rounded),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onSaved: (value) => _staffData['postcode'] = value ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: _buildInputDecoration('State', Icons.map_rounded),
                        textInputAction: TextInputAction.next,
                        onSaved: (value) => _staffData['state'] = value ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: _buildInputDecoration('Country', Icons.public_rounded),
                        textInputAction: TextInputAction.next,
                        onSaved: (value) => _staffData['country'] = value ?? '',
                      ),
                    ),
                  ],
                ),

                // Employment Details
                _buildSectionHeader('Employment Details', Icons.work_rounded),
                DropdownButtonFormField<String>(
                  decoration: _buildRequiredInputDecoration('Category', Icons.corporate_fare_rounded),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('SEATRU')),
                    DropdownMenuItem(value: '2', child: Text('CMS')),
                    DropdownMenuItem(value: '3', child: Text('Intern')),
                  ],
                  onChanged: (value) => setState(() => _staffData['category'] = value!),
                  onSaved: (value) => _staffData['category'] = value!,
                  // ✅ KEEP: category validator
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),

                // ✅ Department dropdown (after Category)
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Department', Icons.account_tree_rounded),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  items: const [
                    DropdownMenuItem(value: '',                 child: Text('General (No Department)')),
                    DropdownMenuItem(value: 'Marine Biologist', child: Text('Marine Biologist')),
                    DropdownMenuItem(value: 'Taaras',           child: Text('Taaras')),
                  ],
                  onChanged: (value) => setState(() => _staffData['department'] = value ?? ''),
                  onSaved:   (value) => _staffData['department'] = value ?? '',
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: _buildRequiredInputDecoration('Role', Icons.admin_panel_settings_rounded),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  items: const [
                    DropdownMenuItem(value: '6', child: Text('Staff Admin')),
                    DropdownMenuItem(value: '7', child: Text('Staff')),
                    DropdownMenuItem(value: '8', child: Text('Manager')),
                    DropdownMenuItem(value: '9', child: Text('Officer')),
                    DropdownMenuItem(value: '10', child: Text('Trainee')),
                  ],
                  onChanged: (value) => setState(() => _staffData['usertype'] = value!),
                  // ✅ KEEP: role validator
                  validator: (value) => value == null ? 'Please select a role' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Occupation', Icons.work_outline_rounded),
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _staffData['occupation'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Office Phone', Icons.phone_in_talk_rounded),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _staffData['office_phone'] = value ?? '',
                ),

                // Emergency Contact
                _buildSectionHeader('Emergency Contact', Icons.health_and_safety_rounded),
                TextFormField(
                  decoration: _buildInputDecoration('Contact Name', Icons.person_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                  onSaved: (value) => _staffData['emergency_name'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Contact IC Number', Icons.credit_card_rounded),
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _staffData['emergency_ic'] = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Relation', Icons.diversity_1_rounded),
                  textInputAction: TextInputAction.next,
                  // removed validator
                  onSaved: (value) => _staffData['emergency_relation'] = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Contact Gender', Icons.wc_rounded),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Male')),
                    DropdownMenuItem(value: '2', child: Text('Female')),
                  ],
                  onChanged: (value) => setState(() => _staffData['emergency_gender'] = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Contact Phone', Icons.phone_rounded),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  // removed validator
                  onSaved: (value) => _staffData['emergency_phone'] = value ?? '',
                ),
                const SizedBox(height: 32),

                // Submit Button
                if (_isLoading)
                  Center(child: CircularProgressIndicator(color: primaryBlue))
                else
                  ElevatedButton(
                    onPressed: _submit,
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
                      'Register Staff',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}