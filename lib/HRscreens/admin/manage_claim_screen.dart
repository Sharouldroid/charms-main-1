import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';

class ManageClaimScreen extends StatefulWidget {
  const ManageClaimScreen({super.key});

  @override
  State<ManageClaimScreen> createState() => _ManageClaimScreenState();
}

class _ManageClaimScreenState extends State<ManageClaimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<int> selectedClaims = [];
  bool _processing = false;

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    await Provider.of<Staffs>(context, listen: false).fetchStaff();
    await Provider.of<Claims>(context, listen: false).fetchClaims();
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

  Future<void> _approveClaim(Claim claim) async {
    try {
      final claimsProvider = Provider.of<Claims>(context, listen: false);
      await claimsProvider.updateClaim(claim.claimId, 'Approved');
      await _fetchClaims();
      if (mounted) setState(() => selectedClaims.clear());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve claim: $error')),
      );
    }
  }

  Future<void> _rejectClaim(Claim claim) async {
    try {
      final claimsProvider = Provider.of<Claims>(context, listen: false);
      await claimsProvider.updateClaim(claim.claimId, 'Rejected');
      await _fetchClaims();
      if (mounted) setState(() => selectedClaims.clear());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject claim: $error')),
      );
    }
  }

  Future<void> _deleteClaim(Claim claim) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Claim',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to delete this claim record?'),
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
      await Provider.of<Claims>(context, listen: false)
          .deleteClaim(claim.claimId);
      await _fetchClaims();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim deleted successfully'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete claim: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showRejectDialog(List<Claim> claims) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Claims',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to reject the ${selectedClaims.length} selected claims?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () async {
              Navigator.pop(context);
              for (var claimId in selectedClaims) {
                final claim =
                    claims.firstWhere((c) => c.claimId == claimId);
                await _rejectClaim(claim);
              }
            },
            child:
                const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(List<Claim> claims) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Claims',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to approve the ${selectedClaims.length} selected claims?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              for (var claimId in selectedClaims) {
                final claim =
                    claims.firstWhere((c) => c.claimId == claimId);
                await _approveClaim(claim);
              }
            },
            child: const Text('Approve',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _hasProof(Claim claim) {
    return (claim.proofFileUrl?.trim().isNotEmpty ?? false) ||
        (claim.proofFilePath?.trim().isNotEmpty ?? false) ||
        (claim.proofFile?.isNotEmpty ?? false) ||
        (claim.proofFileName?.trim().isNotEmpty ?? false);
  }

  void _showClaimDetails(Claim claim, List<Staff> staffList) {
    final hasProof = _hasProof(claim);
    final String staffName = _getStaffName(claim.staffId, staffList);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Claim Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Claim ID', claim.claimId.toString()),
              _detailRow('Staff', staffName), // Staff Name instead of ID
              _detailRow('Type', claim.claimType),
              _detailRow('Amount',
                  'RM ${claim.amount.toStringAsFixed(2)}',
                  isHighlight: true),
              _detailRow(
                  'Date', claim.claimDate.toString().split(' ')[0]),
              const SizedBox(height: 8),
              const Text('Description:',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(claim.description,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF334155))),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              if (hasProof) ...[
                Text(
                  'Attachment: ${claim.proofFileName ?? 'Proof File'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B)),
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
                    Icon(Icons.attachment_rounded,
                        size: 16, color: Colors.grey.shade400),
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
              backgroundColor: primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? Colors.teal
                    : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Claim claim, List<Staff> staffList,
      {bool showDelete = false}) {
    final hasProof = _hasProof(claim);
    final isSelected = selectedClaims.contains(claim.claimId);
    final String staffName = _getStaffName(claim.staffId, staffList);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: isSelected ? primaryBlue.withOpacity(0.05) : Colors.white,
        border: Border.all(
          color: isSelected ? primaryBlue : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!showDelete) {
              setState(() {
                if (isSelected) {
                  selectedClaims.remove(claim.claimId);
                } else {
                  selectedClaims.add(claim.claimId);
                }
              });
            } else {
              _showClaimDetails(claim, staffList);
            }
          },
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
                  child: const Icon(Icons.receipt_long_rounded,
                      size: 24, color: Colors.orange),
                ),
                const SizedBox(width: 16),

                // Middle Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${claim.claimId} - ${claim.claimType}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staffName, // Staff Name instead of Staff ID
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${claim.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 12, color: Colors.grey),
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
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showClaimDetails(claim, staffList),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded,
                                size: 16, color: primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              hasProof ? 'View Proof' : 'View Details',
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Actions
                if (showDelete)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: _processing
                          ? null
                          : () => _deleteClaim(claim),
                    ),
                  )
                else
                  Checkbox(
                    value: isSelected,
                    activeColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedClaims.add(claim.claimId);
                        } else {
                          selectedClaims.remove(claim.claimId);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimsList(List<Claim> claims, List<Staff> staffList,
      {bool showActions = false, bool showDelete = false}) {
    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No claims found',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: showActions ? 80 : 24),
            itemCount: claims.length,
            itemBuilder: (context, index) =>
                _buildClaimCard(claims[index], staffList, showDelete: showDelete),
          ),
        ),
        // Action Bar at the bottom
        if (showActions && selectedClaims.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showRejectDialog(claims),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showApproveDialog(claims),
                      icon:
                          const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MANAGE CLAIM',
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
                child: Text('Pending',
                    style: TextStyle(color: Colors.white))),
            Tab(
                child: Text('Approved',
                    style: TextStyle(color: Colors.white))),
            Tab(
                child: Text('Rejected',
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer2<Staffs, Claims>(
        builder: (context, staffsData, claimsData, child) {
          final staffList = staffsData.staffList;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildClaimsList(
                claimsData.claims
                    .where((c) => c.status == 'Pending')
                    .toList(),
                staffList,
                showActions: true,
              ),
              _buildClaimsList(
                claimsData.claims
                    .where((c) => c.status == 'Approved')
                    .toList(),
                staffList,
                showDelete: true,
              ),
              _buildClaimsList(
                claimsData.claims
                    .where((c) => c.status == 'Rejected')
                    .toList(),
                staffList,
                showDelete: true,
              ),
            ],
          );
        },
      ),
    );
  }
}