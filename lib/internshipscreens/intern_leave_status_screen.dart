import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intern_apply_leave_screen.dart';

// Intern-facing "My Leaves" screen. Shares the Leave model/Leaves provider
// with the staff module, but keeps its own intern-styled chrome (no staff
// bottom nav / staff-only widgets) so it doesn't look like the intern was
// dropped into the staff app.
class InternLeaveStatusScreen extends StatefulWidget {
  final int staffId;

  const InternLeaveStatusScreen({super.key, required this.staffId});

  @override
  State<InternLeaveStatusScreen> createState() =>
      _InternLeaveStatusScreenState();
}

class _InternLeaveStatusScreenState extends State<InternLeaveStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _processing = false;

  static const Color _primary = Color(0xFF0F766E);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _cardBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaves() async {
    try {
      final leavesProvider = context.read<Leaves>();
      await leavesProvider.getLeaveByStaffId(staffId: widget.staffId);
      await _markDecidedLeavesSeen(leavesProvider.leaves);
    } catch (e) {
      debugPrint('Error loading intern leaves: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Record every approved/rejected leave as "seen" so the dashboard's alert
  // dot clears once the intern has actually viewed this screen. Stored
  // locally (works on web/PWA via localStorage) since there's no backend
  // notification tied to leave status changes.
  Future<void> _markDecidedLeavesSeen(List<Leave> leaves) async {
    final decidedIds = leaves
        .where((l) => l.staffId == widget.staffId)
        .where((l) {
          final s = l.status.trim().toLowerCase();
          return s == 'approved' || s == 'rejected';
        })
        .map((l) => l.leaveId.toString())
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'intern_seen_leave_ids_${widget.staffId}', decidedIds);
  }

  Future<void> _cancelLeave(Leave leave) async {
    if (_processing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Leave',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to cancel this leave request?'),
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
    if (confirm != true || !mounted) return;

    setState(() => _processing = true);
    try {
      await context.read<Leaves>().deleteLeave(leave.leaveId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Leave request cancelled successfully'),
        backgroundColor: Colors.teal,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to cancel leave: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _openApplyLeave() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => InternApplyLeaveScreen(staffId: widget.staffId)),
    );
    if (created == true && mounted) {
      setState(() => _isLoading = true);
      await _fetchLeaves();
      _tabController.animateTo(0);
    }
  }

  Widget _buildLeaveCard(Leave leave, {bool showCancel = false}) {
    final status = leave.status.trim().toLowerCase();
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
        border: Border.all(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(leave.leaveType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(leave.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
            ),
            if (showCancel)
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
                  onPressed: _processing ? null : () => _cancelLeave(leave),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          Row(children: [
            Icon(Icons.date_range_rounded, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              '${DateFormat('dd MMM yyyy').format(leave.startDate)} → ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.subject_rounded, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
                child: Text(leave.reason,
                    style: TextStyle(color: Colors.grey.shade700))),
          ]),
          if (status == 'rejected' &&
              leave.rejectionReason != null &&
              leave.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rejection Reason',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(leave.rejectionReason!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ]),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          ProofAttachmentViewer(
            fileUrl: leave.proofFileUrl,
            fileName: leave.proofFileName,
            fileType: leave.proofFileType,
          ),
        ]),
      ),
    );
  }

  Widget _buildLeaveList(List<Leave> leaves, {bool showCancel = false}) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No leave records found',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ]),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      itemCount: leaves.length,
      itemBuilder: (_, i) => _buildLeaveCard(leaves[i], showCancel: showCancel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MY LEAVES',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: _primary,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text('Pending', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Approved', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Rejected', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _fetchLeaves,
              child: Consumer<Leaves>(
                builder: (context, leavesData, _) {
                  final all = leavesData.leaves
                      .where((l) => l.staffId == widget.staffId)
                      .toList();
                  final pending = all
                      .where((l) => l.status.trim().toLowerCase() == 'pending')
                      .toList();
                  final approved = all
                      .where((l) => l.status.trim().toLowerCase() == 'approved')
                      .toList();
                  final rejected = all
                      .where((l) => l.status.trim().toLowerCase() == 'rejected')
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaveList(pending, showCancel: true),
                      _buildLeaveList(approved),
                      _buildLeaveList(rejected),
                    ],
                  );
                },
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FloatingActionButton.extended(
          onPressed: _openApplyLeave,
          backgroundColor: _primary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Apply Leave',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
