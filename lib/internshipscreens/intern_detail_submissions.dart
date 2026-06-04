import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:charms/internshipmodels/register.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:provider/provider.dart';

class InternDetailScreen extends StatefulWidget {
  final int internId;

  const InternDetailScreen({super.key, required this.internId});

  @override
  State<InternDetailScreen> createState() => _InternDetailScreenState();
}

class _InternDetailScreenState extends State<InternDetailScreen> {
  Register? _intern;
  String? _photoUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInternWithPhoto();
  }

  Future<void> _loadInternWithPhoto() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Load intern details with photo in parallel
      final results = await Future.wait([
        context.read<RegisterProvider>().getInternDetails(widget.internId),
        _fetchPhoto(widget.internId),
      ]);

      setState(() {
        _intern   = results[0] as Register;
        _photoUrl = results[1] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<String?> _fetchPhoto(int internId) async {
  try {
    final url = '${AppConfig.hostname}/api/internship/registers/$internId/with-photo';
    print('DEBUG photo URL: $url');
    final response = await http.get(Uri.parse(url));
    print('DEBUG status: ${response.statusCode}');
    print('DEBUG body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final filepath = data['filepath'];
      print('DEBUG filepath value: $filepath');

      if (filepath != null && filepath.toString().isNotEmpty) {
        // Handle if filepath already includes 'storage/'
        final cleanPath = filepath.toString().startsWith('storage/')
            ? filepath.toString().replaceFirst('storage/', '')
            : filepath.toString();

        return 'https://devcms.com.my/charmsAPI/public/storage/$cleanPath';
      }
    }
  } catch (e) {
    print('DEBUG error: $e');
  }
  return null;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Intern Details'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load intern details',
                          style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadInternWithPhoto,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header card with photo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // ✅ Show real photo if available, else initial avatar
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              backgroundImage: _photoUrl != null
                                  ? NetworkImage(_photoUrl!) as ImageProvider
                                  : null,
                              child: _photoUrl == null
                                  ? Text(
                                      _intern!.firstName.isNotEmpty
                                          ? _intern!.firstName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_intern!.firstName} ${_intern!.lastName}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _intern!.email,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_user,
                                            size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Intern',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _sectionTitle('Personal Information'),
                      _infoCard([
                        _infoRow(Icons.cake, 'Age', '${_intern!.age}'),
                        _infoRow(Icons.person, 'Gender', _intern!.gender),
                        _infoRow(Icons.calendar_today, 'Date of Birth', _intern!.dateOfBirth),
                      ]),

                      const SizedBox(height: 16),

                      _sectionTitle('Contact Information'),
                      _infoCard([
                        _infoRow(Icons.phone, 'Phone', '${_intern!.areaCode} ${_intern!.phoneNumber}'),
                        _infoRow(Icons.email, 'Email', _intern!.email),
                      ]),

                      const SizedBox(height: 16),

                      _sectionTitle('Academic Information'),
                      _infoCard([
                        _infoRow(Icons.school, 'Institution', _intern!.institutionName),
                        _infoRow(Icons.menu_book, 'Programme', _intern!.programme),
                        _infoRow(Icons.class_, 'Course', _intern!.course),
                        _infoRow(Icons.layers, 'Level of Study', _intern!.levelOfStudy),
                        if (_intern!.faculty != null && _intern!.faculty!.isNotEmpty)
                          _infoRow(Icons.account_balance, 'Faculty', _intern!.faculty!),
                      ]),

                      const SizedBox(height: 16),

                      _sectionTitle('Address'),
                      _infoCard([
                        _infoRow(Icons.location_on, 'Street',
                            _intern!.streetAddress2 != null && _intern!.streetAddress2!.isNotEmpty
                                ? '${_intern!.streetAddress1}, ${_intern!.streetAddress2}'
                                : _intern!.streetAddress1),
                        _infoRow(Icons.location_city, 'City', _intern!.city),
                        _infoRow(Icons.map, 'State', _intern!.state),
                        _infoRow(Icons.markunread_mailbox, 'Postal Code', _intern!.postalCode),
                        _infoRow(Icons.flag, 'Country', _intern!.country),
                      ]),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}