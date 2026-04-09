import 'package:charms/models/user.dart';
import 'package:charms/providers/auth.dart';
import 'package:charms/providers/users.dart';
import 'package:charms/screens/auth_screen.dart';
import 'package:charms/widgets/auth/auth_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class UpdateProfile extends StatefulWidget {
  final int userid;
  final String hostname;
  // We keep this for fallback, but we will primarily fetch from Provider
  final User userdata; 

  const UpdateProfile({
    super.key,
    required this.userid,
    required this.hostname,
    required this.userdata,
  });

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _profileFormKey = GlobalKey();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey();

  late User _editedUser;
  var _isLoading = false;
  var _isInit = true; // To track initialization
  DateTime? _selectedDate;
  String? _selectedCountry;
  var _isDeleting = false; // specifically for delete button


  // Password fields
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 1. DYNAMIC FIX: Force fetch latest data from server when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Users>(context, listen: false)
          .fetchIndividual(widget.hostname, widget.userid);
    });
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // 2. DYNAMIC FIX: Get user from Provider (State) instead of Widget (Constructor)
      // This ensures we have the version currently in memory, not the one passed 5 mins ago
      try {
        final userFromProvider = Provider.of<Users>(context)
            .userlist
            .firstWhere((u) => u.id == widget.userid.toString());
        _editedUser = userFromProvider;
      } catch (e) {
        _editedUser = widget.userdata; // Fallback
      }

      _selectedDate = DateTime.tryParse(_editedUser.dob);
      _selectedCountry = _editedUser.country;
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  // --- Helper to reduce repetitive User object creation ---
  void _updateUserField({
    String? firstname, String? lastname, String? phone, String? dob,
    String? address1, String? address2, String? city, dynamic postcode,
    String? state, String? country, String? occupation, String? email,
    String? idnum, int? gender
  }) {
    _editedUser = User(
      id: _editedUser.id,
      firstname: firstname ?? _editedUser.firstname,
      lastname: lastname ?? _editedUser.lastname,
      phone: phone ?? _editedUser.phone,
      dob: dob ?? _editedUser.dob,
      address1: address1 ?? _editedUser.address1,
      address2: address2 ?? _editedUser.address2,
      city: city ?? _editedUser.city,
      postcode: postcode ?? _editedUser.postcode,
      state: state ?? _editedUser.state,
      country: country ?? _editedUser.country,
      occupation: occupation ?? _editedUser.occupation,
      username: _editedUser.username, // Username usually cannot be changed here
      email: email ?? _editedUser.email,
      password: _editedUser.password,
      usertype: _editedUser.usertype,
      status: _editedUser.status,
      gender: gender ?? _editedUser.gender,
      idnum: idnum ?? _editedUser.idnum,
    );
  }

  void _showSuccessNotification(String message) {
    showSimpleNotification(
      Text(message, style: const TextStyle(color: Colors.white)),
      background: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }



 void _confirmDeleteAccount() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
          'Are you sure you want to delete your account? This action can be reversed by contacting support.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            Navigator.of(ctx).pop(); // Close the dialog
            _deleteAccount(); // Call deletion
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}



  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    _profileFormKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      await Provider.of<Users>(context, listen: false)
          .update(widget.hostname, _editedUser, widget.userid);

      _showSuccessNotification('Profile updated successfully');
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      showSimpleNotification(
         Text(error.toString(), style: const TextStyle(color: Colors.white)),
         background: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await Provider.of<Users>(context, listen: false).updateLogin(
        widget.hostname,
        UserLogin(
          id: widget.userid,
          username: _editedUser.username,
          password: _passwordController.text,
        ),
        widget.userid,
      );

      _showSuccessNotification('Password changed successfully');
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      showSimpleNotification(
         const Text('Failed to update password', style: TextStyle(color: Colors.white)),
         background: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _updateUserField(dob: pickedDate.toIso8601String());
      });
    }
  }


  Future<void> softDeleteUser(String hostname, int userid) async {
  // ✅ FIX: Use the correct soft-delete endpoint defined in api.php
  final url = '${hostname}users/soft-delete/$userid'; 
  
  try {
    // Change to PUT request
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user. Status: ${response.statusCode}');
    }
  } catch (error) {
    rethrow;
  }
}
  
Future<void> _deleteAccount() async {
  setState(() => _isDeleting = true);

  try {
    await softDeleteUser(widget.hostname, widget.userid);

    // Show success notification
    _showSuccessNotification('Your account has been deleted');

    // Navigate to LoginPage and remove all previous routes
    if (mounted) {

      await Provider.of<Auth>(context, listen: false).logout();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const AuthScreen()),
        (route) => false,
      );
    }
  } catch (error) {
    showSimpleNotification(
      const Text('Failed to delete account', style: TextStyle(color: Colors.white)),
      background: Colors.red,
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for better contrast
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.person_outline)),
            Tab(text: 'Security', icon: Icon(Icons.lock_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildProfileTab(), _buildPasswordTab()],
      ),
    );
  }

  // ==========================================
  // TAB 1: PROFILE DETAILS
  // ==========================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            // --- Personal Info Card ---
            _buildSectionHeader('Personal Information'),
            _buildFormCard(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField('First Name', _editedUser.firstname, Icons.person, (val) => _updateUserField(firstname: val))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Last Name', _editedUser.lastname, Icons.person_outline, (val) => _updateUserField(lastname: val))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('I/C or Passport', _editedUser.idnum, Icons.badge_outlined, (val) => _updateUserField(idnum: val)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: _inputDecoration('Date of Birth', Icons.calendar_today),
                          child: Text(
                            _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : 'Select Date',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _editedUser.gender,
                        decoration: _inputDecoration('Gender', Icons.people_outline),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Male')),
                          DropdownMenuItem(value: 2, child: Text('Female')),
                        ],
                        onChanged: (val) => setState(() => _updateUserField(gender: val)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // --- Contact Info Card ---
            const SizedBox(height: 20),
            _buildSectionHeader('Contact Details'),
            _buildFormCard(
              children: [
                _buildTextField('Email Address', _editedUser.email, Icons.email_outlined, (val) => _updateUserField(email: val), isEmail: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Phone Number', _editedUser.phone, Icons.phone_outlined, (val) => _updateUserField(phone: val), isPhone: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Occupation', _editedUser.occupation, Icons.work_outline, (val) => _updateUserField(occupation: val))),
                  ],
                )
              ],
            ),

            // --- Address Info Card ---
            const SizedBox(height: 20),
            _buildSectionHeader('Address Information'),
            _buildFormCard(
              children: [
                 _buildTextField('Address Line 1', _editedUser.address1, Icons.home_outlined, (val) => _updateUserField(address1: val)),
                 const SizedBox(height: 16),
                 _buildTextField('Address Line 2', _editedUser.address2, Icons.home_work_outlined, (val) => _updateUserField(address2: val), required: false),
                 const SizedBox(height: 16),
                 Row(
                   children: [
                     Expanded(child: _buildTextField('City', _editedUser.city, Icons.location_city, (val) => _updateUserField(city: val))),
                     const SizedBox(width: 16),
                     Expanded(
                       child: TextFormField(
                         initialValue: _editedUser.postcode.toString(),
                         decoration: _inputDecoration('Postcode', Icons.markunread_mailbox_outlined),
                         keyboardType: TextInputType.number,
                         validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
                         onSaved: (val) => _updateUserField(postcode: int.tryParse(val ?? '0')),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                   initialValue: _selectedCountry,
                   decoration: _inputDecoration('Country', Icons.public),
                   items: AuthConstants.countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                   onChanged: (val) {
                     setState(() {
                       _selectedCountry = val;
                       _updateUserField(country: val, state: ''); // Reset state if country changes
                     });
                   },
                 ),
                 const SizedBox(height: 16),
                 if (_selectedCountry == 'Malaysia')
                   DropdownButtonFormField<String>(
                     initialValue: AuthConstants.statesOfMalaysia.contains(_editedUser.state) ? _editedUser.state : null,
                     decoration: _inputDecoration('State', Icons.map),
                     items: AuthConstants.statesOfMalaysia.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                     onChanged: (val) => _updateUserField(state: val),
                   )
                 else
                   _buildTextField('State / Province', _editedUser.state, Icons.map, (val) => _updateUserField(state: val)),
              ],
            ),

            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  onPressed: _updateProfile,
                  child: const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
             const SizedBox(height: 30),

            const SizedBox(height: 16),
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
  backgroundColor: Colors.redAccent,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
),
onPressed: _confirmDeleteAccount, // <-- Show confirmation dialog
child: _isDeleting
    ? const CircularProgressIndicator(
        color: Colors.white,
      )
    : const Text(
        'DELETE ACCOUNT',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white, // <-- use color instead of foreground
        ),
      ),

  ),
),


          ],
        ),
      ),
    );


    
  }

  // ==========================================
  // TAB 2: PASSWORD
  // ==========================================
  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          children: [
             _buildSectionHeader('Security Settings'),
             _buildFormCard(
               children: [
                 TextFormField(
                   initialValue: _editedUser.username,
                   decoration: _inputDecoration('Username', Icons.person_pin).copyWith(filled: true, fillColor: Colors.grey[200]),
                   enabled: false,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _passwordController,
                   decoration: _inputDecoration('New Password', Icons.lock_outline),
                   obscureText: true,
                   validator: (val) => (val != null && val.length < 6) ? 'Min 6 characters' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _confirmPasswordController,
                   decoration: _inputDecoration('Confirm Password', Icons.lock_reset),
                   obscureText: true,
                   validator: (val) {
                     if (val?.isEmpty ?? true) return 'Required';
                     if (val != _passwordController.text) return "Passwords don't match";
                     return null;
                   },
                 ),
               ],
             ),
             const SizedBox(height: 30),
             if (_isLoading)
               const CircularProgressIndicator()
             else
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.redAccent, // Red for sensitive actions
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   onPressed: _updatePassword,
                   child: const Text('CHANGE PASSWORD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,)),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // UI HELPERS
  // ==========================================

  Widget _buildSectionHeader(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(String label, String? initialValue, IconData icon, Function(String?) onSaved, {bool required = true, bool isEmail = false, bool isPhone = false}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: _inputDecoration(label, icon),
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
      validator: (val) {
        if (required && (val?.isEmpty ?? true)) return 'Required';
        if (isEmail && (val != null && !val.contains('@'))) return 'Invalid Email';
        return null;
      },
      onSaved: onSaved,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
