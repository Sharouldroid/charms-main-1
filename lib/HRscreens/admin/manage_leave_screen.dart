import 'dart:typed_data';

import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManageLeaveScreen extends StatefulWidget {
  @override
  _ManageLeaveScreenState createState() => _ManageLeaveScreenState();
}

class _ManageLeaveScreenState extends State<ManageLeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    await Provider.of<Leaves>(context, listen: false).fetchLeaves();
  }

  Future<void> _handleLeaveAction(Leave leave, String action) async {
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
      status: action == 'approve' ? 'Approved' : 'Rejected',
      createdAt: leave.createdAt,
      updatedAt: DateTime.now(),
    );

    await Provider.of<Leaves>(context, listen: false).updateLeave(updatedLeave);
    _fetchLeaves();
  }

  Widget _buildLeaveCard(Leave leave) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Staff ID: ${leave.staffId}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text("Leave Type: ${leave.leaveType}"),
            Text("Duration: ${DateFormat('dd/MM/yyyy').format(leave.startDate)} - ${DateFormat('dd/MM/yyyy').format(leave.endDate)}"),
            Text("Reason: ${leave.reason}"),
            if (leave.proofFile != null)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: InteractiveViewer(
                        child: Image.memory(
                          Uint8List.fromList(leave.proofFile!),
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Attachment: ${leave.proofFileName}"),
                    Image.memory(
                      Uint8List.fromList(leave.proofFile!),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported);
                      },
                    ),
                  ],
                ),
              ),
            if (leave.status == 'Pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleLeaveAction(leave, 'approve'),
                    child: Text('Approve', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _handleLeaveAction(leave, 'reject'),
                    child: Text('Reject', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      backgroundColor: Colors.blue,
      title: Text("Manage Leave", style: TextStyle(color: Colors.white)),
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(child: Text("Pending", style: TextStyle(color: Colors.white))),
          Tab(child: Text("Approved", style: TextStyle(color: Colors.white))),
          Tab(child: Text("Rejected", style: TextStyle(color: Colors.white))),
        ],
      ),
    ),
    body: Consumer<Leaves>(
      builder: (context, leavesData, child) {
        return TabBarView(
          controller: _tabController,
          children: [
            // Pending Tab
            ListView(
              children: leavesData.leaves
                  .where((leave) => leave.status == 'Pending')
                  .map((leave) => _buildLeaveCard(leave))
                  .toList(),
            ),
            // Approved Tab
            ListView(
              children: leavesData.leaves
                  .where((leave) => leave.status == 'Approved')
                  .map((leave) => _buildLeaveCard(leave))
                  .toList(),
            ),
            // Rejected Tab
            ListView(
              children: leavesData.leaves
                  .where((leave) => leave.status == 'Rejected')
                  .map((leave) => _buildLeaveCard(leave))
                  .toList(),
            ),
          ],
        );
      },
    ),
  );
}
}