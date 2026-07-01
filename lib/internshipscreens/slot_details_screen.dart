import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:intl/intl.dart';
import 'package:charms/internshipmodels/schedule.dart';

class SlotDetailsScreen extends StatefulWidget {
  const SlotDetailsScreen({super.key});

  @override
  State<SlotDetailsScreen> createState() => _SlotDetailsScreenState();
}

class _SlotDetailsScreenState extends State<SlotDetailsScreen> {
  List<dynamic> _schedules = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _error;
  int? _expandedIndex;

  // ── Filter state ─────────────────────────────────────────────
  String _filterTeam = 'All';
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _loadSlotDetails();
  }

  Future<void> _loadSlotDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/schedules/details'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _schedules = body['data'] ?? [];
          _summary = body['summary'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load schedules (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  // ── Status is purely date-based ───────────────────────────────
  String _getStatus(String startDate, String endDate) {
    final now = DateTime.now();
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null) return 'Unknown';
    if (now.isBefore(start)) return 'Upcoming';
    if (now.isAfter(end)) return 'Completed';
    return 'Active';
  }

  bool _isAvailable(String startDate, String endDate) {
    return _getStatus(startDate, endDate) != 'Completed';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return Colors.green;
      case 'Upcoming': return Colors.blueAccent;
      case 'Completed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Active': return Colors.green[50]!;
      case 'Upcoming': return Colors.blue[50]!;
      case 'Completed': return Colors.grey[100]!;
      default: return Colors.grey[100]!;
    }
  }

  String? _buildPhotoUrl(String? filepath) {
    if (filepath == null || filepath.isEmpty) return null;
    return 'https://devcms.com.my/charmsAPI/public/storage/$filepath';
  }

  List<dynamic> get _filteredSchedules {
    var list = _filterTeam == 'All'
        ? _schedules
        : _schedules.where((s) => s['description'] == _filterTeam).toList();

    if (_availableOnly) {
      list = list
          .where((s) => _isAvailable(s['start_date'], s['end_date']))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Slot Details'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSlotDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text('Failed to load slots',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadSlotDetails,
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
              : _schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 72, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No schedules found',
                              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSlotDetails,
                      child: Column(
                        children: [
                          // ── Summary header ────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _summaryTile('${_summary['total_slots'] ?? 0}', 'Total Slots', Icons.event_note),
                                _summaryTile('${_summary['active_slots'] ?? 0}', 'Active', Icons.play_circle_outline),
                                _summaryTile('${_summary['upcoming_slots'] ?? 0}', 'Upcoming', Icons.upcoming),
                                _summaryTile('${_summary['total_unique_interns'] ?? 0}', 'Interns', Icons.people),
                              ],
                            ),
                          ),

                          // ── Filter bar ─────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(children: [
                              Row(children: [
                                const Icon(Icons.filter_alt, size: 18, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                const Text('Team:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _filterTeam,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: ['All', ...kInternshipTeams]
                                        .map((t) => DropdownMenuItem(
                                            value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      _filterTeam = v ?? 'All';
                                      _expandedIndex = null;
                                    }),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Checkbox(
                                  value: _availableOnly,
                                  activeColor: Colors.blueAccent,
                                  onChanged: (v) => setState(() {
                                    _availableOnly = v ?? false;
                                    _expandedIndex = null;
                                  }),
                                ),
                                const Text('Available only (Active + Upcoming)',
                                    style: TextStyle(fontSize: 13)),
                              ]),
                            ]),
                          ),

                          // ── Schedule cards ─────────────────────
                          Expanded(
                            child: _filteredSchedules.isEmpty
                                ? Center(
                                    child: Text(
                                      'No schedules match your filters',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredSchedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = _filteredSchedules[index];
                                      final isExpanded = _expandedIndex == index;
                                      final status = _getStatus(schedule['start_date'], schedule['end_date']);
                                      final current = (schedule['current_registrations'] as num).toInt();
                                      final participants = schedule['participants'] as List<dynamic>? ?? [];

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade200),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () {
                                                setState(() {
                                                  _expandedIndex = isExpanded ? null : index;
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(10),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blueAccent.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: const Icon(Icons.event, color: Colors.blueAccent, size: 20),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            schedule['description'] ?? 'Schedule',
                                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: _statusBg(status),
                                                            borderRadius: BorderRadius.circular(99),
                                                          ),
                                                          child: Text(
                                                            status,
                                                            style: TextStyle(
                                                                fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 14),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.calendar_today, size: 13, color: Colors.grey[400]),
                                                        const SizedBox(width: 5),
                                                        Flexible(
                                                          child: Text(
                                                            '${_formatDate(schedule['start_date'])} → ${_formatDate(schedule['end_date'])}',
                                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Icon(Icons.schedule, size: 13, color: Colors.grey[400]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${schedule['duration']} day${(schedule['duration'] as num).toInt() > 1 ? 's' : ''}',
                                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(children: [
                                                      const Icon(Icons.people_alt, size: 14, color: Colors.green),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '$current registered',
                                                        style: const TextStyle(
                                                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                                                      ),
                                                    ]),
                                                    const SizedBox(height: 10),
                                                    if (!isExpanded && participants.isNotEmpty) ...[
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            height: 28,
                                                            width: (participants.length.clamp(1, 3) * 20.0) + 8,
                                                            child: Stack(
                                                              children: participants.take(3).toList().asMap().entries.map((e) {
                                                                final p = e.value;
                                                                final photoUrl = _buildPhotoUrl(p['filepath']);
                                                                final firstName = (p['first_name'] ?? '').toString();
                                                                return Positioned(
                                                                  left: e.key * 18.0,
                                                                  child: CircleAvatar(
                                                                    radius: 14,
                                                                    backgroundColor: Colors.white,
                                                                    child: CircleAvatar(
                                                                      radius: 13,
                                                                      backgroundColor: Colors.blueAccent.withOpacity(0.15),
                                                                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                                                      child: photoUrl == null
                                                                          ? Text(
                                                                              firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                                                              style: const TextStyle(
                                                                                  fontSize: 11,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Colors.blueAccent),
                                                                            )
                                                                          : null,
                                                                    ),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            'View $current participant${current != 1 ? 's' : ''}',
                                                            style: const TextStyle(
                                                                fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w500),
                                                          ),
                                                          const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 18),
                                                        ],
                                                      ),
                                                    ] else if (!isExpanded) ...[
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text('No participants yet',
                                                              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                                        ],
                                                      ),
                                                    ] else ...[
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Text(
                                                            'Hide participants',
                                                            style: TextStyle(
                                                                fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w500),
                                                          ),
                                                          const Icon(Icons.keyboard_arrow_up, color: Colors.blueAccent, size: 18),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (isExpanded) ...[
                                              Divider(color: Colors.grey[100], height: 1),
                                              participants.isEmpty
                                                  ? Padding(
                                                      padding: const EdgeInsets.all(16),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.person_off_outlined, color: Colors.grey[400], size: 18),
                                                          const SizedBox(width: 8),
                                                          Text('No participants yet',
                                                              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                                        ],
                                                      ),
                                                    )
                                                  : ListView.separated(
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                                      itemCount: participants.length,
                                                      separatorBuilder: (_, __) => Divider(color: Colors.grey[100], height: 1),
                                                      itemBuilder: (context, pIndex) {
                                                        final p = participants[pIndex];
                                                        final firstName = p['first_name'] ?? '';
                                                        final lastName = p['last_name'] ?? '';
                                                        final name = '$firstName $lastName'.trim();
                                                        final photoUrl = _buildPhotoUrl(p['filepath']);

                                                        return Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                                          child: Row(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 22,
                                                                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                                                child: photoUrl == null
                                                                    ? Text(
                                                                        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                                                        style: const TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Colors.blueAccent),
                                                                      )
                                                                    : null,
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      name.isEmpty ? 'Unknown' : name,
                                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                                    ),
                                                                    if (p['institution_name'] != null)
                                                                      Text(
                                                                        p['institution_name'],
                                                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    if (p['email'] != null)
                                                                      Text(
                                                                        p['email'],
                                                                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.green[50],
                                                                  borderRadius: BorderRadius.circular(99),
                                                                ),
                                                                child: Text(
                                                                  'Registered',
                                                                  style: TextStyle(
                                                                      fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w500),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _summaryTile(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}