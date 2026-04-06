import 'package:flutter/material.dart';

class ChangePassScreen extends StatefulWidget {
  @override
  _ChangePassScreenState createState() => _ChangePassScreenState();
}

class _ChangePassScreenState extends State<ChangePassScreen> {
  final _formKey = GlobalKey<FormState>();
  String _oldPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _isLoading = false;

  // Function to save the form and validate inputs
  void _submit() {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    
    if (_newPassword != _confirmPassword) {
      _showErrorDialog("Passwords do not match");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    // Here you can add your password change logic.
    // After successful password change, you can show a success message or navigate to another screen.
    
    setState(() {
      _isLoading = false;
    });
  }

  // Function to show error dialogs
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildPasswordField('Old Password', (value) {
                      _oldPassword = value!;
                    }),
                    SizedBox(height: 20),
                    _buildPasswordField('New Password', (value) {
                      _newPassword = value!;
                    }),
                    SizedBox(height: 20),
                    _buildPasswordField('Confirm New Password', (value) {
                      _confirmPassword = value!;
                    }),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blue,
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Change Password'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Function to build password fields
  Widget _buildPasswordField(String label, Function(String?) onSaved) {
    return TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (value.length < 6) {
          return '$label must be at least 6 characters long';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}
