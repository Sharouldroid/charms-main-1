import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManageLeaveScreen extends StatefulWidget {
  const ManageLeaveScreen({super.key});

  @override
  State<ManageLeaveScreen> createState() => _ManageLeaveScreenState();
}

class _ManageLeaveScreenState extends State<ManageLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _processing = false;

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    await Provider.of<Staffs>(context, listen: false).fetchStaff();
    await Provider.of<Leaves>(context, listen: false).fetchLeaves();
    if (mounted) setState(() {});
  }

  String _getStaffName(int staffId, List<Staff> staffList) {
    final Staff? staff = staffList.cast<Staff?>().firstWhere(
          (s) => s?.staffId == staffId,
          orElse: () => null,
        );
    return staff != null
        ? '${staff.firstname} ${staff.lastname}'
        : 'Staff ID: $staffId';
  }

  Future<void> _handleLeaveAction(Leave leave, String action) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final updatedLeave = Leave(
        leaveId: leave.leaveId,
        staffId: leave.staffId,
        leaveType: leave.leaveType,
        startDate: leave.startDate,
        endDate: leave.endDate,
        reason: leave.reason,
        proofFileName: leave.proofFileName,
        proofFileType: leave.proofFileType,
        proofFile: leave.proofFile,
        proofFilePath: leave.proofFilePath,
        proofFileUrl: leave.proofFileUrl,
        status: action == 'approve' ? 'Approved' : 'Rejected',
        createdAt: leave.createdAt,
        updatedAt: DateTime.now(),
      );

      await Provider.of<Leaves>(context, listen: false)
          .updateLeave(updatedLeave);
      await _fetchLeaves();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Leave approved successfully'
                : 'Leave rejected successfully',
          ),
          backgroundColor:
              action == 'approve' ? Colors.teal : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update leave: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _handleLeaveDelete(Leave leave) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Leave',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to delete this leave record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Leaves>(context, listen: false)
          .deleteLeave(leave.leaveId);
      await _fetchLeaves();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave record deleted successfully'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete leave: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildLeaveCard(Leave leave, List<Staff> staffList,
      {bool showDelete = false}) {
    final status = leave.status.trim().toLowerCase();
    final String staffName = _getStaffName(leave.staffId, staffList);

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
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Staff Name + Status + Delete
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Staff Name",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        staffName, // Staff Name instead of Staff ID
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                // Modern Status Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        leave.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (showDelete) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: _processing
                          ? null
                          : () => _handleLeaveDelete(leave),
                    ),
                  ),
                ],
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

            // Content details
            Row(
              children: [
                const Icon(Icons.category_rounded,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Type: ",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                Text(leave.leaveType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Date: ",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                Text(
                  "${DateFormat('dd MMM yyyy').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}",
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
                const Icon(Icons.subject_rounded,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Reason: ",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                Expanded(
                  child: Text(
                    leave.reason,
                    style: const TextStyle(color: Color(0xFF334155)),
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

            // Approve / Reject actions for Pending only
            if (status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _handleLeaveAction(leave, 'reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon:
                            const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _handleLeaveAction(leave, 'approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Approve',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusList(
      List<Leave> leaves, List<Staff> staffList,
      {bool showDelete = false}) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No leave records found',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: _fetchLeaves,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        itemCount: leaves.length,
        itemBuilder: (context, index) =>
            _buildLeaveCard(leaves[index], staffList, showDelete: showDelete),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("MANAGE LEAVE",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(
                child: Text("Pending",
                    style: TextStyle(color: Colors.white))),
            Tab(
                child: Text("Approved",
                    style: TextStyle(color: Colors.white))),
            Tab(
                child: Text("Rejected",
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer2<Staffs, Leaves>(
        builder: (context, staffsData, leavesData, child) {
          final staffList = staffsData.staffList;

          final pending = leavesData.leaves
              .where((l) => l.status.trim().toLowerCase() == 'pending')
              .toList();
          final approved = leavesData.leaves
              .where((l) => l.status.trim().toLowerCase() == 'approved')
              .toList();
          final rejected = leavesData.leaves
              .where((l) => l.status.trim().toLowerCase() == 'rejected')
              .toList();

          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildStatusList(pending, staffList),
                  _buildStatusList(approved, staffList, showDelete: true),
                  _buildStatusList(rejected, staffList, showDelete: true),
                ],
              ),
              if (_processing)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(
                      child: CircularProgressIndicator(color: primaryBlue)),
                ),
            ],
          );
        },
      ),
    );
  }
}