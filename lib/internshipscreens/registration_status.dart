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
  List<Map<String, dynamic>> _registrations = [];
  String? _errorMessage;
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

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];

        if (decoded is Map && decoded['data'] != null) {
          final inner = decoded['data'];
          rawList = inner is List ? inner : [inner];
        } else if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList = [decoded];
        }

        setState(() {
          _registrations = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });

        for (final reg in _registrations) {
          final scheduleId = reg['schedule_id'];
          if (scheduleId != null && !_scheduleCache.containsKey(scheduleId)) {
            await _fetchScheduleDetails(scheduleId as int);
          }
        }
        if (mounted) setState(() {});
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'not_registered';
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
    } catch (_) {}
  }

  String _getScheduleDuration(Map<String, dynamic> reg) {
    final scheduleId = reg['schedule_id'] as int?;
    if (scheduleId == null) return 'N/A';
    final schedule = _scheduleCache[scheduleId];
    if (schedule == null) return 'N/A';
    final duration = schedule['duration'] ?? schedule['duration_days'] ?? schedule['days'];
    return duration != null ? '$duration days' : 'N/A';
  }

  String _getScheduleDates(Map<String, dynamic> reg) {
    final scheduleId = reg['schedule_id'] as int?;
    if (scheduleId == null) return 'N/A';
    final schedule = _scheduleCache[scheduleId];
    if (schedule == null) return 'N/A';
    try {
      final start = DateFormat('dd MMM yyyy').format(DateTime.parse(schedule['start_date']));
      final end = DateFormat('dd MMM yyyy').format(DateTime.parse(schedule['end_date']));
      return '$start – $end';
    } catch (_) {
      return 'N/A';
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Registration Status',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRegistrationStatus,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : (_errorMessage != null || _registrations.isEmpty)
              ? _buildNotRegisteredView()
              : _buildRegisteredView(),
    );
  }

  // ── Loading ───────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 16),
          Text(
            'Checking your status...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Not registered ────────────────────────────────────────────

  Widget _buildNotRegisteredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: Colors.orange, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not Registered Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'You haven\'t registered for an internship schedule yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text(
                  'Register Now',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Registered ────────────────────────────────────────────────

  Widget _buildRegisteredView() {
    return RefreshIndicator(
      onRefresh: _loadRegistrationStatus,
      color: Colors.blueAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildTopBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                children: [
                  ..._registrations.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRegistrationCard(entry.key, entry.value),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        'Back to Dashboard',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top banner ────────────────────────────────────────────────

  Widget _buildTopBanner() {
    final reg = _registrations.first;
    final name = '${reg['first_name'] ?? ''} ${reg['last_name'] ?? ''}'.trim();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            _registrations.length > 1
                ? 'Registered for ${_registrations.length} Sessions'
                : 'Registration Successful!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bannerStat(
                icon: Icons.assignment_rounded,
                label: 'Sessions',
                value: '${_registrations.length}',
              ),
              _bannerDivider(),
              _bannerStat(
                icon: Icons.school_rounded,
                label: 'Institution',
                value: reg['institution_name'] ?? 'N/A',
              ),
              _bannerDivider(),
              _bannerStat(
                icon: Icons.book_rounded,
                label: 'Programme',
                value: reg['programme'] ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _bannerDivider() {
    return Container(
      height: 36,
      width: 0.5,
      color: Colors.white30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ── Registration card ─────────────────────────────────────────

  Widget _buildRegistrationCard(int index, Map<String, dynamic> reg) {
    final name = '${reg['first_name'] ?? ''} ${reg['last_name'] ?? ''}'.trim();
    final registeredOn = reg['created_at'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(reg['created_at']))
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _registrations.length > 1
                            ? 'Registration ${index + 1}'
                            : 'Registration Details',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Registered on $registeredOn',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _sectionLabel('Personal'),
                const SizedBox(height: 10),
                _infoTile(Icons.person_rounded, 'Full Name', name, Colors.blueAccent),
                _infoTile(Icons.email_rounded, 'Email', reg['email'] ?? 'N/A', Colors.purple),

                const SizedBox(height: 16),
                _sectionLabel('Academic'),
                const SizedBox(height: 10),
                _infoTile(Icons.school_rounded, 'Institution', reg['institution_name'] ?? 'N/A', Colors.teal),
                _infoTile(Icons.menu_book_rounded, 'Programme', reg['programme'] ?? 'N/A', Colors.indigo),
                _infoTile(Icons.grade_rounded, 'Level of Study', reg['level_of_study'] ?? 'N/A', Colors.orange),

                const SizedBox(height: 16),
                _sectionLabel('Schedule'),
                const SizedBox(height: 10),
                _infoTile(Icons.timelapse_rounded, 'Duration', _getScheduleDuration(reg), Colors.green),
                _infoTile(Icons.date_range_rounded, 'Period', _getScheduleDates(reg), Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[400],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey[200], height: 1)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}