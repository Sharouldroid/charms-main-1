import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipmodels/activity.dart';
import 'package:charms/internshipservices/activity_service.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:intl/intl.dart';

class MonitorPerformancePage extends StatefulWidget {
  final String role;
  final int userId;
  final String? internName;
  final String? internId;

  const MonitorPerformancePage({
    super.key,
    required this.role,
    required this.userId,
    this.internName,
    this.internId,
  });

  @override
  _MonitorPerformancePageState createState() => _MonitorPerformancePageState();
}

class _MonitorPerformancePageState extends State<MonitorPerformancePage> {
  List<Activity> _activities = [];
  bool _isLoading = false;
  final TextEditingController _activityController = TextEditingController();
  final ActivityService _activityService = ActivityService();

  List<dynamic> _interns = [];
  int? _selectedInternId;
  String _selectedInternName = '';

  @override
  void initState() {
    super.initState();
    if (widget.role == 'Admin') {
      _loadInterns();
    } else {
      _loadActivities();
    }
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _loadInterns() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
      final allInterns =
          Provider.of<RegisterProvider>(context, listen: false).internList;
      setState(() {
        _interns = allInterns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load interns: $e');
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      List<Activity> activities;
      if (widget.role == 'Admin' && _selectedInternId != null) {
        activities =
            await _activityService.getActivitiesByIntern(_selectedInternId!);
      } else if (widget.role == 'Intern') {
        activities =
            await _activityService.getActivitiesByIntern(widget.userId);
      } else {
        activities = [];
      }
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!e.toString().contains('Not Found')) {
        _showErrorSnackbar('Failed to load activities: $e');
      }
    }
  }

  void _onInternSelected(int? internId) {
    if (internId != null) {
      final selected = _interns.firstWhere(
          (intern) => (intern['user_id'] as num).toInt() == internId);
      setState(() {
        _selectedInternId = internId;
        final first = selected['first_name'] ?? '';
        final last = selected['last_name'] ?? '';
        _selectedInternName = '$first $last'.trim();
        if (_selectedInternName.isEmpty) _selectedInternName = 'Unknown';
      });
      _loadActivities();
    }
  }

  /// Returns true if the activity was logged today (local time).
  bool _isEditableToday(Activity activity) {
    final now = DateTime.now();
    final logged = activity.createdAt.toLocal();
    return logged.year == now.year &&
        logged.month == now.month &&
        logged.day == now.day;
  }

  void _showAddActivityDialog() {
    _activityController.clear();
    _showActivityDialog(
      title: 'Log Activity',
      hint: 'What did you work on today?',
      onSubmit: _addActivity,
    );
  }

  void _showEditActivityDialog(Activity activity) {
    _activityController.text = activity.activityDescription;
    _showActivityDialog(
      title: 'Edit Activity',
      hint: 'Update your activity description...',
      onSubmit: () => _editActivity(activity),
      submitLabel: 'Update',
      submitColor: Colors.deepPurple,
    );
  }

  void _showActivityDialog({
    required String title,
    required String hint,
    required VoidCallback onSubmit,
    String submitLabel = 'Submit',
    Color submitColor = Colors.blueAccent,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: submitColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      title == 'Edit Activity' ? Icons.edit : Icons.edit_note,
                      color: submitColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _activityController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: submitColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSubmit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: submitColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addActivity() async {
    if (_activityController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter an activity description');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _activityService.addActivity(
        widget.userId,
        _activityController.text.trim(),
      );
      _activityController.clear();
      await _loadActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to log activity: $e');
    }
  }

  Future<void> _editActivity(Activity activity) async {
  if (activity.id == null) {
    _showErrorSnackbar('Cannot edit this activity: missing ID');
    return;
  }
  if (_activityController.text.trim().isEmpty) {
    _showErrorSnackbar('Please enter an activity description');
    return;
  }
  setState(() => _isLoading = true);
  try {
    await _activityService.updateActivity(
      activity.id!,
      _activityController.text.trim(),
    );
    _activityController.clear();
    await _loadActivities();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity updated successfully!'),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showErrorSnackbar('Failed to update activity: $e');
  }
}

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt.toLocal());
  String _formatTime(DateTime dt) =>
      DateFormat('hh:mm a').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            widget.role == 'Admin' ? 'Monitor Performance' : 'My Activities'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent,
                        Color.fromARGB(255, 123, 64, 251)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: widget.role == 'Admin'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Intern to Monitor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonFormField<int>(
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                hint: const Text('Choose an intern'),
                                value: _selectedInternId,
                                items: _interns.map((intern) {
                                  final first = intern['first_name'] ?? '';
                                  final last = intern['last_name'] ?? '';
                                  final name = '$first $last'.trim();
                                  return DropdownMenuItem<int>(
                                    value: (intern['user_id'] as num).toInt(),
                                    child:
                                        Text(name.isEmpty ? 'Unknown' : name),
                                  );
                                }).toList(),
                                onChanged: _onInternSelected,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 24,
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Activity Log',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_activities.length} activit${_activities.length == 1 ? 'y' : 'ies'} logged',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                // Admin selected intern info bar
                if (widget.role == 'Admin' && _selectedInternId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: Colors.green[50],
                    child: Row(
                      children: [
                        Icon(Icons.person_pin,
                            color: Colors.green[700], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$_selectedInternName — ${_activities.length} activit${_activities.length == 1 ? 'y' : 'ies'}',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Activity list
                Expanded(
                  child: _activities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined,
                                  size: 72, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                widget.role == 'Admin'
                                    ? (_selectedInternId == null
                                        ? 'Select an intern to view activities'
                                        : 'No activities logged yet')
                                    : 'No activities logged yet',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                              if (widget.role == 'Intern') ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to log your first activity',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[400]),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadActivities,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              final activity = _activities[index];
                              final isFirst = index == 0;
                              final canEdit = widget.role == 'Intern' &&
                                  _isEditableToday(activity);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline column
                                  Column(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isFirst
                                              ? Colors.blueAccent
                                              : Colors.blueAccent
                                                  .withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: isFirst
                                              ? Colors.white
                                              : Colors.blueAccent,
                                          size: 18,
                                        ),
                                      ),
                                      if (index < _activities.length - 1)
                                        Container(
                                          width: 2,
                                          height: 60,
                                          color: Colors.blueAccent
                                              .withOpacity(0.15),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Activity card
                                  Expanded(
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.05),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  activity.activityDescription,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (canEdit) ...[
                                                const SizedBox(width: 8),
                                                Tooltip(
                                                  message: 'Edit activity',
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _showEditActivityDialog(
                                                            activity),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.deepPurple
                                                            .withOpacity(0.08),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 16,
                                                        color:
                                                            Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ] else if (widget.role ==
                                                  'Intern') ...[
                                                // Show locked icon for past entries
                                                const SizedBox(width: 8),
                                                Tooltip(
                                                  message:
                                                      'Can only edit today\'s activities',
                                                  child: Icon(
                                                    Icons.lock_outline,
                                                    size: 14,
                                                    color: Colors.grey[300],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 12,
                                                  color: Colors.grey[400]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(activity.createdAt),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500]),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.access_time,
                                                  size: 12,
                                                  color: Colors.grey[400]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatTime(activity.createdAt),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: widget.role == 'Intern'
          ? FloatingActionButton.extended(
              onPressed: _showAddActivityDialog,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Log Activity'),
            )
          : null,
    );
  }
}