import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // ── Filter state ─────────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  String _activeChip  = 'All';
  String _searchQuery = '';

  // ── Palette ──────────────────────────────────────────────────────────────────
  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClaims() async {
    await Provider.of<Staffs>(context, listen: false).fetchStaff();
    await Provider.of<Claims>(context, listen: false).fetchClaims();
    if (mounted) setState(() {});
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

  // ── Filter logic ──────────────────────────────────────────────────────────────
  List<Claim> _applyFilters(List<Claim> claims, List<Staff> staffList) {
    return claims.where((claim) {
      // Date filter on claimDate
      if (_fromDate != null) {
        final from =
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (claim.claimDate.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(
            _toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (claim.claimDate.isAfter(to)) return false;
      }
      // Staff name search
      if (_searchQuery.isNotEmpty) {
        final name =
            _getStaffName(claim.staffId, staffList).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  void _applyQuickChip(String chip) {
    final now = DateTime.now();
    setState(() {
      _activeChip = chip;
      switch (chip) {
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate   = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Last Month':
          final last = DateTime(now.year, now.month - 1);
          _fromDate = DateTime(last.year, last.month, 1);
          _toDate   = DateTime(now.year, now.month, 0);
          break;
        case 'This Year':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate   = DateTime(now.year, 12, 31);
          break;
        default:
          _fromDate = null;
          _toDate   = null;
          break;
      }
    });
  }

  Future<void> _pickFromDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (p != null) {
      setState(() {
        _fromDate   = p;
        _activeChip = 'Custom';
        if (_toDate != null && _toDate!.isBefore(p)) _toDate = p;
      });
    }
  }

  Future<void> _pickToDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() { _toDate = p; _activeChip = 'Custom'; });
  }

  // ── Claim actions ─────────────────────────────────────────────────────────────
  Future<void> _approveClaim(Claim claim) async {
    try {
      await Provider.of<Claims>(context, listen: false)
          .updateClaim(claim.claimId, 'Approved');
      await _fetchClaims();
      if (mounted) setState(() => selectedClaims.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve claim: $e')));
    }
  }

  Future<void> _rejectClaim(Claim claim, String reason) async {
    try {
      await Provider.of<Claims>(context, listen: false)
          .updateClaim(claim.claimId, 'Rejected', rejectionReason: reason);
      await _fetchClaims();
      if (mounted) setState(() => selectedClaims.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject claim: $e')));
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
        content: const Text(
            'Are you sure you want to delete this claim record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Claim deleted successfully'),
          backgroundColor: Colors.teal));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete claim: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showRejectDialog(List<Claim> allClaims) {
    final controller = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Rejection Reason',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter reason for rejection...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.redAccent, width: 2)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please provide a reason'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Reject'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reason = controller.text.trim();
                Navigator.pop(ctx);
                for (final id in selectedClaims) {
                  final claim =
                      allClaims.firstWhere((c) => c.claimId == id);
                  await _rejectClaim(claim, reason);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(List<Claim> allClaims) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Claims',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Approve ${selectedClaims.length} selected claim(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in selectedClaims) {
                final claim =
                    allClaims.firstWhere((c) => c.claimId == id);
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

  bool _hasProof(Claim c) =>
      (c.proofFileUrl?.trim().isNotEmpty ?? false) ||
      (c.proofFilePath?.trim().isNotEmpty ?? false) ||
      (c.proofFile?.isNotEmpty ?? false) ||
      (c.proofFileName?.trim().isNotEmpty ?? false);

  void _showClaimDetails(Claim claim, List<Staff> staffList) {
    final hasProof  = _hasProof(claim);
    final staffName = _getStaffName(claim.staffId, staffList);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              _detailRow('Staff', staffName),
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
              if (claim.rejectionReason != null &&
                  claim.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rejection Reason',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(claim.rejectionReason!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              if (hasProof) ...[
                Text(
                    'Attachment: ${claim.proofFileName ?? 'Proof File'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                ProofAttachmentViewer(
                  fileUrl:  claim.proofFileUrl,
                  fileName: claim.proofFileName,
                  fileType: claim.proofFileType,
                ),
              ] else
                Row(children: [
                  Icon(Icons.attachment_rounded,
                      size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text('No proof attached.',
                      style:
                          TextStyle(color: Colors.grey.shade500)),
                ]),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isHighlight = false}) =>
      Padding(
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
              child: Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: isHighlight
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isHighlight
                          ? Colors.teal
                          : const Color(0xFF334155))),
            ),
          ],
        ),
      );

  // ── Filter panel ──────────────────────────────────────────────────────────────
  Widget _buildFilterPanel() {
    final df    = DateFormat('dd MMM yyyy');
    final chips = ['All', 'This Month', 'Last Month', 'This Year'];
    final isFiltered = _fromDate != null || _toDate != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 16, color: primaryBlue),
              const SizedBox(width: 6),
              Text('Filter & Search',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: primaryBlue)),
              const Spacer(),
              if (isFiltered || _searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _applyQuickChip('All');
                    setState(() => _searchQuery = '');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.close_rounded,
                            size: 13, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text('Clear all',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) {
                final isActive = _activeChip == chip;
                return GestureDetector(
                  onTap: () => _applyQuickChip(chip),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryBlue
                          : primaryBlue.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive
                              ? primaryBlue
                              : primaryBlue.withOpacity(0.2)),
                    ),
                    child: Text(chip,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : primaryBlue)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // From → To pickers
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromDate,
                  child: _datePill(
                      label: _fromDate != null
                          ? df.format(_fromDate!)
                          : 'From date',
                      active: _fromDate != null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('→',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickToDate,
                  child: _datePill(
                      label: _toDate != null
                          ? df.format(_toDate!)
                          : 'To date',
                      active: _toDate != null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search by staff name
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by staff name...',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: primaryBlue, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: primaryBlue, width: 1.5)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ],
      ),
    );
  }

  Widget _datePill({required String label, required bool active}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? primaryBlue.withOpacity(0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active
                  ? primaryBlue.withOpacity(0.4)
                  : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 13,
                color: active ? primaryBlue : Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? primaryBlue : Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  // ── Summary row ───────────────────────────────────────────────────────────────
  Widget _buildSummaryRow(List<Claim> filtered) {
    final total    = filtered.length;
    final pending  = filtered.where((c) => c.status == 'Pending').length;
    final approved = filtered.where((c) => c.status == 'Approved').length;
    final rejected = filtered.where((c) => c.status == 'Rejected').length;
    final totalAmt = filtered.fold<double>(0, (s, c) => s + c.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip(Icons.list_alt_rounded,    '$total Total',         Colors.blueGrey),
            const SizedBox(width: 8),
            _summaryChip(Icons.pending_actions_rounded, '$pending Pending', Colors.orange),
            const SizedBox(width: 8),
            _summaryChip(Icons.check_circle_rounded, '$approved Approved',  Colors.teal),
            const SizedBox(width: 8),
            _summaryChip(Icons.cancel_rounded,       '$rejected Rejected',  Colors.redAccent),
            const SizedBox(width: 8),
            _summaryChip(Icons.attach_money_rounded,
                'RM ${totalAmt.toStringAsFixed(2)}', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );

  // ── Claim card ────────────────────────────────────────────────────────────────
  Widget _buildClaimCard(Claim claim, List<Staff> staffList,
      {bool showDelete = false}) {
    final hasProof   = _hasProof(claim);
    final isSelected = selectedClaims.contains(claim.claimId);
    final staffName  = _getStaffName(claim.staffId, staffList);

    Color statusColor   = Colors.orange;
    Color statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon = Icons.pending_actions_rounded;
    if (claim.status == 'Approved') {
      statusColor   = Colors.teal;
      statusBgColor = Colors.teal.withOpacity(0.1);
      statusIcon    = Icons.check_circle_rounded;
    } else if (claim.status == 'Rejected') {
      statusColor   = Colors.redAccent;
      statusBgColor = Colors.redAccent.withOpacity(0.1);
      statusIcon    = Icons.cancel_rounded;
    }

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryBlue.withOpacity(0.05)
            : Colors.white,
        border: Border.all(
            color: isSelected ? primaryBlue : Colors.transparent,
            width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
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
                // Left icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long_rounded,
                      size: 24, color: Colors.orange),
                ),
                const SizedBox(width: 16),

                // Middle content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${claim.claimId} — ${claim.claimType}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 3),
                      Text(staffName,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text('RM ${claim.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                            claim.claimDate.toString().split(' ')[0],
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 8),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(claim.status,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ]),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () =>
                            _showClaimDetails(claim, staffList),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded,
                                size: 14, color: primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              hasProof
                                  ? 'View Proof'
                                  : 'View Details',
                              style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: delete or checkbox
                if (showDelete)
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10)),
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
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
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

  // ── Claims list ───────────────────────────────────────────────────────────────
  Widget _buildClaimsList(List<Claim> claims, List<Staff> staffList,
      {bool showActions = false, bool showDelete = false}) {
    final filtered = _applyFilters(claims, staffList);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              (_fromDate != null ||
                      _toDate != null ||
                      _searchQuery.isNotEmpty)
                  ? 'No records match your filter'
                  : 'No claims found',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            if (_fromDate != null ||
                _toDate != null ||
                _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _applyQuickChip('All');
                  setState(() => _searchQuery = '');
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: primaryBlue,
            onRefresh: _fetchClaims,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                  top: 8, bottom: showActions ? 80 : 24),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildClaimCard(
                  filtered[i], staffList,
                  showDelete: showDelete),
            ),
          ),
        ),
        // Approve / Reject action bar (pending tab)
        if (showActions && selectedClaims.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5)),
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
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
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchClaims,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text('Pending',  style: TextStyle(color: Colors.white))),
            Tab(child: Text('Approved', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Rejected', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer2<Staffs, Claims>(
        builder: (context, staffsData, claimsData, child) {
          final staffList = staffsData.staffList;
          final pending   = claimsData.claims.where((c) => c.status == 'Pending').toList();
          final approved  = claimsData.claims.where((c) => c.status == 'Approved').toList();
          final rejected  = claimsData.claims.where((c) => c.status == 'Rejected').toList();

          final currentTab  = _tabController.index;
          final currentList = currentTab == 0
              ? pending
              : currentTab == 1 ? approved : rejected;

          return Column(
            children: [
              // ── Filter panel ───────────────────────────────────────────
              _buildFilterPanel(),

              // ── Summary row ────────────────────────────────────────────
              _buildSummaryRow(
                  _applyFilters(currentList, staffList)),

              const SizedBox(height: 8),

              // ── Tab content ────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClaimsList(pending,  staffList, showActions: true),
                    _buildClaimsList(approved, staffList, showDelete: true),
                    _buildClaimsList(rejected, staffList, showDelete: true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}