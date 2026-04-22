import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffNotificationScreen extends StatefulWidget {
  final int staffId;

  const StaffNotificationScreen({super.key, required this.staffId});

  @override
  State<StaffNotificationScreen> createState() =>
      _StaffNotificationScreenState();
}

class _StaffNotificationScreenState extends State<StaffNotificationScreen> {
  Set<String> _dismissedLeaves = {};
  Set<String> _dismissedClaims = {};
  Set<String> _dismissedSchedules = {};
  bool _isLoadingPrefs = true;

  // ✅ Keys scoped per staffId so different staff on same device don't share
  String get _leaveKey => 'dismissed_leaves_${widget.staffId}';
  String get _claimKey => 'dismissed_claims_${widget.staffId}';
  String get _scheduleKey => 'dismissed_schedules_${widget.staffId}';

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  // ✅ Load dismissed IDs from SharedPreferences on screen open
  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedLeaves =
          (prefs.getStringList(_leaveKey) ?? []).toSet();
      _dismissedClaims =
          (prefs.getStringList(_claimKey) ?? []).toSet();
      _dismissedSchedules =
          (prefs.getStringList(_scheduleKey) ?? []).toSet();
      _isLoadingPrefs = false;
    });
  }

  // ✅ Save dismissed IDs to SharedPreferences
  Future<void> _saveDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_leaveKey, _dismissedLeaves.toList());
    await prefs.setStringList(_claimKey, _dismissedClaims.toList());
    await prefs.setStringList(_scheduleKey, _dismissedSchedules.toList());
  }

  void _dismissLeave(String id) {
    setState(() => _dismissedLeaves.add(id));
    _saveDismissed();
  }

  void _dismissClaim(String id) {
    setState(() => _dismissedClaims.add(id));
    _saveDismissed();
  }

  void _dismissSchedule(String id) {
    setState(() => _dismissedSchedules.add(id));
    _saveDismissed();
  }

  void _dismissAll(List leaves, List claims, List schedules) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (final l in leaves) {
                  _dismissedLeaves.add(l.leaveId.toString());
                }
                for (final c in claims) {
                  _dismissedClaims.add(c.claimId.toString());
                }
                for (final s in schedules) {
                  _dismissedSchedules.add(s.schedId.toString());
                }
              });
              _saveDismissed(); // ✅ persist after clear all
            },
            child: const Text('Clear All',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getBranchName(int workLocation) {
    const branches = {
      1: 'Chagar Hutang',
      2: 'Turtle Lab',
      3: 'UMT',
    };
    return branches[workLocation] ?? 'Unknown Location';
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show loading while SharedPreferences is being read
    if (_isLoadingPrefs) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer3<Leaves, Claims, Schedules>(
        builder: (context, leavesProvider, claimsProvider,
            schedulesProvider, child) {
          // ✅ Filter by staffId + not pending + not dismissed
          final myLeaves = leavesProvider.leaves
              .where((l) =>
                  l.staffId == widget.staffId &&
                  l.status != 'Pending' &&
                  !_dismissedLeaves.contains(l.leaveId.toString()))
              .toList();

          final myClaims = claimsProvider.claims
              .where((c) =>
                  c.staffId == widget.staffId &&
                  c.status != 'Pending' &&
                  !_dismissedClaims.contains(c.claimId.toString()))
              .toList();

          final mySchedules = schedulesProvider.schedules
              .where((s) =>
                  s.staffId == widget.staffId &&
                  !_dismissedSchedules.contains(s.schedId.toString()))
              .toList();

          final hasAny = myLeaves.isNotEmpty ||
              myClaims.isNotEmpty ||
              mySchedules.isNotEmpty;

          return Column(
            children: [
              // ✅ Clear All button
              if (hasAny)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _dismissAll(
                            myLeaves, myClaims, mySchedules),
                        icon: const Icon(Icons.delete_sweep,
                            color: Colors.red),
                        label: const Text('Clear All',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: !hasAny
                    ? const Center(
                        child: Text(
                          "No notifications right now.",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // --- LEAVE NOTIFICATIONS ---
                            if (myLeaves.isNotEmpty) ...[
                              _buildSectionHeader(
                                  'Leave Notifications',
                                  Icons.beach_access,
                                  Colors.red),
                              ...myLeaves.map(
                                (leave) => Dismissible(
                                  key: Key('leave_${leave.leaveId}'),
                                  direction:
                                      DismissDirection.endToStart,
                                  background: _buildDismissBackground(),
                                  onDismissed: (_) => _dismissLeave(
                                      leave.leaveId.toString()),
                                  child: Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(
                                        bottom: 8.0),
                                    child: ListTile(
                                      leading: Icon(
                                        leave.status == 'Approved'
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: leave.status == 'Approved'
                                            ? Colors.green
                                            : Colors.red,
                                        size: 32,
                                      ),
                                      title: Text(
                                        'Leave ${leave.status}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                          'From: ${leave.startDate}\nTo: ${leave.endDate}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        tooltip: 'Dismiss',
                                        onPressed: () => _dismissLeave(
                                            leave.leaveId.toString()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // --- CLAIM NOTIFICATIONS ---
                            if (myClaims.isNotEmpty) ...[
                              _buildSectionHeader(
                                  'Claim Notifications',
                                  Icons.receipt,
                                  Colors.teal),
                              ...myClaims.map(
                                (claim) => Dismissible(
                                  key: Key('claim_${claim.claimId}'),
                                  direction:
                                      DismissDirection.endToStart,
                                  background: _buildDismissBackground(),
                                  onDismissed: (_) => _dismissClaim(
                                      claim.claimId.toString()),
                                  child: Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(
                                        bottom: 8.0),
                                    child: ListTile(
                                      leading: Icon(
                                        claim.status == 'Approved'
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: claim.status == 'Approved'
                                            ? Colors.green
                                            : Colors.red,
                                        size: 32,
                                      ),
                                      title: Text(
                                        'Claim ${claim.status}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                          'Type: ${claim.claimType}\nAmount: RM ${claim.amount}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        tooltip: 'Dismiss',
                                        onPressed: () => _dismissClaim(
                                            claim.claimId.toString()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // --- SCHEDULE NOTIFICATIONS ---
                            if (mySchedules.isNotEmpty) ...[
                              _buildSectionHeader(
                                  'Your Schedules',
                                  Icons.calendar_today,
                                  Colors.orange),
                              ...mySchedules.map(
                                (schedule) => Dismissible(
                                  key: Key(
                                      'schedule_${schedule.schedId}'),
                                  direction:
                                      DismissDirection.endToStart,
                                  background: _buildDismissBackground(),
                                  onDismissed: (_) => _dismissSchedule(
                                      schedule.schedId.toString()),
                                  child: Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(
                                        bottom: 8.0),
                                    child: ListTile(
                                      leading: const Icon(
                                          Icons.location_on,
                                          color: Colors.blue,
                                          size: 32),
                                      title: Text(
                                        'Location: ${_getBranchName(schedule.workLocation)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Date: ${DateFormat('yyyy-MM-dd').format(schedule.workDate)}\n'
                                        'Time: ${schedule.workStartTime} - ${schedule.workEndTime}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.grey),
                                        tooltip: 'Dismiss',
                                        onPressed: () => _dismissSchedule(
                                            schedule.schedId.toString()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}