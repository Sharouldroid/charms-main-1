import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRmodels/claim.dart';

class ManageClaimScreen extends StatefulWidget {
  const ManageClaimScreen({super.key});

  @override
  _ManageClaimScreenState createState() => _ManageClaimScreenState();
}

class _ManageClaimScreenState extends State<ManageClaimScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<int> selectedClaims = [];

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
    setState(() {
      selectedClaims.clear();
    });
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to approve claim: $error'))
    );
  }
}

Future<void> _rejectClaim(Claim claim) async {
  try {
    final claimsProvider = Provider.of<Claims>(context, listen: false);
    await claimsProvider.updateClaim(claim.claimId, 'Rejected');
    await _fetchClaims();
    setState(() {
      selectedClaims.clear();
    });
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to reject claim: $error'))
    );
  }
}

void _showRejectDialog(List<Claim> claims) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reject Claims'),
      content: Text('Are you sure you want to reject the selected claims?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            for (var claimId in selectedClaims) {
              final claim = claims.firstWhere((c) => c.claimId == claimId);
              _rejectClaim(claim);
            }
          },
          child: Text('Reject'),
        ),
      ],
    ),
  );
}

  void _showClaimDetails(Claim claim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Claim Details'),
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
                                      Text('Image preview not available')
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
      ),
    );
  }

  Widget _buildClaimCard(Claim claim) {
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
            trailing: Checkbox(
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
        title: Text('Manage Claim', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text( 'Pending', style: TextStyle(color: Colors.white))),
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
                showActions: true,
              ),
              _buildClaimsList(
                claimsData.claims.where((c) => c.status == 'Approved').toList(),
              ),
              _buildClaimsList(
                claimsData.claims.where((c) => c.status == 'Rejected').toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClaimsList(List<Claim> claims, {bool showActions = false}) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: claims.length,
            itemBuilder: (context, index) => _buildClaimCard(claims[index]),
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
                    child: Text('Reject', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _showApproveDialog(claims),
                    child: Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showApproveDialog(List<Claim> claims) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Claims'),
        content: Text('Are you sure you want to approve the selected claims?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (var claimId in selectedClaims) {
                final claim = claims.firstWhere((c) => c.claimId == claimId);
                _approveClaim(claim);
              }
            },
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }
}