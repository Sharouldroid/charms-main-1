
import 'dart:typed_data';
import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRwidgets/custom_drawer.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:flutter/material.dart';
import 'package:charms/HRscreens/staff/apply_leave_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class LeaveDashboardScreen extends StatefulWidget {
  final String username;
  final int staffId;

  const LeaveDashboardScreen({
    Key? key,
    required this.username,
    required this.staffId,
  }) : super(key: key);

  @override
  _LeaveDashboardScreenState createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  int _selectedIndex = 1;
  Map<String, Map<String, int>> _leaveBalance = {
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

    print("Fetched leaves: ${leavesProvider.leaves}");

    _calculateLeaveBalance();
    setState(() {}); // Force UI rebuild
  }

  void _calculateLeaveBalance() {
    final leavesProvider = Provider.of<Leaves>(context, listen: false);
    final leaves = leavesProvider.leaves;

    // Reset taken days
    _leaveBalance['Annual Leave']!['taken'] = 0;
    _leaveBalance['Medical Leave']!['taken'] = 0;

    for (var leave in leaves) {
      if (leave.status == 'Approved') {
        final days = leave.endDate.difference(leave.startDate).inDays + 1;
        if (leave.leaveType == 'Annual Leave') {
          _leaveBalance['Annual Leave']!['taken'] =
              _leaveBalance['Annual Leave']!['taken']! + days;
        } else if (leave.leaveType == 'Medical Leave') {
          _leaveBalance['Medical Leave']!['taken'] =
              _leaveBalance['Medical Leave']!['taken']! + days;
        }
      }
    }

    // Calculate remaining days
    _leaveBalance['Annual Leave']!['remaining'] =
        _leaveBalance['Annual Leave']!['total']! -
            _leaveBalance['Annual Leave']!['taken']!;
    _leaveBalance['Medical Leave']!['remaining'] =
        _leaveBalance['Medical Leave']!['total']! -
            _leaveBalance['Medical Leave']!['taken']!;

    setState(() {});
  }

  Widget _buildLeaveBalanceCard(String leaveType) {
    final balance = _leaveBalance[leaveType]!;
    return Container(
      width: 180,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                leaveType,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text('Total: ${balance['total']} days'),
              Text('Taken: ${balance['taken']} days'),
              Text(
                'Left: ${balance['remaining']} days',
                style: TextStyle(
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
    return Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        elevation: 3,
        child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Staff ID: ${leave.staffId}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text("Leave Type: ${leave.leaveType}"),
                  Text(
                      "Duration: ${DateFormat('dd/MM/yyyy').format(leave.startDate)} - ${DateFormat('dd/MM/yyyy').format(leave.endDate)}"),
                  Text("Reason: ${leave.reason}"),
                  Text(
                    "Status: ${leave.status}",
                    style: TextStyle(
                      color: leave.status == 'Approved'
                          ? Colors.green
                          : leave.status == 'Rejected'
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.image_not_supported,
                                            size: 48, color: Colors.grey),
                                        Text('Image preview not available',
                                            style:
                                                TextStyle(color: Colors.grey))
                                      ],
                                    ),
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
                          SizedBox(height: 8),
                          Text(
                            "Attachment: ${leave.proofFileName}",
                            style: TextStyle(color: Colors.blue),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                Uint8List.fromList(leave.proofFile!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("CHARMS STAFF", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text("Pending", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Approved", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Rejected", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      drawer: CustomDrawer(
        selectedLanguage: _selectedLanguage,
        languages: _languages,
        onLanguageChanged: (String? newValue) {
          setState(() {
            _selectedLanguage = newValue!;
          });
        },
        onLogOut: _logout,
      ),
      body: Consumer<Leaves>(
        builder: (context, leavesData, child) {
          return Column(
            children: [
              SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  children: _leaveBalance.keys
                      .map((type) => _buildLeaveBalanceCard(type))
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaveList(leavesData.leaves
                        .where((l) =>
                            l.status == 'Pending' &&
                            l.staffId == widget.staffId)
                        .toList()),
                    _buildLeaveList(leavesData.leaves
                        .where((l) =>
                            l.status == 'Approved' &&
                            l.staffId == widget.staffId)
                        .toList()),
                    _buildLeaveList(leavesData.leaves
                        .where((l) =>
                            l.status == 'Rejected' &&
                            l.staffId == widget.staffId)
                        .toList()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LeaveFormScreen(staffId: widget.staffId)),
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildLeaveList(List<Leave> leaves) {
    final staffLeaves =
        leaves.where((leave) => leave.staffId == widget.staffId).toList();

    print("Filtered leaves for staff ${widget.staffId}: $staffLeaves");

    return ListView.builder(
      itemCount: staffLeaves.length,
      itemBuilder: (context, index) => _buildLeaveCard(staffLeaves[index]),
    );
  }

  Future<void> _logout() async {
    await Provider.of<Auth>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    StaffDashboardScreen(username: widget.username)));
        break;
      case 1:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LeaveDashboardScreen(
                    username: widget.username, staffId: widget.staffId)));
        break;
      case 2:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PayrollDashboardScreen(username: widget.username)));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ClaimDashboardScreen(
              username: widget.username, staffId: widget.staffId
            )));
        break;
      case 4:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => StaffMySelfScreen()));
        break;
    }
  }
}
