import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:charms/main.dart';
import 'package:charms/internshipmodels/alumni_update.dart';
import 'package:charms/internshipservices/alumni_service.dart';
import 'package:charms/internshipservices/schedule_service.dart';

class AlumniUpdateScreen extends StatefulWidget {
  final int userId;

  /// True when an admin is viewing an intern's alumni history (read-only:
  /// no submission form). False for the alumnus viewing/submitting their own.
  final bool isAdminView;

  /// Display name of the intern, used in the title when [isAdminView] is true.
  final String? internName;

  const AlumniUpdateScreen({
    super.key,
    required this.userId,
    this.isAdminView = false,
    this.internName,
  });

  @override
  State<AlumniUpdateScreen> createState() => _AlumniUpdateScreenState();
}

class _AlumniUpdateScreenState extends State<AlumniUpdateScreen> {
  final AlumniService _alumniService = AlumniService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<AlumniUpdate> _updates = [];

  final _organisationController = TextEditingController();
  final _roleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatus = kAlumniStatuses.first;

  @override
  void initState() {
    super.initState();
    if (widget.isAdminView) {
      _loadUpdates();
    } else {
      _checkEligibilityThenLoad();
    }
  }

  @override
  void dispose() {
    _organisationController.dispose();
    _roleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _screenTitle {
    if (!widget.isAdminView) return 'Career Updates';
    final name = widget.internName?.trim();
    return (name != null && name.isNotEmpty) ? "$name's Updates" : 'Alumni Updates';
  }

  // Only alumni whose internship has actually ended may submit an update.
  // Mirrors the registration → schedule lookup used in intern_timeline_screen.dart.
  Future<void> _checkEligibilityThenLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final regResponse = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/registers/by-user/${widget.userId}'),
      );

      if (regResponse.statusCode == 404 || regResponse.statusCode == 204) {
        setState(() { _errorMessage = 'not_registered'; _isLoading = false; });
        return;
      }
      if (regResponse.statusCode != 200) {
        setState(() { _errorMessage = 'Failed to load your registration.'; _isLoading = false; });
        return;
      }

      final regDecoded = jsonDecode(regResponse.body);
      Map<String, dynamic>? regData;
      if (regDecoded is Map && regDecoded['data'] != null) {
        final inner = regDecoded['data'];
        regData = inner is List ? (inner.isNotEmpty ? inner.first : null) : inner;
      } else if (regDecoded is List && regDecoded.isNotEmpty) {
        regData = regDecoded.first;
      } else if (regDecoded is Map && regDecoded['id'] != null) {
        regData = regDecoded as Map<String, dynamic>;
      }

      final scheduleId = regData?['schedule_id'] as int?;
      if (regData == null || scheduleId == null) {
        setState(() { _errorMessage = 'not_registered'; _isLoading = false; });
        return;
      }

      final scheduleService = ScheduleService(baseUrl: AppConfig.hostname);
      final allSchedules = await scheduleService.fetchSchedules();
      final matching = allSchedules.where((s) => s.id == scheduleId).toList();
      if (matching.isEmpty) {
        setState(() { _errorMessage = 'Your registered schedule could not be found.'; _isLoading = false; });
        return;
      }

      final isCompleted = DateTime.now().isAfter(matching.first.endDate);
      if (!isCompleted) {
        setState(() { _errorMessage = 'not_completed'; _isLoading = false; });
        return;
      }

      await _loadUpdates();
    } catch (e) {
      setState(() { _errorMessage = 'Something went wrong. Please try again.'; _isLoading = false; });
    }
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final updates = await _alumniService.fetchUpdates(widget.userId);
      updates.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      setState(() {
        _updates = updates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load updates.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_organisationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your organisation/institution'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _alumniService.createUpdate(
        userId: widget.userId,
        status: _selectedStatus,
        organisation: _organisationController.text.trim(),
        roleOrProgramme: _roleController.text.trim(),
        notes: _notesController.text.trim(),
      );
      _organisationController.clear();
      _roleController.clear();
      _notesController.clear();
      await _loadUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Update submitted!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _refresh() =>
      widget.isAdminView ? _loadUpdates() : _checkEligibilityThenLoad();

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  Color _statusColor(String status) {
    switch (status) {
      case 'Employed': return Colors.green;
      case 'Studying': return Colors.blueAccent;
      case 'Job Seeking': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }
    if (_errorMessage == 'not_registered') {
      return _buildMessageState(
        icon: Icons.event_busy,
        title: 'No internship registered',
        message: 'You need to register for an internship slot before you can share a career update.',
      );
    }
    if (_errorMessage == 'not_completed') {
      return _buildMessageState(
        icon: Icons.hourglass_top_rounded,
        title: 'Not available yet',
        message: 'Career updates open up once your internship has ended. Check back after your end date.',
      );
    }
    if (_errorMessage != null) {
      return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
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
    return RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.blueAccent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.isAdminView) ...[
                          _buildSubmitCard(),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          widget.isAdminView ? 'Update History' : 'Your Update History',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        if (_updates.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                widget.isAdminView
                                    ? 'No updates submitted yet'
                                    : 'No updates submitted yet — share your first one above',
                                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                              ),
                            ),
                          )
                        else
                          ..._updates.map(_buildUpdateCard),
                      ],
                    ),
                  ),
                );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_outlined, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text('Share a Career Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Current Status',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: kAlumniStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedStatus = v ?? kAlumniStatuses.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _organisationController,
            decoration: InputDecoration(
              labelText: 'Company / Institution',
              hintText: 'e.g. Universiti Malaysia Terengganu',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roleController,
            decoration: InputDecoration(
              labelText: 'Role / Programme',
              hintText: 'e.g. Junior Developer, Masters in Marine Biology',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Anything else you\'d like to share (optional)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitUpdate,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(AlumniUpdate update) {
    final color = _statusColor(update.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  update.status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              const Spacer(),
              Text(_formatDate(update.submittedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 10),
          if (update.organisation.isNotEmpty)
            Text(update.organisation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (update.roleOrProgramme.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(update.roleOrProgramme,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          if (update.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(update.notes, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
