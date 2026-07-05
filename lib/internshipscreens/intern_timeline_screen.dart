import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:charms/internshipservices/schedule_service.dart';
import 'package:charms/internshipservices/milestone_service.dart';

class InternTimelineScreen extends StatefulWidget {
  final int userId;

  /// True when an admin is viewing another intern's timeline (read-only:
  /// no milestone add/edit/delete). False for the intern viewing their own.
  final bool isAdminView;

  /// Display name of the intern, used in the title/loading text when
  /// [isAdminView] is true.
  final String? internName;

  const InternTimelineScreen({
    super.key,
    required this.userId,
    this.isAdminView = false,
    this.internName,
  });

  @override
  State<InternTimelineScreen> createState() => _InternTimelineScreenState();
}

class _InternTimelineScreenState extends State<InternTimelineScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Registration data
  int? _scheduleId;
  String _firstName = '';
  String _lastName = '';
  String _institutionName = '';
  String _programme = '';

  // Schedule data
  DateTime? _startDate;
  DateTime? _endDate;
  String _scheduleDescription = '';

  // Milestones
  final MilestoneService _milestoneService = MilestoneService();
  List<InternMilestone> _manualMilestones = [];
  bool _milestonesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  // ── Data loading ──────────────────────────────────────────────

  Future<void> _loadTimelineData() async {
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
        setState(() { _errorMessage = 'Failed to load registration data.'; _isLoading = false; });
        return;
      }

      final regDecoded = jsonDecode(regResponse.body);
      Map<String, dynamic>? regData;

      if (regDecoded is Map && regDecoded['data'] != null) {
        final inner = regDecoded['data'];
        regData = inner is List ? inner.first : inner;
      } else if (regDecoded is List && regDecoded.isNotEmpty) {
        regData = regDecoded.first;
      } else if (regDecoded is Map && regDecoded['id'] != null) {
        regData = regDecoded as Map<String, dynamic>;
      }

      if (regData == null) {
        setState(() { _errorMessage = 'not_registered'; _isLoading = false; });
        return;
      }

      _scheduleId      = regData['schedule_id'] as int?;
      _firstName       = regData['first_name'] ?? '';
      _lastName        = regData['last_name'] ?? '';
      _institutionName = regData['institution_name'] ?? '';
      _programme       = regData['programme'] ?? '';

      if (_scheduleId == null) {
        setState(() { _errorMessage = 'No schedule linked to your registration.'; _isLoading = false; });
        return;
      }

      final scheduleService = ScheduleService(baseUrl: AppConfig.hostname);
      final allSchedules = await scheduleService.fetchSchedules();
      final matching = allSchedules.where((s) => s.id == _scheduleId).toList();

      if (matching.isEmpty) {
        setState(() { _errorMessage = 'Your registered schedule could not be found.'; _isLoading = false; });
        return;
      }

      final schedule = matching.first;
      _startDate           = schedule.startDate;
      _endDate             = schedule.endDate;
      _scheduleDescription = schedule.description;

      await _loadMilestones();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Timeline error: $e');
      setState(() { _errorMessage = 'Something went wrong. Please try again.'; _isLoading = false; });
    }
  }

  Future<void> _loadMilestones() async {
    try {
      final milestones = await _milestoneService.fetchMilestones(widget.userId);
      setState(() => _manualMilestones = milestones);
    } catch (e) {
      debugPrint('Milestone fetch error: $e');
    }
  }

  // ── Computed helpers ──────────────────────────────────────────

  String get _screenTitle {
    if (!widget.isAdminView) return 'My Timeline';
    final name = widget.internName?.trim();
    return (name != null && name.isNotEmpty) ? '$name\'s Timeline' : 'Intern Timeline';
  }

  int get _totalDays => _endDate != null && _startDate != null
      ? _endDate!.difference(_startDate!).inDays : 0;

  int get _daysElapsed {
    if (_startDate == null) return 0;
    final now = DateTime.now();
    if (now.isBefore(_startDate!)) return 0;
    if (now.isAfter(_endDate!)) return _totalDays;
    return now.difference(_startDate!).inDays;
  }

  int get _daysRemaining {
    if (_endDate == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(_endDate!)) return 0;
    return _endDate!.difference(now).inDays;
  }

  double get _progressFraction =>
      _totalDays > 0 ? (_daysElapsed / _totalDays).clamp(0.0, 1.0) : 0.0;

  String get _internshipStatus {
    if (_startDate == null || _endDate == null) return 'Unknown';
    final now = DateTime.now();
    if (now.isBefore(_startDate!)) return 'Upcoming';
    if (now.isAfter(_endDate!)) return 'Completed';
    return 'Active';
  }

  Color get _statusColor {
    switch (_internshipStatus) {
      case 'Active': return Colors.green;
      case 'Upcoming': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Map<String, dynamic>> get _autoMilestones {
    if (_startDate == null || _endDate == null) return [];
    final week1 = _startDate!.add(Duration(days: (_totalDays * 0.10).round()));
    return [
      {
        'label': 'Week 1 Check-in',
        'date': week1,
        'icon': Icons.flag_outlined,
        'isPast': DateTime.now().isAfter(week1),
        'isAuto': true,
        'id': null,
      },
    ];
  }

  Map<String, dynamic> get _endMilestone => {
    'label': 'Internship End',
    'date': _endDate,
    'icon': Icons.school_outlined,
    'isPast': _endDate != null && DateTime.now().isAfter(_endDate!),
    'isAuto': true,
    'id': null,
  };

  List<Map<String, dynamic>> get _allMilestones {
    final List<Map<String, dynamic>> combined = [
      ..._autoMilestones,
      ..._manualMilestones.map((m) => {
            'label': m.title,
            'date': m.milestoneDate,
            'icon': Icons.bookmark_outlined,
            'isPast': DateTime.now().isAfter(m.milestoneDate),
            'isAuto': false,
            'id': m.id,
          }),
      _endMilestone,
    ];
    combined.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return combined;
  }

  // ── Milestone dialogs ─────────────────────────────────────────

  Future<void> _showAddMilestoneDialog() async {
    final titleController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Add Milestone', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Submit Report, Presentation Day',
                  labelText: 'Milestone Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: _endDate ?? DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate == null ? 'Select Date' : _formatDate(selectedDate),
                        style: TextStyle(
                          color: selectedDate == null ? Colors.grey : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in both fields'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _milestonesLoading = true);
                try {
                  await _milestoneService.createMilestone(
                    userId: widget.userId,
                    title: titleController.text.trim(),
                    date: selectedDate!,
                  );
                  await _loadMilestones();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Milestone added!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _milestonesLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditMilestoneDialog(InternMilestone milestone) async {
    final titleController = TextEditingController(text: milestone.title);
    DateTime selectedDate = milestone.milestoneDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Edit Milestone', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Milestone Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: _endDate ?? DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 10),
                      Text(_formatDate(selectedDate), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _milestonesLoading = true);
                try {
                  await _milestoneService.updateMilestone(
                    id: milestone.id,
                    title: titleController.text.trim(),
                    date: selectedDate,
                  );
                  await _loadMilestones();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Milestone updated!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _milestonesLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMilestone(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Milestone', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this milestone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _milestonesLoading = true);
    try {
      await _milestoneService.deleteMilestone(id);
      await _loadMilestones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestone deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _milestonesLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(_screenTitle),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                widget.isAdminView ? 'Loading timeline...' : 'Loading your timeline...',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage == 'not_registered') return _buildNotRegisteredState();
    if (_errorMessage != null) return _buildErrorState();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimelineData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTimelineData,
        color: Colors.blueAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildProgressCard(),
              const SizedBox(height: 16),
              _buildDateInfoCard(),
              const SizedBox(height: 16),
              _buildMilestonesCard(),
              const SizedBox(height: 16),
              _buildInternInfoCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: wrap title Text in Flexible so status badge never gets pushed off
          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Internship Timeline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _internshipStatus == 'Active'
                          ? Icons.circle
                          : _internshipStatus == 'Upcoming'
                              ? Icons.schedule
                              : Icons.check_circle,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _internshipStatus,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_scheduleDescription,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat(label: 'Total Days', value: '$_totalDays', icon: Icons.calendar_today),
              _headerDivider(),
              _headerStat(label: 'Days Done', value: '$_daysElapsed', icon: Icons.check_circle_outline),
              _headerDivider(),
              _headerStat(
                label: 'Days Left',
                value: _internshipStatus == 'Completed' ? 'Done!' : '$_daysRemaining',
                icon: Icons.hourglass_bottom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat({required String label, required String value, required IconData icon}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _headerDivider() => Container(
        height: 40,
        width: 0.5,
        color: Colors.white30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Progress card ─────────────────────────────────────────────

  Widget _buildProgressCard() {
    final percent = (_progressFraction * 100).round();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              const Text('Overall Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('$percent%',
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progressFraction,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _internshipStatus == 'Completed' ? Colors.green : Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(_startDate),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                _internshipStatus == 'Completed'
                    ? '🎉 Internship completed!'
                    : _internshipStatus == 'Upcoming'
                        ? 'Starting in $_daysRemaining days'
                        : '$_daysRemaining days remaining',
                style: TextStyle(
                    fontSize: 12,
                    color: _statusColor,
                    fontWeight: FontWeight.w600),
              ),
              Text(_formatDate(_endDate),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Date info card ────────────────────────────────────────────

  Widget _buildDateInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.date_range, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text('Internship Period',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _dateTile(
                      label: 'Start Date',
                      date: _formatDate(_startDate),
                      icon: Icons.play_circle_outline,
                      color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _dateTile(
                      label: 'End Date',
                      date: _formatDate(_endDate),
                      icon: Icons.stop_circle_outlined,
                      color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timelapse, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Total duration: $_totalDays days',
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(
      {required String label,
      required String date,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(date,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Milestones card ───────────────────────────────────────────

  Widget _buildMilestonesCard() {
    final milestones = _allMilestones;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              const Text('Key Milestones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              if (!widget.isAdminView)
                GestureDetector(
                  onTap: _showAddMilestoneDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.blueAccent, size: 14),
                        SizedBox(width: 4),
                        Text('Add',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_milestonesLoading) ...[
            const SizedBox(height: 12),
            const Center(
                child: CircularProgressIndicator(
                    color: Colors.blueAccent, strokeWidth: 2)),
          ],
          const SizedBox(height: 14),
          ...milestones.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isLast = i == milestones.length - 1;
            final isPast = m['isPast'] as bool;
            final isAuto = m['isAuto'] as bool;
            final milestoneId = m['id'] as int?;
            final isNext =
                !isPast && (i == 0 || milestones[i - 1]['isPast'] == true);

            final internMilestone = milestoneId != null
                ? _manualMilestones
                    .where((ml) => ml.id == milestoneId)
                    .firstOrNull
                : null;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dot + line
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isPast
                                ? Colors.green
                                : isNext
                                    ? Colors.blueAccent
                                    : Colors.grey[200],
                            shape: BoxShape.circle,
                            border: isNext
                                ? Border.all(
                                    color: Colors.blueAccent, width: 2)
                                : null,
                          ),
                          child: Icon(
                            isPast ? Icons.check : (m['icon'] as IconData),
                            color: isPast || isNext
                                ? Colors.white
                                : Colors.grey[400],
                            size: 13,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isPast
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.grey[200],
                              margin:
                                  const EdgeInsets.symmetric(vertical: 3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m['label'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isPast
                                              ? Colors.grey
                                              : isNext
                                                  ? Colors.blueAccent
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isAuto)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.grey.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text('Auto',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(m['date'] as DateTime),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isPast)
                            _statusBadge('Done', Colors.green)
                          else if (isNext)
                            _statusBadge('Up next', Colors.blueAccent),
                          if (!widget.isAdminView && !isAuto && internMilestone != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  _showEditMilestoneDialog(internMilestone),
                              child: const Icon(Icons.edit_outlined,
                                  size: 16, color: Colors.blueAccent),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  _deleteMilestone(internMilestone.id),
                              child: const Icon(Icons.delete_outline,
                                  size: 16, color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // ── Intern info card ──────────────────────────────────────────

  Widget _buildInternInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text('Registration Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outlined, 'Name', '$_firstName $_lastName'),
          _infoRow(Icons.school_outlined, 'Institution', _institutionName),
          _infoRow(Icons.book_outlined, 'Programme', _programme),
          _infoRow(Icons.event_note_outlined, 'Schedule', _scheduleDescription),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ── Not registered ────────────────────────────────────────────

  Widget _buildNotRegisteredState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                widget.isAdminView ? 'No internship registered' : 'No internship registered yet',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isAdminView
                    ? 'This intern has not registered for an internship slot yet.'
                    : 'Register for an internship slot first to see your timeline here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTimelineData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card wrapper ──────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}