import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart' as app_auth;


class ChangePassScreen extends StatefulWidget {
  const ChangePassScreen({super.key});

  @override
  _ChangePassScreenState createState() => _ChangePassScreenState();
}

class _ChangePassScreenState extends State<ChangePassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Password fields ──────────────────────────────────────────────────────────
  final _passFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // ── Username fields ──────────────────────────────────────────────────────────
  final _userFormKey = GlobalKey<FormState>();
  final _newUsernameController = TextEditingController();
  final _confirmPasswordForUsernameController = TextEditingController();
  bool _showPassForUsername = false;

  bool _isLoading = false;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const _hostname = 'https://devcms.com.my/charmsAPI/api';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newUsernameController.dispose();
    _confirmPasswordForUsernameController.dispose();
    super.dispose();
  }

  // ── Change Password ──────────────────────────────────────────────────────────
  Future<void> _submitPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    final authProvider = context.read<app_auth.Auth>();
    final username = authProvider.username;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_hostname/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorDialog(data['message'] ?? 'Failed to change password');
      }
    } catch (error) {
      if (mounted) _showErrorDialog('An error occurred: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Change Username ──────────────────────────────────────────────────────────
  Future<void> _submitUsername() async {
    if (!_userFormKey.currentState!.validate()) return;
    final authProvider = context.read<app_auth.Auth>();
    final currentUsername = authProvider.username;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_hostname/user/change-username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': currentUsername,
          'new_username': _newUsernameController.text,
          'password': _confirmPasswordForUsernameController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        // Update username in auth provider if your Auth provider supports it
        // authProvider.updateUsername(_newUsernameController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username changed successfully! Please log in again.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorDialog(data['message'] ?? 'Failed to change username');
      }
    } catch (error) {
      if (mounted) _showErrorDialog('An error occurred: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Error',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(message,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK',
                style:
                    TextStyle(color: _primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    IconData icon,
    TextEditingController controller,
    bool show,
    VoidCallback onToggle, {
    String? Function(String?)? extraValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !show,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20,
              color: const Color(0xFF94A3B8),
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (value.length < 8) return '$label must be at least 8 characters';
          if (extraValidator != null) return extraValidator(value);
          return null;
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'ACCOUNT SETTINGS',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        backgroundColor: _primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Top banner ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        top: 24, bottom: 20, left: 24, right: 24),
                    decoration: const BoxDecoration(
                      color: _primary,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded,
                              size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Manage Your Account',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Update your username or password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.indigo.shade200,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Tab bar ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: _primary,
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                            unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 15),
                                    SizedBox(width: 6),
                                    Text('Password'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_rounded, size: 15),
                                    SizedBox(width: 6),
                                    Text('Username'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tab content ────────────────────────────────────────────
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ── Tab 1: Change Password ─────────────────────────
                        _buildFormCard(
                          formKey: _passFormKey,
                          onSubmit: _submitPassword,
                          buttonLabel: 'Update Password',
                          buttonIcon: Icons.check_circle_outline_rounded,
                          children: [
                            _buildPasswordField(
                              'Current Password',
                              Icons.lock_outline_rounded,
                              _oldPasswordController,
                              _showOld,
                              () => setState(() => _showOld = !_showOld),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: _cardBorder, height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('New password',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade400,
                                            letterSpacing: 0.5)),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: _cardBorder, height: 1)),
                                ],
                              ),
                            ),
                            _buildPasswordField(
                              'New Password',
                              Icons.lock_rounded,
                              _newPasswordController,
                              _showNew,
                              () => setState(() => _showNew = !_showNew),
                            ),
                            _buildPasswordField(
                              'Confirm New Password',
                              Icons.lock_clock_rounded,
                              _confirmPasswordController,
                              _showConfirm,
                              () =>
                                  setState(() => _showConfirm = !_showConfirm),
                              extraValidator: (value) {
                                if (value != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        // ── Tab 2: Change Username ─────────────────────────
                        _buildFormCard(
                          formKey: _userFormKey,
                          onSubmit: _submitUsername,
                          buttonLabel: 'Update Username',
                          buttonIcon: Icons.person_rounded,
                          children: [
                            _buildTextField(
                              'New Username',
                              Icons.person_outline_rounded,
                              _newUsernameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new username';
                                }
                                if (value.length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: _cardBorder, height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('Confirm identity',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade400,
                                            letterSpacing: 0.5)),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: _cardBorder, height: 1)),
                                ],
                              ),
                            ),
                            _buildPasswordField(
                              'Current Password',
                              Icons.lock_outline_rounded,
                              _confirmPasswordForUsernameController,
                              _showPassForUsername,
                              () => setState(() =>
                                  _showPassForUsername = !_showPassForUsername),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormCard({
    required GlobalKey<FormState> formKey,
    required VoidCallback onSubmit,
    required String buttonLabel,
    required IconData buttonIcon,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...children,
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSubmit,
                  icon: Icon(buttonIcon, size: 20),
                  label: Text(
                    buttonLabel,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}