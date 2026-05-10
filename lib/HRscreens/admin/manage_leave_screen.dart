import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ManageLeaveScreen extends StatefulWidget {
  const ManageLeaveScreen({super.key});

  @override
  State<ManageLeaveScreen> createState() => _ManageLeaveScreenState();
}

class _ManageLeaveScreenState extends State<ManageLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _processing = false;

  // ── Filter state ─────────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  String _activeChip = 'All';
  String _searchQuery = '';

  // ── Palette ──────────────────────────────────────────────────────────────────
  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaves() async {
    await Provider.of<Staffs>(context, listen: false).fetchStaff();
    await Provider.of<Leaves>(context, listen: false).fetchLeaves();
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

  // ── Date filter ───────────────────────────────────────────────────────────────
  List<Leave> _applyFilters(List<Leave> leaves, List<Staff> staffList) {
    return leaves.where((leave) {
      // Date filter on startDate
      if (_fromDate != null) {
        final from =
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (leave.startDate.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(
            _toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (leave.startDate.isAfter(to)) return false;
      }
      // Search by staff name
      if (_searchQuery.isNotEmpty) {
        final name =
            _getStaffName(leave.staffId, staffList).toLowerCase();
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
        default: // 'All'
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

  // ── Reject dialog ─────────────────────────────────────────────────────────────
  Future<String?> _showRejectionReasonDialog() async {
    final controller = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    return showDialog<String>(
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
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 2),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please provide a reason'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Reject'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Leave actions ─────────────────────────────────────────────────────────────
  Future<void> _handleLeaveAction(Leave leave, String action) async {
    if (_processing) return;

    String? rejectionReason;
    if (action == 'reject') {
      rejectionReason = await _showRejectionReasonDialog();
      if (rejectionReason == null) return;
    }

    setState(() => _processing = true);
    try {
      final updatedLeave = Leave(
        leaveId:         leave.leaveId,
        staffId:         leave.staffId,
        leaveType:       leave.leaveType,
        startDate:       leave.startDate,
        endDate:         leave.endDate,
        reason:          leave.reason,
        proofFileName:   leave.proofFileName,
        proofFileType:   leave.proofFileType,
        proofFile:       leave.proofFile,
        proofFilePath:   leave.proofFilePath,
        proofFileUrl:    leave.proofFileUrl,
        status:          action == 'approve' ? 'Approved' : 'Rejected',
        rejectionReason: action == 'reject' ? rejectionReason : null,
        createdAt:       leave.createdAt,
        updatedAt:       DateTime.now(),
      );

      await Provider.of<Leaves>(context, listen: false)
          .updateLeave(updatedLeave);
      await _fetchLeaves();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'approve'
            ? 'Leave approved successfully'
            : 'Leave rejected successfully'),
        backgroundColor:
            action == 'approve' ? Colors.teal : Colors.redAccent,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update leave: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _handleLeaveDelete(Leave leave) async {
    if (_processing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Leave',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this leave record?'),
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
      await Provider.of<Leaves>(context, listen: false)
          .deleteLeave(leave.leaveId);
      await _fetchLeaves();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Leave record deleted successfully'),
          backgroundColor: Colors.teal));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete leave: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

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
          // Header row
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
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: primaryBlue, width: 1.5),
              ),
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

  // ── Summary chips ─────────────────────────────────────────────────────────────
  Widget _buildSummaryRow(List<Leave> filtered) {
    final total    = filtered.length;
    final pending  = filtered.where((l) => l.status.trim().toLowerCase() == 'pending').length;
    final approved = filtered.where((l) => l.status.trim().toLowerCase() == 'approved').length;
    final rejected = filtered.where((l) => l.status.trim().toLowerCase() == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip(Icons.list_alt_rounded, '$total Total', Colors.blueGrey),
            const SizedBox(width: 8),
            _summaryChip(Icons.pending_actions_rounded, '$pending Pending', Colors.orange),
            const SizedBox(width: 8),
            _summaryChip(Icons.check_circle_rounded, '$approved Approved', Colors.teal),
            const SizedBox(width: 8),
            _summaryChip(Icons.cancel_rounded, '$rejected Rejected', Colors.redAccent),
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
          borderRadius: BorderRadius.circular(10),
        ),
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

  // ── Leave card ────────────────────────────────────────────────────────────────
  Widget _buildLeaveCard(Leave leave, List<Staff> staffList,
      {bool showDelete = false}) {
    final status     = leave.status.trim().toLowerCase();
    final staffName  = _getStaffName(leave.staffId, staffList);

    Color    statusColor   = Colors.orange;
    Color    statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon    = Icons.pending_actions_rounded;

    if (status == 'approved') {
      statusColor   = Colors.teal;
      statusBgColor = Colors.teal.withOpacity(0.1);
      statusIcon    = Icons.check_circle_rounded;
    }
    if (status == 'rejected') {
      statusColor   = Colors.redAccent;
      statusBgColor = Colors.redAccent.withOpacity(0.1);
      statusIcon    = Icons.cancel_rounded;
    }

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Staff Name',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      Text(staffName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(leave.status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (showDelete) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: _processing
                          ? null
                          : () => _handleLeaveDelete(leave),
                    ),
                  ),
                ],
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

            // ── Details ──────────────────────────────────────────────────
            _infoRow(Icons.category_rounded, 'Type', leave.leaveType),
            const SizedBox(height: 6),
            _infoRow(
              Icons.date_range_rounded,
              'Date',
              '${DateFormat('dd MMM yyyy').format(leave.startDate)} → ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.subject_rounded,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text('Reason: ',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Expanded(
                    child: Text(leave.reason,
                        style: const TextStyle(
                            color: Color(0xFF334155), fontSize: 13))),
              ],
            ),

            // Rejection reason box
            if (status == 'rejected' &&
                leave.rejectionReason != null &&
                leave.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rejection Reason',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(leave.rejectionReason!,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            ProofAttachmentViewer(
              fileUrl:  leave.proofFileUrl,
              fileName: leave.proofFileName,
              fileType: leave.proofFileType,
            ),

            // Approve / Reject buttons (pending only)
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processing
                          ? null
                          : () => _handleLeaveAction(leave, 'reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processing
                          ? null
                          : () => _handleLeaveAction(leave, 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon:
                          const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontSize: 13))),
        ],
      );

  // ── Leave list ────────────────────────────────────────────────────────────────
  Widget _buildStatusList(
      List<Leave> leaves, List<Staff> staffList,
      {bool showDelete = false}) {
    final filtered = _applyFilters(leaves, staffList);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              (_fromDate != null ||
                      _toDate != null ||
                      _searchQuery.isNotEmpty)
                  ? 'No records match your filter'
                  : 'No leave records found',
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

    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: _fetchLeaves,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        itemCount: filtered.length,
        itemBuilder: (_, i) =>
            _buildLeaveCard(filtered[i], staffList, showDelete: showDelete),
      ),
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
        title: const Text('MANAGE LEAVE',
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
            onPressed: _fetchLeaves,
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
      body: Consumer2<Staffs, Leaves>(
        builder: (context, staffsData, leavesData, child) {
          final staffList = staffsData.staffList;
          final allLeaves = leavesData.leaves;

          final pending  = allLeaves.where((l) => l.status.trim().toLowerCase() == 'pending').toList();
          final approved = allLeaves.where((l) => l.status.trim().toLowerCase() == 'approved').toList();
          final rejected = allLeaves.where((l) => l.status.trim().toLowerCase() == 'rejected').toList();

          // Summary uses current tab's filtered results
          final currentTab = _tabController.index;
          final currentList = currentTab == 0
              ? pending
              : currentTab == 1
                  ? approved
                  : rejected;

          return Stack(
            children: [
              Column(
                children: [
                  // ── Filter panel ───────────────────────────────────────
                  _buildFilterPanel(),

                  // ── Summary row ────────────────────────────────────────
                  _buildSummaryRow(
                      _applyFilters(currentList, staffList)),

                  const SizedBox(height: 8),

                  // ── Tab content ────────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStatusList(pending,  staffList),
                        _buildStatusList(approved, staffList, showDelete: true),
                        _buildStatusList(rejected, staffList, showDelete: true),
                      ],
                    ),
                  ),
                ],
              ),
              if (_processing)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: primaryBlue)),
                ),
            ],
          );
        },
      ),
    );
  }
}