import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRscreens/staff/apply_claim_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRwidgets/custom_drawer.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';

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
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaimData();
  }

  Future<void> _fetchClaimData() async {
    final claimsProvider = Provider.of<Claims>(context, listen: false);
    await claimsProvider.getClaimByStaffId(widget.staffId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            builder: (context) => ApplyClaimScreen(staffId: widget.staffId),
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

  void _showClaimDetails(Claim claim) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Claim Details'),
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
                SizedBox(height: 8),
                Text('Attachment: ${claim.proofFileName}'),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.memory(
                              Uint8List.fromList(claim.proofFile!),
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                      Text('Image preview not available',
                                          style: TextStyle(color: Colors.grey))
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 150,
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
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

  Widget _buildClaimCard(Claim claim) {
  Color getStatusColor() {
    switch (claim.status) {
      case 'Pending':
        return Colors.orange[100]!;
      case 'Approved':
        return Colors.green[100]!;
      case 'Rejected':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  return Card(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
            label: Text(
              claim.status,
              style: TextStyle(
                color: claim.status == 'Rejected' ? Colors.red[900] : Colors.black87,
              ),
            ),
            backgroundColor: getStatusColor(),
          ),
        ),
        if (claim.proofFile != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => _showClaimDetails(claim),
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
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Tab(child: Text("Applied", style: TextStyle(color: Colors.white))),
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
      body: Consumer<Claims>(
        builder: (context, claimsData, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Pending Claims
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyClaimScreen(
                              staffId: widget.staffId,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('Apply New Claim'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 45),
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
              // Approved Claims
              _buildClaimList(
                claimsData.claims.where((c) => c.status == 'Approved').toList(),
              ),
              // Rejected Claims
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

  Widget _buildClaimList(List<Claim> claims) {
    return ListView.builder(
      itemCount: claims.length,
      itemBuilder: (context, index) => _buildClaimCard(claims[index]),
    );
  }
}