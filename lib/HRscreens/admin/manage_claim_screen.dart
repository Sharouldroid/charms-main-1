import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRmodels/claim.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    final claimsProvider = Provider.of<Claims>(context, listen: false);
    await claimsProvider.fetchClaims();
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

  // ✅ New delete method
  Future<void> _deleteClaim(Claim claim) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Claim'),
        content: const Text('Are you sure you want to delete this claim record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Claims>(context, listen: false).deleteClaim(claim.claimId);
      await _fetchClaims();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim deleted successfully'),
          backgroundColor: Colors.green,
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
        title: const Text('Reject Claims'),
        content: const Text('Are you sure you want to reject the selected claims?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (var claimId in selectedClaims) {
                final claim = claims.firstWhere((c) => c.claimId == claimId);
                await _rejectClaim(claim);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(List<Claim> claims) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Claims'),
        content: const Text('Are you sure you want to approve the selected claims?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (var claimId in selectedClaims) {
                final claim = claims.firstWhere((c) => c.claimId == claimId);
                await _approveClaim(claim);
              }
            },
            child: const Text('Approve'),
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

  void _showClaimDetails(Claim claim) {
    final hasProof = _hasProof(claim);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Claim ID: ${claim.claimId}'),
              Text('Staff ID: ${claim.staffId}'),
              Text('Type: ${claim.claimType}'),
              Text('Amount: RM ${claim.amount.toStringAsFixed(2)}'),
              Text('Date: ${claim.claimDate.toString().split(' ')[0]}'),
              Text('Description: ${claim.description}'),
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
    final hasProof = _hasProof(claim);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        onTap: () => _showClaimDetails(claim),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${claim.claimId} - ${claim.claimType}'),
            // ✅ Delete button on approved/rejected cards
            if (showDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
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
            ? null // ✅ Hide checkbox on approved/rejected
            : Checkbox(
                value: selectedClaims.contains(claim.claimId),
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
      ),
    );
  }

  Widget _buildClaimsList(List<Claim> claims,
      {bool showActions = false, bool showDelete = false}) {
    if (claims.isEmpty) {
      return const Center(
        child: Text('No claims found', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: claims.length,
            itemBuilder: (context, index) =>
                _buildClaimCard(claims[index], showDelete: showDelete),
          ),
        ),
        if (showActions && selectedClaims.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _showRejectDialog(claims),
                    child: const Text('Reject', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _showApproveDialog(claims),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
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
      appBar: AppBar(
        title: const Text('Manage Claim', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Text('Pending', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Approved', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Rejected', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer<Claims>(
        builder: (context, claimsData, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildClaimsList(
                claimsData.claims.where((c) => c.status == 'Pending').toList(),
                showActions: true,               // keep approve/reject + checkbox
              ),
              _buildClaimsList(
                claimsData.claims.where((c) => c.status == 'Approved').toList(),
                showDelete: true,                // ✅ delete button, no checkbox
              ),
              _buildClaimsList(
                claimsData.claims.where((c) => c.status == 'Rejected').toList(),
                showDelete: true,                // ✅ delete button, no checkbox
              ),
            ],
          );
        },
      ),
    );
  }
}