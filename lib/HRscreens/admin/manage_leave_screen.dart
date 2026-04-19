import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    await Provider.of<Leaves>(context, listen: false).fetchLeaves();
    if (mounted) setState(() {});
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

      await Provider.of<Leaves>(context, listen: false).updateLeave(updatedLeave);
      await _fetchLeaves();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Leave approved successfully'
                : 'Leave rejected successfully',
          ),
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

  Widget _buildLeaveCard(Leave leave) {
    final status = leave.status.trim().toLowerCase();
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Staff ID: ${leave.staffId}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text("Leave Type: ${leave.leaveType}"),
            Text(
              "Duration: ${DateFormat('dd/MM/yyyy').format(leave.startDate)} - ${DateFormat('dd/MM/yyyy').format(leave.endDate)}",
            ),
            Text("Reason: ${leave.reason}"),
            Text(
              "Status: ${leave.status}",
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            // NEW: URL/path-based attachment viewer
            ProofAttachmentViewer(
              fileUrl: leave.proofFileUrl,
              fileName: leave.proofFileName,
              fileType: leave.proofFileType,
            ),

            if (status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _processing
                          ? null
                          : () => _handleLeaveAction(leave, 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _processing
                          ? null
                          : () => _handleLeaveAction(leave, 'reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildStatusList(List<Leave> leaves) {
    if (leaves.isEmpty) {
      return const Center(
        child: Text(
          'No leave records found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLeaves,
      child: ListView.builder(
        itemCount: leaves.length,
        itemBuilder: (context, index) => _buildLeaveCard(leaves[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: const Text("Manage Leave", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Text("Pending", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Approved", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Rejected", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer<Leaves>(
        builder: (context, leavesData, child) {
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
                  _buildStatusList(pending),
                  _buildStatusList(approved),
                  _buildStatusList(rejected),
                ],
              ),
              if (_processing)
                Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}