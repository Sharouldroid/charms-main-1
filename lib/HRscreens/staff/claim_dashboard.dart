import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRscreens/staff/apply_claim_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/schedules.dart';

class ClaimDashboardScreen extends StatefulWidget {
  final String username;
  final int staffId;

  const ClaimDashboardScreen({
    super.key,
    required this.username,
    required this.staffId,
  });

  @override
  State<ClaimDashboardScreen> createState() => _ClaimDashboardScreenState();
}

class _ClaimDashboardScreenState extends State<ClaimDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3;
  bool _processing = false;

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

  // ✅ Staff can only cancel their own pending claims
  Future<void> _deleteClaim(Claim claim) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Claim'),
        content: const Text('Are you sure you want to cancel this claim request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Claims>(context, listen: false).deleteClaim(claim.claimId);
      await _fetchClaimData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim request cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel claim: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
        return;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffMySelfScreen()),
        );
        break;
    }
  }

  bool _hasProof(Claim claim) {
    return (claim.proofFileUrl?.trim().isNotEmpty ?? false) ||
        (claim.proofFilePath?.trim().isNotEmpty ?? false) ||
        (claim.proofFile?.isNotEmpty ?? false) ||
        (claim.proofFileName?.trim().isNotEmpty ?? false);
  }

  void _showClaimDetails(Claim claim) {
    final hasProof = _hasProof(claim);

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
              const SizedBox(height: 10),
              if (hasProof) ...[
                Text(
                  'Attachment: ${claim.proofFileName ?? 'Proof File'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ProofAttachmentViewer(
                  fileUrl: claim.proofFileUrl,
                  fileName: claim.proofFileName,
                  fileType: claim.proofFileType,
                ),
              ] else
                const Text(
                  'No proof attached for this claim.',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Claim claim, {bool showDelete = false}) {
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

    final hasProof = _hasProof(claim);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        onTap: () => _showClaimDetails(claim),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${claim.claimId} - ${claim.claimType}'),
            // ✅ Cancel button only on pending
            if (showDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Cancel Claim',
                onPressed: _processing ? null : () => _deleteClaim(claim),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RM ${claim.amount.toStringAsFixed(2)}'),
            Text('Date: ${claim.claimDate.toString().split(' ')[0]}'),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _showClaimDetails(claim),
              icon: const Icon(Icons.visibility, size: 18),
              label: Text(hasProof ? 'View Proof' : 'View Details'),
            ),
          ],
        ),
        trailing: showDelete
            ? null
            : Chip(
                label: Text(claim.status),
                backgroundColor: statusColor(),
              ),
      ),
    );
  }

  Widget _buildClaimList(List<Claim> claims, {bool showDelete = false}) {
    if (claims.isEmpty) {
      return const Center(
        child: Text('No claims found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: claims.length,
      itemBuilder: (_, i) => _buildClaimCard(claims[i], showDelete: showDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text("CHARMS STAFF", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
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
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications),
                      )
                    : const Icon(Icons.notifications),
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
              // ✅ Pending — show delete/cancel button
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final submitted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ApplyClaimScreen(staffId: widget.staffId),
                          ),
                        );
                        if (submitted == true) await _fetchClaimData();
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
                      showDelete: true, // ✅ can cancel pending
                    ),
                  ),
                ],
              ),
              // no delete on approved/rejected for staff
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