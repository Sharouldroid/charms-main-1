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

  // ── Matches StaffDashboardScreen palette ─────────────────────────────────────
  final Color staffPrimary = const Color(0xFF4F46E5);
  final Color staffBg = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  String get _leaveKey => 'dismissed_leaves_${widget.staffId}';
  String get _claimKey => 'dismissed_claims_${widget.staffId}';
  String get _scheduleKey => 'dismissed_schedules_${widget.staffId}';

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedLeaves = (prefs.getStringList(_leaveKey) ?? []).toSet();
      _dismissedClaims = (prefs.getStringList(_claimKey) ?? []).toSet();
      _dismissedSchedules =
          (prefs.getStringList(_scheduleKey) ?? []).toSet();
      _isLoadingPrefs = false;
    });
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Clear All',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all notifications?',
          style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
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
              _saveDismissed();
            },
            child: const Text('Clear All',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
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

  // ── Dismiss swipe background ──────────────────────────────────────────────────
  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
    );
  }

  // ── Section header — matches StaffDashboard "Your Upcoming Shifts" label ──────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification card — outlined style from StaffDashboard schedule cards ─────
  Widget _buildNotifCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onDismiss,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        trailing: GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded,
                size: 14, color: Colors.grey.shade500),
          ),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── Status pill (Approved / Rejected) ────────────────────────────────────────
  Widget _buildStatusIcon(String status) {
    final bool approved = status == 'Approved';
    final color = approved ? Colors.green : Colors.red;
    final icon =
        approved ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return Scaffold(
        backgroundColor: staffBg,
        body: Center(
            child: CircularProgressIndicator(color: staffPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: staffBg,
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'NOTIFICATIONS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,   // matches dashboard's 1.2
            ),
          ),
          centerTitle: true,
          backgroundColor: staffPrimary,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      body: Consumer3<Leaves, Claims, Schedules>(
        builder: (context, leavesProvider, claimsProvider,
            schedulesProvider, child) {
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
                  !_dismissedSchedules
                      .contains(s.schedId.toString()))
              .toList();

          final hasAny = myLeaves.isNotEmpty ||
              myClaims.isNotEmpty ||
              mySchedules.isNotEmpty;

          return Column(
            children: [
              // ── Header banner ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 16, bottom: 24, left: 24, right: 24),
                decoration: BoxDecoration(
                  color: staffPrimary,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Total badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${myLeaves.length + myClaims.length + mySchedules.length}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'notifications',
                          style: TextStyle(
                            color: Colors.indigo.shade200,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Clear all button
                    if (hasAny)
                      GestureDetector(
                        onTap: () => _dismissAll(
                            myLeaves, myClaims, mySchedules),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Clear all',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── List body ──────────────────────────────────────────────
              Expanded(
                child: !hasAny
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications right now',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              // ── Leave notifications ──────────────────
                              if (myLeaves.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Leave Notifications',
                                  Icons.beach_access_rounded,
                                  Colors.red,
                                ),
                                ...myLeaves.map(
                                  (leave) => Dismissible(
                                    key: Key(
                                        'leave_${leave.leaveId}'),
                                    direction:
                                        DismissDirection.endToStart,
                                    background:
                                        _buildDismissBackground(),
                                    onDismissed: (_) => _dismissLeave(
                                        leave.leaveId.toString()),
                                    child: _buildNotifCard(
                                      leading: _buildStatusIcon(
                                          leave.status),
                                      title:
                                          'Leave ${leave.status}',
                                      subtitle:
                                          'From: ${leave.startDate}\nTo: ${leave.endDate}',
                                      accentColor:
                                          leave.status == 'Approved'
                                              ? Colors.green
                                              : Colors.red,
                                      onDismiss: () => _dismissLeave(
                                          leave.leaveId.toString()),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ── Claim notifications ──────────────────
                              if (myClaims.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Claim Notifications',
                                  Icons.request_page_rounded,
                                  Colors.teal,
                                ),
                                ...myClaims.map(
                                  (claim) => Dismissible(
                                    key: Key(
                                        'claim_${claim.claimId}'),
                                    direction:
                                        DismissDirection.endToStart,
                                    background:
                                        _buildDismissBackground(),
                                    onDismissed: (_) => _dismissClaim(
                                        claim.claimId.toString()),
                                    child: _buildNotifCard(
                                      leading: _buildStatusIcon(
                                          claim.status),
                                      title:
                                          'Claim ${claim.status}',
                                      subtitle:
                                          'Type: ${claim.claimType}\nAmount: RM ${claim.amount}',
                                      accentColor:
                                          claim.status == 'Approved'
                                              ? Colors.green
                                              : Colors.red,
                                      onDismiss: () => _dismissClaim(
                                          claim.claimId.toString()),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ── Schedule notifications ───────────────
                              if (mySchedules.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Your Schedules',
                                  Icons.calendar_today_rounded,
                                  Colors.orange,
                                ),
                                ...mySchedules.map(
                                  (schedule) => Dismissible(
                                    key: Key(
                                        'schedule_${schedule.schedId}'),
                                    direction:
                                        DismissDirection.endToStart,
                                    background:
                                        _buildDismissBackground(),
                                    onDismissed: (_) =>
                                        _dismissSchedule(
                                            schedule.schedId
                                                .toString()),
                                    child: _buildNotifCard(
                                      leading: Container(
                                        padding:
                                            const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: staffPrimary
                                              .withOpacity(0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                            Icons
                                                .location_on_rounded,
                                            size: 22,
                                            color: staffPrimary),
                                      ),
                                      title:
                                          _getBranchName(schedule.workLocation),
                                      subtitle:
                                          'Date: ${DateFormat('dd MMM yyyy').format(schedule.workDate)}\n'
                                          'Time: ${schedule.workStartTime} – ${schedule.workEndTime}',
                                      accentColor: staffPrimary,
                                      onDismiss: () =>
                                          _dismissSchedule(
                                              schedule.schedId
                                                  .toString()),
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