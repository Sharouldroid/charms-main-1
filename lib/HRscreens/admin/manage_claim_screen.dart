import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/payment_claims.dart';
import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/payment_claim.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class ManageClaimScreen extends StatefulWidget {
  const ManageClaimScreen({super.key});

  @override
  State<ManageClaimScreen> createState() => _ManageClaimScreenState();
}

class _ManageClaimScreenState extends State<ManageClaimScreen>
    with SingleTickerProviderStateMixin {
  // ── Tab controller: 4 tabs now ────────────────────────────────────────────
  late TabController _tabController;

  List<int> selectedClaims        = [];
  List<int> selectedPaymentClaims = [];
  bool _processing = false;

  // ── Filter state ──────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  String _activeChip  = 'All';
  String _searchQuery = '';

  // ── Palette ───────────────────────────────────────────────────────────────
  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  // Admin user ID — replace with your actual logged-in admin ID from auth
  // TODO: get this from your auth provider
  static const int _adminUserId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // ← 4 tabs
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Provider.of<Staffs>(context, listen: false).fetchStaff();
    await Provider.of<Claims>(context, listen: false).fetchClaims();
    await Provider.of<PaymentClaims>(context, listen: false).fetchAllClaims();
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

  // ── Filter logic ──────────────────────────────────────────────────────────
  List<Claim> _applyFilters(List<Claim> claims, List<Staff> staffList) {
    return claims.where((claim) {
      if (_fromDate != null) {
        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (claim.claimDate.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (claim.claimDate.isAfter(to)) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = _getStaffName(claim.staffId, staffList).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  List<PaymentClaim> _applyPaymentClaimFilters(List<PaymentClaim> claims) {
    return claims.where((claim) {
      if (_searchQuery.isNotEmpty) {
        final name = (claim.staffName ?? '').toLowerCase();
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

  // ── Expense claim actions (unchanged) ─────────────────────────────────────
  Future<void> _approveClaim(Claim claim) async {
    try {
      await Provider.of<Claims>(context, listen: false)
          .updateClaim(claim.claimId, 'Approved');
      await _fetchAll();
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
      await _fetchAll();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Claim',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this claim record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      await Provider.of<Claims>(context, listen: false)
          .deleteClaim(claim.claimId);
      await _fetchAll();
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

  // ── Payment claim actions ──────────────────────────────────────────────────
  Future<void> _approvePaymentClaim(PaymentClaim claim) async {
    setState(() => _processing = true);
    try {
      final success = await Provider.of<PaymentClaims>(context, listen: false)
          .approveClaim(claim.claimId, _adminUserId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment claim approved!'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ));
        await _fetchAll();
        setState(() => selectedPaymentClaims.clear());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to approve payment claim')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _rejectPaymentClaim(PaymentClaim claim, String reason) async {
    setState(() => _processing = true);
    try {
      final success = await Provider.of<PaymentClaims>(context, listen: false)
          .rejectClaim(claim.claimId, _adminUserId, reason);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment claim rejected.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
        await _fetchAll();
        setState(() => selectedPaymentClaims.clear());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to reject payment claim')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  // ── Mark a payment claim as paid (NEW) ─────────────────────────────────────
  Future<void> _confirmMarkAsPaid(PaymentClaim claim) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.payments_rounded, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('Mark as Paid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Confirm that RM ${claim.totalAmount.toStringAsFixed(2)} has been paid '
          'to ${claim.staffName ?? 'this staff'}?\n\n'
          'This records today\'s date as the payment date.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await _markClaimAsPaid(claim);
  }

  Future<void> _markClaimAsPaid(PaymentClaim claim) async {
    setState(() => _processing = true);
    try {
      final success = await Provider.of<PaymentClaims>(context, listen: false)
          .markAsPaid(claim.claimId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ Marked as paid.'
            : 'Failed to mark as paid. Try again.'),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (success) {
        await _fetchAll();
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _pickAndSendReceipt(PaymentClaim claim) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // required for Flutter Web — avoids dart:io path access
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    await _sendReceipt(claim, file.bytes!, file.name);
  }

  Future<void> _sendReceipt(
      PaymentClaim claim, Uint8List bytes, String fileName) async {
    setState(() => _processing = true);
    try {
      final success = await Provider.of<PaymentClaims>(context, listen: false)
          .sendReceipt(claimId: claim.claimId, fileBytes: bytes, fileName: fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ Receipt sent to ${claim.staffName ?? 'staff'}.'
            : 'Failed to send receipt. Try again.'),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (success) await _fetchAll();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _bulkMarkAsPaid(List<PaymentClaim> claims) async {
    final eligible = claims.where((c) => c.status == 'Approved' && c.paidAt == null).toList();
    if (eligible.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.payments_rounded, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('Mark as Paid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Mark ${eligible.length} selected claim(s) totalling '
          'RM ${eligible.fold<double>(0, (s, c) => s + c.totalAmount).toStringAsFixed(2)} as paid?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _processing = true);
    try {
      final ids = eligible.map((c) => c.claimId).toList();
      final success = await Provider.of<PaymentClaims>(context, listen: false)
          .markMultipleAsPaid(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ ${ids.length} claim(s) marked as paid.'
            : 'Failed to mark claims as paid.'),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (success) {
        setState(() => selectedPaymentClaims.clear());
        await _fetchAll();
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _bulkSendReceipt(List<PaymentClaim> claims) async {
    final eligible = claims.where((c) => c.paidAt != null && c.receiptSentAt == null).toList();
    if (eligible.isEmpty) return;

    final staffIds = eligible.map((c) => c.staffId).toSet();
    if (staffIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select claims for ONE staff member only to send a combined receipt.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _processing = true);
    try {
      final ids = eligible.map((c) => c.claimId).toList();
      final result = await Provider.of<PaymentClaims>(context, listen: false).sendReceiptBulk(
        claimIds: ids,
        fileBytes: file.bytes!,
        fileName: file.name,
      );
      final success = result['success'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ ${result['message']}'
            : '❌ ${result['message']}'),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (success) {
        setState(() => selectedPaymentClaims.clear());
        await _fetchAll();
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showPaymentClaimRejectDialog(PaymentClaim claim) {
    final controller = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 8),
          Text('Rejection Reason',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
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
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 2)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please provide a reason'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
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
                await _rejectPaymentClaim(claim, reason);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentClaimDetails(PaymentClaim claim) {
    final monthName = DateFormat('MMMM yyyy')
        .format(DateTime(claim.year, claim.month));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Payment Claim Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Staff',    claim.staffName ?? 'Staff ID: ${claim.staffId}'),
              _detailRow('Period',   monthName),
              _detailRow('Days',     '${claim.totalDays} days'),
              _detailRow('Day Rate', 'RM ${claim.dayRate.toStringAsFixed(2)}'),
              _detailRow('Total',
                  'RM ${claim.totalAmount.toStringAsFixed(2)}',
                  isHighlight: true),
              _detailRow('Status',   claim.status),
              if (claim.submittedAt != null)
                _detailRow('Submitted',
                    DateFormat('dd MMM yyyy').format(claim.submittedAt!)),
              if (claim.reviewedAt != null)
                _detailRow('Reviewed',
                    DateFormat('dd MMM yyyy').format(claim.reviewedAt!)),
              if (claim.paidAt != null)
                _detailRow('Paid On',
                    DateFormat('dd MMM yyyy').format(claim.paidAt!),
                    isHighlight: true),
              if (claim.receiptSentAt != null)
                _detailRow('Receipt Sent',
                    DateFormat('dd MMM yyyy').format(claim.receiptSentAt!)),
              if (claim.rejectionReason != null &&
                  claim.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
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
                  ]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (claim.status == 'Pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showPaymentClaimRejectDialog(claim);
              },
              child: const Text('Reject',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(ctx);
                _approvePaymentClaim(claim);
              },
              child: const Text('Approve'),
            ),
          ] else if (claim.status == 'Approved' && claim.paidAt == null) ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.payments_rounded, size: 16),
              label: const Text('Mark as Paid'),
              onPressed: () {
                Navigator.pop(ctx);
                _confirmMarkAsPaid(claim);
              },
            ),
          ] else if (claim.paidAt != null && claim.receiptSentAt == null) ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text('Send Receipt'),
              onPressed: () {
                Navigator.pop(ctx);
                _pickAndSendReceipt(claim);
              },
            ),
          ] else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    fontWeight:
                        isHighlight ? FontWeight.bold : FontWeight.w500,
                    color: isHighlight
                        ? Colors.teal
                        : const Color(0xFF334155))),
          ),
        ]),
      );

  // ── Payment claim card ──────────────────────────────────────────────────────
  Widget _buildPaymentClaimCard(PaymentClaim claim, {bool isPending = false}) {
    final monthLabel = DateFormat('MMMM yyyy')
        .format(DateTime(claim.year, claim.month));

    Color    statusColor = Colors.orange;
    Color    statusBg    = Colors.orange.withOpacity(0.1);
    IconData statusIcon  = Icons.pending_actions_rounded;
    String   statusLabel = claim.status;

    final isPaid = claim.status == 'Approved' && claim.paidAt != null;

    if (isPaid) {
      statusColor = Colors.green;
      statusBg    = Colors.green.withOpacity(0.1);
      statusIcon  = Icons.verified_rounded;
      statusLabel = 'Paid';
    } else if (claim.status == 'Approved') {
      statusColor = Colors.teal;
      statusBg    = Colors.teal.withOpacity(0.1);
      statusIcon  = Icons.check_circle_rounded;
    } else if (claim.status == 'Rejected') {
      statusColor = Colors.redAccent;
      statusBg    = Colors.redAccent.withOpacity(0.1);
      statusIcon  = Icons.cancel_rounded;
    }

    final canMarkPaid = claim.status == 'Approved' && claim.paidAt == null;
    final canSendReceipt = claim.paidAt != null && claim.receiptSentAt == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPaymentClaimDetails(claim),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.payments_rounded,
                    size: 24, color: Color(0xFFF97316)),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(claim.staffName ?? 'Staff ID: ${claim.staffId}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 3),
                  Text(monthLabel,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    '${claim.totalDays} days × RM ${claim.dayRate.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text('RM ${claim.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  if (claim.submittedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${DateFormat('dd MMM yyyy').format(claim.submittedAt!)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                  if (claim.paidAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Paid: ${DateFormat('dd MMM yyyy').format(claim.paidAt!)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: claim.receiptSentAt != null
                            ? Colors.blueAccent.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          claim.receiptSentAt != null
                              ? Icons.mark_email_read_rounded
                              : Icons.mail_outline_rounded,
                          size: 12,
                          color: claim.receiptSentAt != null
                              ? Colors.blueAccent
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          claim.receiptSentAt != null
                              ? 'Receipt Sent — ${DateFormat('dd MMM').format(claim.receiptSentAt!)}'
                              : 'Receipt Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: claim.receiptSentAt != null
                                ? Colors.blueAccent
                                : Colors.orange,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),

              // Quick actions
              if (isPending)
                Column(children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded,
                        color: Colors.teal, size: 28),
                    tooltip: 'Approve',
                    onPressed: _processing
                        ? null
                        : () => _approvePaymentClaim(claim),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded,
                        color: Colors.redAccent, size: 28),
                    tooltip: 'Reject',
                    onPressed: _processing
                        ? null
                        : () => _showPaymentClaimRejectDialog(claim),
                  ),
                ])
              else if (canMarkPaid || canSendReceipt)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: selectedPaymentClaims.contains(claim.claimId),
                      activeColor: primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedPaymentClaims.add(claim.claimId);
                          } else {
                            selectedPaymentClaims.remove(claim.claimId);
                          }
                        });
                      },
                    ),
                    if (canMarkPaid)
                      IconButton(
                        icon: const Icon(Icons.payments_rounded,
                            color: Colors.green, size: 26),
                        tooltip: 'Mark as Paid',
                        onPressed: _processing
                            ? null
                            : () => _confirmMarkAsPaid(claim),
                      )
                    else if (canSendReceipt)
                      IconButton(
                        icon: const Icon(Icons.receipt_long_rounded,
                            color: Colors.blueAccent, size: 26),
                        tooltip: 'Send Receipt',
                        onPressed: _processing
                            ? null
                            : () => _pickAndSendReceipt(claim),
                      ),
                  ],
                ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Payment claims list ────────────────────────────────────────────────────
 Widget _buildPaymentClaimsList(List<PaymentClaim> claims, {bool isPending = false}) {
    final filtered = _applyPaymentClaimFilters(claims);

    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.payments_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No records match your search'
                : 'No payment claims',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ]),
      );
    }

    final selected = claims.where((c) => selectedPaymentClaims.contains(c.claimId)).toList();
    final canBulkPay = selected.isNotEmpty &&
        selected.every((c) => c.status == 'Approved' && c.paidAt == null);
    final canBulkReceipt = selected.isNotEmpty &&
        selected.every((c) => c.paidAt != null && c.receiptSentAt == null);

    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _fetchAll,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: 8, bottom: selected.isNotEmpty ? 90 : 24),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildPaymentClaimCard(
              filtered[i],
              isPending: filtered[i].status == 'Pending',
            ),
          ),
        ),
      ),
      if (selected.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: Text('${selected.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              ),
              if (canBulkPay)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _processing ? null : () => _bulkMarkAsPaid(selected),
                  icon: const Icon(Icons.payments_rounded, size: 16),
                  label: Text('Mark Paid (${selected.length})'),
                ),
              if (canBulkReceipt) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _processing ? null : () => _bulkSendReceipt(selected),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: Text('Send Receipt (${selected.length})'),
                ),
              ],
              if (!canBulkPay && !canBulkReceipt)
                TextButton(
                  onPressed: () => setState(() => selectedPaymentClaims.clear()),
                  child: const Text('Clear selection', style: TextStyle(color: Colors.redAccent)),
                ),
            ]),
          ),
        ),
    ]);
  }

  // ── Filter panel ──────────────────────────────────────────────────────────
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.filter_list_rounded, size: 16, color: primaryBlue),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.close_rounded, size: 13, color: Colors.redAccent),
                  SizedBox(width: 4),
                  Text('Clear all',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 10),
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
                          color: isActive ? Colors.white : primaryBlue)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickFromDate,
              child: _datePill(
                  label: _fromDate != null ? df.format(_fromDate!) : 'From date',
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
                  label: _toDate != null ? df.format(_toDate!) : 'To date',
                  active: _toDate != null),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by staff name...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:
                Icon(Icons.search_rounded, color: primaryBlue, size: 20),
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
                borderSide: BorderSide(color: primaryBlue, width: 1.5)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ]),
    );
  }

  Widget _datePill({required String label, required bool active}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? primaryBlue.withOpacity(0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active
                  ? primaryBlue.withOpacity(0.4)
                  : Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 13, color: active ? primaryBlue : Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? primaryBlue : Colors.grey),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  // ── Summary rows ──────────────────────────────────────────────────────────
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
        child: Row(children: [
          _summaryChip(Icons.list_alt_rounded, '$total Total', Colors.blueGrey),
          const SizedBox(width: 8),
          _summaryChip(Icons.pending_actions_rounded, '$pending Pending', Colors.orange),
          const SizedBox(width: 8),
          _summaryChip(Icons.check_circle_rounded, '$approved Approved', Colors.teal),
          const SizedBox(width: 8),
          _summaryChip(Icons.cancel_rounded, '$rejected Rejected', Colors.redAccent),
          const SizedBox(width: 8),
          _summaryChip(Icons.attach_money_rounded,
              'RM ${totalAmt.toStringAsFixed(2)}', Colors.purple),
        ]),
      ),
    );
  }

  Widget _buildPaymentClaimSummaryRow(List<PaymentClaim> filtered) {
    final total    = filtered.length;
    final pending  = filtered.where((c) => c.status == 'Pending').length;
    final approved = filtered.where((c) => c.status == 'Approved').length;
    final rejected = filtered.where((c) => c.status == 'Rejected').length;
    final paid     = filtered.where((c) => c.paidAt != null).length;
    final totalAmt = filtered.fold<double>(0, (s, c) => s + c.totalAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _summaryChip(Icons.list_alt_rounded, '$total Total', Colors.blueGrey),
          const SizedBox(width: 8),
          _summaryChip(Icons.pending_actions_rounded, '$pending Pending', Colors.orange),
          const SizedBox(width: 8),
          _summaryChip(Icons.check_circle_rounded, '$approved Approved', Colors.teal),
          const SizedBox(width: 8),
          _summaryChip(Icons.verified_rounded, '$paid Paid', Colors.green),
          const SizedBox(width: 8),
          _summaryChip(Icons.cancel_rounded, '$rejected Rejected', Colors.redAccent),
          const SizedBox(width: 8),
          _summaryChip(Icons.attach_money_rounded,
              'RM ${totalAmt.toStringAsFixed(2)}', Colors.purple),
        ]),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      );

  // ── Expense claim card (unchanged) ────────────────────────────────────────
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            _detailRow('Amount', 'RM ${claim.amount.toStringAsFixed(2)}',
                isHighlight: true),
            _detailRow('Date', claim.claimDate.toString().split(' ')[0]),
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
                  border:
                      Border.all(color: Colors.redAccent.withOpacity(0.3)),
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
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),
            if (hasProof) ...[
              Text('Attachment: ${claim.proofFileName ?? 'Proof File'}',
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
                    style: TextStyle(color: Colors.grey.shade500)),
              ]),
          ]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Claim claim, List<Staff> staffList,
      {bool showDelete = false}) {
    final hasProof   = _hasProof(claim);
    final isSelected = selectedClaims.contains(claim.claimId);
    final staffName  = _getStaffName(claim.staffId, staffList);

    Color    statusColor   = Colors.orange;
    Color    statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon    = Icons.pending_actions_rounded;
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
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isSelected ? primaryBlue.withOpacity(0.05) : Colors.white,
        border: Border.all(
            color: isSelected ? primaryBlue : Colors.transparent, width: 1.5),
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
                if (isSelected)
                  selectedClaims.remove(claim.claimId);
                else
                  selectedClaims.add(claim.claimId);
              });
            } else {
              _showClaimDetails(claim, staffList);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 24, color: Colors.orange),
              ),
              const SizedBox(width: 16),
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
                    Text(claim.claimDate.toString().split(' ')[0],
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 12, color: statusColor),
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
                    onTap: () => _showClaimDetails(claim, staffList),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.visibility_rounded,
                          size: 14, color: primaryBlue),
                      const SizedBox(width: 4),
                      Text(hasProof ? 'View Proof' : 'View Details',
                          style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
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
                    onPressed:
                        _processing ? null : () => _deleteClaim(claim),
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
                      if (v == true)
                        selectedClaims.add(claim.claimId);
                      else
                        selectedClaims.remove(claim.claimId);
                    });
                  },
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(List<Claim> allClaims) {
    final controller = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 8),
          Text('Rejection Reason',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
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
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 2)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please provide a reason'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
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
                  final claim = allClaims.firstWhere((c) => c.claimId == id);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Claims',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Approve ${selectedClaims.length} selected claim(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in selectedClaims) {
                final claim = allClaims.firstWhere((c) => c.claimId == id);
                await _approveClaim(claim);
              }
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsList(List<Claim> claims, List<Staff> staffList,
      {bool showActions = false, bool showDelete = false}) {
    final filtered = _applyFilters(claims, staffList);

    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.request_quote_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            (_fromDate != null || _toDate != null || _searchQuery.isNotEmpty)
                ? 'No records match your filter'
                : 'No claims found',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          if (_fromDate != null || _toDate != null || _searchQuery.isNotEmpty)
            ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _applyQuickChip('All');
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear filters'),
            ),
          ],
        ]),
      );
    }

    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _fetchAll,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                EdgeInsets.only(top: 8, bottom: showActions ? 80 : 24),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildClaimCard(filtered[i], staffList,
                showDelete: showDelete),
          ),
        ),
      ),
      if (showActions && selectedClaims.isNotEmpty)
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showRejectDialog(claims),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showApproveDialog(claims),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: HRAppBar(
        title: 'MANAGE CLAIM',
        bottomHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,                        // needed for 4 tabs
          tabAlignment: TabAlignment.center,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text('Pending',    style: TextStyle(color: Colors.white))),
            Tab(child: Text('Approved',   style: TextStyle(color: Colors.white))),
            Tab(child: Text('Rejected',   style: TextStyle(color: Colors.white))),
            Tab(child: Text('Pay Claims', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer3<Staffs, Claims, PaymentClaims>(
        builder: (context, staffsData, claimsData, paymentClaimsData, child) {
          final staffList    = staffsData.staffList;
          final pending      = claimsData.claims.where((c) => c.status == 'Pending').toList();
          final approved     = claimsData.claims.where((c) => c.status == 'Approved').toList();
          final rejected     = claimsData.claims.where((c) => c.status == 'Rejected').toList();
          final paymentClaims = paymentClaimsData.claims;

          final currentTab = _tabController.index;

          // Summary for current tab
          Widget summaryRow;
          if (currentTab < 3) {
            final currentList = currentTab == 0
                ? pending
                : currentTab == 1 ? approved : rejected;
            summaryRow = _buildSummaryRow(_applyFilters(currentList, staffList));
          } else {
            summaryRow = _buildPaymentClaimSummaryRow(
                _applyPaymentClaimFilters(paymentClaims));
          }

          return Column(children: [
            _buildFilterPanel(),
            summaryRow,
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildClaimsList(pending,  staffList, showActions: true),
                  _buildClaimsList(approved, staffList, showDelete: true),
                  _buildClaimsList(rejected, staffList, showDelete: true),
                  // ── 4th tab: Payment Claims ───────────────────────────
                  _buildPaymentClaimsList(paymentClaims, isPending: true),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}