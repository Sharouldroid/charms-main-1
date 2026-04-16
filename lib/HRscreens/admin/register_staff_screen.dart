import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/auth.dart';

class RegisterStaffScreen extends StatelessWidget {
  const RegisterStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Staff'),
        centerTitle: true,
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
    // Additional fields for the staff table
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
  };

  bool _isLoading = false;
  DateTime? _selectedDate;

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  setState(() => _isLoading = true);

  try {
    // Ensure password key expected by backend
    _staffData['password'] = _staffData['passkey'] ?? '';

    // Optional defaults to avoid null/empty for required dropdowns
    _staffData['category'] = (_staffData['category'] ?? '').isEmpty ? '1' : _staffData['category']!;
    _staffData['usertype'] = (_staffData['usertype'] ?? '').isEmpty ? '9' : _staffData['usertype']!;
    _staffData['marital_status'] = (_staffData['marital_status'] ?? '').isEmpty ? '1' : _staffData['marital_status']!;
    _staffData['emergency_gender'] = (_staffData['emergency_gender'] ?? '').isEmpty ? '1' : _staffData['emergency_gender']!;
    _staffData['filename'] = _staffData['filename'] ?? '';

    // Call your provider (step1->step2->step3)
    await Provider.of<Auth>(context, listen: false).registerStaff(_staffData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff registered successfully!')),
    );

    // IMPORTANT: return true so StaffList can refresh
    Navigator.of(context).pop(true);
  } catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration failed: $error')),
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
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _staffData['dob'] = pickedDate.toIso8601String();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // Username
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a username'
                      : null,
                  onSaved: (value) => _staffData['username'] = value!,
                ),
                // Password
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (value) {
                    _staffData['passkey'] = value ?? '';
                    _staffData['password'] = value ?? '';
                  },
                ),
                // First Name
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a first name'
                      : null,
                  onSaved: (value) => _staffData['firstname'] = value!,
                ),
                // Last Name
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a last name'
                      : null,
                  onSaved: (value) => _staffData['lastname'] = value!,
                ),
                // ID Number
                TextFormField(
                  decoration: const InputDecoration(labelText: 'ID Number'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your identity card number'
                      : null,
                  onSaved: (value) => _staffData['id_num'] = value!,
                ),
                // Date of Birth
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(context),
                    ),
                  ),
                  onTap: () => _pickDate(context),
                  controller: TextEditingController(
                    text: _selectedDate == null
                        ? ''
                        : "${_selectedDate!.toLocal()}".split(' ')[0],
                  ),
                ),
                // Gender
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Male')),
                    DropdownMenuItem(value: '2', child: Text('Female')),
                  ],
                  onChanged: (value) =>
                      setState(() => _staffData['gender'] = value!),
                  validator: (value) =>
                      value == null ? 'Please choose a gender' : null,
                ),
                // Occupation
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Occupation'),
                  onSaved: (value) => _staffData['occupation'] = value!,
                ),
                // Phone
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _staffData['phone'] = value!,
                ),
                // Email
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Please enter a valid email address'
                      : null,
                  onSaved: (value) => _staffData['email'] = value!,
                ),
                // Address Line 1
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Address Line 1'),
                  onSaved: (value) => _staffData['address1'] = value!,
                ),
                // Address Line 2 (optional)
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Address Line 2 (optional)'),
                  onSaved: (value) => _staffData['address2'] = value!,
                ),
                // City
                TextFormField(
                  decoration: const InputDecoration(labelText: 'City'),
                  onSaved: (value) => _staffData['city'] = value!,
                ),
                // Zip Code
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Zip Code'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _staffData['postcode'] = value!,
                ),
                // State
                TextFormField(
                  decoration: const InputDecoration(labelText: 'State'),
                  onSaved: (value) => _staffData['state'] = value!,
                ),
                // Country
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Country'),
                  onSaved: (value) => _staffData['country'] = value!,
                ),
                // Category of staff 1 = SEATRU, 2 = CMS, 3 = Intern
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('SEATRU')),
                    DropdownMenuItem(value: '2', child: Text('CMS')),
                    DropdownMenuItem(value: '3', child: Text('Intern')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _staffData['category'] =
                          value!; // Ensure this line updates the map
                    });
                  },
                  onSaved: (value) {
                    _staffData['category'] =
                        value!; // Ensure this line saves the value
                  },
                  validator: (value) => value == null
                      ? 'Please select a category'
                      : null, // Add validation
                ),
                // Role
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: '6', child: Text('Staff Admin')),
                    DropdownMenuItem(value: '7', child: Text('Staff')),
                    DropdownMenuItem(value: '8', child: Text('Manager')),
                    DropdownMenuItem(value: '9', child: Text('Officer')),
                    DropdownMenuItem(value: '10', child: Text('Trainee')),
                  ],
                  onChanged: (value) =>
                      setState(() => _staffData['usertype'] = value!),
                  validator: (value) =>
                      value == null ? 'Please select a role' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nationality'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter nationality'
                      : null,
                  onSaved: (value) => _staffData['nationality'] = value!,
                ),

                TextFormField(
                  decoration: const InputDecoration(labelText: 'Religion'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter religion'
                      : null,
                  onSaved: (value) => _staffData['religion'] = value!,
                ),

                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Marital Status'),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Single')),
                    DropdownMenuItem(value: '2', child: Text('Married')),
                  ],
                  onChanged: (value) =>
                      setState(() => _staffData['marital_status'] = value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Office Phone'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _staffData['office_phone'] = value!,
                ),
                // Emergency Contact Name
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter emergency contact name'
                      : null,
                  onSaved: (value) => _staffData['emergency_name'] = value!,
                ),
// Emergency Contact IC
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Emergency Contact IC Number'),
                  onSaved: (value) => _staffData['emergency_ic'] = value!,
                ),
// Emergency Contact Relation
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Relation'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter relation'
                      : null,
                  onSaved: (value) => _staffData['emergency_relation'] = value!,
                ),
// Emergency Contact Gender
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Male')),
                    DropdownMenuItem(value: '2', child: Text('Female')),
                  ],
                  onChanged: (value) =>
                      setState(() => _staffData['emergency_gender'] = value!),
                ),
// Emergency Contact Phone
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter emergency contact phone'
                      : null,
                  onSaved: (value) => _staffData['emergency_phone'] = value!,
                ),

                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Register Staff'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
