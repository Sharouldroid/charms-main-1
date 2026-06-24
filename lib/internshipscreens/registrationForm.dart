import 'package:flutter/material.dart';
import 'package:charms/internshipscreens/docs_upload.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:charms/internshipmodels/register.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegistrationForm extends StatefulWidget {
  final int scheduleId;
  final int userId;

  const RegistrationForm({
    super.key,
    required this.scheduleId,
    required this.userId,
  });

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _icNumberController = TextEditingController(); // ✅ NEW: IC number
  final _institutionController = TextEditingController();
  final _programmeController = TextEditingController();
  final _courseController = TextEditingController();
  final _facultyController = TextEditingController();
  final _branchController = TextEditingController();
  final _streetAddress1Controller = TextEditingController();
  final _streetAddress2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  //final _passwordController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  int? _age;
  String? _phoneNumber;
  String? _countryCode;
  String? _selectedState;

  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  final List<String> _levelsOfStudy = [
    'Diploma',
    'STPM',
    'Bachelor',
    'Master',
    'PhD'
  ];
  String? _selectedLevel;
  String? _selectedCountry;
  String? _selectedInstitution;

  final List<String> _malaysianUniversities = [
    'Universiti Malaya (UM)',
    'Universiti Sains Malaysia (USM)',
    'Universiti Kebangsaan Malaysia (UKM)',
    'Universiti Putra Malaysia (UPM)',
    'Universiti Teknologi Malaysia (UTM)',
    'Universiti Teknologi MARA (UiTM)',
    'Universiti Islam Antarabangsa Malaysia (UIAM)',
    'Universiti Utara Malaysia (UUM)',
    'Universiti Malaysia Sarawak (UNIMAS)',
    'Universiti Malaysia Sabah (UMS)',
    'Universiti Tun Hussein Onn Malaysia (UTHM)',
    'Universiti Teknikal Malaysia Melaka (UTeM)',
    'Universiti Pendidikan Sultan Idris (UPSI)',
    'Universiti Sultan Zainal Abidin (UniSZA)',
    'Universiti Malaysia Kelantan (UMK)',
    'Universiti Malaysia Pahang (UMP)',
    'Universiti Malaysia Perlis (UniMAP)',
    'Universiti Malaysia Terengganu (UMT)',
    'Universiti Tunku Abdul Rahman (UTAR)',
    'Multimedia University (MMU)',
    'Sunway University',
    'Taylor\'s University',
    'INTI International University',
    'Asia Pacific University (APU)',
    'Management & Science University (MSU)',
    'Universiti Tenaga Nasional (UNITEN)',
    'Others'
  ];

  final List<String> _genders = ['Male', 'Female'];

  final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  // ✅ NEW: Malaysian IC format XXXXXX-XX-XXXX
  final RegExp _icRegExp = RegExp(r'^\d{6}-\d{2}-\d{4}$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _icNumberController.dispose(); // ✅ NEW
    _institutionController.dispose();
    _programmeController.dispose();
    _courseController.dispose();
    _facultyController.dispose();
    _branchController.dispose();
    _streetAddress1Controller.dispose();
    _streetAddress2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    //_passwordController.dispose();
    super.dispose();
  }

  // ✅ SOLUTION 1: Enhanced Date Picker with Validation
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Blocks future dates
      helpText: 'Select your date of birth',
      errorFormatText: 'Enter valid date',
      errorInvalidText: 'Enter date in valid range',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // ✅ Extra validation: Ensure date is not in the future
      if (selectedDate.isAfter(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ Date of birth cannot be in the future!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final calculatedAge = _calculateAge(selectedDate);

      // ✅ Validate minimum age requirement
      if (calculatedAge < 16) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 28),
                  const SizedBox(width: 12),
                  const Text('Age Requirement'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You must be at least 16 years old to register for the internship program.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Your age: $calculatedAge years old',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      setState(() {
        _dateOfBirth = selectedDate;
        _age = calculatedAge;
      });

      // Debug logging
      print('');
      print('========================================');
      print('📅 DATE OF BIRTH SELECTED');
      print('========================================');
      print('Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}');
      print('Age: $calculatedAge years');
      print('Valid: ${calculatedAge >= 16 ? "✅ Yes" : "❌ No"}');
      print('========================================');
      print('');
    }
  }

  int _calculateAge(DateTime dob) {
    final DateTime today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }

  // ✅ SOLUTION 3: Enhanced Form Validation
  Future<void> _submitForm() async {
    // ✅ Validate Date of Birth is selected
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Please select your date of birth',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Validate age is valid
    if (_age == null || _age! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Invalid date of birth. Please select a valid date.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Validate minimum age
    if (_age! < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ You must be at least 16 years old. Your age: $_age',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Ensure state is set correctly
      String finalState = '';
      if (_selectedCountry == 'Malaysia') {
        finalState = _selectedState ?? '';
      } else {
        finalState = _stateController.text;
      }

      final register = Register(
        userId: widget.userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
            : '',
        icNumber: _icNumberController.text.trim(), // ✅ NEW
        age: _age ?? 0,
        gender: _selectedGender ?? '',
        levelOfStudy: _selectedLevel ?? '',
        institutionName: _institutionController.text,
        programme: _programmeController.text,
        course: _courseController.text,
        faculty: _facultyController.text,
        branch: _branchController.text,
        streetAddress1: _streetAddress1Controller.text,
        streetAddress2: _streetAddress2Controller.text,
        city: _cityController.text,
        state: finalState,
        postalCode: _postalCodeController.text,
        country: _selectedCountry ?? '',
        areaCode: _countryCode ?? '',
        phoneNumber: _phoneNumber ?? '',
        email: _emailController.text,
        //password: _passwordController.text,
        scheduleId: widget.scheduleId,
      );

      try {
        print('🚀 Submitting registration...');
        print('Age being submitted: ${_age}');
        print('IC Number: ${_icNumberController.text.trim()}');
        print('Date of Birth: ${DateFormat('yyyy-MM-dd').format(_dateOfBirth!)}');

        final internId = await Provider.of<RegisterProvider>(context, listen: false)
            .registerUser(register);

        print('✅ Registration successful! Intern ID: $internId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registration successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to DocsUpload
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocsUpload(
                userId: widget.userId,
                scheduleId: widget.scheduleId,
              ),
            ),
          );

          // Pop back with success result to refresh schedule calendar
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        print('❌ Registration error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Registration failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fill in all required fields correctly'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Registration Form'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.person_add, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Please fill in your details below',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personal Details Section
              _buildSectionCard(
                'Basic Information',
                Icons.person,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ NEW: IC Number Field (identity info, placed near DOB)
                  _buildTextFormField(
                    controller: _icNumberController,
                    label: 'IC Number (No. Kad Pengenalan)',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your IC number';
                      }
                      if (!_icRegExp.hasMatch(value.trim())) {
                        return 'Format: XXXXXX-XX-XXXX (e.g. 030405-11-0417)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ✅ SOLUTION 2: Enhanced Date of Birth Display with Visual Validation
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () => _selectDateOfBirth(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: _dateOfBirth == null
                              ? Border.all(color: Colors.orange, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _dateOfBirth == null
                                  ? Colors.orange
                                  : Colors.blue[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date of Birth',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateOfBirth == null
                                        ? 'Tap to select *Required'
                                        : DateFormat('dd MMM yyyy')
                                            .format(_dateOfBirth!),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _dateOfBirth == null
                                          ? Colors.orange
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ✅ Age Badge with Validation Colors
                            if (_age != null && _age! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _age! < 16
                                      ? Colors.red[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _age! < 16
                                        ? Colors.red[300]!
                                        : Colors.green[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _age! < 16
                                          ? Icons.error_outline
                                          : Icons.check_circle,
                                      size: 16,
                                      color: _age! < 16
                                          ? Colors.red[800]
                                          : Colors.green[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Age: $_age',
                                      style: TextStyle(
                                        color: _age! < 16
                                            ? Colors.red[800]
                                            : Colors.green[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber,
                                        size: 16, color: Colors.orange[800]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Select DOB',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ✅ Age Requirement Info
                  if (_dateOfBirth != null && _age != null && _age! < 16)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Minimum age requirement: 16 years old',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Gender Section
              _buildSectionCard(
                'Gender',
                Icons.wc,
                [
                  _buildDropdownField(
                    value: _selectedGender,
                    items: _genders,
                    label: 'Gender',
                    icon: Icons.wc,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Please select your gender';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Institution Information Section
              const Text(
                'Institution Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Country Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                items: [
                  'Malaysia',
                  'Singapore',
                  'Brunei',
                  'Thailand',
                  'Indonesia',
                  'Philippines',
                  'Others'
                ].map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Country'),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _selectedInstitution = null;
                    _institutionController.clear();
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select your country';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Level of Study Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                items: _levelsOfStudy.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Level of Study'),
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select your level of study';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Institution Field
              if (_selectedCountry == 'Malaysia') ...[
                DropdownButtonFormField<String>(
                  value: _selectedInstitution,
                  items: _malaysianUniversities.map((university) {
                    return DropdownMenuItem<String>(
                      value: university,
                      child: Text(university),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                      labelText: 'University/Institution'),
                  onChanged: (value) {
                    setState(() {
                      _selectedInstitution = value;
                      if (value != 'Others') {
                        _institutionController.text = value!;
                      } else {
                        _institutionController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select your university';
                    return null;
                  },
                ),
                if (_selectedInstitution == 'Others') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _institutionController,
                    decoration: const InputDecoration(
                        labelText: 'Please specify your institution'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your institution';
                      }
                      return null;
                    },
                  ),
                ],
              ] else if (_selectedCountry != null) ...[
                TextFormField(
                  controller: _institutionController,
                  decoration: const InputDecoration(labelText: 'Institution'),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your institution';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Faculty
              TextFormField(
                controller: _facultyController,
                decoration: const InputDecoration(labelText: 'Faculty'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your faculty';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Branch
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(labelText: 'Branch'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your branch';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Programme
              TextFormField(
                controller: _programmeController,
                decoration: const InputDecoration(labelText: 'Programme'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your programme';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Course
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Course'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your course';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Address Information
              const Text(
                'Address Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Street Address 1
              TextFormField(
                controller: _streetAddress1Controller,
                decoration: const InputDecoration(labelText: 'Street Address 1'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your street address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Street Address 2
              TextFormField(
                controller: _streetAddress2Controller,
                decoration: const InputDecoration(labelText: 'Street Address 2 (Optional)'),
              ),
              const SizedBox(height: 16),

              // Country Picker
              Container(
                alignment: Alignment.centerLeft,
                child: CountryListPick(
                  theme: CountryTheme(
                    isShowFlag: true,
                    isShowTitle: true,
                    isShowCode: false,
                    isDownIcon: true,
                    showEnglishName: true,
                  ),
                  initialSelection: '+60',
                  onChanged: (CountryCode? code) {
                    setState(() {
                      _selectedCountry = code?.name ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // State Field
              _selectedCountry == 'Malaysia'
                  ? DropdownButtonFormField<String>(
                      value: _selectedState,
                      items: _malaysianStates.map((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      decoration: const InputDecoration(labelText: 'State'),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _stateController.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a state';
                        }
                        return null;
                      },
                    )
                  : TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your state';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your city';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Postal Code
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(labelText: 'Postal Code'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your postal code';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Phone Number
              IntlPhoneField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                initialCountryCode: 'MY',
                onChanged: (phone) {
                  setState(() {
                    _phoneNumber = phone.number;
                    _countryCode = phone.countryCode;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your email';
                  if (!_emailRegExp.hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.blue[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build section cards
  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper method to build styled text form fields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  // Helper method to build styled dropdown fields
  Widget _buildDropdownField<T>({
    required T? value,
    required List<T> items,
    required String label,
    required IconData icon,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}