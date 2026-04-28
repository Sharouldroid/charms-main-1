import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRscreens/staff/apply_leave_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/auth.dart' as app_auth;
import 'package:charms/screens/auth_screen.dart';

class LeaveDashboardScreen extends StatefulWidget {
  final String username;
  final int staffId;

  const LeaveDashboardScreen({
    super.key,
    required this.username,
    required this.staffId,
  });

  @override
  State<LeaveDashboardScreen> createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1;
  bool _processing = false;

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5); // Deep Indigo
  final Color staffBg = const Color(0xFFF8FAFC); // Very Light Slate
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  final Map<String, Map<String, int>> _leaveBalance = {
    'Annual Leave': {'total': 20, 'taken': 0, 'remaining': 20},
    'Medical Leave': {'total': 22, 'taken': 0, 'remaining': 22},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaveData();
  }

  Future<void> _fetchLeaveData() async {
    final leavesProvider = Provider.of<Leaves>(context, listen: false);
    final claimsProvider = Provider.of<Claims>(context, listen: false);

    await Future.wait([
      leavesProvider.getLeaveByStaffId(staffId: widget.staffId),
      claimsProvider.fetchClaims(),
    ]);

    _calculateLeaveBalance();
    if (mounted) setState(() {});
  }

  void _calculateLeaveBalance() {
    final leavesProvider = Provider.of<Leaves>(context, listen: false);
    final leaves = leavesProvider.leaves;

    _leaveBalance['Annual Leave']!['taken'] = 0;
    _leaveBalance['Medical Leave']!['taken'] = 0;

    for (final leave in leaves) {
      final status = leave.status.trim().toLowerCase();
      if (status == 'approved') {
        final days = leave.endDate.difference(leave.startDate).inDays + 1;
        if (leave.leaveType == 'Annual Leave') {
          _leaveBalance['Annual Leave']!['taken'] =
              _leaveBalance['Annual Leave']!['taken']! + days;
        } else if (leave.leaveType == 'Medical Leave' ||
            leave.leaveType == 'Sick Leave') {
          _leaveBalance['Medical Leave']!['taken'] =
              _leaveBalance['Medical Leave']!['taken']! + days;
        }
      }
    }

    _leaveBalance['Annual Leave']!['remaining'] =
        _leaveBalance['Annual Leave']!['total']! -
            _leaveBalance['Annual Leave']!['taken']!;
    _leaveBalance['Medical Leave']!['remaining'] =
        _leaveBalance['Medical Leave']!['total']! -
            _leaveBalance['Medical Leave']!['taken']!;
  }

  // ✅ Staff can only cancel/delete their own pending leaves
  Future<void> _deleteLeave(Leave leave) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Leave', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep It', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Leaves>(context, listen: false).deleteLeave(leave.leaveId);
      await _fetchLeaveData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request cancelled successfully'),
          backgroundColor: Colors.teal, // Modern success color
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel leave: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildLeaveBalanceCard(String leaveType) {
    final balance = _leaveBalance[leaveType]!;
    final isMedical = leaveType == 'Medical Leave';
    
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMedical ? Colors.redAccent.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMedical ? Icons.local_hospital_rounded : Icons.beach_access_rounded,
                    color: isMedical ? Colors.redAccent : Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    leaveType,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total: ${balance['total']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Taken: ${balance['taken']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Left', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      '${balance['remaining']}',
                      style: TextStyle(
                        color: staffPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveCard(Leave leave, {bool showDelete = false}) {
    final status = leave.status.trim().toLowerCase();
    
    // Modern Status Colors
    Color statusColor = Colors.orange;
    Color statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon = Icons.pending_actions_rounded;
    
    if (status == 'approved') {
      statusColor = Colors.teal;
      statusBgColor = Colors.teal.withOpacity(0.1);
      statusIcon = Icons.check_circle_rounded;
    }
    if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusBgColor = Colors.redAccent.withOpacity(0.1);
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder), // Flat outlined look
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.leaveType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      // Modern Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              leave.status,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ Only show delete on pending
                if (showDelete)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'Cancel Leave',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: _processing ? null : () => _deleteLeave(leave),
                    ),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),
            
            Row(
              children: [
                Icon(Icons.date_range_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  "${DateFormat('dd MMM yyyy').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.subject_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    leave.reason,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProofAttachmentViewer(
              fileUrl: leave.proofFileUrl,
              fileName: leave.proofFileName,
              fileType: leave.proofFileType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveList(List<Leave> leaves, {bool showDelete = false}) {
    final staffLeaves =
        leaves.where((leave) => leave.staffId == widget.staffId).toList();

    if (staffLeaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No leave records found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 80), // Padding for FAB
      itemCount: staffLeaves.length,
      itemBuilder: (context, index) =>
          _buildLeaveCard(staffLeaves[index], showDelete: showDelete),
    );
  }

  Future<void> _logout() async {
  // Clear auth state
  await Provider.of<app_auth.Auth>(context, listen: false).logout();

  if (!mounted) return;

  // Navigate to auth screen and remove all routes
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthScreen()),
    (route) => false,
  );
}
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StaffDashboardScreen(username: widget.username),
          ),
        );
        break;
      case 1:
        // Already here
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PayrollDashboardScreen(username: widget.username),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClaimDashboardScreen(
              username: widget.username,
              staffId: widget.staffId,
            ),
          ),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StaffMySelfScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text("MY LEAVES", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
        backgroundColor: staffPrimary,
        centerTitle: true,
        actions: [
          Consumer3<Leaves, Claims, Schedules>(
            builder: (context, leaves, claims, schedules, child) {
              int resolvedLeaves = leaves.leaves
                  .where((l) => l.staffId == widget.staffId && l.status != 'Pending')
                  .length;
              int resolvedClaims = claims.claims
                  .where((c) => c.staffId == widget.staffId && c.status != 'Pending')
                  .length;
              int assignedSchedules = schedules.schedules
                  .where((s) => s.staffId == widget.staffId)
                  .length;
              int totalNotifications =
                  resolvedLeaves + resolvedClaims + assignedSchedules;

              return IconButton(
                icon: totalNotifications > 0
                    ? Badge(
                        label: Text(totalNotifications.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.notifications_active_rounded),
                      )
                    : const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffNotificationScreen(
                        staffId: widget.staffId,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text("Pending", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Approved", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Rejected", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer<Leaves>(
        builder: (context, leavesData, child) {
          final allLeaves = leavesData.leaves
              .where((l) => l.staffId == widget.staffId)
              .toList();

          final pending = allLeaves
              .where((l) => l.status.trim().toLowerCase() == 'pending')
              .toList();
          final approved = allLeaves
              .where((l) => l.status.trim().toLowerCase() == 'approved')
              .toList();
          final rejected = allLeaves
              .where((l) => l.status.trim().toLowerCase() == 'rejected')
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Leave Balances',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _leaveBalance.keys
                      .map((type) => _buildLeaveBalanceCard(type))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaveList(pending, showDelete: true),  // ✅ can cancel pending
                    _buildLeaveList(approved),                   // no delete on approved
                    _buildLeaveList(rejected),                   // no delete on rejected
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0), // Avoid navbar overlap
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaveFormScreen(staffId: widget.staffId),
              ),
            );

            if (created == true && mounted) {
              await Provider.of<Leaves>(context, listen: false)
                  .getLeaveByStaffId(staffId: widget.staffId);
              _calculateLeaveBalance();
              setState(() {});
              _tabController.animateTo(0);
            }
          },
          backgroundColor: staffPrimary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}