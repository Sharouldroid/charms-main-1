import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRscreens/staff/apply_claim_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
//import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/schedules.dart';
//import 'package:charms/providers/auth.dart' as app_auth;
//import 'package:charms/screens/auth_screen.dart';
import 'package:charms/utils/logout_helper.dart';

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

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5); // Deep Indigo
  final Color staffBg = const Color(0xFFF8FAFC); // Very Light Slate
  final Color staffCardBorder = const Color(0xFFE2E8F0);

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
  await LogoutHelper.fullLogout(context);
}

  // ✅ Staff can only cancel their own pending claims
  Future<void> _deleteClaim(Claim claim) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Claim', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this claim request?'),
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

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Claims>(context, listen: false).deleteClaim(claim.claimId);
      await _fetchClaimData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim request cancelled successfully'),
          backgroundColor: Colors.teal, // Modernized success color
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel claim: $e'), backgroundColor: Colors.redAccent),
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
          MaterialPageRoute(builder: (_) => const StaffMySelfScreen()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Claim Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Claim ID', claim.claimId.toString()),
              _detailRow('Type', claim.claimType),
              _detailRow('Amount', 'RM ${claim.amount.toStringAsFixed(2)}', isHighlight: true),
              _detailRow('Date', claim.claimDate.toString().split(' ')[0]),
              _detailRow('Status', claim.status),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(claim.description, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              if (hasProof) ...[
                Text(
                  'Attachment: ${claim.proofFileName ?? 'Proof File'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                ProofAttachmentViewer(
                  fileUrl: claim.proofFileUrl,
                  fileName: claim.proofFileName,
                  fileType: claim.proofFileType,
                ),
              ] else
                Row(
                  children: [
                    Icon(Icons.attachment_rounded, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'No proof attached.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: staffPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper widget for dialog rows
  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? staffPrimary : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Claim claim, {bool showDelete = false}) {
    // Modern Status Colors
    Color statusColor = Colors.orange;
    Color statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon = Icons.pending_actions_rounded;
    
    if (claim.status == 'Approved') {
      statusColor = Colors.teal;
      statusBgColor = Colors.teal.withOpacity(0.1);
      statusIcon = Icons.check_circle_rounded;
    } else if (claim.status == 'Rejected') {
      statusColor = Colors.redAccent;
      statusBgColor = Colors.redAccent.withOpacity(0.1);
      statusIcon = Icons.cancel_rounded;
    }

    final hasProof = _hasProof(claim);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder), // Flat outlined look
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showClaimDetails(claim),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.request_quote_rounded, size: 24, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                
                // Middle Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.claimType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${claim.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: staffPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            claim.claimDate.toString().split(' ')[0],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Modern Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              claim.status,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Actions (Delete or View Details)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showDelete)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Cancel Claim',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          onPressed: _processing ? null : () => _deleteClaim(claim),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: staffPrimary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(hasProof ? Icons.attachment_rounded : Icons.visibility_rounded, color: staffPrimary, size: 20),
                        tooltip: 'View Details',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _showClaimDetails(claim),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimList(List<Claim> claims, {bool showDelete = false}) {
    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No claims found',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 80), // Padding for FAB
      itemCount: claims.length,
      itemBuilder: (_, i) => _buildClaimCard(claims[i], showDelete: showDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg, // Modern background
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text("MY CLAIMS",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        backgroundColor: staffPrimary,
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
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.notifications_active_rounded),
                      )
                    : const Icon(Icons.notifications_none_rounded),
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
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Back to Login',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
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
              _buildClaimList(
                claimsData.claims.where((c) => c.status == 'Pending').toList(),
                showDelete: true,
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
      // Upgraded to a consistent FloatingActionButton matching LeaveDashboard
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0), // Avoid navbar overlap
        child: FloatingActionButton.extended(
          onPressed: () async {
            final submitted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ApplyClaimScreen(staffId: widget.staffId),
              ),
            );
            if (submitted == true) {
              await _fetchClaimData();
              _tabController.animateTo(0);
            }
          },
          backgroundColor: staffPrimary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Apply Claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}