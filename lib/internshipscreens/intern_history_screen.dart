import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:charms/main.dart';
import 'intern_list_assesstment.dart';

class InternHistoryScreen extends StatefulWidget {
  final String role;
  final int userId;

  const InternHistoryScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<InternHistoryScreen> createState() => _InternHistoryScreenState();
}

class _InternHistoryScreenState extends State<InternHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Batch tab state ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _allInterns = [];
  Map<String, String> _photoMap = {};
  bool _batchLoading = true;
  String? _batchError;
  String _batchFilter = 'all'; // all / upcoming / active / completed
  final Set<int> _expandedBatches = {};

  // ── Document tab state ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _submissions = [];
  bool _docLoading = true;
  String _docFilterStatus = 'all';
  String _docFilterInternship = 'completed';

  static const _gradStart = Colors.blueAccent;
  static const _gradEnd = Color(0xFF7B40FB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBatches();
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadBatches() async {
    setState(() {
      _batchLoading = true;
      _batchError = null;
    });
    try {
      final schedRes = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/schedules'),
      );
      final internRes = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/registers'),
      );
      final photoMap = await fetchAllPhotos();

      if (!mounted) return;

      if (schedRes.statusCode == 200 && internRes.statusCode == 200) {
        final schedDecoded = jsonDecode(schedRes.body);
        final List<dynamic> schedList = schedDecoded is List
            ? schedDecoded
            : ((schedDecoded as Map)['data'] ?? []);

        final internDecoded = jsonDecode(internRes.body);
        final List<dynamic> internList = internDecoded is List
            ? internDecoded
            : ((internDecoded as Map)['data'] ?? []);

        setState(() {
          _schedules = schedList.cast<Map<String, dynamic>>();
          _allInterns = internList.cast<Map<String, dynamic>>();
          _photoMap = photoMap;
          _batchLoading = false;
        });
      } else {
        setState(() {
          _batchError = 'Failed to load batch data';
          _batchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _batchError = 'Error: $e';
          _batchLoading = false;
        });
      }
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _docLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
            '${AppConfig.hostname}/api/internship/documents/admin/submissions'),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _submissions = data.cast<Map<String, dynamic>>();
          _docLoading = false;
        });
      } else {
        setState(() => _docLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _docLoading = false);
    }
  }

  // ── Filtered / derived data ───────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredSchedules {
    final now = DateTime.now();
    final result = _schedules.where((s) {
      try {
        final start = DateTime.parse(s['start_date'].toString());
        final end = DateTime.parse(s['end_date'].toString());
        return switch (_batchFilter) {
          'upcoming' => start.isAfter(now),
          'active' => start.isBefore(now) && end.isAfter(now),
          'completed' => end.isBefore(now),
          _ => true,
        };
      } catch (_) {
        return true;
      }
    }).toList();

    result.sort((a, b) {
      try {
        return DateTime.parse(b['start_date'].toString())
            .compareTo(DateTime.parse(a['start_date'].toString()));
      } catch (_) {
        return 0;
      }
    });
    return result;
  }

  List<Map<String, dynamic>> _internsForSchedule(int scheduleId) =>
    _allInterns.where((i) {
      final sid = i['schedule_id'];
      if (sid == null) return false;
      return (sid as num).toInt() == scheduleId;
    }).toList();

  List<Map<String, dynamic>> get _filteredSubmissions {
    var result = _submissions;
    if (_docFilterStatus != 'all') {
      result =
          result.where((s) => s['status'] == _docFilterStatus).toList();
    }
    if (_docFilterInternship != 'all') {
      result = result
          .where((s) => s['internship_status'] == _docFilterInternship)
          .toList();
    }
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return 'N/A';
    }
  }

  String _batchStatus(Map<String, dynamic> s) {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(s['start_date'].toString());
      final end = DateTime.parse(s['end_date'].toString());
      if (start.isAfter(now)) return 'upcoming';
      if (end.isBefore(now)) return 'completed';
      return 'active';
    } catch (_) {
      return 'unknown';
    }
  }

  Color _statusColor(String status) => switch (status) {
        'active' => Colors.green,
        'completed' => Colors.blueAccent,
        'upcoming' => Colors.orange,
        'approved' => Colors.green,
        'rejected' => Colors.red,
        'resubmit' => Colors.orange,
        _ => Colors.grey,
      };

  IconData _statusIcon(String status) => switch (status) {
        'active' => Icons.play_circle_rounded,
        'completed' => Icons.check_circle_rounded,
        'upcoming' => Icons.schedule_rounded,
        'approved' => Icons.check_circle_rounded,
        'rejected' => Icons.cancel_rounded,
        'resubmit' => Icons.replay_rounded,
        _ => Icons.help_rounded,
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Intern History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _gradStart,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              _loadBatches();
              _loadDocuments();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.groups_rounded), text: 'Batches'),
            Tab(icon: Icon(Icons.description_rounded), text: 'Resumes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBatchesTab(),
          _buildDocumentsTab(),
        ],
      ),
    );
  }

  // ── Batches Tab ───────────────────────────────────────────────────────────

  Widget _buildBatchesTab() {
    if (_batchLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent));
    }
    if (_batchError != null) {
      return _buildError(_batchError!, _loadBatches);
    }

    final schedules = _filteredSchedules;

    return Column(
      children: [
        _buildBatchFilterBar(),
        Expanded(
          child: schedules.isEmpty
              ? _buildEmpty('No batches found for this filter.')
              : RefreshIndicator(
                  onRefresh: _loadBatches,
                  color: Colors.blueAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: schedules.length,
                    itemBuilder: (_, i) => _buildBatchCard(schedules[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBatchFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in {
              'all': 'All',
              'upcoming': 'Upcoming',
              'active': 'Active',
              'completed': 'Completed',
            }.entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: _batchFilter == entry.key,
                  onSelected: (_) =>
                      setState(() => _batchFilter = entry.key),
                  selectedColor: Colors.blueAccent,
                  labelStyle: TextStyle(
                    color: _batchFilter == entry.key
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> schedule) {
    final id = schedule['id'] as int;
    final status = _batchStatus(schedule);
    final interns = _internsForSchedule(id);
    final isExpanded = _expandedBatches.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom:
                  isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedBatches.remove(id);
              } else {
                _expandedBatches.add(id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gradStart, _gradEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_fmt(schedule['start_date']?.toString())} – ${_fmt(schedule['end_date']?.toString())}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (schedule['description'] != null &&
                                schedule['description']
                                    .toString()
                                    .isNotEmpty)
                              Text(
                                schedule['description'].toString(),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statChip(Icons.people_rounded,
                          '${interns.length} intern${interns.length == 1 ? '' : 's'}',
                          Colors.blueAccent),
                      const SizedBox(width: 8),
                      if (schedule['duration'] != null)
                        _statChip(Icons.timelapse_rounded,
                            '${schedule['duration']} days', Colors.purple),
                      const Spacer(),
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded intern list
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 0.8),
            if (interns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 16),
                child: Text(
                  'No interns registered for this batch.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              )
            else
              ...interns.map((i) => _buildInternTile(i)),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildInternTile(Map<String, dynamic> intern) {
    final firstName = intern['first_name']?.toString() ?? '';
    final lastName = intern['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final userId = intern['user_id']?.toString() ??
        intern['id']?.toString() ??
        '';
    final photoUrl = _photoMap.containsKey(userId)
        ? buildPhotoUrl(_photoMap[userId])
        : null;
    final institution = intern['institution_name']?.toString() ?? '';
    final registeredOn = intern['created_at'] != null
        ? _fmt(intern['created_at'].toString())
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Row(
        children: [
          internAvatar(firstName, photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'Intern #$userId',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (institution.isNotEmpty)
                  Text(
                    institution,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (registeredOn.isNotEmpty)
            Text(registeredOn,
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ── Documents Tab ─────────────────────────────────────────────────────────

  Widget _buildDocumentsTab() {
    if (_docLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    final docs = _filteredSubmissions;

    return Column(
      children: [
        _buildDocFilterBar(),
        Expanded(
          child: docs.isEmpty
              ? _buildEmpty('No documents found for this filter.')
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  color: Colors.blueAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (_, i) => _buildDocCard(docs[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDocFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Internship Status',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in {
                'all': 'All',
                'active': 'Active',
                'completed': 'Completed',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _docFilterInternship == entry.key,
                  onSelected: (_) =>
                      setState(() => _docFilterInternship = entry.key),
                  selectedColor: Colors.blueAccent,
                  labelStyle: TextStyle(
                    color: _docFilterInternship == entry.key
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Resume Status',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in {
                'all': 'All',
                'pending': 'Pending',
                'approved': 'Approved',
                'rejected': 'Rejected',
                'resubmit': 'Resubmit',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _docFilterStatus == entry.key,
                  onSelected: (_) =>
                      setState(() => _docFilterStatus = entry.key),
                  selectedColor: entry.key == 'all'
                      ? Colors.blueAccent
                      : _statusColor(entry.key),
                  labelStyle: TextStyle(
                    color: _docFilterStatus == entry.key
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> submission) {
    final status = submission['status']?.toString() ?? 'pending';
    final firstName = submission['first_name']?.toString() ?? '';
    final lastName = submission['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final fileName =
        submission['file_name']?.toString() ?? 'Unnamed File';
    final submittedOn = submission['created_at'] != null
        ? _fmt(submission['created_at'].toString())
        : '';
    final internshipStatus =
        submission['internship_status']?.toString() ?? '';
    final comments = submission['admin_comments']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon(status),
                  color: _statusColor(status), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      _statusBadge(status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullName.isNotEmpty ? fullName : 'Unknown',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      comments,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (submittedOn.isNotEmpty)
                        Text(submittedOn,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                      if (submittedOn.isNotEmpty &&
                          internshipStatus.isNotEmpty)
                        Text(' • ',
                            style: TextStyle(color: Colors.grey[300])),
                      if (internshipStatus.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (internshipStatus == 'completed'
                                    ? Colors.blueAccent
                                    : Colors.green)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            internshipStatus[0].toUpperCase() +
                                internshipStatus.substring(1),
                            style: TextStyle(
                              fontSize: 10,
                              color: internshipStatus == 'completed'
                                  ? Colors.blueAccent
                                  : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  // ── Shared small widgets ──────────────────────────────────────────────────

  Widget _statusBadge(String status, {bool compact = false}) {
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(_statusIcon(status),
                color: _statusColor(status), size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
