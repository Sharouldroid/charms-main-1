import 'dart:typed_data';

import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRscreens/staff/apply_claim_screen.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClaimDashboardScreen extends StatefulWidget {
  final String username;
  final int staffId;

  const ClaimDashboardScreen({
    Key? key,
    required this.username,
    required this.staffId,
  }) : super(key: key);

  @override
  _ClaimDashboardScreenState createState() => _ClaimDashboardScreenState();
}

class _ClaimDashboardScreenState extends State<ClaimDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaimData();
  }

  Future<void> _fetchClaimData() async {
    await context.read<Claims>().getClaimByStaffId(widget.staffId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDashboardScreen(username: widget.username),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveDashboardScreen(
              username: widget.username,
              staffId: widget.staffId,
            ),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PayrollDashboardScreen(username: widget.username),
          ),
        );
        break;
      case 3:
        return; // current
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffMySelfScreen()),
        );
        break;
    }
  }

  void _showClaimDetails(Claim claim) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Claim Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Claim ID: ${claim.claimId}'),
              Text('Type: ${claim.claimType}'),
              Text('Amount: RM ${claim.amount.toStringAsFixed(2)}'),
              Text('Date: ${claim.claimDate.toString().split(' ')[0]}'),
              Text('Description: ${claim.description}'),
              Text('Status: ${claim.status}'),
              if (claim.proofFile != null) ...[
                const SizedBox(height: 8),
                Text('Attachment: ${claim.proofFileName}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Claim claim) {
    Color statusColor() {
      switch (claim.status) {
        case 'Pending':
          return Colors.orange.shade100;
        case 'Approved':
          return Colors.green.shade100;
        case 'Rejected':
          return Colors.red.shade100;
        default:
          return Colors.grey.shade100;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () => _showClaimDetails(claim),
            title: Text('${claim.claimId} - ${claim.claimType}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RM ${claim.amount.toStringAsFixed(2)}'),
                Text('Date: ${claim.claimDate.toString().split(' ')[0]}'),
              ],
            ),
            trailing: Chip(
              label: Text(claim.status),
              backgroundColor: statusColor(),
            ),
          ),
          if (claim.proofFile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    Uint8List.fromList(claim.proofFile!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClaimList(List<Claim> claims) {
    return ListView.builder(
      itemCount: claims.length,
      itemBuilder: (_, i) => _buildClaimCard(claims[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // remove drawer/hamburger
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
            Tab(child: Text("Applied", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Approved", style: TextStyle(color: Colors.white))),
            Tab(child: Text("Rejected", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer<Claims>(
        builder: (_, claimsData, __) {
          return TabBarView(
            controller: _tabController,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplyClaimScreen(staffId: widget.staffId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Apply New Claim'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildClaimList(
                      claimsData.claims.where((c) => c.status == 'Pending').toList(),
                    ),
                  ),
                ],
              ),
              _buildClaimList(
                claimsData.claims.where((c) => c.status == 'Approved').toList(),
              ),
              _buildClaimList(
                claimsData.claims.where((c) => c.status == 'Rejected').toList(),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}