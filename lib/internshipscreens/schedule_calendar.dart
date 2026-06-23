import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/schedule_provider.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'registrationForm.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class ScheduleCalendar extends StatefulWidget {
  final bool isAdmin;
  final int userId;

  const ScheduleCalendar({
    super.key,
    required this.isAdmin,
    required this.userId,
  });

  @override
  _ScheduleCalendarState createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _duration;

  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  List<int> _userRegisteredScheduleIds = [];
  Map<int, Map<String, dynamic>> _registrationCounts = {};

  // ── Filter state ─────────────────────────────────────────────
  String _filterTeam = 'All';
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
    _loadSchedules();
    _loadUserRegistrations();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _updateDateControllers() {
    _startDateController.text =
        _startDate == null ? '' : _startDate!.toLocal().toString().split(' ')[0];
    _endDateController.text =
        _endDate == null ? '' : _endDate!.toLocal().toString().split(' ')[0];
  }

  // ── Availability is purely date-based now (no capacity cap) ──
  bool _isScheduleAvailable(DateTime endDate) {
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return DateTime.now().isBefore(endOfDay);
  }

  Future<void> _loadSchedules() async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    await provider.loadSchedules();
    for (final s in provider.schedules) {
      final data = await _getRegistrationCount(s.id);
      if (mounted) {
        setState(() => _registrationCounts[s.id] = data);
      }
    }
  }

  Future<void> _loadUserRegistrations() async {
    if (widget.isAdmin) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/registers/by-user/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> registrations = [];
        if (decoded is Map && decoded['data'] != null) {
          final inner = decoded['data'];
          registrations = inner is List ? inner : [inner];
        } else if (decoded is List) {
          registrations = decoded;
        }
        setState(() {
          _userRegisteredScheduleIds =
              registrations.map((item) => item['schedule_id'] as int).toList();
        });
      } else if (response.statusCode == 404) {
        setState(() => _userRegisteredScheduleIds = []);
      }
    } catch (e) {
      setState(() => _userRegisteredScheduleIds = []);
    }
  }

  // Still fetched for informational display (count registered).
  Future<Map<String, dynamic>> _getRegistrationCount(int scheduleId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.hostname}/api/internship/schedules/$scheduleId/check-registration'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'currentRegistrations': (decoded['currentRegistrations'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'currentRegistrations': 0};
  }

  Future<void> _checkRegistrationLimit(int scheduleId, DateTime endDate) async {
    if (_userRegisteredScheduleIds.contains(scheduleId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ You have already registered for this session!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (!_isScheduleAvailable(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration closed — this period has ended'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationForm(
          scheduleId: scheduleId,
          userId: widget.userId,
        ),
      ),
    );
    if (result == true) await _loadUserRegistrations();
  }

  Future<void> _confirmDeleteSchedule(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_forever, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Delete Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'Are you sure you want to delete this schedule? This action cannot be undone.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<ScheduleProvider>(context, listen: false)
            .deleteSchedule(scheduleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? DateTime.now()
          : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
        ),
        child: child!,
      ),
    );
    if (selected != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selected;
          _endDate = null;
          _duration = null;
        } else {
          _endDate = selected;
          _duration = _endDate!.difference(_startDate!).inDays;
        }
        _updateDateControllers();
      });
    }
  }

  void _showAddScheduleDialog() {
    String? selectedTeam;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_box, color: Colors.blueAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Schedule',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  decoration: InputDecoration(
                    hintText: 'Select team',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  items: kInternshipTeams
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedTeam = v),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedTeam != null && _startDate != null && _endDate != null) {
                          Provider.of<ScheduleProvider>(context, listen: false)
                              .addSchedule(Schedule(
                            id: DateTime.now().millisecondsSinceEpoch,
                            startDate: _startDate!,
                            endDate: _endDate!,
                            description: selectedTeam!,
                            duration: _endDate!.difference(_startDate!).inDays.toString(),
                            maxRegistrations: kUnlimitedRegistrations,
                          ));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Schedule created successfully!'),
                            backgroundColor: Colors.green,
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Please select a team and pick a date range'),
                            backgroundColor: Colors.orange,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final schedules = scheduleProvider.schedules;

    var filteredSchedules = _filterTeam == 'All'
        ? schedules
        : schedules.where((s) => s.description == _filterTeam).toList();

    if (_availableOnly) {
      filteredSchedules =
          filteredSchedules.where((s) => _isScheduleAvailable(s.endDate)).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Manage Schedules' : 'Registration Slots'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: widget.isAdmin
                ? _buildAdminDatePicker()
                : _buildInternHeader(schedules.length),
          ),

          // Filter bar
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
                    onChanged: (v) => setState(() => _filterTeam = v ?? 'All'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Checkbox(
                  value: _availableOnly,
                  activeColor: Colors.blueAccent,
                  onChanged: (v) => setState(() => _availableOnly = v ?? false),
                ),
                const Text('Available only', style: TextStyle(fontSize: 13)),
              ]),
            ]),
          ),

          // Schedule list
          Expanded(
            child: filteredSchedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: filteredSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = filteredSchedules[index];
                      return _buildScheduleCard(schedule);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create New Schedule',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Select a date range to create a new internship slot',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _datePickerField(
              controller: _startDateController,
              hint: 'Start Date',
              onTap: () => _selectDate(context, isStartDate: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _datePickerField(
              controller: _endDateController,
              hint: 'End Date',
              onTap: _startDate == null
                  ? null
                  : () => _selectDate(context, isStartDate: false),
            ),
          ),
        ]),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.timelapse, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text('Duration: $_duration day${_duration == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddScheduleDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Slot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _datePickerField({
    required TextEditingController controller,
    required String hint,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(onTap == null ? 0.1 : 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.text.isEmpty ? hint : controller.text,
              style: TextStyle(
                color: controller.text.isEmpty ? Colors.white60 : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInternHeader(int total) {
    final registered = _userRegisteredScheduleIds.length;
    return Row(children: [
      const CircleAvatar(
        backgroundColor: Colors.white24,
        radius: 24,
        child: Icon(Icons.event_available, color: Colors.white, size: 26),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Available Slots',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
          '$total slot${total == 1 ? '' : 's'} available${registered > 0 ? ' • $registered registered' : ''}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ]),
    ]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _filterTeam == 'All' && !_availableOnly
                ? 'No schedules available'
                : 'No schedules match your filters',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          if (widget.isAdmin && _filterTeam == 'All' && !_availableOnly) ...[
            const SizedBox(height: 8),
            Text('Select dates above to create a schedule',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    final isRegistered = _userRegisteredScheduleIds.contains(schedule.id);
    final isAvailable = _isScheduleAvailable(schedule.endDate);
    final countData = _registrationCounts[schedule.id];
    final current = (countData?['currentRegistrations'] as num?)?.toInt() ?? 0;
    final startDate = schedule.startDate.toLocal().toString().split(' ')[0];
    final endDate = schedule.endDate.toLocal().toString().split(' ')[0];
    final duration = schedule.duration;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isRegistered
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.isAdmin
              ? null
              : (isAvailable
                  ? () => _checkRegistrationLimit(schedule.id, schedule.endDate)
                  : () => _checkRegistrationLimit(schedule.id, schedule.endDate)),
          child: Opacity(
            opacity: (!widget.isAdmin && !isAvailable && !isRegistered) ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule.description,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('CLOSED',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])),
                      ),
                    const Spacer(),
                    if (isRegistered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('REGISTERED',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      )
                    else if (widget.isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteSchedule(schedule.id),
                        tooltip: 'Delete',
                      ),
                  ]),

                  const SizedBox(height: 12),

                  // Date and duration row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: _infoChip(
                          Icons.calendar_month,
                          '$startDate → $endDate',
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        Icons.timelapse,
                        '$duration day${duration == '1' ? '' : 's'}',
                        Colors.purple,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Registration count (informational only — no cap anymore)
                  Row(children: [
                    const Icon(Icons.people_alt, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$current registered',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ]),

                  // Bottom action hint
                  if (!widget.isAdmin) ...[
                    const SizedBox(height: 10),
                    if (isRegistered)
                      const Row(children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                        SizedBox(width: 6),
                        Text('You are registered for this session',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ])
                    else if (isAvailable)
                      const Row(children: [
                        Icon(Icons.touch_app, color: Colors.blueAccent, size: 14),
                        SizedBox(width: 6),
                        Text('Tap to register for this slot',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ])
                    else
                      const Row(children: [
                        Icon(Icons.block, color: Colors.red, size: 14),
                        SizedBox(width: 6),
                        Text('Registration closed — period has ended',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}