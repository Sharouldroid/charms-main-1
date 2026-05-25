import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:charms/main.dart';

class RegistrationStatusPage extends StatefulWidget {
  final int userId;

  const RegistrationStatusPage({
    super.key,
    required this.userId,
  });

  @override
  State<RegistrationStatusPage> createState() => _RegistrationStatusPageState();
}

class _RegistrationStatusPageState extends State<RegistrationStatusPage> {
  bool _isLoading = true;

  // ✅ Now a list to support multiple registrations
  List<Map<String, dynamic>> _registrations = [];
  String? _errorMessage;

  // ✅ Cache schedule details (duration) keyed by schedule_id
  final Map<int, Map<String, dynamic>> _scheduleCache = {};

  @override
  void initState() {
    super.initState();
    _loadRegistrationStatus();
  }

  Future<void> _loadRegistrationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _registrations = [];
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/registers/by-user/${widget.userId}'),
      );

      print('📥 Status check: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ Handle new response format: { "success": true, "data": [...] }
        List<dynamic> rawList = [];

        if (decoded is Map && decoded['data'] != null) {
          final inner = decoded['data'];
          if (inner is List) {
            rawList = inner;
          } else if (inner is Map) {
            rawList = [inner];
          }
        } else if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList = [decoded]; // old single-object fallback
        }

        setState(() {
          _registrations = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });

        // ✅ Fetch schedule details for each registration
        for (final reg in _registrations) {
          final scheduleId = reg['schedule_id'];
          if (scheduleId != null && !_scheduleCache.containsKey(scheduleId)) {
            await _fetchScheduleDetails(scheduleId as int);
          }
        }
        if (mounted) setState(() {});

      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Not registered';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load status';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchScheduleDetails(int scheduleId) async {
    try {
      // ✅ Fetch from schedules list to get duration field
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/schedules'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = decoded is List ? decoded : (decoded['data'] ?? []);
        for (final item in list) {
          final id = item['id'] as int?;
          if (id != null && !_scheduleCache.containsKey(id)) {
            _scheduleCache[id] = Map<String, dynamic>.from(item);
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not fetch schedule $scheduleId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Status'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegistrationStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null || _registrations.isEmpty)
              ? _buildNotRegisteredView()
              : _buildRegisteredView(),
    );
  }

  Widget _buildNotRegisteredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.orange, size: 100.0),
            const SizedBox(height: 20),
            const Text(
              'Not Registered Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You haven\'t registered for an internship schedule yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Register Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100.0),
          const SizedBox(height: 20),
          Text(
            _registrations.length > 1
                ? 'Registered for ${_registrations.length} Sessions!'
                : 'Registration Approved!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ✅ Show a card for each registration
          ..._registrations.asMap().entries.map((entry) {
            final index = entry.key;
            final reg = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Registration ${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Name', '${reg['first_name'] ?? ''} ${reg['last_name'] ?? ''}'),
                      _buildInfoRow('Email', reg['email']),
                      _buildInfoRow('Institution', reg['institution_name']),
                      _buildInfoRow('Programme', reg['programme']),
                      _buildInfoRow('Level', reg['level_of_study']),
                      _buildInfoRow('Duration', () {
                        final scheduleId = reg['schedule_id'] as int?;
                        if (scheduleId == null) return 'N/A';
                        final schedule = _scheduleCache[scheduleId];
                        if (schedule == null) return 'N/A';
                        // Try all possible field names the API might return
                        final duration = schedule['duration'] ??
                            schedule['duration_days'] ??
                            schedule['days'];
                        return duration != null ? '$duration days' : 'N/A';
                      }()),
                      _buildInfoRow(
                        'Registered On',
                        reg['created_at'] != null
                            ? DateFormat('dd MMM yyyy').format(DateTime.parse(reg['created_at']))
                            : 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ value is nullable — no more TypeError
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}