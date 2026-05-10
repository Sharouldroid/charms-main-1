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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/logout_helper.dart';

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

  // ── Filter state ────────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  String _activeChip = 'All'; // 'All', 'This Month', 'Last Month', 'This Year'

  // ── Palette ─────────────────────────────────────────────────────────────────
  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaveData() async {
    await Future.wait([
      Provider.of<Leaves>(context, listen: false)
          .getLeaveByStaffId(staffId: widget.staffId),
      Provider.of<Claims>(context, listen: false).fetchClaims(),
    ]);
    _calculateLeaveBalance();
    if (mounted) setState(() {});
  }

  void _calculateLeaveBalance() {
    final leaves = Provider.of<Leaves>(context, listen: false).leaves;
    _leaveBalance['Annual Leave']!['taken']  = 0;
    _leaveBalance['Medical Leave']!['taken'] = 0;

    for (final leave in leaves) {
      if (leave.status.trim().toLowerCase() == 'approved') {
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

  // ── Date filter logic ────────────────────────────────────────────────────────
  List<Leave> _applyDateFilter(List<Leave> leaves) {
    if (_fromDate == null && _toDate == null) return leaves;
    return leaves.where((l) {
      final d = l.startDate;
      if (_fromDate != null) {
        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (d.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(
            _toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (d.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }

  void _applyQuickChip(String chip) {
    final now = DateTime.now();
    setState(() {
      _activeChip = chip;
      switch (chip) {
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate   = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Last Month':
          final lastMonth = DateTime(now.year, now.month - 1);
          _fromDate = DateTime(lastMonth.year, lastMonth.month, 1);
          _toDate   = DateTime(now.year, now.month, 0);
          break;
        case 'This Year':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate   = DateTime(now.year, 12, 31);
          break;
        case 'All':
        default:
          _fromDate = null;
          _toDate   = null;
          break;
      }
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: staffPrimary,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fromDate   = picked;
        _activeChip = 'Custom';
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: staffPrimary,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _toDate = picked; _activeChip = 'Custom'; });
  }

  // ── Delete pending leave ─────────────────────────────────────────────────────
  Future<void> _deleteLeave(Leave leave) async {
    if (_processing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Leave',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep It',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Leaves>(context, listen: false)
          .deleteLeave(leave.leaveId);
      await _fetchLeaveData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Leave request cancelled successfully'),
            backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to cancel leave: $e'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _logout() async => LogoutHelper.fullLogout(context);

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(
                builder: (_) =>
                    StaffDashboardScreen(username: widget.username)));
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(
                builder: (_) =>
                    PayrollDashboardScreen(username: widget.username)));
        break;
      case 3:
        Navigator.pushReplacement(context,
            MaterialPageRoute(
                builder: (_) => ClaimDashboardScreen(
                    username: widget.username, staffId: widget.staffId)));
        break;
      case 4:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const StaffMySelfScreen()));
        break;
    }
  }

  // ── Filter panel ─────────────────────────────────────────────────────────────
  Widget _buildFilterPanel() {
    final df = DateFormat('dd MMM yyyy');
    final chips = ['All', 'This Month', 'Last Month', 'This Year'];
    final isCustom = _fromDate != null || _toDate != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...chips.map((chip) {
                  final isActive = _activeChip == chip;
                  return GestureDetector(
                    onTap: () => _applyQuickChip(chip),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive
                            ? staffPrimary
                            : staffPrimary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? staffPrimary
                              : staffPrimary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(chip,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : staffPrimary)),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // From → To date pickers
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromDate,
                  child: _datePill(
                    label: _fromDate != null
                        ? df.format(_fromDate!)
                        : 'From date',
                    active: _fromDate != null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('→',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickToDate,
                  child: _datePill(
                    label:
                        _toDate != null ? df.format(_toDate!) : 'To date',
                    active: _toDate != null,
                  ),
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _applyQuickChip('All'),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _datePill({required String label, required bool active}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? staffPrimary.withOpacity(0.07)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? staffPrimary.withOpacity(0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 13,
              color: active ? staffPrimary : Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? staffPrimary : Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Leave balance card ────────────────────────────────────────────────────────
  Widget _buildLeaveBalanceCard(String leaveType) {
    final balance  = _leaveBalance[leaveType]!;
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
                    color: isMedical
                        ? Colors.redAccent.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMedical
                        ? Icons.local_hospital_rounded
                        : Icons.beach_access_rounded,
                    color: isMedical ? Colors.redAccent : Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(leaveType,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis),
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
                    Text('Total: ${balance['total']}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    Text('Taken: ${balance['taken']}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Left',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Text('${balance['remaining']}',
                        style: TextStyle(
                            color: staffPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.0)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Leave card ───────────────────────────────────────────────────────────────
  Widget _buildLeaveCard(Leave leave, {bool showDelete = false}) {
    final status = leave.status.trim().toLowerCase();
    Color statusColor   = Colors.orange;
    Color statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon = Icons.pending_actions_rounded;

    if (status == 'approved') {
      statusColor   = Colors.teal;
      statusBgColor = Colors.teal.withOpacity(0.1);
      statusIcon    = Icons.check_circle_rounded;
    }
    if (status == 'rejected') {
      statusColor   = Colors.redAccent;
      statusBgColor = Colors.redAccent.withOpacity(0.1);
      statusIcon    = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
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
                      Text(leave.leaveType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(leave.status,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDelete)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      tooltip: 'Cancel Leave',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed:
                          _processing ? null : () => _deleteLeave(leave),
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
                Icon(Icons.date_range_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(leave.startDate)} → ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.subject_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(leave.reason,
                        style: TextStyle(color: Colors.grey.shade700))),
              ],
            ),

            // Rejection reason
            if (status == 'rejected' &&
                leave.rejectionReason != null &&
                leave.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rejection Reason',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(leave.rejectionReason!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            ProofAttachmentViewer(
              fileUrl:  leave.proofFileUrl,
              fileName: leave.proofFileName,
              fileType: leave.proofFileType,
            ),
          ],
        ),
      ),
    );
  }

  // ── Leave list with date filter applied ──────────────────────────────────────
  Widget _buildLeaveList(List<Leave> leaves, {bool showDelete = false}) {
    final filtered = _applyDateFilter(
        leaves.where((l) => l.staffId == widget.staffId).toList());

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              (_fromDate != null || _toDate != null)
                  ? 'No records for selected period'
                  : 'No leave records found',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            if (_fromDate != null || _toDate != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _applyQuickChip('All'),
                child: const Text('Clear filter'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      itemCount: filtered.length,
      itemBuilder: (_, i) =>
          _buildLeaveCard(filtered[i], showDelete: showDelete),
    );
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
        title: const Text('MY LEAVES',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        backgroundColor: staffPrimary,
        centerTitle: true,
        actions: [
          Consumer3<Leaves, Claims, Schedules>(
            builder: (context, leaves, claims, schedules, child) {
              final total =
                  leaves.leaves.where((l) =>
                      l.staffId == widget.staffId && l.status != 'Pending').length +
                  claims.claims.where((c) =>
                      c.staffId == widget.staffId && c.status != 'Pending').length +
                  schedules.schedules.where((s) => s.staffId == widget.staffId).length;
              return IconButton(
                icon: total > 0
                    ? Badge(
                        label: Text(total.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.notifications_active_rounded))
                    : const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => StaffNotificationScreen(
                            staffId: widget.staffId))),
              );
            },
          ),
          IconButton(
              icon: const Icon(Icons.logout_rounded), onPressed: _logout),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text('Pending',  style: TextStyle(color: Colors.white))),
            Tab(child: Text('Approved', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Rejected', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer<Leaves>(
        builder: (context, leavesData, child) {
          final all = leavesData.leaves
              .where((l) => l.staffId == widget.staffId)
              .toList();
          final pending  = all.where((l) => l.status.trim().toLowerCase() == 'pending').toList();
          final approved = all.where((l) => l.status.trim().toLowerCase() == 'approved').toList();
          final rejected = all.where((l) => l.status.trim().toLowerCase() == 'rejected').toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave balances
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Leave Balances',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _leaveBalance.keys
                      .map(_buildLeaveBalanceCard)
                      .toList(),
                ),
              ),

              // ── Date filter panel ──────────────────────────────────────────
              _buildFilterPanel(),
              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaveList(pending,  showDelete: true),
                    _buildLeaveList(approved),
                    _buildLeaveList(rejected),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) =>
                        LeaveFormScreen(staffId: widget.staffId)));
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
          label: const Text('Apply Leave',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}