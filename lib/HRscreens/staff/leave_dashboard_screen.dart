import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRscreens/staff/apply_leave_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    await leavesProvider.getLeaveByStaffId(staffId: widget.staffId);
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

  Widget _buildLeaveBalanceCard(String leaveType) {
    final balance = _leaveBalance[leaveType]!;
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                leaveType,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text('Total: ${balance['total']} days'),
              Text('Taken: ${balance['taken']} days'),
              Text(
                'Left: ${balance['remaining']} days',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveCard(Leave leave) {
    final status = leave.status.trim().toLowerCase();
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
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

  Widget _buildLeaveList(List<Leave> leaves) {
    final staffLeaves =
        leaves.where((leave) => leave.staffId == widget.staffId).toList();

    if (staffLeaves.isEmpty) {
      return const Center(
        child: Text(
          'No leave records found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: staffLeaves.length,
      itemBuilder: (context, index) => _buildLeaveCard(staffLeaves[index]),
    );
  }

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffDashboardScreen(username: widget.username),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDashboardScreen(
              username: widget.username,
              staffId: widget.staffId,
            ),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayrollDashboardScreen(username: widget.username),
          ),
        );
        break;
      case 3:
        Navigator.push(
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StaffMySelfScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text("CHARMS STAFF", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Dashboard',
            onPressed: _logout,
          ),
        ],
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
          final allLeaves =
              leavesData.leaves.where((l) => l.staffId == widget.staffId).toList();

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
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: _leaveBalance.keys
                      .map((type) => _buildLeaveBalanceCard(type))
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaveList(pending),
                    _buildLeaveList(approved),
                    _buildLeaveList(rejected),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}