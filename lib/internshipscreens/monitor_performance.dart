import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipmodels/activity.dart';
import 'package:charms/internshipservices/activity_service.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:intl/intl.dart';

class MonitorPerformancePage extends StatefulWidget {
  final String role; // 'Admin' or 'Intern'
  final int userId;
  final String? internName; // For admin view
  final String? internId; // For admin view

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

  // For admin view
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
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
      final allInterns = Provider.of<RegisterProvider>(context, listen: false).internList;
      
      setState(() {
        // All entries in internregister table are interns, no filtering needed
        _interns = allInterns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load interns: $e');
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Activity> activities;
      
      if (widget.role == 'Admin' && _selectedInternId != null) {
        activities = await _activityService.getActivitiesByIntern(_selectedInternId!);
      } else if (widget.role == 'Intern') {
        activities = await _activityService.getActivitiesByIntern(widget.userId);
      } else {
        activities = [];
      }

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Only show error if it's not just an empty list
      if (!e.toString().contains('Not Found')) {
        _showErrorDialog('Failed to load activities: $e');
      }
    }
  }

  void _onInternSelected(int? internId) {
    if (internId != null) {
      final selectedIntern = _interns.firstWhere((intern) => intern['id'] == internId);
      setState(() {
        _selectedInternId = internId;
        // Combine first_name and last_name from internregister table
        String firstName = selectedIntern['first_name'] ?? '';
        String lastName = selectedIntern['last_name'] ?? '';
        _selectedInternName = '$firstName $lastName'.trim();
        if (_selectedInternName.isEmpty) {
          _selectedInternName = 'Unknown';
        }
      });
      _loadActivities();
    }
  }

  void _showAddActivityDialog() {
    _activityController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Activity'),
          content: TextField(
            controller: _activityController,
            decoration: const InputDecoration(
              labelText: 'What did you do?',
              border: OutlineInputBorder(),
              hintText: 'Describe your activity...',
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addActivity();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addActivity() async {
    if (_activityController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an activity description');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _activityService.addActivity(
        widget.userId,
        _activityController.text.trim(),
      );
      
      _activityController.clear();
      await _loadActivities();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to log activity: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.role == 'Admin' ? 'Monitor Performance' : 'My Activities'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.role == 'Admin') ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Intern',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          hint: const Text('Choose an intern'),
                          initialValue: _selectedInternId,
                          items: _interns.map((intern) {
                            // Combine first_name and last_name for display
                            String firstName = intern['first_name'] ?? '';
                            String lastName = intern['last_name'] ?? '';
                            String fullName = '$firstName $lastName'.trim();
                            if (fullName.isEmpty) fullName = 'Unknown';
                            
                            return DropdownMenuItem<int>(
                              value: intern['id'],
                              child: Text(fullName),
                            );
                          }).toList(),
                          onChanged: _onInternSelected,
                        ),
                      ],
                    ),
                  ),
                  if (_selectedInternId != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        '$_selectedInternName - Activities (${_activities.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: _activities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                widget.role == 'Admin'
                                    ? (_selectedInternId == null
                                        ? 'Select an intern to view activities'
                                        : 'No activities logged yet')
                                    : 'No activities logged yet',
                                style:
                                    const TextStyle(fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              if (widget.role == 'Intern') ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to log your first activity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadActivities,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              final activity = _activities[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[600],
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    activity.activityDescription,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatDateTime(activity.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: widget.role == 'Intern'
          ? FloatingActionButton(
              onPressed: _showAddActivityDialog,
              backgroundColor: Colors.blue[600],
              tooltip: 'Log Activity',
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
