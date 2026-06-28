import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class InternChangePasswordScreen extends StatefulWidget {
  final int userId;
  final String username;

  const InternChangePasswordScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<InternChangePasswordScreen> createState() =>
      _InternChangePasswordScreenState();
}

class _InternChangePasswordScreenState
    extends State<InternChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Password fields ──────────────────────────────────────────────────────
  final _passFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // ── Username fields ──────────────────────────────────────────────────────
  final _userFormKey = GlobalKey<FormState>();
  final _newUsernameController = TextEditingController();
  final _passwordForUsernameController = TextEditingController();
  bool _showPassForUsername = false;

  bool _isLoading = false;

  final Color _primary = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newUsernameController.dispose();
    _passwordForUsernameController.dispose();
    super.dispose();
  }

  // ── Change Password ──────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.hostname}/api/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': widget.username,
          'old_password': _currentPasswordController.text,
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
            duration: Duration(seconds: 2),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showErrorDialog(data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Change Username ──────────────────────────────────────────────────────
  Future<void> _changeUsername() async {
    if (!_userFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.hostname}/api/user/change-username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': widget.username,
          'new_username': _newUsernameController.text,
          'password': _passwordForUsernameController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username changed! Please log in again.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showErrorDialog(data['message'] ?? 'Failed to change username');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('An error occurred: $e');
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
            child: Text('OK',
                style: TextStyle(
                    color: _primary, fontWeight: FontWeight.w700)),
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
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off : Icons.visibility, size: 20),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (value.length < 6) return '$label must be at least 6 characters';
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
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // ── Header banner with tabs ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 20, bottom: 16, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.manage_accounts_rounded,
                            size: 34, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Manage Your Account',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your username or password',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // ── Tab bar ──────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
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

                // ── Tab views ─────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Tab 1: Change Password ─────────────────────────
                      _buildFormCard(
                        formKey: _passFormKey,
                        onSubmit: _changePassword,
                        buttonLabel: 'Change Password',
                        buttonIcon: Icons.lock_reset,
                        children: [
                          _buildPasswordField(
                            'Current Password',
                            Icons.lock_outline,
                            _currentPasswordController,
                            _showCurrent,
                            () => setState(() => _showCurrent = !_showCurrent),
                          ),
                          _buildPasswordField(
                            'New Password',
                            Icons.lock,
                            _newPasswordController,
                            _showNew,
                            () => setState(() => _showNew = !_showNew),
                          ),
                          _buildPasswordField(
                            'Confirm New Password',
                            Icons.lock_clock,
                            _confirmPasswordController,
                            _showConfirm,
                            () => setState(() => _showConfirm = !_showConfirm),
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
                        onSubmit: _changeUsername,
                        buttonLabel: 'Change Username',
                        buttonIcon: Icons.person_rounded,
                        children: [
                          _buildTextField(
                            'New Username',
                            Icons.person_outline,
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
                          _buildPasswordField(
                            'Current Password (to confirm)',
                            Icons.lock_outline,
                            _passwordForUsernameController,
                            _showPassForUsername,
                            () => setState(
                                () => _showPassForUsername = !_showPassForUsername),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                  label: Text(buttonLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
